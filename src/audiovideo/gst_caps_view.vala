namespace AudioVideo {

    public class GstCapabilitiesViewToggle : Gtk.Widget {

        private GstCapabilitiesView capabilities_view;
        private Gtk.Popover popover;
        private Gtk.ToggleButton toggle_button;
        
        construct {
            set_layout_manager (new Gtk.BinLayout ());
        }

        ~GstCapabilitiesViewToggle() {
            if (popover != null) {
                popover.unparent();
            } 
            if (toggle_button != null) {
                toggle_button.unparent();
            }
        }

        public GstCapabilitiesViewToggle(Gst.Caps caps) {
            this.capabilities_view = new GstCapabilitiesView(caps);
            if (!capabilities_view.supports_any) {
                return;
            }

            this.popover = new Gtk.Popover();
            var button_icons_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 1);

            this.toggle_button = new Gtk.ToggleButton();
            toggle_button.valign = Gtk.Align.CENTER;
            toggle_button.toggled.connect(this.button_toggled);

            if (capabilities_view.supports_image) {
                button_icons_box.append(new Gtk.Image.from_icon_name("image-x-generic-symbolic"));
            }
            if (capabilities_view.supports_audio) {
                button_icons_box.append(new Gtk.Image.from_icon_name("audio-x-generic-symbolic"));
            }
            if (capabilities_view.supports_video) {
                button_icons_box.append(new Gtk.Image.from_icon_name("video-x-generic-symbolic"));
            }
            if (capabilities_view.supports_text) {
                button_icons_box.append(new Gtk.Image.from_icon_name("text-x-generic-symbolic"));
            }

            popover.set_parent(this);
            popover.set_child(capabilities_view);
            popover.closed.connect(this.popover_closed);

            toggle_button.set_child(button_icons_box);
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
    }

    public class GstCapabilitiesView : Gtk.Widget {

        construct {
            set_layout_manager (new Gtk.BinLayout ());
        }

        ~GstCapabilitiesView() {
            scrolled_window.unparent();
        }

        private Gst.Caps caps;
        private Gtk.ScrolledWindow scrolled_window;

        public bool supports_image {
            get;
            private set;
        }

        public bool supports_video {
            get;
            private set;
        }

        public bool supports_audio {
            get;
            private set;
        }

        public bool supports_text {
            get;
            private set;
        }

        public bool supports_any {
            get {
                return supports_image || supports_video || supports_audio || supports_text;
            }
        }

        public GstCapabilitiesView(Gst.Caps caps) {
            this.caps = caps;

            this.scrolled_window = new Gtk.ScrolledWindow();
            scrolled_window.set_parent(this);
            scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolled_window.set_max_content_height(400);
            scrolled_window.set_min_content_width(400);
            scrolled_window.set_propagate_natural_height(true);

            var view_grid = new Gtk.Grid ();
            view_grid.margin_start = view_grid.margin_end = view_grid.margin_top = view_grid.margin_end = 5;
            view_grid.column_spacing = view_grid.row_spacing = 3;
            view_grid.vexpand = true;
            view_grid.hexpand = true;

            var rows = 0;
            for (var index = 0; index < caps.get_size (); index++) {
                unowned var structure = caps.get_structure (index);
                update_supports(structure);

                var structure_label = new Gtk.Label ("");
                structure_label.set_markup("<b>%s</b>".printf(structure.get_name ()));
                view_grid.attach (structure_label, 0, ++rows, 2, 1);

                for (int field_index = 0; field_index < structure.n_fields (); field_index++) {
                    var field_name = structure.nth_field_name (field_index);
                    var field_name_label = new Gtk.Label("%s:".printf(field_name));
                    field_name_label.valign = Gtk.Align.START;
                    field_name_label.halign = Gtk.Align.END;

                    var value_label = new Gtk.Label(to_text(structure.get_value (field_name)));
                    value_label.wrap = true;
                    value_label.wrap_mode = Pango.WrapMode.WORD;
                    value_label.halign = Gtk.Align.START;

                    view_grid.attach (field_name_label, 0, ++rows, 1, 1);
                    view_grid.attach (value_label, 1, rows, 1, 1);
                }
            }

            scrolled_window.set_child(view_grid);
        }

        private void update_supports(Gst.Structure caps_structure) {
            var name = caps_structure.get_name();

            if (name.has_prefix("audio/")) {
                this.supports_audio = true;
            } else if (name.has_prefix("video/")) {
                this.supports_video = true;
            } else if (name.has_prefix("image/")) {
                this.supports_image = true;
            } else if (name.has_prefix("text/")) {
                this.supports_text = true;
            }
        }

        private string to_text(GLib.Value value) {
            var value_type = value.type();
        
            if (value_type == Type.STRING) {
                return value.get_string();
            } else if (value_type == Type.BOOLEAN) {
                return "%s".printf(value.get_boolean() ? "yes" : "no");
            } else if (value_type == Type.UCHAR) {
                return "%c".printf(value.get_uchar());
            } else if (value_type == Type.INT) {
                return "%d".printf(value.get_int());
            } else if (value_type == Type.UINT) {
                return "%u".printf(value.get_uint());
            } else if (value_type == Type.INT64) {
                return "%lld".printf(value.get_int64());
            } else if (value_type == Type.UINT64) {
                return "%llu".printf(value.get_uint64());
            } else if (value_type == Type.LONG) {
                return "%ld".printf(value.get_long());
            } else if (value_type == Type.ULONG) {
                return "%lu".printf(value.get_ulong());
            } else if (value_type == Type.FLOAT) {
                return "%.2f".printf(value.get_float());
            } else if (value_type == Type.DOUBLE) {
                return "%.2f".printf(value.get_double());
            } else if (value_type == Type.ENUM || value_type == Type.FLAGS) {
                return "%d".printf(value.get_enum());
            } else if (value_type == typeof(Gst.IntRange)) {
                var min = Gst.Value.get_int_range_min(value);
                var max = Gst.Value.get_int_range_max(value);
                return "[%d - %d]".printf(min, max);
            } else if (value_type == typeof(Gst.FractionRange)) {
                var max = Gst.Value.get_fraction_range_max(value);
                var max_denominator = Gst.Value.get_fraction_denominator(max);
                var max_numerator = Gst.Value.get_fraction_numerator(max);
                
                var min = Gst.Value.get_fraction_range_min(value);
                var min_denominator = Gst.Value.get_fraction_denominator(min); 
                var min_numerator = Gst.Value.get_fraction_numerator(min); 

                return "[%d/%d - %d/%d]".printf(min_numerator, min_denominator, max_numerator, max_denominator);
            } else if (value_type == typeof(Gst.ValueList)) {
                string[] elements = {};
                for (var index = 0; index < Gst.ValueList.get_size(value); index++) {
                    elements += to_text(Gst.ValueList.get_value(value, index));
                }
                return string.joinv(", ", elements);
            } else {
                debug("unsupported type: %s\n", value.type_name());
                return "??";
            }
        }

        
    }
}