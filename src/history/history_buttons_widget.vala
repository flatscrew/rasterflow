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
            redo_button.tooltip_text = "Redo last undone change (Ctrl+Y)";

            undo_button.sensitive = history.can_undo;
            redo_button.sensitive = history.can_redo;

            undo_button.clicked.connect(() => history.undo_last());
            redo_button.clicked.connect(() => history.redo_last());

            history.changed.connect(() => {
                undo_button.sensitive = history.can_undo;
                redo_button.sensitive = history.can_redo;
            });

            box.append(undo_button);
            box.append(redo_button);
            box.set_parent(this);
        }

        ~HistoryButtonsWidget() {
            box.unparent();
        }
    }
}