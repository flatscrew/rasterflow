public class AdwCanvasGraphPropertyRow : Adw.ActionRow {
    public signal void removed(CanvasGraphProperty property);

    public CanvasGraphProperty property { get; set; }

    private Gtk.Button remove_button;
    private Data.DataPropertyFactory factory;

    public AdwCanvasGraphPropertyRow(Data.DataPropertyFactory factory, CanvasGraphProperty prop) {
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
        drag_source.drag_begin.connect (drag => {
            var label = new Gtk.Label(property.readable_name);
            
            int width, height;
            label.measure(Gtk.Orientation.HORIZONTAL, -1, out width, null, null, null);
            label.measure(Gtk.Orientation.VERTICAL, -1, out height, null, null, null);
        
            var snapshot = new Gtk.Snapshot();
            label.allocate(width, height, -1, null); // wymusza układ
            label.snapshot(snapshot);
        
            Graphene.Size size = { (float) width, (float) height };
            var paintable = snapshot.to_paintable(size);
        
            drag_source.set_icon(paintable, width / 2, height / 2);
        });
        this.add_controller (drag_source);
    }
    
    private void property_removed() {
        this.removed(this.property);
    }
}

public class AdwCanvasGraphPropertyListView : Gtk.Box {
    public signal void list_changed();

    private CanvasGraph graph;
    private Data.DataPropertyFactory factory;

    private Gtk.ScrolledWindow scroller;
    private Adw.PreferencesPage page;
    private Adw.PreferencesGroup group;
    
    private List<AdwCanvasGraphPropertyRow> rows = new List<AdwCanvasGraphPropertyRow>();

    public AdwCanvasGraphPropertyListView(CanvasGraph graph) {
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

        page.add(group);
        scroller.set_child(page);
        append(scroller);

        reload_properties();

        graph.property_added.connect((prop) => add_property(prop));
        graph.properties_removed.connect(() => clear_group());
    }

    private void add_property(CanvasGraphProperty prop) {
        var row = new AdwCanvasGraphPropertyRow(factory, prop);
        row.removed.connect(p => {
            group.remove(row);
            rows.remove(row);
            list_changed();
        });
        group.add(row);
        rows.append(row);
    }

    private void reload_properties() {
        clear_group();
        foreach (var prop in graph.get_all_properties())
            add_property(prop);
    }

    private void clear_group() {
        foreach (var row in rows) {
            group.remove(row);
        }
        
        rows = new List<AdwCanvasGraphPropertyRow>();
    }
}


//  public class CanvasGraphPropertyRow : Gtk.Box {

//      public signal void removed(CanvasGraphProperty property, uint row_position);

//      public CanvasGraphProperty property { get; set; }

//      public uint position;
//      private Data.DataPropertyFactory data_property_factory;
    
//      private Gtk.Button remove_button;
//      private Gtk.Label name_label;
//      private Gtk.Label type_label;
    
//      public CanvasGraphPropertyRow (Data.DataPropertyFactory data_property_factory) {
//          Object (orientation: Gtk.Orientation.HORIZONTAL, spacing: 6);
//          this.data_property_factory = data_property_factory;
//          halign = Gtk.Align.FILL;
//          hexpand = true;
//          margin_start = margin_end = margin_top = margin_bottom = 8;

//          this.remove_button = new Gtk.Button.from_icon_name("list-remove-symbolic");
//          remove_button.set_tooltip_text("Remove property");
//          remove_button.clicked.connect(this.remove_row);
//          remove_button.add_css_class("flat");
//          append(remove_button);
        
//          this.type_label = new Gtk.Label("");
//          type_label.add_css_class("dim-label");
//          type_label.hexpand = true;
//          type_label.halign = Gtk.Align.START;
//          type_label.set_xalign(0);
//          append(type_label);
        
//          this.name_label = new Gtk.Label("");
//          name_label.hexpand = true;
//          name_label.halign = Gtk.Align.END;
//          name_label.set_xalign(0);
//          append(name_label);
        
        
//          create_drag_controller();
//      }
    
