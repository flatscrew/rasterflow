class MiniMap : Gtk.Widget {
    
    construct {
        set_layout_manager(new Gtk.BinLayout());
        add_css_class("canvas_minimap");
    }

    private GtkFlow.NodeView node_view;
    private Gtk.Box box;

    ~MiniMap() {
        box.unparent();
    }

    public MiniMap(GtkFlow.NodeView node_view) {
        this.node_view = node_view;

        var motion_controller = new Gtk.EventControllerMotion ();
        motion_controller.enter.connect(this.mouse_entered);
        motion_controller.leave.connect(this.mouse_left);
        add_controller (motion_controller);

        margin_bottom = margin_end = margin_start = margin_top = 5;
        set_size_request(100, 100);
        
        this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        box.set_parent(this);

        var miniMap = new GtkFlow.Minimap();
        miniMap.nodeview = this.node_view;
        miniMap.hexpand = true;
        miniMap.vexpand = true;
        box.append(miniMap);
    }

    private void mouse_entered() {
        set_size_request(200, 200);
    }

    private void mouse_left() {
        set_size_request(100, 100);
    }
}