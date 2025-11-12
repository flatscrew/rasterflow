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

public class CanvasGraphModificationGuard : Object {
    public signal void dirty_state_changed(bool is_dirty);

    private static CanvasGraphModificationGuard? _instance;
    public static CanvasGraphModificationGuard instance {
        get {
            if (_instance == null)
                _instance = new CanvasGraphModificationGuard();
            return _instance;
        }
    }

    private History.IAction? baseline_action;
    private bool _is_dirty = false;
    private History.HistoryOfChangesRecorder history;

    public bool is_dirty {
        get { return _is_dirty; }
        private set {
            if (_is_dirty == value)
                return;
            _is_dirty = value;
            dirty_state_changed(_is_dirty);
        }
    }

    private CanvasGraphModificationGuard() {
        history = History.HistoryOfChangesRecorder.instance;
        history.changed.connect(on_history_changed);
        reset();
    }

    private void on_history_changed() {
        var current_action = history.peek_undo();
        bool dirty_now = current_action != baseline_action;
        is_dirty = dirty_now;
    }

    public void reset() {
        baseline_action = history.peek_undo();
        is_dirty = false;
    }

    public async bool confirm_discard_if_dirty(Gtk.Widget parent) {
        if (!is_dirty)
            return true;

        var dialog = new Adw.AlertDialog("Unsaved changes", "Ignore unsaved changes?");
        dialog.add_response("cancel", "_Cancel");
        dialog.add_response("discard", "_Ignore");
        dialog.set_response_appearance("discard", Adw.ResponseAppearance.DESTRUCTIVE);
        dialog.set_default_response("cancel");
        dialog.set_close_response("cancel");

        var response = yield dialog.choose(parent, null);
        return response == "discard";
    }
}
