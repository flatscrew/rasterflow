public class AddPropertyPopover : Gtk.Popover {

    public signal void property_added(string name, GLib.Type property_type);

    private class TypeOption : Object {
        public GLib.Type property_type { get; construct; }
        public string label { get; construct; }
        
        public TypeOption (GLib.Type property_type) {
            Object (property_type: property_type, label: property_type.name());
        }
    }

    private Data.DataPropertyFactory property_factory;
    private Gtk.Box popover_box;
    private Gtk.Grid grid;
    private Gtk.Entry name_entry;
    private Gtk.DropDown type_dropdown;
    private Gtk.Button add_button;

    construct {
        set_autohide(true);
    }

    public AddPropertyPopover () {
        Object (has_arrow: true);

        this.property_factory = Data.DataPropertyFactory.instance;
        this.grid = create_grid();
        this.popover_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 8);
        popover_box.margin_top = 8;
        popover_box.margin_bottom = 8;
        popover_box.margin_start = 8;
        popover_box.margin_end = 8;
        popover_box.append(grid);
        
        add_name_row();
        add_type_row();
        add_submit_button();
        
        set_child(popover_box);
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

        name_entry = new Gtk.Entry();
        name_entry.set_placeholder_text("Enter name...");

        name_entry.activate.connect(() => {
            on_submit();
        });

        grid.attach(name_label, 0, 0, 1, 1);
        grid.attach(name_entry, 1, 0, 1, 1);
    }

    private void add_type_row() {
        var type_label = new Gtk.Label("Type:");
        type_label.halign = Gtk.Align.START;

        var type_store = new GLib.ListStore(typeof(TypeOption));

        foreach (var type in this.property_factory.available_types()) {
            type_store.append(new TypeOption(type));
        }

        var label_expr = new Gtk.PropertyExpression(typeof(TypeOption), null, "label");
        type_dropdown = new Gtk.DropDown(type_store, label_expr);


        grid.attach(type_label, 0, 1, 1, 1);
        grid.attach(type_dropdown, 1, 1, 1, 1);
    }

    private void add_submit_button() {
        add_button = new Gtk.Button.with_label("Add");
        add_button.halign = Gtk.Align.CENTER;

        add_button.clicked.connect(() => {
            on_submit();
        });

        popover_box.append(add_button);
    }

    private void on_submit() {
        var name = name_entry.text.strip();
        if (name == "") return;

        var selected_item = type_dropdown.selected_item as TypeOption;
        if (selected_item == null) return;

        property_added(name, selected_item.property_type);

        popdown();
    }
}
