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

namespace History {

    public class HistoryButtonsWidget : Gtk.Widget {
        private Gtk.Box box;
        private Gtk.Button undo_button;
        private Gtk.Button redo_button;
        private HistoryOfChangesRecorder history;

        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        public HistoryButtonsWidget() {
            history = HistoryOfChangesRecorder.instance;
            history.changed.connect(() => {
                update_sensitivity();
                update_tooltips();
            });

            box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.add_css_class("linked");
            box.set_parent(this);

            undo_button = new Gtk.Button.from_icon_name("edit-undo-symbolic");
            undo_button.clicked.connect(history.undo_last);
            
            redo_button = new Gtk.Button.from_icon_name("edit-redo-symbolic");
            redo_button.clicked.connect(history.redo_last);

            box.append(undo_button);
            box.append(redo_button);

            update_sensitivity();
            update_tooltips();
        }
        
        private void update_sensitivity() {
            undo_button.sensitive = history.can_undo;
            redo_button.sensitive = history.can_redo;
        }

        private void update_tooltips() {
            var undo_action = history.peek_undo();
            var redo_action = history.peek_redo();

            undo_button.tooltip_text = undo_action != null
                ? "Undo: %s (Ctrl+Z)".printf(undo_action.get_label())
                : "Undo last change (Ctrl+Z)";

            redo_button.tooltip_text = redo_action != null
                ? "Redo: %s (Ctrl+Shift+Z)".printf(redo_action.get_label())
                : "Redo last undone change (Ctrl+Shift+Z)";
        }

        ~HistoryButtonsWidget() {
            box.unparent();
        }
    }
}