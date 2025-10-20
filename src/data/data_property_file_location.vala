namespace Data {
    class FileLocationProperty : Data.AbstractDataProperty {

        private Gtk.Box box;
        private Gtk.Button file_chooser_button;
        private Gtk.Label file_location_label;
        private Gtk.FileDialog file_dialog;

        ~FileLocationProperty() {
            box.unparent();
        }

        public FileLocationProperty(ParamSpecString string_spec) {
            base(string_spec);

            var all_filter = new Gtk.FileFilter();
            all_filter.name = "Any file";
            all_filter.add_pattern("*");

            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
            filters.append(all_filter);

            setup(string_spec, filters);
        }

        public FileLocationProperty.with_file_filters(ParamSpecString string_spec, GLib.ListStore filters) {
            base(string_spec);
            setup(string_spec, filters);
        }

        private void setup(ParamSpecString string_spec, GLib.ListStore filters) {
            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            this.file_location_label = new Gtk.Label("");
            file_location_label.ellipsize = Pango.EllipsizeMode.END;
            file_location_label.add_css_class("property_label_text");

            this.file_dialog = new Gtk.FileDialog();
            file_dialog.set_filters(filters);

            this.file_chooser_button = new Gtk.Button.with_label("Choose a File");
            file_chooser_button.clicked.connect(() => open_dialog());

            box.append(file_chooser_button);
            box.append(file_location_label);
            box.set_parent(this);
        }

        private void open_dialog() {
            var parent_window = base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window;

            file_dialog.open.begin(parent_window, null, (obj, res) => {
                try {
                    var file = file_dialog.open.end(res);
                    if (file != null) {
                        var path = file.get_path();
                        property_value_changed(path);
                        file_location_label.set_text(path);
                    }
                } catch (Error e) {
                    warning("File dialog cancelled or failed: %s", e.message);
                }
            });
        }

        protected override void set_property_value(GLib.Value value) {
            file_location_label.set_text(value.get_string());
        }
    }
}
