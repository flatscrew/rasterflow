public class AppSettings : Object {
    private GLib.Settings settings;

    private const string DARK_VARIANT_PROPERTY = "dark-variant";
    private const string WINDOW_X_KEY = "window-x";
    private const string WINDOW_Y_KEY = "window-y";
    private const string WINDOW_WIDTH_KEY = "window-width";
    private const string WINDOW_HEIGHT_KEY = "window-height";

    public AppSettings(string schema_id = "io.canvas.Canvas") {
        settings = new GLib.Settings(schema_id);
    }

    public void write_window_dimensions(Gdk.Rectangle rect) {
        settings.set_int(WINDOW_X_KEY, rect.x);
        settings.set_int(WINDOW_Y_KEY, rect.y);
        settings.set_int(WINDOW_WIDTH_KEY, rect.width);
        settings.set_int(WINDOW_HEIGHT_KEY, rect.height);
    }

    public Gdk.Rectangle read_window_dimensions() {
        var rect = Gdk.Rectangle();
        rect.x = settings.get_int(WINDOW_X_KEY);
        rect.y = settings.get_int(WINDOW_Y_KEY);
        rect.width = settings.get_int(WINDOW_WIDTH_KEY);
        rect.height = settings.get_int(WINDOW_HEIGHT_KEY);
        return rect;
    }

    public void bind_theme_variant(Gtk.Switch variant_switch) {
        var gtk_settings = Gtk.Settings.get_default();

        variant_switch.bind_property(
            "active",
            gtk_settings,
            "gtk-application-prefer-dark-theme",
            GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.BIDIRECTIONAL
        );

        settings.bind(
            DARK_VARIANT_PROPERTY,
            variant_switch,
            "active",
            GLib.SettingsBindFlags.DEFAULT
        );
    }

    public bool get_dark_variant() {
        return settings.get_boolean(DARK_VARIANT_PROPERTY);
    }

    public void set_dark_variant(bool value) {
        settings.set_boolean(DARK_VARIANT_PROPERTY, value);
    }
}
