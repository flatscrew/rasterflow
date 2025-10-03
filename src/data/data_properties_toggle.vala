namespace Data {

    public class DataPropertiesToggle : Gtk.Widget {

        private const string[] FORBIDDEN_PARAMETERS = {
            "name",
            "parent",
            "caps",
            "direction",
            "template",
            "offset",
            "emit-signals"
        };

        private DataPropertiesEditor properties_editor;
        private Gtk.Popover popover;
        private Gtk.ToggleButton toggle_button;
        
        construct {
            set_layout_manager (new Gtk.BinLayout ());
        }

        ~DataPropertiesToggle() {
            if (popover != null) {
                popover.unparent();
            } 
            if (toggle_button != null) {
                toggle_button.unparent();
            }
        }

        public DataPropertiesToggle(GLib.Object data_object) {
            this.properties_editor = new DataPropertiesEditor(data_object, 300);
            if (!properties_editor.populate_properties(this.is_allowed_property)) {
                return;
            }

            this.popover = new Gtk.Popover();

            this.toggle_button = new Gtk.ToggleButton();
            toggle_button.valign = Gtk.Align.CENTER;
            toggle_button.toggled.connect(this.button_toggled);

            popover.set_parent(this);
            popover.set_child(properties_editor);
            popover.closed.connect(this.popover_closed);

            toggle_button.set_child(new Gtk.Image.from_icon_name("open-menu-symbolic"));
            toggle_button.set_parent(this);
        }

        private void button_toggled() {
            if (this.toggle_button.active) {
                this.popover.show();
            } else {
                this.popover.hide();
            }
        }

        private void popover_closed() {
            this.toggle_button.active = false;
        }

        private bool is_allowed_property(GLib.ParamSpec param_spec) {
            foreach (var forbidden in FORBIDDEN_PARAMETERS) {
                if (param_spec.name == forbidden) {
                    return false;
                }
            }
            return true;
        }
    }
}