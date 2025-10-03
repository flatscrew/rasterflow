namespace AudioVideo {

    class DataModel : ListModel, Object {

        private List<DataObject> objects = new List<DataObject>();
    
        public GLib.Object? get_item (uint position) {
          return objects.nth_data(position);
        }
    
        public GLib.Type get_item_type () {
          return typeof(DataObject);
        }
        public uint get_n_items () {
          return objects.length();
        }
    
        public void add(DataObject object) {
          object.parent_model = this;
          objects.append(object);
    
          items_changed(objects.length(), 0, 1);
        }
    
        public void remove(DataObject object) {
          var index = objects.index(object);
          objects.remove(object);
          items_changed(index, 1, 0);
        }
    
        public void printout() {
          foreach (var child in objects) {
              child.printout();
            }
        }

        public void clear() {
          uint current_size = objects.length();
          this.objects = new List<DataObject>();

          items_changed(0, current_size, 0);
        }
    }
    
    class AttributeObject : DataObject {
    
      public AttributeObject(string name, GLib.Value value) {
        base(false, name, value.type(), value);
      }

      public AttributeObject.with_type(string name, GLib.Type type) {
        base(false, name, type);
      }
    }
    
    class StructureObject : DataObject {
    
      public StructureObject(string name, DataObject[]? children = null) {
        base(true, name, null, null, children);
      }
    }
    
    class DataObject : Object {
      public string? name;
      public GLib.Type? data_type;
      private GLib.Value? _value;
      
      public GLib.Value? typed_value {
        get {
          return _value;
        }

        set {
          if (value != null && this.data_type != null && value.type() == this.data_type) {
            _value = value;
          }
        }
      }

      public DataModel children { get; construct set;}
      internal DataModel parent_model;
    
      public bool can_have_children {
        get;
        construct set;
      }
    
      public DataObject(bool can_have_children, string name, GLib.Type? type = null, GLib.Value? value = null, DataObject[]? children = null) {
          this.can_have_children = can_have_children;
          this.name = name;
          this.data_type = type;
          this.children = new DataModel();

          typed_value = value;

          foreach (var child in children) {
              this.children.add(child);
          }
        }
      
        public void remove_from_parent() {
          parent_model.remove(this);
        }
      
        public void add_child(DataObject child) {
          children.add(child);
        }

        public void printout() {
          if (typed_value == null ) {
            return;
          }
          
          print("name = %s, value = %s\n", name, typed_value.get_string());
          if (children == null) {
              return;
          }
          children.printout();
      }
    }

    public class GstCapsEditorProperty : Data.DataProperty {

        private Gst.Caps caps;

        private Gtk.ColumnView list_view;
        private Gtk.Button edit_button;
        private Gtk.Button apply_button;
        private Gtk.Button revert_button;

        private Gtk.EventControllerKey key_controller;
        private Gtk.GestureClick click_listener;

        private Gtk.SingleSelection selection;
        private DataModel data_model;

        private Gtk.PopoverMenu context_menu;
        private GLib.Menu menu_model;

        private TypedProperties typed_properties = new TypedProperties();

        ~GstCapsEditorProperty() {
        }

        public GstCapsEditorProperty(ParamSpec param_spec) {
            base(param_spec);
            base.hexpand = true;
            base.set_size_request (-1, 150);
            base.set_halign(Gtk.Align.FILL);

            var editor_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            editor_box.add_css_class ("frame");

            create_column_view();
            add_key_controller();
            add_mouse_click_controller();
      
            add_context_menu();
            init_context_actions();
      
            var scrolled_window = new Gtk.ScrolledWindow();
            scrolled_window.set_child(list_view);
            scrolled_window.vexpand = true;

            this.edit_button = new Gtk.Button.from_icon_name("document-edit");
            edit_button.set_tooltip_text("Edit");
            edit_button.clicked.connect(this.edit_caps);

            this.apply_button = new Gtk.Button.from_icon_name("document-save");
            apply_button.set_tooltip_text("Apply");
            apply_button.set_sensitive(false);
            apply_button.clicked.connect(this.apply_caps_changes);

            this.revert_button = new Gtk.Button.from_icon_name("edit-undo");
            revert_button.set_tooltip_text("Cancel");
            revert_button.set_sensitive(false);
            revert_button.clicked.connect(this.revert_caps_changes);
        
            var buttons_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            buttons_box.add_css_class("linked");
            buttons_box.append(apply_button);
            buttons_box.append(revert_button);

            var action_bar = new Gtk.ActionBar();
            action_bar.pack_start(edit_button);
            action_bar.pack_end(buttons_box);
            
            editor_box.append(scrolled_window);
            editor_box.append(action_bar);

            editor_box.set_parent(this);
        }

        private void create_column_view() {
            this.data_model = new DataModel();
            this.selection = new Gtk.SingleSelection(new Gtk.TreeListModel(data_model, false, true, add_tree_node));
        
            this.list_view = new Gtk.ColumnView(selection);
            list_view.set_sensitive(false);
            list_view.append_column(name_column());
            list_view.append_column(value_column());
          }
        
          private void add_key_controller() {
            this.key_controller = new Gtk.EventControllerKey ();
            list_view.add_controller (key_controller);
            key_controller.key_pressed.connect(this.key_pressed);
          }
        
          private void add_mouse_click_controller() {
            this.click_listener = new Gtk.GestureClick();
            click_listener.set_button(3);
            click_listener.pressed.connect(this.mouse_button_pressed);
            list_view.add_controller(click_listener);
          }
        
          private void add_context_menu() {
            this.menu_model = new GLib.Menu();
            this.context_menu = new Gtk.PopoverMenu.from_model(menu_model);
            context_menu.set_parent(list_view);
          }  
        
          private void fill_menu_items() {
            menu_model.remove_all();
            menu_model.append("Create new structure", "actions.new_structure");
        
            var selected_row = selection.get_selected_item() as Gtk.TreeListRow;
            if (selected_row == null) {
                return;
            }
            
            if (selected_row.get_parent() == null) {
              var selected_object = selected_row.get_item() as DataObject;
              var attributes_menu = new GLib.Menu();
              
              foreach (var supported_type in typed_properties.supported_types()) {
                var add_attribute_item = new GLib.MenuItem(supported_type.name(), null);
                add_attribute_item.set_action_and_target_value("actions.add_attribute.%".printf(supported_type.name()), supported_type.name());

                attributes_menu.append_item(add_attribute_item);
              }
              menu_model.append_submenu("Add attribute to %s".printf(selected_object.name), attributes_menu);
            }
            menu_model.append("Delete row", "actions.delete_row");
          }
        
          private void init_context_actions() {
            var actions_group = new SimpleActionGroup();
        
            var new_structure_action = new GLib.SimpleAction("new_structure", null);
            new_structure_action.activate.connect(insert_new_structure);
            actions_group.add_action(new_structure_action);
        
        
            var delete_row_action = new GLib.SimpleAction("delete_row", null);
            delete_row_action.activate.connect(delete_selected);
            actions_group.add_action(delete_row_action);
            

            foreach (var supported_type in typed_properties.supported_types()) {
              var add_attribute_action = new GLib.SimpleAction("add_attribute.%".printf(supported_type.name()), VariantType.STRING);

              add_attribute_action.activate.connect(type_attribute => {
                size_t length;
                var type_string = type_attribute.get_string(out length);
                var parsed_type = Type.from_name(type_string);
                
                insert_new_attribute(parsed_type);
              });
              actions_group.add_action(add_attribute_action);
            }

            list_view.insert_action_group("actions", actions_group);
          }

          private void mouse_button_pressed(int n_press, double x, double y) {
            var button = click_listener.get_button();
            if (button == Gdk.BUTTON_SECONDARY) {
                fill_menu_items();
        
                context_menu.set_pointing_to(Gdk.Rectangle() {
                  x= (int)x,
                  y= (int)y
                });
                context_menu.popup();
            }
          }
        
          private void edit_caps() {
            this.edit_button.sensitive = false;
            this.list_view.sensitive = true;
            this.apply_button.sensitive = true;
            this.revert_button.sensitive = true;
          }

          private void apply_caps_changes() {
            this.edit_button.sensitive = true;
            this.list_view.sensitive = false;
            this.apply_button.sensitive = false;
            this.revert_button.sensitive = false;
          
            caps_changed();
          }

          private void revert_caps_changes() {
            this.edit_button.sensitive = true;
            this.list_view.sensitive = false;
            this.apply_button.sensitive = false;
            this.revert_button.sensitive = false;
            
            set_model_from_caps();
          }

          private bool key_pressed(uint keyval, uint keycode, Gdk.ModifierType state) {
            if (keyval == Gdk.Key.Delete) {
              delete_selected();
              return Gdk.EVENT_STOP;
            } else if (keyval == Gdk.Key.Insert) {
              insert_new_structure();
              return Gdk.EVENT_STOP;
            }
            return Gdk.EVENT_PROPAGATE;
          }
        
          private void delete_selected() {
            var selected_row = selection.get_selected_item() as Gtk.TreeListRow;
            var data_obj = selected_row.get_item() as DataObject;
            data_obj.remove_from_parent();
          }
        
          private void insert_new_structure() {
            data_model.add(new StructureObject("unnamed_%u".printf(Random.next_int())));
          }

          private void insert_new_attribute(GLib.Type type) {
            var selected_row = selection.get_selected_item() as Gtk.TreeListRow;
            var selected_object = selected_row.get_item() as DataObject;
            selected_object.add_child(new AttributeObject.with_type("unnamed", type));
          }
        
          private Gtk.ColumnViewColumn name_column() {
            var name_factory = new Gtk.SignalListItemFactory();
            name_factory.setup.connect(setup_name);
            name_factory.bind.connect(bind_name);
        
            var name_column = new Gtk.ColumnViewColumn("Name", name_factory);
            return name_column;
          }
        
          void setup_name(GLib.Object object) {
              var list_item = object as Gtk.ListItem;
        
              var entry = new Gtk.EditableLabel("");
              entry.set_editable(true);
        
              var expander = new Gtk.TreeExpander();
              expander.set_child(entry);
              list_item.set_child(expander);
          }
        
          void bind_name(GLib.Object object) {
              var list_item = object as Gtk.ListItem;
              var row = list_item.get_item() as Gtk.TreeListRow;
              var data_obj = row.get_item() as DataObject;
        
              var expander = list_item.get_child() as Gtk.TreeExpander;
              expander.set_list_row(row);
              
              var entry = expander.get_child() as Gtk.EditableLabel;
              entry.set_text(data_obj.name);
              entry.notify["text"].connect(() => {
                data_obj.name = entry.text;
              });
          }

          private Gtk.ColumnViewColumn value_column() {
            var value_factory = new Gtk.SignalListItemFactory();
            value_factory.setup.connect(setup_value);
            value_factory.bind.connect(bind_value);
      
            var value_column = new Gtk.ColumnViewColumn("Value", value_factory);
            value_column.set_expand(true);
            return value_column;
          }

          void setup_value(GLib.Object object) {
            var list_item = object as Gtk.ListItem;
      
            var wrapper = new TypedPropertyWrapper(this.typed_properties);
            list_item.set_child(wrapper);
          }
        
          void bind_value(GLib.Object object) {
            var list_item = object as Gtk.ListItem;
      
            var wrapper = list_item.get_child() as TypedPropertyWrapper;
            var row = list_item.get_item() as Gtk.TreeListRow;
            var data_obj = row.get_item() as DataObject;
      
            if (data_obj.data_type != null) {
              wrapper.change_type(data_obj.data_type);
            }
            if (data_obj.typed_value != null) {
              wrapper.set_value(data_obj.typed_value);
            }
            wrapper.value_changed.connect(new_value => {
              data_obj.typed_value = new_value;
            });
          }

          GLib.ListModel? add_tree_node(GLib.Object object) {
            var data_obj = object as DataObject;
            if (!data_obj.can_have_children) {
              return null;
            }
            return data_obj.children;
          }

        protected override void set_property_value(GLib.Value value) {
          this.caps = value as Gst.Caps;
          set_model_from_caps();
        }

        private void set_model_from_caps() {
          data_model.clear();
          
          for (var index = 0; index < caps.get_size(); index ++) {
            unowned var structure = caps.get_structure(index);
            
            AttributeObject[] attributes = {};
            structure.foreach((field_id, value) => {
              attributes += new AttributeObject(field_id.to_string(), value);
              return true;
            });
            var structure_data = new StructureObject(structure.get_name(), attributes);
            data_model.add(structure_data);
          }
        }

        private void caps_changed() {
          var current_caps = new Gst.Caps.empty();

          for (var index = 0; index < data_model.get_n_items(); index++) {
            var structure_object = data_model.get_item(index) as DataObject;
            var new_structure = new Gst.Structure.empty(structure_object.name);

            for (var child_index = 0; child_index < structure_object.children.get_n_items(); child_index++) {
              var child = structure_object.children.get_item(child_index) as DataObject;
              if (child.typed_value == null) {
                continue;
              }
              new_structure.set_value(child.name, child.typed_value);
            }
            current_caps.append_structure(new_structure.copy());
          }

          property_value_changed(current_caps);
        }
    }

}