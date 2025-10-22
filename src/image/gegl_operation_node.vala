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
            deserializer.for_each_property_with_context_object((name, value) => {
                gegl_node.set_property(name, value);
            }, gegl_node.gegl_operation);
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
}