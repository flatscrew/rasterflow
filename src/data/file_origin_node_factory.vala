namespace Data {

    public class FileOriginNodeBuilder : Object {

        public string node_builder_id {
            get;
            private set;
        }

        public FileOriginNodeBuilder(string node_builder_id) {
            this.node_builder_id = node_builder_id;
        }

        public virtual void apply_file_data(CanvasDisplayNode node, File file, FileInfo file_info) {

        }

        public CanvasNodeBuilder? find_builder(CanvasNodeFactory node_factory) {
            return node_factory.find_builder(node_builder_id);
        }
    }

    public class FileOriginNodeFactory : Object {
        private Gee.MultiMap<string, FileOriginNodeBuilder> data_type_builders = new Gee.HashMultiMap<string, FileOriginNodeBuilder> ();

        public void register(FileOriginNodeBuilder node_builder, string[] mime_types) {
            foreach (var mime_type in mime_types) {
                try {
                    data_type_builders.set(mime_type, node_builder);
                } catch (RegexError e) {
                    warning(e.message);
                }
            }
        }

        public FileOriginNodeBuilder[] available_builders(string content_type) {
            FileOriginNodeBuilder[] builders = {};

            foreach (var key in data_type_builders.get_keys()) {
                Regex regex = new Regex(key);
                if (regex.match(content_type)) {
                    foreach (var builder in data_type_builders.get(key)) {
                        builders += builder;
                    }
                }
            }
            return builders;
        }
    }
}