public class CanvasGraphPropertiesEditor : Gtk.Widget {

    private CanvasGraph canvas_graph;
    private Gtk.Box editor_box;
    private Gtk.Box add_property_box;
    private CanvasGraphPropertyListView property_list_view;
    private Gtk.ActionBar action_bar;
    private Gtk.MenuButton add_property_button;
    private AddPropertyPopover popover;
    
    private int last_width = 250;

    construct {
        set_layout_manager(new Gtk.BinLayout());
    }

    ~CanvasGraphPropertiesEditor() {
        editor_box.unparent();
    }

    public CanvasGraphPropertiesEditor(CanvasGraph canvas_graph) {
        this.canvas_graph = canvas_graph;
        this.visible = false;
        this.editor_box = create_main_layout();
        editor_box.set_parent(this);
        
        update_visibility();
        canvas_graph.property_added.connect((prop) => {
            update_visibility();
        });
    }
    
    private void add_property(string name, GLib.Type type) {
        canvas_graph.add_property(new CanvasGraphProperty(name, type));
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
        
        var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        content_box.halign = Gtk.Align.FILL;
        content_box.valign = Gtk.Align.FILL;
        content_box.vexpand = true;
        content_box.append(add_property_box);
        content_box.append(property_list_view);
        return content_box;
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
