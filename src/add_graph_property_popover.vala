public class AddPropertyPopover : Gtk.Popover {

    public signal void property_added(string name, string label, GLib.Type property_type);

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
    private Gtk.Entry label_entry;
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
        add_label_row();
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
        name_label.halign = Gtk.Align.END;

        name_entry = new Gtk.Entry();
        name_entry.set_placeholder_text("Enter name...");
        name_entry.changed.connect(() => {
            string? error_message = null;
            if (!validate_name(name_entry.text.strip(), out error_message)) {
                show_entry_error(name_entry, error_message);
            } else {
                clear_entry_error(name_entry);
            }
        });
        clear_entry_error(name_entry);
        
        name_entry.activate.connect(() => {
            on_submit();
        });

        grid.attach(name_label, 0, 0, 1, 1);
        grid.attach(name_entry, 1, 0, 1, 1);
    }
    
    private void add_label_row() {
        var label_label = new Gtk.Label("Label:");
        label_label.halign = Gtk.Align.END;
    
        label_entry = new Gtk.Entry();
        label_entry.set_placeholder_text("Display label");
        label_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "face-smile-symbolic");
        label_entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, "Insert emoji");
        label_entry.show_emoji_icon = true;
        
        label_entry.changed.connect(() => {
            string? error_message = null;
            if (!validate_label(label_entry.text.strip(), out error_message)) {
                show_entry_error(label_entry, error_message);
            } else {
                clear_entry_error(label_entry, "face-smile-symbolic", "Insert emoji");
            }
        });
        clear_entry_error(label_entry, "face-smile-symbolic", "Insert emoji");
    
        label_entry.activate.connect(() => {
            on_submit();
        });
    
        grid.attach(label_label, 0, 2, 1, 1);
        grid.attach(label_entry, 1, 2, 1, 1);
    }

    private void add_type_row() {
        var type_label = new Gtk.Label("Type:");
        type_label.halign = Gtk.Align.END;

        var type_store = new GLib.ListStore(typeof(TypeOption));

        foreach (var type in this.property_factory.available_types()) {
            type_store.append(new TypeOption(type));
        }

        var label_expr = new Gtk.PropertyExpression(typeof(TypeOption), null, "label");
        type_dropdown = new Gtk.DropDown(type_store, label_expr);

        grid.attach(type_label, 0, 3, 1, 1);
        grid.attach(type_dropdown, 1, 3, 1, 1);
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
        var label = label_entry.text.strip();
        string? error_message = null;
        bool has_error = false;
    
        if (!validate_name(name, out error_message)) {
            show_entry_error(name_entry, error_message);
            has_error = true;
        } else {
            clear_entry_error(name_entry);
        }
    
        if (!validate_label(label, out error_message)) {
            show_entry_error(label_entry, error_message);
            has_error = true;
        } else {
            clear_entry_error(label_entry, "face-smile-symbolic", "Insert emoji");
        }
        
        if (has_error) return;
    
        var selected_item = type_dropdown.selected_item as TypeOption;
        if (selected_item == null) return;
    
        property_added(name, label, selected_item.property_type);
        popdown();
    }
    
    private bool validate_name(string name, out string? error_message = null) {
        if (name == "") {
            error_message = "Name cannot be empty.";
            return false;
        }
    
        if (!/^([a-z][a-z0-9-]*)$/.match(name)) {
            error_message = "Name must start with a lowercase letter and contain only lowercase letters, digits, or hyphens.";
            return false;
        }
    
        error_message = null;
        return true;
    }
    
    private bool validate_label(string label, out string? error_message = null) {
        if (label == "") {
            error_message = "Label cannot be empty.";
            return false;
        }
    
        if (label.length > 64) {
            error_message = "Label is too long (max 64 characters).";
            return false;
        }
    
        error_message = null;
        return true;
    }
    
    private void show_entry_error(Gtk.Entry entry, string message) {
        entry.add_css_class("error");
        entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, "dialog-warning-symbolic");
        entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, message);
        entry.set_tooltip_text(message);
    }
    
    private void clear_entry_error
    (
        Gtk.Entry entry, 
        string? icon_replacement = null, 
        string? tooltip_replacement = null
    ) 
    {
        
        entry.remove_css_class("error");
        entry.set_icon_from_icon_name(Gtk.EntryIconPosition.SECONDARY, icon_replacement);
        entry.set_icon_tooltip_text(Gtk.EntryIconPosition.SECONDARY, tooltip_replacement);
        entry.set_tooltip_text(null);
    }
}
