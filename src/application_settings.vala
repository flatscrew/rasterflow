public class AppSettings : Object {
    private GLib.Settings settings;

    private const string SIDEBAR_VISIBLE = "sidebar-visible";
    private const string WINDOW_X_KEY = "window-x";
    private const string WINDOW_Y_KEY = "window-y";
    private const string WINDOW_WIDTH_KEY = "window-width";
    private const string WINDOW_HEIGHT_KEY = "window-height";

    public AppSettings(string schema_id = "io.flatscrew.RasterFlow") {
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

    public bool is_sidebar_visible() {
        return settings.get_boolean(SIDEBAR_VISIBLE);
    }

    public void write_sidebar_visible(bool value) {
        settings.set_boolean(SIDEBAR_VISIBLE, value);
    }
}
