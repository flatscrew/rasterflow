namespace Image {

    public class GeglOperationsFactory : Object {
        public static void register_gegl_operations(CanvasNodeFactory node_factory) {
            var gegl_operations = Gegl.list_operations();
            foreach (var gegl_operation in gegl_operations) {
                var title = Gegl.Operation.get_key(gegl_operation, "title");
                if (title == null) {
                    title = gegl_operation;
                }

                var description = Gegl.Operation.get_key(gegl_operation, "description");
                string pango_compatible_description = description
                    .replace("<code>", "<tt>")
                    .replace("</code>", "</tt>")
                    .replace("<em>", "<i>")
                    .replace("</em>", "</i>")
                    .replace(" > ", " &gt;")
                    .replace(" < ", " &lt;")
                    .replace(" <= ", " &lt;=");

                node_factory.register(
                    new GeglOperationNodeBuilder(
                        title, 
                        gegl_operation, 
                        pango_compatible_description
                    )
                );
            }
        }
    }

    public class GeglOperationNodeBuilder : CanvasNodeBuilder, Object {
        private string node_name;
        private string gegl_operation;
        private string? gegl_description;

        internal GeglOperationNodeBuilder(string name, string gegl_operation, string? gegl_description = null) {
            this.node_name = name;
            this.gegl_operation = gegl_operation;
            this.gegl_description = gegl_description;
        }

        public CanvasDisplayNode create() throws Error {
            return new GeglOperationDisplayNode(
                gegl_operation, 
                new GeglOperationNode(node_name, gegl_operation)
            );
        }

        public string name() {
            return node_name;
        }

        public override string? description() {
            return "<b>[%s]</b> %s".printf(gegl_operation, gegl_description);
        }

        public string id() {
            return gegl_operation;
        }
    }

    public class GeglContext : GLib.Object {
        public Gegl.Node context {get; private set;}
        private static GeglContext? instance = null;

        private GeglContext() {
            this.context = new Gegl.Node();
        }

        public static Gegl.Node root_node() {
         
            if (GeglContext.instance == null) {
                GeglContext.instance = new GeglContext();
            }
            return GeglContext.instance.context;
        }
    }

    public class PadSink : CanvasNodeSink {
        public signal void updated();
        
        public Gegl.Node gegl_node {get; private set;}
        public string padname {get; private set;}

        public PadSink (Gegl.Node n, string padname) {
            base(n);
            this.gegl_node = n;
            this.padname = padname;

            this.linked.connect(this.connected);
            this.unlinked.connect(this.disconnected);
            this.changed.connect(this.sink_updated);
        }

        private void disconnected(GFlow.Dock target) {
            this.gegl_node.disconnect(this.padname);
            sink_updated();
        }

        private void connected(GFlow.Dock target) {
            if (target is PadSource) {
                var target_source = target as PadSource;
                target_source.gegl_node.connect_to(target_source.padname, gegl_node, padname);
                sink_updated();
            } else {
                warning("Not supported target source: %s\n", target.get_type().name());
            }
        }

        private void sink_updated() {
            this.updated();
        }
    }

    public class PadSource : CanvasNodeSource {
        public Gegl.Node gegl_node {get; set;}
        public string padname {get; private set;}

        public PadSource (Gegl.Node gegl_node, string padname) {
            base(gegl_node);
            this.gegl_node = gegl_node;
            this.padname = padname;
        }
    }

    public interface GeglProcessor : Object {
        internal abstract void process_gegl();
    }

    public class GeglOperationNode : CanvasNode, GeglProcessor {
        private string gegl_operation;
        private ImageProcessingRealtimeGuard realtime_guard;
        private bool realtime_processing;
        internal Gegl.Node gegl_node {
            get;
            private set;
        }
        private Gee.Map<string, GLib.Type> changed_properties = new Gee.HashMap<string, GLib.Type>();

        ~GeglOperationNode() {
            remove_from_graph();
        }

        public GeglOperationNode(string node_name, string gegl_operation) {
            base(node_name);
            this.gegl_operation = gegl_operation;
            this.realtime_guard = ImageProcessingRealtimeGuard.instance;
            this.realtime_processing = realtime_guard.enabled;
            this.realtime_guard.mode_changed.connect(this.realtime_mode_changed);

            create_gegl_node();
            create_sinks();
            create_sources();
        }

        private void realtime_mode_changed(bool is_realtime) {
            this.realtime_processing = is_realtime;
        }

        private void create_gegl_node() {
            this.gegl_node = GeglContext.root_node().create_child(gegl_operation);

            var properties = gegl_node.gegl_operation.get_class().list_properties();
            foreach (var param_spec in properties) {
                gegl_node.gegl_operation.notify[param_spec.name].connect(this.gegl_node_property_changed);
            }
        }

        private void create_sinks() {
            foreach (string padname in gegl_node.list_input_pads()) {
                var sink = new PadSink(gegl_node, padname);
                sink.name = padname[0].to_string().up().concat(padname.substring(1));
                sink.updated.connect(this.process_gegl);
                this.add_sink(sink);
            }
        }

        private void create_sources() {
            foreach (string padname in gegl_node.list_output_pads()) {
                var source = new PadSource(gegl_node, padname);
                source.name = padname[0].to_string().up().concat(padname.substring(1));
                this.add_source(source);
            }
        }

        internal void process_gegl() {
            var has_connected_sinks = false;
            foreach (var source in get_sources()) {
                if (source.sinks.length() > 0) {
                    has_connected_sinks = true;
                    break;
                }
            }
            if (!has_connected_sinks) {
                if (get_sources().length() == 0) {
                    gegl_node.process();
                } else {
                    debug("no connected sinks for node %s!\n", name);
                }
                return;
            }

            // sending notification to all other connected nodes
            if (!realtime_processing) return;

            foreach (var source in get_sources()) {
                if (!(source is PadSource)) {
                    continue;
                }
                var pad_source = source as PadSource;
                foreach (var sink in pad_source.sinks) {
                    var target_node = sink.node as GeglProcessor;
                    target_node.process_gegl();
                }
            }
        }

        private void remove_from_graph() {
            var context = GeglContext.root_node(); 
            context.remove_child(this.gegl_node);
        }

        private void gegl_node_property_changed(ParamSpec property_spec) {
            changed_properties.set(property_spec.name, property_spec.value_type);
        }

        protected override void serialize(Serialize.SerializedObject serializer) {
            base.serialize(serializer);

            foreach (var changed_property in changed_properties) {
                GLib.Value value = GLib.Value(changed_property.value);
                gegl_node.gegl_operation.get_property(changed_property.key, ref value);
                serializer.set_value(changed_property.key, value);
            }
        }

        protected override void deserialize(Serialize.DeserializedObject deserializer) {
            deserializer.for_each_property((name, value) => {
                gegl_node.set_property(name, value);
            });
        }

        internal Gegl.Operation get_gegl_operation() {
            return this.gegl_node.gegl_operation;
        }

        public bool is_output_node() {
            return gegl_node.list_output_pads().length == 0
                && gegl_node.list_input_pads().length > 0;
        }
    }

    class OverridenTitleWidgetBuilder : CanvasNodeTitleWidgetBuilder, Object {
        private Gtk.Widget title_widget;
        
        public OverridenTitleWidgetBuilder(Gtk.Widget title_widget) {
            this.title_widget = title_widget;
        }

        public Gtk.Widget? build_title_widget(CanvasNode _) {
            return title_widget;
        }   
    }

    class GeglOperationDisplayNode : CanvasDisplayNode {
        private GeglOperationNode gegl_operation_node;
        private GeglOperationOverridesCallback? operation_overrides_callback;
        private Data.DataDisplayView data_display_view;

        public GeglOperationDisplayNode(string builder_id, GeglOperationNode node) {
            base(builder_id, node);

            this.details_expand_toggled.connect(this.node_details_expanded);
            this.data_display_view = new Data.DataDisplayView();
            this.gegl_operation_node = node;
            this.gegl_operation_node.sink_added.connect_after(this.sink_added);
            this.operation_overrides_callback = GeglOperationOverrides.find_operation_overrides(builder_id);

            if (operation_overrides_callback != null) {
                var title_widget = operation_overrides_callback.build_title(gegl_operation_node.get_gegl_operation());
                build_title(new OverridenTitleWidgetBuilder(title_widget));

                var overriden_widget = operation_overrides_callback.build_operation(gegl_operation_node.get_gegl_operation());
                if (overriden_widget != null) {
                    add_child(overriden_widget);
                } else {
                    add_default_content(gegl_operation_node.get_gegl_operation());
                }
            } else {
                build_default_title();
                add_default_content(gegl_operation_node.get_gegl_operation());
            }

            if (node.is_output_node()) {
                create_process_gegl_button();
            } else {
                create_gegl_export_button();
            }
        }

        private void node_details_expanded(bool expanded) {
            if (!expanded) return;

            this.set_size_request(400, 300);
        }

        private void create_process_gegl_button() {
            var render_button = new Gtk.Button.from_icon_name("media-playback-start");
            render_button.clicked.connect(gegl_operation_node.process_gegl);
            render_button.set_tooltip_text("Process");
            add_action_bar_child_start(render_button);
        }

        private void create_gegl_export_button() {
            var export_button = new Gtk.Button.from_icon_name("document-export-symbolic");
            export_button.clicked.connect(export_graph_as_xml);
            export_button.set_tooltip_text("Export to XML");
            add_action_bar_child_end(export_button);
        }

        public void add_default_content(Gegl.Operation operation) {
            var scrolled_window = new Gtk.ScrolledWindow();
            scrolled_window.vexpand = scrolled_window.hexpand = true;
            scrolled_window.set_propagate_natural_height(true);
            scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC); 
            scrolled_window.set_placement(Gtk.CornerType.TOP_RIGHT);

            var properties_editor = new Data.DataPropertiesEditor(operation);
            properties_editor.vexpand = true;
            properties_editor.data_property_changed.connect(this.property_changed);
            properties_editor.enable_control_override(
                this.check_supported_pad_data_type, 
                "Promote as property pad",
                this.on_property_promoted
            );
            properties_editor.populate_properties(
                () => true,
                compose_overrides
            );

            data_display_view.add_child(properties_editor);
            data_display_view.set_margin(10);

            if (properties_editor.has_properties) {
                scrolled_window.set_child(data_display_view);
                add_child(scrolled_window);
            } else {
                n.resizable = false;
            }
        }

        private bool check_supported_pad_data_type(GLib.ParamSpec param_spec) {
            if (param_spec is ParamSpecString 
                || param_spec is ParamSpecInt
                || param_spec is ParamSpecDouble) {
                return true;
            }
            // TODO introduce one place for supported types maybe?
            return false;
        }

        private void on_property_promoted(ParamSpec param_spec) {
            // TODO introduce some kind of controller that will be 
            // passed to this method instead of just param spec
            var property_sink = new CanvasNodePropertySink(param_spec);
            gegl_operation_node.add_sink(property_sink);
        }

        private void sink_added(GFlow.Sink new_sink) {
            var canvas_view = get_parent() as GtkFlow.NodeView;
            if (canvas_view == null) {
                return;
            }

            var dock = canvas_view.retrieve_dock(new_sink);
            if (dock == null) {
                warning("Unable to find dock");
            }
            dock.resolve_color.connect_after(this.node_property_sink_edge_color);
        }

        private Gdk.RGBA node_property_sink_edge_color(GtkFlow.Dock dock, Value? value) {
            return {
                red: 0.63f,
                green: 0.63f,
                blue: 0.63f,
                alpha: 1.0f
            };
        }

        private void compose_overrides(Data.PropertyOverridesComposer composer) {
            if (operation_overrides_callback == null) {
                return;
            }
            operation_overrides_callback.copy_property_overrides(composer);
        }

        internal void set_gegl_property(string name, GLib.Value value) {
            gegl_operation_node.get_gegl_operation().set_property(name, value);
        }

        private void property_changed(string property_name, GLib.Value property_value) {
            unowned var node = n as GeglOperationNode;
            node.process_gegl();
        }

        private void export_graph_as_xml () {
            var file_dialog = new Gtk.FileDialog ();
            var filter = new Gtk.FileFilter ();
            filter.name = "GEGL XML graph";
            filter.add_pattern ("*.xml");

            var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
            filters.append (filter);

            file_dialog.set_filters (filters);
            file_dialog.set_initial_name ("untitled.xml");

            file_dialog.save.begin (base.get_ancestor (typeof (Gtk.Window)) as Gtk.Window, null, (obj, res) => {
                try {
                    var file = file_dialog.save.end (res);
                    if (file != null) {
                        string path = file.get_path ();

                        var exporter = new Image.GXml.Exporter ();
                        exporter.export_to (gegl_operation_node.gegl_node, path);

                        message ("Exported graph to: %s", path);
                    }
                } catch (Error e) {
                    warning ("Export cancelled or failed: %s", e.message);
                }
            });
        }
    }
}