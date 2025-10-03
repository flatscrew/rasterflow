namespace AudioVideo {
    class CameraDeviceProperty : Data.DataProperty {

        private Gtk.ComboBoxText combobox;
        private string first_device;

        ~CameraDeviceProperty() {
            if (combobox != null) {
                combobox.unparent();
            }
        }
        
        public CameraDeviceProperty(ParamSpecString string_spec) {
            base(string_spec);


            var monitor = new Gst.DeviceMonitor();
            monitor.set_show_all_devices (true);
            var caps = Gst.Caps.from_string ("video/x-raw");
            monitor.add_filter ("Video/Source", caps);
            
            var devices = monitor.get_devices ();
            if (devices == null || devices.length() == 0) {
                message ("No video devices found.\n");
                return;
            }
            
            this.combobox = new Gtk.ComboBoxText();

            bool first = true;
            foreach (var device in devices) {
                var properties = device.get_properties ();
                var device_path = properties.get_string ("device.path");
                if (device_path == null) {
                    continue;
                }
                if (first) {
                    this.first_device = device_path;
                    first = false;
                }
                var device_name = properties.get_string ("v4l2.device.card");
                combobox.append(device_path, device_name);
            }

            combobox.changed.connect(() => {
                property_value_changed(combobox.get_active_id());
            });
            combobox.set_parent (this);
        }

        internal override GLib.Value? default_value() {
            return this.first_device;
        }

        protected override void set_property_value(GLib.Value value) {
            combobox.set_active_id(value.get_string());
        }
    }
}