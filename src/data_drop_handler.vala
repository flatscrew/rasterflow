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