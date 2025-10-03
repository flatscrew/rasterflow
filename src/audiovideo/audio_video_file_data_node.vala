namespace AudioVideo {

    public class AudioVideoFileDataDisplayNodeBuilder : Data.FileOriginNodeBuilder {

        public AudioVideoFileDataDisplayNodeBuilder() {
            base("gst:filesrc");
        }
        
        protected override void apply_file_data(CanvasDisplayNode node, File file, FileInfo file_info) {
            var gst_node = node as GstElementDisplayNode;
            gst_node.set_gst_property ("location", file.get_path ());
        }
    }
}