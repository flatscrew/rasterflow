namespace Image {

    public class GeglXmlFileOriginNodeBuilder : Data.FileOriginNodeBuilder {

        public GeglXmlFileOriginNodeBuilder() {
            base("image:gegl-xml");
        }

        protected override void apply_file_data(CanvasDisplayNode node, File file, FileInfo file_info) {
            var xml_node = node as GeglXmlDisplayNode;
            xml_node.set_file_path(file.get_path());
        }
    }

    public class GeglXmlDisplayNodeBuilder : CanvasNodeBuilder, Object {

        public CanvasDisplayNode create() throws Error{
            return new GeglXmlDisplayNode(id(), new GeglXmlDataNode());
        }

        public string name() {
            return "GEGL XML";
        }

        public string id() {
            return "image:gegl-xml";
        }
    }

    public class GeglXmlDisplayNode : CanvasDisplayNode {

        private Gtk.Label path_label;

        public GeglXmlDisplayNode(string builder_id, GeglXmlDataNode data_node) {
            base (builder_id, data_node, new GtkFlow.NodeDockLabelWidgetFactory(data_node));
        
            build_default_title();
            add_child(this.path_label = new Gtk.Label(""));
            
        }

        public void set_file_path(string file_path) {
            //  var xml_node = n as GeglXmlDataNode;
            path_label.set_text(file_path);
        }
    }

    public class GeglXmlDataNode : CanvasNode, GeglProcessor {

        private Gegl.Node output_proxy;
        private Gegl.Node? xml_node;

        private PadSource source;

        public GeglXmlDataNode() {
            base("GEGL XML Node");

            this.output_proxy = GeglContext.root_node().create_child("gegl:nop");

            this.source = new PadSource(output_proxy, "output");
            //  gegl_node_sink.linked.connect(this.process_gegl);
            //  gegl_node_sink.unlinked.connect(this.process_gegl);
            source.name = "Output";
            add_source(source);
        }

        internal void process_gegl() {
            // this.xml_node = new Gegl.Node.from_file("");
        }
    }
}