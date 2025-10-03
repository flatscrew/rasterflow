namespace Data {
    class FileLocationProperty : Data.DataProperty {

        private Gtk.Box box;
        private Gtk.Button file_chooser_button;
        private Gtk.FileChooserNative file_chooser_dialog;
        private Gtk.Label file_location_label;
        
        ~FileLocationProperty() {
            box.unparent();
        }
        
        public FileLocationProperty(ParamSpecString string_spec) {
            base(string_spec);

            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            this.file_location_label = new Gtk.Label("");
            file_location_label.ellipsize = Pango.EllipsizeMode.END;
            file_location_label.add_css_class("property_label_text");

            this.file_chooser_dialog = new Gtk.FileChooserNative("Choose a File", base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window, Gtk.FileChooserAction.OPEN, "_Open", "_Cancel");
            file_chooser_dialog.response.connect(handle_dialog_response);

            this.file_chooser_button = new Gtk.Button.with_label("Choose a File");
            file_chooser_button.clicked.connect(file_chooser_dialog.show);
            
            box.append(file_chooser_button);
            box.append(file_location_label);
            box.set_parent(this);
        }

        private void handle_dialog_response(int response_id) {
            if (response_id == Gtk.ResponseType.ACCEPT) {
                var file = file_chooser_dialog.get_file();
                property_value_changed(file.get_path());
                file_location_label.set_text(file.get_path());
                return;
            }
        }

        protected override void set_property_value(GLib.Value value) {
            file_location_label.set_text(value.get_string());
        }
    }
}