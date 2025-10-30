public static void add_shortcuts(Gtk.ApplicationWindow app_window) {
    var changes_recorder = History.HistoryOfChangesRecorder.instance;

    var shortcuts = new Gtk.ShortcutController();
    shortcuts.add_shortcut(create_undo_shortcut(changes_recorder));
    shortcuts.add_shortcut(create_redo_shortcut(changes_recorder));

    (app_window as Gtk.Widget).add_controller(shortcuts);
}

private static Gtk.Shortcut create_undo_shortcut(History.HistoryOfChangesRecorder changes_recorder) {
    return new Gtk.Shortcut(
        new Gtk.KeyvalTrigger(Gdk.Key.z, Gdk.ModifierType.CONTROL_MASK),
        new Gtk.CallbackAction((_, __) => {
            if (changes_recorder.can_undo)
                changes_recorder.undo_last();
            return true;
        })
    );
}

private static Gtk.Shortcut create_redo_shortcut(History.HistoryOfChangesRecorder changes_recorder) {
    return new Gtk.Shortcut(
        new Gtk.KeyvalTrigger(Gdk.Key.z, Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK),
        new Gtk.CallbackAction((widget, _) => {
            if (changes_recorder.can_redo)
                changes_recorder.redo_last();
            return true;
        })
    );
}