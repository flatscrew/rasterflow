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

namespace Data {
    public class DataDisplayView : Gtk.Widget {

        private Gtk.Box node_box;
        private Gtk.Box node_children_box;

        construct {
            set_layout_manager(new Gtk.BinLayout());
            vexpand = true;
        }

        ~DataDisplayView() {
            node_box.unparent();
        }

        public DataDisplayView() {
            create_node_with_details();
        }

        private void create_node_with_details() {
            this.node_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            //  node_box.add_css_class("card");
            this.node_children_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            node_children_box.vexpand = true;
            node_box.append(node_children_box);
            node_box.set_parent(this);
        }

        public new void add_child(Gtk.Widget child) {
            node_children_box.append(child);
        }

        public new void remove_child(Gtk.Widget child) {
            node_children_box.remove(child);
        }

        public void set_margin(int margin) {
            margin_bottom = margin_top = margin_start = margin_end = margin;
        }
    }
}