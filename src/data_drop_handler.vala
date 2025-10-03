class DataDropHandler : Object {

    public signal void file_dropped(File file, double x, double y);
    public signal void text_dropped(string text);

    public Gtk.DropTarget data_drop_target {
        get;
        private set;
    }

    construct {
        this.data_drop_target = new Gtk.DropTarget (typeof (string), COPY);
        data_drop_target.drop.connect (handle_data_drop);
    }

    private bool handle_data_drop(GLib.Value value, double x, double y) {
        var string_value = value.get_string();
        var drop_formats = data_drop_target.current_drop.formats;

        stdout.printf("%s\n", drop_formats.to_string());

        if (drop_formats.contain_gtype(typeof(Gdk.FileList))) {
            var uris = string_value.split ("\n");
            foreach (var uri in uris) {
                var stripped = uri.strip();
                if (stripped != "") {
                    file_dropped(File.new_for_uri(stripped), x, y);
                }
            }
        } else {
            text_dropped(string_value);
        }
        return true;
    }
}