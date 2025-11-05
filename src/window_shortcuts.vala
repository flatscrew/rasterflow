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