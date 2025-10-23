public class CanvasGraphPropertiesEditor : Gtk.Widget {

    private CanvasGraph canvas_graph;
    private Gtk.Box editor_box;
    private Gtk.Box add_property_box;
    private CanvasGraphPropertyListView property_list_view;
    private Gtk.ActionBar action_bar;
    private Gtk.MenuButton add_property_button;
    private AddPropertyPopover popover;
    
    construct {
        set_layout_manager(new Gtk.BinLayout());
    }

    ~CanvasGraphPropertiesEditor() {
        editor_box.unparent();
    }

    public CanvasGraphPropertiesEditor(CanvasGraph canvas_graph) {
        this.canvas_graph = canvas_graph;
        this.editor_box = create_main_layout();
        editor_box.set_parent(this);
        
        update_visibility();
        canvas_graph.property_added.connect((prop) => {
            update_visibility();
        });
        canvas_graph.properties_removed.connect(this.update_visibility);
    }
    
    private void add_property(string name, string label, GLib.Type type) {
        canvas_graph.add_property(new CanvasGraphProperty(name, label, type));
    }

    private Gtk.Box create_main_layout() {
        this.popover = new AddPropertyPopover();
        popover.property_added.connect(this.add_property);
        
        var editor_box_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        editor_box_layout.vexpand = true;
        editor_box_layout.hexpand = true;
        editor_box_layout.append(create_content_box());
        editor_box_layout.append(create_action_bar());
        return editor_box_layout;
    }
    
    private Gtk.Widget create_content_box() {
        var add_property_button = new Gtk.Button.from_icon_name("list-add-symbolic");
        add_property_button.set_tooltip_text("Add property");
        add_property_button.clicked.connect(popover.show);
        
        this.add_property_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        add_property_box.vexpand = true;
        add_property_box.valign = add_property_box.halign = Gtk.Align.CENTER;
        add_property_box.append(new Gtk.Label("Add new property"));
        add_property_box.append(add_property_button);
        
        this.property_list_view = new CanvasGraphPropertyListView(this.canvas_graph);
        property_list_view.list_changed.connect_after(this.update_visibility);
        
        var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        content_box.add_css_class("view");
        content_box.halign = Gtk.Align.FILL;
        content_box.valign = Gtk.Align.FILL;
        content_box.vexpand = true;
        content_box.append(add_property_box);
        content_box.append(property_list_view);
        return content_box;
    }
    
    private Gtk.Widget create_pin_button(Adw.OverlaySplitView split_view) {
        var pin_button = new Gtk.ToggleButton();
        pin_button.set_icon_name("pin-symbolic");
        pin_button.set_tooltip_text("Pin sidebar");
        pin_button.valign = Gtk.Align.START;
        pin_button.halign = Gtk.Align.END;
        pin_button.margin_top = 6;
        pin_button.margin_end = 6;
        pin_button.add_css_class("flat");
    
        split_view.bind_property(
            "show-sidebar",
            pin_button,
            "active",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
    
        pin_button.notify["active"].connect(() => {
            pin_button.set_icon_name(pin_button.active ? "unpin-symbolic" : "pin-symbolic");
        });
    
        return pin_button;
    }
    
    private void update_visibility() {
        bool has_props = canvas_graph.has_any_property();
        add_property_box.visible = !has_props;
        property_list_view.visible = has_props;
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
        button.set_popover(popover);
        return button;
    }

    public Gtk.ToggleButton create_toggle_button(Adw.OverlaySplitView split_view) {
        var button = new Gtk.ToggleButton();
        button.set_tooltip_text("Toggle graph properties");
    
        var icon = new Gtk.Image.from_icon_name("document-properties-symbolic");
        icon.set_pixel_size(16);
        button.set_child(icon);
    
        split_view.bind_property(
            "show-sidebar",
            button,
            "active",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );
    
        button.bind_property(
            "active",
            icon,
            "icon-name",
            BindingFlags.SYNC_CREATE,
            (binding, from_value, ref to_value) => {
                bool active = from_value.get_boolean();
                to_value.set_string(active ? "window-close-symbolic" : "document-properties-symbolic");
                return true;
            }
        );
    
        return button;
    }
}
