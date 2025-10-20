public class AddPropertyPopover : Gtk.Popover {

    private class TypeOption : Object {
        public string label { get; construct; }
        public TypeOption (string label) {
            Object (label: label);
        }
    }

    private Gtk.Grid grid;

    construct {
        set_autohide(true);
    }

    public AddPropertyPopover () {
        Object (has_arrow: true);

        this.grid = create_grid();

        add_name_row();
        add_type_row();
        set_child(grid);
    }

    private Gtk.Grid create_grid() {
        var grid = new Gtk.Grid();
        grid.row_spacing = 6;
        grid.column_spacing = 12;
        grid.margin_top = 8;
        grid.margin_bottom = 8;
        grid.margin_start = 8;
        grid.margin_end = 8;
        return grid;
    }

    private void add_name_row() {
        var name_label = new Gtk.Label("Name:");
        name_label.halign = Gtk.Align.START;

        var name_entry = new Gtk.Entry();
        name_entry.set_placeholder_text("Enter name...");

        grid.attach(name_label, 0, 0, 1, 1);
        grid.attach(name_entry, 1, 0, 1, 1);
    }

    private void add_type_row() {
        var type_label = new Gtk.Label("Type:");
        type_label.halign = Gtk.Align.START;

        var type_store = new GLib.ListStore(typeof(TypeOption));

        foreach (var type in Data.DataPropertyFactory.instance.available_types()) {
            var type_name = type.name();
            type_store.append(new TypeOption(type_name));
        }

        var label_expr = new Gtk.PropertyExpression(typeof(TypeOption), null, "label");
        var type_dropdown = new Gtk.DropDown(type_store, label_expr);

        grid.attach(type_label, 0, 1, 1, 1);
        grid.attach(type_dropdown, 1, 1, 1, 1);
    }
}
