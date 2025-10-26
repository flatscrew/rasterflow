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
            this.history = HistoryOfChangesRecorder.instance;

            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.add_css_class("linked");

            this.undo_button = new Gtk.Button.from_icon_name("edit-undo-symbolic");
            redo_button = new Gtk.Button.from_icon_name("edit-redo-symbolic");

            undo_button.tooltip_text = "Undo last change (Ctrl+Z)";
            redo_button.tooltip_text = "Redo last undone change (Ctrl+Shift+Z)";

            undo_button.sensitive = history.can_undo;
            redo_button.sensitive = history.can_redo;

            undo_button.clicked.connect(history.undo_last);
            redo_button.clicked.connect(history.redo_last);

            history.changed.connect(() => {
                update_sensitivity();
                update_tooltips();
            });

            box.append(undo_button);
            box.append(redo_button);
            box.set_parent(this);
            
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