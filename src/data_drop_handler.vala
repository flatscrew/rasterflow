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

class DataDropHandler : Object {

    public signal void file_dropped(File file, double x, double y);
    public signal void text_dropped(string text);

    public Gtk.DropTarget data_drop_target {
        get;
        private set;
    }

    construct {
        this.data_drop_target = new Gtk.DropTarget (typeof (File), COPY);
        data_drop_target.drop.connect (handle_data_drop);
    }

    private bool handle_data_drop(GLib.Value value, double x, double y) {
        var file = (File) value;
        if (file != null) {
            file_dropped (file, x, y);
            return true;
        }
        return false;
    }
}

class PropertyDropHandler : Object {

    public signal void property_dropped(CanvasGraphProperty property, double x, double y);

    public Gtk.DropTarget data_drop_target {
        get;
        private set;
    }

    construct {
        this.data_drop_target = new Gtk.DropTarget (typeof (CanvasGraphProperty), COPY);
        data_drop_target.drop.connect (handle_data_drop);
    }

    private bool handle_data_drop(GLib.Value value, double x, double y) {
        var property = (CanvasGraphProperty) value;
        if (property != null) {
            property_dropped (property, x, y);
            return true;
        }
        return false;
    }
}