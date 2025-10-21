public class CanvasGraphPropertyRow : Gtk.Box {
    public CanvasGraphProperty property { get; set; }

    private Data.DataPropertyFactory data_property_factory;
    private Gtk.Label name_label;
    
    public CanvasGraphPropertyRow (Data.DataPropertyFactory data_property_factory) {
        Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 6);
        this.data_property_factory = data_property_factory;
        halign = Gtk.Align.FILL;
        hexpand = true;
        margin_start = margin_end = margin_top = margin_bottom = 8;

        this.name_label = new Gtk.Label("");
        name_label.hexpand = true;
        name_label.halign = Gtk.Align.END;
        name_label.set_xalign(0);
        append(name_label);
        
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
        drag_source.drag_begin.connect (drag => {
            var snapshot = new Gtk.Snapshot ();
            name_label.add_css_class ("dragging");
            name_label.snapshot (snapshot);
        
            var width = name_label.get_width ();
            var height = name_label.get_height ();
            
            Graphene.Size size = { (float) width, (float) height };
            var paintable = snapshot.to_paintable (size);
        
            drag_source.set_icon (paintable, width / 2, 20);
        });
        drag_source.drag_end.connect (() => {
            name_label.remove_css_class ("dragging");
        });
        this.add_controller (drag_source);
    }

    public void update_from_property (CanvasGraphProperty prop) {
        if (this.property != null) {
            return;
        }
        
        this.property = prop;

        var name_label = (Gtk.Label) get_first_child ();
        name_label.set_label (prop.name);
        
        var data_property = data_property_factory.build(property.param_spec);
        data_property.changed.connect(this.property_changed);
        if (data_property == null) {
            return;
        }
        append(data_property);
    }
    
    private void property_changed(string name, GLib.Value value) {
        property.set_value(value);
    }
}

public class CanvasGraphPropertyListView : Gtk.Box {
    private CanvasGraph graph;
    private GLib.ListStore store;
    private Gtk.ListView list_view;
    private Data.DataPropertyFactory data_property_factory;

    public CanvasGraphPropertyListView (CanvasGraph graph) {
        Object (orientation: Gtk.Orientation.VERTICAL, spacing: 4);

        this.data_property_factory = Data.DataPropertyFactory.instance;
        this.graph = graph;
        this.vexpand = true;
        this.hexpand = true;

        store = new GLib.ListStore (typeof (CanvasGraphProperty));
        var selection = new Gtk.SingleSelection (store);

        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (setup_item);
        factory.bind.connect (bind_item);

        list_view = new Gtk.ListView (selection, factory);
        list_view.vexpand = true;
        list_view.hexpand = true;
        list_view.single_click_activate = true;

        append (list_view);

        reload_properties ();
        graph.property_added.connect ((p) => {
            store.append (p);
        });
    }

    private void setup_item (GLib.Object obj) {
        var item = obj as Gtk.ListItem;
        if (item == null) return;

        item.set_child (new CanvasGraphPropertyRow (data_property_factory));
    }

    private void bind_item (GLib.Object obj) {
        var item = obj as Gtk.ListItem;
        if (item == null) return;

        var prop = item.get_item () as CanvasGraphProperty;
        var row = item.get_child () as CanvasGraphPropertyRow;

        if (prop != null && row != null)
            row.update_from_property (prop);
    }

    private void reload_properties () {
        store.remove_all ();
        foreach (var prop in graph.get_all_properties ())
            store.append (prop);
    }
}

