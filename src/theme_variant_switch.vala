public class ThemeVariantSwitch : Gtk.Widget {
    private Gtk.Box switcher_box;
    private Gtk.Switch variant_switch;
    private AppSettings app_settings;

    construct {
        base.set_layout_manager(new Gtk.BinLayout());
    }

    public ThemeVariantSwitch(AppSettings app_settings) {
        this.app_settings = app_settings;

        this.switcher_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        this.variant_switch = new Gtk.Switch();

        app_settings.bind_theme_variant(this.variant_switch);

        var light_image = new Gtk.Image.from_icon_name("display-brightness-symbolic");
        var light_controller = new Gtk.GestureClick();
        light_controller.end.connect(() => { variant_switch.active = false; });
        light_image.add_controller(light_controller);

        var dark_image = new Gtk.Image.from_icon_name("weather-clear-night-symbolic");
        var dark_controller = new Gtk.GestureClick();
        dark_controller.end.connect(() => { variant_switch.active = true; });
        dark_image.add_controller(dark_controller);

        switcher_box.append(light_image);
        switcher_box.append(variant_switch);
        switcher_box.append(dark_image);
        switcher_box.set_parent(this);
    }

    ~ThemeVariantSwitch() {
        switcher_box.unparent();
    }
}
