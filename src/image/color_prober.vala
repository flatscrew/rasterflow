// Copyright (C) 2025 activey
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

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
