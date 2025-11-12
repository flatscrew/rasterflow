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

private static SimpleAction create_undo_action() {
    var undo_action = new SimpleAction("undo", null);
    undo_action.activate.connect(() => {
        var history = History.HistoryOfChangesRecorder.instance;
        if (history.can_undo)
            history.undo_last();
    });
    return undo_action;
}

private static SimpleAction create_redo_action() {
    var redo_action = new SimpleAction("redo", null);
    redo_action.activate.connect(() => {
        var history = History.HistoryOfChangesRecorder.instance;
        if (history.can_redo)
            history.redo_last();
    });
    return redo_action;
}

private static SimpleAction create_window_resize_action(Gtk.Window window) {
    var undo_action = new SimpleAction("window_resize", null);
    undo_action.activate.connect(() => {
        WindowGeometryManager.set_geometry(window, Gdk.Rectangle() {
            width = 1600,
            height = 1000
        });
    });
    return undo_action;
}