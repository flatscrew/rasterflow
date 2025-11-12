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

public class CanvasActionBar : Gtk.Widget {
    private Gtk.Box container;
    private Gtk.Box start_box;
    private Gtk.Box end_box;

    construct {
        set_layout_manager(new Gtk.BinLayout());

        container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        container.add_css_class("toolbar");
        container.hexpand = true;
        container.vexpand = false;

        start_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        start_box.name = "start-box";
        
        end_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        end_box.name = "end-box";
        end_box.halign = Gtk.Align.END;
        end_box.hexpand = true;

        container.append(start_box);
        container.append(end_box);

        container.set_parent(this);
    }

    ~CanvasActionBar() {
        container.unparent();
    }

    public Gtk.Box add_action_start(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.margin_start = 5;
        wrapper.append(child);
        start_box.append(wrapper);
        return wrapper;
    }

    public Gtk.Box add_action_end(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.margin_end = 5;
        wrapper.append(child);
        end_box.append(wrapper);
        return wrapper;
    }

    public void remove_action(Gtk.Widget child) {
        var parent = child.get_parent().get_parent();
        if (parent == null) return;
        
        if (parent == start_box) {
            start_box.remove(child.get_parent());
            return;
        }
        end_box.remove(child.get_parent());
    }
}