//      private void create_drag_controller() {
//          var drag_source = new Gtk.DragSource ();
//          drag_source.set_propagation_phase (Gtk.PropagationPhase.CAPTURE);
//          drag_source.set_actions (Gdk.DragAction.COPY);
//          drag_source.prepare.connect (() => {
//              var val = GLib.Value (typeof (CanvasGraphProperty));
//              val.set_object (property);
//              return new Gdk.ContentProvider.for_value (val);
//          });
//          drag_source.drag_begin.connect (drag => {
//              var snapshot = new Gtk.Snapshot ();
//              name_label.add_css_class ("dragging");
//              name_label.snapshot (snapshot);
        
//              var width = name_label.get_width ();
//              var height = name_label.get_height ();
            
//              Graphene.Size size = { (float) width, (float) height };
//              var paintable = snapshot.to_paintable (size);
        
//              drag_source.set_icon (paintable, width / 2, 20);
//          });
//          drag_source.drag_end.connect (() => {
//              name_label.remove_css_class ("dragging");
//          });
//          this.add_controller (drag_source);
//      }

//      public void update_from_property (CanvasGraphProperty prop) {
//          if (this.property != null) {
//              return;
//          }
        
//          this.property = prop;
//          this.property.removed.connect(() => {
//              removed(this.property, this.position);
//          });
        
//          name_label.set_label(prop.readable_name);
//          type_label.set_label(prop.property_type.name());
        
//          var data_property = data_property_factory.build(property.param_spec);
//          data_property.changed.connect(this.property_changed);
//          if (data_property == null) {
//              return;
//          }
//          if (prop.property_value != null) {
//              data_property.set_value_from_model(prop.property_value);
//          }
        
//          append(data_property);
//      }
    
//      private void property_changed(string name, GLib.Value value) {
//          property.set_value(value);
//      }
    
//      private void remove_row() {
//          property.remove();
//      }
//  }

//  public class CanvasGraphPropertyListView : Gtk.Box {
    
//      public signal void list_changed();
    
//      private CanvasGraph graph;
//      private GLib.ListStore store;
//      private Gtk.ListView list_view;
//      private Data.DataPropertyFactory data_property_factory;

//      public CanvasGraphPropertyListView (CanvasGraph graph) {
//          Object (orientation: Gtk.Orientation.VERTICAL, spacing: 4);

//          this.data_property_factory = Data.DataPropertyFactory.instance;
//          this.graph = graph;
//          this.vexpand = true;
//          this.hexpand = true;

//          this.store = new GLib.ListStore (typeof (CanvasGraphProperty));
//          var selection = new Gtk.SingleSelection (store);

//          var factory = new Gtk.SignalListItemFactory ();
//          factory.setup.connect (setup_item);
//          factory.bind.connect (bind_item);

//          this.list_view = new Gtk.ListView (selection, factory);
//          list_view.vexpand = true;
//          list_view.hexpand = true;
//          list_view.single_click_activate = true;

//          append(list_view);

//          reload_properties ();
//          graph.property_added.connect(store.append);
//          graph.properties_removed.connect(store.remove_all);
//      }

//      private void setup_item (GLib.Object obj) {
//          var item = obj as Gtk.ListItem;
//          if (item == null) return;

//          var row = new CanvasGraphPropertyRow(data_property_factory);
//          row.removed.connect((property, row_position) => {
//              this.graph.remove_property(property);
            
//              store.remove(row_position);
//              list_changed();
//          });
//          item.set_child(row);
//      }

//      private void bind_item (GLib.Object obj) {
//          var item = obj as Gtk.ListItem;
//          if (item == null) return;

//          var prop = item.get_item() as CanvasGraphProperty;
//          var row = item.get_child() as CanvasGraphPropertyRow;

//          row.position = item.position;
        
//          if (prop != null && row != null)
//              row.update_from_property (prop);
//      }

//      private void reload_properties () {
//          store.remove_all ();
//          foreach (var prop in graph.get_all_properties ())
//              store.append (prop);
//      }
//  }

