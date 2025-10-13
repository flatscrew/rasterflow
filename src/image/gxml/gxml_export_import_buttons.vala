namespace Image.GXml {

    public class ExportImportButtons : Gtk.Widget {
        
        private Gtk.Box box;
        private Gtk.Button import_button;

        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        public ExportImportButtons() {
            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.add_css_class("linked");

            import_button = new Gtk.Button.from_icon_name("document-import-symbolic");
            import_button.tooltip_text = "Import GEGL XML";
            import_button.clicked.connect(() => {});

            box.append(import_button);
            box.set_parent(this);
        }

        ~ExportImportButtons() {
            box.unparent();
        }
    }
}