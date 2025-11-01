public class CanvasGraphPropertyRow : Adw.ActionRow {
    public signal void removed(CanvasGraphProperty property);

    public CanvasGraphProperty property { get; set; }

    private Gtk.Button remove_button;
    private Data.DataPropertyFactory factory;

    public CanvasGraphPropertyRow(Data.DataPropertyFactory factory, CanvasGraphProperty prop) {
        this.factory = factory;
        this.property = prop;
        
        property.removed.connect(this.property_removed);

        set_title(prop.readable_name);
        set_subtitle(prop.property_type.name());

        remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic");
        remove_button.add_css_class("flat");
        remove_button.set_tooltip_text("Remove property");
        remove_button.clicked.connect(() => property.remove());
        remove_button.valign = Gtk.Align.CENTER;
        add_prefix(remove_button);

        var data_property = factory.build(prop.param_spec);
        if (data_property != null) {
            if (prop.property_value != null)
                data_property.set_value_from_model(prop.property_value);
            data_property.changed.connect((name, val) => prop.set_value(val));
            data_property.valign = Gtk.Align.CENTER;
            add_suffix(data_property);
        }
        
        create_drag_controller();
    }
    
    private void create_drag_controller() {
        var drag_source = new Gtk.DragSource ();
        drag_source.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
        drag_source.set_actions (Gdk.DragAction.COPY);
        drag_source.prepare.connect (() => {
            var val = GLib.Value (typeof (CanvasGraphProperty));
            val.set_object (property);
            return new Gdk.ContentProvider.for_value (val);
        });
        drag_source.drag_begin.connect((drag) => {
            add_css_class("drag-active");
        });
    
        drag_source.drag_end.connect(() => {
            remove_css_class("drag-active");
        });
        this.add_controller (drag_source);
    }
    
    private void property_removed() {
        this.removed(this.property);
        
        property.removed.disconnect(this.property_removed);
    }
}

public class CanvasGraphPropertyListView : Gtk.Box {
    public signal void properties_changed();
    public signal void property_created(string name, string label, GLib.Type type);
    
    private CanvasGraph graph;
    private Data.DataPropertyFactory factory;
    private AddPropertyPopover popover;

    private Gtk.ScrolledWindow scroller;
    private Adw.PreferencesPage page;
    private Adw.PreferencesGroup group;
    
    private List<CanvasGraphPropertyRow> rows = new List<CanvasGraphPropertyRow>();

    public CanvasGraphPropertyListView(CanvasGraph graph) {
        Object(orientation: Gtk.Orientation.VERTICAL, spacing: 0);

        this.graph = graph;
        this.factory = Data.DataPropertyFactory.instance;

        scroller = new Gtk.ScrolledWindow();
        scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        scroller.hexpand = true;
        scroller.vexpand = true;

        this.page = new Adw.PreferencesPage();
        this.group = new Adw.PreferencesGroup();
        group.set_title("Graph properties");
        group.set_header_suffix(create_add_property_button());

        page.add(group);
        scroller.set_child(page);
        append(scroller);

        reload_properties();

        graph.property_added.connect((prop) => add_property(prop));
        graph.properties_removed.connect(() => clear_properties());
    }

    private Gtk.MenuButton create_add_property_button() {
        this.popover = new AddPropertyPopover(this.validate_property);
        popover.property_added.connect(this.property_added);
    
        var button = new Gtk.MenuButton();
        button.set_tooltip_text("Add property");
        button.add_css_class("flat");
        button.direction = Gtk.ArrowType.DOWN;
        button.set_popover(popover);
    
        var content = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
        content.append(new Gtk.Image.from_icon_name("list-add-symbolic"));
        content.append(new Gtk.Label("Add"));
    
        button.set_child(content);
        return button;
    }
    
    private bool validate_property(string property_name, out string message) {
        message = "Name already used.";
        return !graph.has_property(property_name);
    }
    
    private void property_added(string name, string label, GLib.Type type) {
        this.property_created(name, label, type);
    }
    
    private void add_property(CanvasGraphProperty prop) {
        var row = new CanvasGraphPropertyRow(factory, prop);
        row.removed.connect(p => {
            group.remove(row);
            rows.remove(row);
            properties_changed();
        });
        group.add(row);
        rows.append(row);
    }

    private void reload_properties() {
        clear_properties();
        graph.foreach_property(this.add_property);
    }

    private void clear_properties() {
        foreach (var row in rows) {
            group.remove(row);
        }
        
        rows = new List<CanvasGraphPropertyRow>();
    }
}
