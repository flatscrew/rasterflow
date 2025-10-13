namespace Image {

    public class GeglXmlFileOriginNodeBuilder : Data.FileOriginNodeBuilder {

        public GeglXmlFileOriginNodeBuilder() {
            base("image:gegl-xml");
        }

        protected override void apply_file_data(CanvasDisplayNode node, File file, FileInfo file_info) {
            //  var xml_node = node as GeglXmlDisplayNode;
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

    class GeglXmlDisplayNode : CanvasDisplayNode {

        public GeglXmlDisplayNode(string builder_id, GeglXmlDataNode data_node) {
            base (builder_id, data_node, new GtkFlow.NodeDockLabelWidgetFactory(data_node));
        
            build_default_title();
        }
    }

    class GeglXmlDataNode : CanvasNode, GeglProcessor {

        public GeglXmlDataNode() {
            base("GEGL XML Node");
        }

        internal void process_gegl() {
        }
    }
}