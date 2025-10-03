namespace Data {

    public class FileOriginNodeChooser : Gtk.Widget {

        public signal void node_created(CanvasDisplayNode node);

        private DataNodeChooserBox chooser_box;
        private CanvasNodeFactory node_factory;
        private GLib.File file;
        private GLib.FileInfo file_info;

        private Gee.Map<string, FileOriginNodeBuilder> builders = new Gee.HashMap<string, FileOriginNodeBuilder>();
        
        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        public FileOriginNodeChooser(
                CanvasNodeFactory node_factory, 
                FileOriginNodeBuilder[] builders,
                GLib.File file,
                GLib.FileInfo file_info) {
            this.node_factory = node_factory;
            this.file = file;
            this.file_info = file_info;

            create_builders_list(builders);
        }

        private void create_builders_list(FileOriginNodeBuilder[] builders) {
            this.builders.clear();
            foreach (var builder in builders) {
                this.builders.set(builder.node_builder_id, builder);
            }

            this.chooser_box = new DataNodeChooserBox.with_static_filter(node_factory, this.builders.keys.to_array());
            chooser_box.builder_selected.connect(this.builder_selected);
            chooser_box.set_parent(this);
        }

        private void builder_selected(CanvasNodeBuilder builder) {
            try {
                var new_node = builder.create();

                var file_builder = this.builders.get(builder.id());
                if (file_builder == null) {
                    warning("Unable to find builder with id: %s\n", builder.id());
                    return;
                }
                file_builder.apply_file_data(new_node, this.file, this.file_info);
                this.node_created(new_node);
            } catch (Error e) {
                warning(e.message);
            }
        }
    }
}