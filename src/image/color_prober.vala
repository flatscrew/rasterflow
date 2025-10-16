namespace Image {
    public class ColorProber : Object {
        private static ColorProber? _instance;
        private Xdp.Portal portal;
        private Xdp.Parent parent;

        public static ColorProber instance {
            get {
                if (_instance == null)
                    error ("ColorPicker not initialized! Call ColorPicker.init(window) first.");
                return _instance;
            }
        }

        public static void init (Gtk.Window window) {
            if (_instance != null) return;
            _instance = new ColorProber (window);
        }

        private ColorProber (Gtk.Window window) {
            this.portal = new Xdp.Portal ();
            this.parent = Xdp.parent_new_gtk (window);
        }

        public async bool pick_color_async (out double r, out double g, out double b) {
            r = g = b = 0;
            var cancel = new Cancellable ();
            try {
                var variant = yield portal.pick_color (parent, cancel);
                r = variant.get_child_value (0).get_double ();
                g = variant.get_child_value (1).get_double ();
                b = variant.get_child_value (2).get_double ();
                return true;
            } catch (Error e) {
                return false;
            }
        }
    }
}
