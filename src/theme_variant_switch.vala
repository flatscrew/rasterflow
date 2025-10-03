public class ThemeVariantSwitch : Gtk.Widget {

    private const string DARK_VARIANT_PROPERTY = "dark-variant";

    construct {
        base.set_layout_manager (new Gtk.BinLayout ());
    }

    private Gtk.Box switcher_box;
    private Gtk.Switch variant_switch;
    private GLib.Settings settings;

    public ThemeVariantSwitch(GLib.Settings app_settings) {
        this.settings = app_settings;
        
        this.switcher_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
        this.variant_switch = new Gtk.Switch ();
        var gtk_settings = Gtk.Settings.get_default ();
        variant_switch.bind_property ("active", gtk_settings, "gtk_application_prefer_dark_theme");
        app_settings.bind(DARK_VARIANT_PROPERTY, variant_switch, "active", GLib.SettingsBindFlags.DEFAULT);

        var light_image = new Gtk.Image.from_icon_name ("display-brightness-symbolic");
        var light_controller = new Gtk.GestureClick ();
        light_controller.end.connect (() => {
            variant_switch.active = false;
        });
        light_image.add_controller (light_controller);
        
        var dark_image = new Gtk.Image.from_icon_name ("weather-clear-night-symbolic");
        var dark_controller = new Gtk.GestureClick ();
        dark_controller.end.connect (() => {
            variant_switch.active = true;
        });
        dark_image.add_controller (dark_controller);

        switcher_box.append (light_image);
        switcher_box.append (variant_switch);
        switcher_box.append (dark_image);

        switcher_box.set_parent (this);
    }


    ~ThemeVariantSwitch() {
        switcher_box.unparent ();
    }
}