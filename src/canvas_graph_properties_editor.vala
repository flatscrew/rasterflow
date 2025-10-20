public class CanvasGraphPropertiesEditor : Gtk.Widget {

    private Gtk.Box vbox;
    private Gtk.ActionBar action_bar;
    private Gtk.MenuButton add_property_button;
    private int last_width = 250;

    construct {
        set_layout_manager(new Gtk.BinLayout());
    }

    ~CanvasGraphPropertiesEditor() {
        vbox.unparent();
    }

    public CanvasGraphPropertiesEditor() {
        this.set_size_request(100, -1);
        this.visible = false;
        vbox = create_main_layout();
        vbox.set_parent(this);
    }

    private Gtk.Box create_main_layout() {
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        box.vexpand = true;
        box.hexpand = true;
        box.append(create_content_box());
        box.append(create_action_bar());
        return box;
    }

    private Gtk.Widget create_content_box() {
        var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        content_box.halign = Gtk.Align.CENTER;
        content_box.valign = Gtk.Align.CENTER;
        content_box.vexpand = true;
        content_box.append(new Gtk.Label("List of properties will be here"));
        return content_box;
    }

    private Gtk.ActionBar create_action_bar() {
        action_bar = new Gtk.ActionBar();
        add_property_button = create_add_property_button();
        action_bar.pack_end(add_property_button);
        return action_bar;
    }

    private Gtk.MenuButton create_add_property_button() {
        var button = new Gtk.MenuButton();
        button.direction = Gtk.ArrowType.UP;
        button.set_tooltip_text("Add property");
        button.set_icon_name("list-add-symbolic");
        var popover = create_add_property_popover();
        button.set_popover(popover);
        return button;
    }

    private Gtk.Popover create_add_property_popover() {
        return new AddPropertyPopover();
    }

    public Gtk.ToggleButton create_toggle_button(Gtk.Paned editor_paned) {
        var button = new Gtk.ToggleButton();
        button.set_tooltip_text("Toggle graph properties");
        button.add_css_class("canvas_properties_toggle");
    
        var icon = new Gtk.Image.from_icon_name("document-properties-symbolic");
        icon.set_pixel_size(16);
        button.set_child(icon);
    
        button.toggled.connect(() => {
            bool active = button.active;
            icon.set_from_icon_name(active ? "window-close-symbolic" : "document-properties-symbolic");
            handle_toggle(button, editor_paned);
        });
    
        return button;
    }

    private void handle_toggle(Gtk.ToggleButton button, Gtk.Paned editor_paned) {
        bool active = button.active;

        if (active) {
            this.visible = true;
            editor_paned.set_position(last_width);
        } else {
            this.visible = false;
            int pos = editor_paned.get_position();
            if (pos > 0) last_width = pos;
            editor_paned.set_position(0);
        }
    }
}
