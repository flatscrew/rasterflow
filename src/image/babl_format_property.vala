namespace Image {

    public class FormatProperty : Data.AbstractDataProperty {

        private Gtk.ComboBoxText combo;
        private string[] format_names;

        ~FormatProperty() {
            combo.unparent();
        }

        public FormatProperty(ParamSpecPointer pointer_spec) {
            base(pointer_spec);

            format_names = {
                "RGB u8",
                "RGBA u8",
                "RGB float",
                "RGBA float",
                "RGB double",
                "RGBA double",

                "R'G'B' u8",
                "R'G'B'A u8",
                "R'G'B' float",
                "R'G'B'A float",

                "HSVA float",
                "HSLA float"
            };

            combo = new Gtk.ComboBoxText();
            combo.set_parent(this);

            foreach (var name in format_names)
                combo.append_text(name);

            combo.changed.connect(on_combo_changed);
        }

        private void on_combo_changed() {
            string? name = combo.get_active_text();
            if (name == null)
                return;
        
            unowned var fmt = Babl.format(name);
            if (fmt == null)
                return;
        
            GLib.Value val = GLib.Value(typeof(void*));
            val.set_pointer((void*)fmt);
        
            property_value_changed(val);
        }

        protected override void set_property_value(GLib.Value value) {
            unowned var fmt = (Babl.Object) value.get_pointer();
            if (fmt == null)
                return;
        
            string encoding = Babl.format_get_encoding(fmt);
        
            for (int i = 0; i < format_names.length; i++) {
                if (format_names[i] == encoding) {
                    combo.set_active(i);
                    return;
                }
            }
        
            combo.set_active(-1);
        }
    }
}
