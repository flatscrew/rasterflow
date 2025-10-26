namespace Image {
    public class ColorProperty : Data.AbstractDataProperty {
        private Gtk.Box box;
        private Gtk.ColorButton color_button;
        private Gtk.ToggleButton prober_button;

        ~ColorProperty() {
            box.unparent();
        }

        public ColorProperty(ParamSpec color_specs) {
            base(color_specs);
            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            color_button = new Gtk.ColorButton();
            
            color_button.set_use_alpha(true);
            box.append(color_button);
            box.set_parent(this);
#if LINUX
            create_color_prober();
#endif
            color_button.color_set.connect(() => {
                var rgba = color_button.rgba;
                double r = rgba.red;
                double g = rgba.green;
                double b = rgba.blue;
                double a = rgba.alpha;

                var color_str = "rgba(%s,%s,%s,%s)".printf(
                    color_part(r), color_part(g), color_part(b), color_part(a)
                );
                property_value_changed(new Gegl.Color(color_str));
            });
        }

#if LINUX
        private void create_color_prober() {
            prober_button = new Gtk.ToggleButton();
            prober_button.add_css_class ("flat");
            prober_button.set_child(new Gtk.Image.from_icon_name ("color-select-symbolic"));
            prober_button.set_tooltip_text("Probe color from screen");

            prober_button.toggled.connect(() => {
                if (prober_button.active)
                    pick_color_async.begin();
            });
            
            box.append(prober_button);
        }

        private async void pick_color_async() {
            double r, g, b;
            bool ok = yield Image.ColorProber.instance.pick_color_async(out r, out g, out b);
            prober_button.active = false;

            if (!ok)
                return;

            var rgba = Gdk.RGBA() {
                red = (float)r,
                green = (float)g,
                blue = (float)b,
                alpha = 1.0f
            };
            color_button.set_rgba(rgba);

            var color_str = "rgba(%s,%s,%s,%s)".printf(
                color_part(r), color_part(g), color_part(b), color_part(1.0)
            );
            property_value_changed(new Gegl.Color(color_str));
        }
#endif

        string color_part(double v) {
            return "%.6f".printf(v).replace(",", ".");
        }

        protected override void set_property_value(GLib.Value value) {
            double r, g, b, a;
            var color = value.get_object() as Gegl.Color;
            color.get_rgba(out r, out g, out b, out a);

            var gdk_color = Gdk.RGBA() {
                red = (float)r,
                green = (float)g,
                blue = (float)b,
                alpha = (float)a
            };
            color_button.set_rgba(gdk_color);
        }
    }
}
