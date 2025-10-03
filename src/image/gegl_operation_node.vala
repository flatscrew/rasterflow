namespace Image {

    public class GeglOperationsFactory : Object {
        public static void register_gegl_operations(string[] args, CanvasNodeFactory node_factory) {
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

                node_factory.register(new GeglOperationNodeBuilder(title, gegl_operation, pango_compatible_description), typeof(Gegl.Node));
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
            return new GeglOperationDisplayNode(id(), new GeglOperationNode(node_name, gegl_operation));
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

        public static Gegl.Node rootNode() {
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
        
            create_gegl_node();
            create_sinks();
            create_sources();
        }

        private void create_gegl_node() {
            this.gegl_node = GeglContext.rootNode().create_child(gegl_operation);

            var properties = gegl_node.gegl_operation.get_class().list_properties();
            foreach (var param_spec in properties) {
                gegl_node.gegl_operation.notify[param_spec.name].connect(this.gegl_node_property_changed);
            }
        }

        private void create_sinks() {
            foreach (string padname in gegl_node.list_input_pads()) {
                var sink = new PadSink(gegl_node, padname);
                sink.name = padname[0].to_string().up().concat(padname.substring(1));
                //  sink.updated.connect(this.process_gegl);
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
            //  var has_connected_sinks = false;
            //  foreach (var source in get_sources()) {
            //      if (source.sinks.length() > 0) {
            //          has_connected_sinks = true;
            //          break;
            //      }
            //  }
            //  if (!has_connected_sinks) {
            //      if (get_sources().length() == 0) {
            //          gegl_node.process();
            //      } else {
            //          debug("no connected sinks for node %s!\n", name);
            //      }
            //      return;
            //  }

            //  // sending notification to all other connected nodes
            //  foreach (var source in get_sources()) {
            //      if (!(source is PadSource)) {
            //          continue;
            //      }
            //      var pad_source = source as PadSource;
            //      foreach (var sink in pad_source.sinks) {
            //          var target_node = sink.node as GeglProcessor;
            //          print("Forwarding processing to: %s\n", sink.node.name);
            //          target_node.process_gegl();
            //      }
            //  }
        }

        private void remove_from_graph() {
            var context = GeglContext.rootNode(); 
            context.remove_child(this.gegl_node);
            debug("GEGL children count: %u\n",context.get_children().length());
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
    }

    class GeglOperationDisplayNode : CanvasDisplayNode {
        private GeglOperationNode gegl_operation_node;
        private GeglOperationOverridesCallback? overrides_callback;

        public GeglOperationDisplayNode(string builder_id, GeglOperationNode node) {
            base(builder_id, node);
            this.gegl_operation_node = node;
            this.overrides_callback = GeglOperationOverrides.find_operation_overrides(builder_id);


            if (overrides_callback != null) {
                var overriden_widget = overrides_callback.build_operation(gegl_operation_node.get_gegl_operation());
                if (overriden_widget != null) {
                    add_child(overriden_widget);
                } else {
                    add_default_content();
                }
            } else {
                add_default_content();
            }
        }

        private void add_default_content() {
            var scrolled_window = new Gtk.ScrolledWindow();
            scrolled_window.vexpand = scrolled_window.hexpand = true;
            scrolled_window.set_propagate_natural_height(true);
            scrolled_window.set_min_content_height(150);
            scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC); 
            scrolled_window.set_placement(Gtk.CornerType.TOP_RIGHT);

            var properties_editor = new Data.DataPropertiesEditor(gegl_operation_node.get_gegl_operation());
            properties_editor.data_property_changed.connect(this.property_changed);
            properties_editor.populate_properties(
                () => true,
                compose_overrides
            );

            if (properties_editor.has_properties) {
                scrolled_window.set_child(properties_editor);
                add_child(scrolled_window);
            } else {
                n.resizable = false;
            }
        }

        private void compose_overrides(Data.PropertyOverridesComposer composer) {
            if (overrides_callback == null) {
                return;
            }
            overrides_callback.copy_property_overrides(composer);
        }

        internal void set_gegl_property(string name, GLib.Value value) {
            gegl_operation_node.get_gegl_operation().set_property(name, value);
        }

        private void property_changed(string property_name, GLib.Value property_value) {
            debug("changed property: %s = %s\n", property_name, print_value(property_value));

            //  unowned var node = n as GeglOperationNode;
            //  node.process_gegl();
        }

        string print_value(GLib.Value val) {
            switch (val.type()) {
                case GLib.Type.INT:
                    return "int: %d".printf((int) val);
                case GLib.Type.STRING:
                    return "string: %s".printf((string) val);
                case GLib.Type.BOOLEAN:
                    return "bool: %s".printf((bool) val ? "true" : "false");
                case GLib.Type.DOUBLE:
                    return "double: %g".printf((double) val);
                case GLib.Type.FLOAT:
                    return "float: %g".printf((float) val);
            }
            return "Unknown type or not handled: %s\n".printf(val.type_name());
        }
    }
}