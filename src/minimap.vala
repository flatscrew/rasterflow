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

class MiniMap : Gtk.Widget {
    
    construct {
        set_layout_manager(new Gtk.BinLayout());
    }

    private GtkFlow.NodeView node_view;
    private Gtk.Box box;

    ~MiniMap() {
        box.unparent();
    }

    public MiniMap(GtkFlow.NodeView node_view) {
        this.node_view = node_view;

        var motion_controller = new Gtk.EventControllerMotion ();
        motion_controller.enter.connect(this.mouse_entered);
        motion_controller.leave.connect(this.mouse_left);
        add_controller (motion_controller);

        margin_bottom = margin_end = margin_start = margin_top = 5;
        set_size_request(100, 100);
        
        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.add_css_class("osd");
        box.add_css_class("toolbar");
        box.add_css_class("canvas_overlay");
        box.set_parent(this);

        var mini_map = new GtkFlow.Minimap();
        mini_map.nodeview = this.node_view;
        mini_map.hexpand = true;
        mini_map.vexpand = true;
        box.append(mini_map);
    }

    private void mouse_entered() {
        set_size_request(200, 200);
    }

    private void mouse_left() {
        set_size_request(100, 100);
    }
}