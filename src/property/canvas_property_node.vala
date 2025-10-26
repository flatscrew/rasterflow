public class CanvasNodePropertySink : CanvasNodeSink {
    
    private History.HistoryOfChangesRecorder changes_recorder;
    
    public signal void contract_released();
    public signal void contract_renewed();
    
    public Data.PropertyControlContract control_contract { private set; public get; }

    public CanvasNodePropertySink(Data.PropertyControlContract control_contract) {
        base.with_type(control_contract.param_spec.value_type);
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;
        this.control_contract = control_contract;
        this.name = control_contract.param_spec.get_nick();
        
        control_contract.released.connect(this.on_contract_released);
        control_contract.renewed.connect(this.on_contract_renewed);
        
        base.changed.connect(this.sink_value_changed);
    }
    
    private void sink_value_changed(GLib.Value? value = null, string? flow_id = null) {
        if (value == null) {
            return;
        }
        control_contract.set_value(value);
    }
    
    private void on_contract_released() {
        contract_released();
    }
    
    private void on_contract_renewed() {
        contract_renewed();
    }
    
    public void release_control_contract() {
        control_contract.release();
    }
}

public class CanvasNodePropertySource : CanvasNodeSource {

    public CanvasGraphProperty property { public get; private set; }
    
    public CanvasNodePropertySource(CanvasGraphProperty property) {
        base.with_type(property.property_type);
        base.name = property.name;
        this.property = property;
        
        try {
            set_value(property.property_value);
        } catch (Error e) {
            warning(e.message);
        }
    }
}

public class CanvasPropertyNode : CanvasNode {
    
    public CanvasGraphProperty property {
        public get;
        private set;
    }
    
    public CanvasPropertyNode(CanvasGraphProperty property) {
        base(property.readable_name);
        base.resizable = false;
        this.property = property;
    }
}

public class CanvasPropertyDisplayNode : GtkFlow.Node {
    
    private History.HistoryOfChangesRecorder changes_recorder;
    private CanvasNodePropertySource? node_source;
    
    public CanvasPropertyDisplayNode(CanvasPropertyNode property_node) {
        base.with_margin(property_node, 10, new PropertyNodeSourceLabelFactory(property_node));
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;
        this.position_changed.connect(record_position_changed);
        
        apply_css_provider();
        
        try {
            set_title(node_header());
        } catch (Error e) {
            warning(e.message);
        }
        property_node.source_added.connect(this.source_added);
        property_node.property.removed.connect(this.remove);
        property_node.property.value_changed.connect(this.property_changed);
    }
    
    private void record_position_changed(int old_x, int old_y, int new_x, int new_y) {
        changes_recorder.record_node_moved(this, old_x, old_y, new_x, new_y);
    }
    
    private void source_added(GFlow.Source new_source) {
        this.node_source = new_source as CanvasNodePropertySource;
        
        // edge coloring
        var canvas_view = get_parent() as GtkFlow.NodeView;
        if (canvas_view == null) {
            return;
        }

        var dock = canvas_view.retrieve_dock(new_source);
        if (dock == null) {
            warning("Unable to find dock");
        }
        dock.resolve_color.connect_after(this.edge_color);
    }
    
    private void property_changed(GLib.Value? property_value) {
        if (node_source == null) return;
        
        try {
            node_source.set_value(property_value);
        } catch (Error e) {
            warning(e.message);
        }
    }
    
    private void apply_css_provider() {
        var custom_backround_css = new Gtk.CssProvider();
        var css = "
        .gtkflow_node {
            background-color: @theme_bg_color;
            box-shadow: none;
            border-radius: 10px;
            outline: 1px dashed @theme_fg_color;
            outline-offset: 3px;
        }

        .dark {
            color: white;
        }
        ";
        custom_backround_css.load_from_data(css.data);
        this.get_style_context().add_provider(custom_backround_css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    }
    
    private Gdk.RGBA edge_color(GtkFlow.Dock dock, Value? value) {
        return {
            red: 0.63f,
            green: 0.63f,
            blue: 0.63f,
            alpha: 1.0f
        };
    }
    
    private Gtk.Widget node_header() 
    {
        var property_node = n as CanvasPropertyNode;
        var title_bar = new Data.TitleBar(new Gtk.Label(property_node.property.readable_name));
        title_bar.hexpand = true;
        add_delete_button(title_bar);
        return title_bar;
    }
    
    private void add_delete_button (Data.TitleBar title_bar) {
        var delete_button = new Gtk.Button();
        delete_button.add_css_class("destructive-action");
        delete_button.add_css_class("circular");
        delete_button.set_icon_name("window-close-symbolic");
        delete_button.set_focusable(false);
        delete_button.set_focus_on_click(false);
        delete_button.clicked.connect(this.remove_node);
        title_bar.append_right(delete_button);
    }

    private void remove_node() {
        {
            
            //  int x, y;
            //  get_position(out x, out y);
            //  var parent = this.parent as GtkFlow.NodeView;
            //  changes_recorder.record(new History.RemoveNodeAction(parent, this, x, y), true);
            
            this.remove();
            //  removed(this);
        }
    }
}

public class PropertyNodeSourceLabelFactory : GtkFlow.NodeDockLabelWidgetFactory {
    
    public PropertyNodeSourceLabelFactory(CanvasPropertyNode node) {
        base(node);
    }
    
    public override Gtk.Widget create_dock_label (GFlow.Dock dock) {
        var node_property_source = dock as CanvasNodePropertySource;
        if (node_property_source == null) {
            return base.create_dock_label(dock);
        }
        
        var type_name = node_property_source.property.property_type.name();
        var label_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
    
        var name_label = new Gtk.Label(dock.name);
        name_label.halign = Gtk.Align.START;
    
        var type_label = new Gtk.Label("%s".printf(type_name));
        type_label.halign = Gtk.Align.START;
        type_label.add_css_class("dim-label");
    
        label_box.append(type_label);
        label_box.append(name_label);
    
        return label_box;
    }
}