using Gtk;
using Gdk;

namespace Image {

    public struct WindowGeometry {
        public int x;
        public int y;
        public int width;
        public int height;
    }

    public class WindowGeometryManager : Object {

        public static WindowGeometry get_geometry(Gtk.Window window) {
            int x = 0, y = 0, width = 0, height = 0;
            var surface = window.get_surface();

    #if UNIX
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
            rf_get_window_rect(surface, out x, out y, out width, out height);
    #endif

            return WindowGeometry() { x = x, y = y, width = width, height = height };
        }

        public static void set_geometry(Gtk.Window window, WindowGeometry geom) {
            var surface = window.get_surface();

    #if UNIX
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
    #endif
        }
    }
}