namespace Image.GXml {

    public class Exporter {

        public void export_to (Gegl.Node root_node, string output_file_path) {
            try {
                string xml_data = root_node.to_xml (null);

                FileUtils.set_contents_full (
                    output_file_path,
                    xml_data,
                    xml_data.length,
                    GLib.FileSetContentsFlags.CONSISTENT
                );

                message ("Graph exported to: %s", output_file_path);
            } catch (Error e) {
                warning ("Failed to export graph: %s", e.message);
            }
        }
    }
}
