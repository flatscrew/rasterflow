public class CanvasGraphPropertiesEditor : Gtk.Widget {

    private CanvasGraph canvas_graph;
    private Gtk.Box editor_box;
    private CanvasGraphPropertyListView property_list_view;
    
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
    }
    
    private Gtk.Box create_main_layout() {
        var editor_box_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        editor_box_layout.vexpand = true;
        editor_box_layout.hexpand = true;
        editor_box_layout.append(create_content_box());
        return editor_box_layout;
    }
    
    private Gtk.Widget create_content_box() {
        this.property_list_view = new CanvasGraphPropertyListView(this.canvas_graph);
        property_list_view.property_created.connect(this.add_property);
        
        var content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        content_box.add_css_class("view");
        content_box.halign = Gtk.Align.FILL;
        content_box.valign = Gtk.Align.FILL;
        content_box.vexpand = true;
        content_box.append(property_list_view);
        
        return content_box;
    }
    
    private void add_property(string name, string label, GLib.Type type) {
        canvas_graph.add_property(new CanvasGraphProperty(name, label, type));
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
    
        return button;
    }
}
