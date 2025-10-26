using Gtk;
using Gdk;

public class WindowGeometryManager : Object {

    public static Gdk.Rectangle get_geometry(Gtk.Window window) {
        int x = 0, y = 0, width = window.get_width(), height = window.get_height();
        var surface = window.get_surface();

#if LINUX
        if (surface is Gdk.X11.Surface) {
            var x11_surface = surface as Gdk.X11.Surface;
            var display = window.get_display() as Gdk.X11.Display;
            var xid = x11_surface.get_xid();
            unowned var xdisplay = display.get_xdisplay();

            X.Window root;
            uint w, h, border, depth;
            xdisplay.get_geometry(xid, out root, out x, out y, out w, out h, out border, out depth);

            int root_x, root_y;
            X.Window child_return;
            xdisplay.translate_coordinates(xid, root, 0, 0, out root_x, out root_y, out child_return);

            width = (int) w;
            height = (int) h;
            x = root_x;
            y = root_y;
        }
#endif

#if WIN32
        int w, h;
        rf_get_window_rect(surface, out x, out y, out w, out h);
#endif

        return Gdk.Rectangle() { x = x, y = y, width = width, height = height };
    }

    public static void set_geometry(Gtk.Window window, Gdk.Rectangle geom) {
        var surface = window.get_surface();

#if LINUX
        if (surface is Gdk.X11.Surface) {
            var x11_surface = surface as Gdk.X11.Surface;
            var display = window.get_display() as Gdk.X11.Display;
            var xid = x11_surface.get_xid();
            unowned var xdisplay = display.get_xdisplay();

            xdisplay.move_window(xid, geom.x, geom.y);
            xdisplay.resize_window(xid, geom.width, geom.height);
        }
#endif

#if WIN32
        rf_set_window_rect(surface, geom.x, geom.y, geom.width, geom.height);
        window.set_default_size(geom.width, geom.height);
#endif
    }
}