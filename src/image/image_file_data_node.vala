namespace Image {

    public class ImageFileDataDisplayNodeBuilder : Data.FileOriginNodeBuilder {

        public ImageFileDataDisplayNodeBuilder() {
            base("gegl:load");
        }

        protected override void apply_file_data(CanvasDisplayNode node, File file, FileInfo file_info) {
            var gegl_node = node as GeglOperationDisplayNode;
            gegl_node.set_gegl_property("path", file.get_path ());
        }
    }
}