namespace AudioVideo {
    class PadProperty : Data.DataProperty {

        private Gst.Element element;
        private Gtk.ComboBoxText combobox;
        private Gst.PadDirection pad_direction;

        private string? selected_pad;

        ~PadProperty() {
            combobox.unparent();
        }
        
        public PadProperty(ParamSpec param_spec, Gst.Element element, Gst.PadDirection pad_direction) {
            base(param_spec);
            this.pad_direction = pad_direction;
            this.element = element;

            this.element.pad_added.connect(this.pad_added);
            this.element.pad_removed.connect(this.pad_removed);

            this.combobox = new Gtk.ComboBoxText();
            fill_pads_list();

            combobox.changed.connect(() => {
                var pad_name = combobox.get_active_id();
                if (pad_name == null) {
                    return;
                }
                var pad = element.get_static_pad(pad_name);
                if (pad == null) {
                    warning("Unable to find pad: %s \n", pad_name);
                    return;
                }
                property_value_changed(pad);
            });

            combobox.set_parent (this);
        }

        private void pad_added(Gst.Pad pad) {
            if (pad.direction != this.pad_direction) {
                return;
            }
            fill_pads_list();
        }

        private void pad_removed(Gst.Pad pad) {
            if (pad.direction != this.pad_direction) {
                return;
            }
            fill_pads_list();
        }

        private void fill_pads_list() {
            combobox.remove_all();

            foreach (var pad in element.pads) {
                if (pad.direction != pad_direction) {
                    continue;
                }
                combobox.append(pad.name, pad.name);
            }
            if (this.selected_pad != null) {
                combobox.set_active_id(this.selected_pad);
            }
        }

        protected override void set_property_value(GLib.Value value) {
            if (!(value.type() == typeof (Gst.Pad))) {
                debug("expected to get Gst.Pad type but got: %s\n", value.type_name());
                return;
            }
            var pad = value as Gst.Pad;
            combobox.set_active_id(pad.name);

            this.selected_pad = pad.name;
        }

        //  internal override GLib.Value? default_value() {
        //      return this.first_device;
        //  }
    }
}