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

    public void printout() {
      foreach (var child in objects) {
          child.printout();
        }
    }

    public void remove(DataObject object) {
      var index = objects.index(object);
      objects.remove(object);
      items_changed(index, 1, 0);
    }

    public void refresh(DataObject object) {
      items_changed(objects.index(object), 0, 0);
    }
}

class AttributeObject : DataObject {

  public AttributeObject(string name, string? value = "") {
    base(false, name, value);
  }
}

class StructureObject : DataObject {

  public StructureObject(string name, DataObject[]? children = null) {
    base(true, name, "", children);
  }
}

class DataObject : Object {
  public string? name;
  public string? value;
  public DataModel children { get; construct set;}
  internal DataModel parent_model;

  public bool can_have_children {
    get;
    construct set;
  }

  public DataObject(bool can_have_children, string name, string? value = "", DataObject[]? children = null) {
      this.can_have_children = can_have_children;
      this.name = name;
      this.value = value;
      this.children = new DataModel();
      
      foreach (var child in children) {
          this.children.add(child);
      }
  }

  public void printout() {
      print("name = %s, value = %s\n", name, value);
      if (children == null) {
          return;
      }
      children.printout();
  }

  public void remove_from_parent() {
    parent_model.remove(this);
  }

  public void add_child(DataObject child) {
    children.add(child);
    parent_model.refresh(this);
  }
}

class ColumnViewTestApplication : Gtk.Application {
  
  private Gtk.ColumnView list_view;

  private Gtk.EventControllerKey key_controller;
  private Gtk.GestureClick click_listener;

  private Gtk.SingleSelection selection;
  private DataModel data_model;

  private Gtk.PopoverMenu context_menu;
  private GLib.Menu menu_model;

  public ColumnViewTestApplication() {
    activate.connect (() => {
      var window = new Gtk.ApplicationWindow(this);
      window.set_default_size(800, 600);
      
      create_column_view(window);
      add_key_controller();
      add_mouse_click_controller();

      add_context_menu();
      init_context_actions();

      var scrolled_window = new Gtk.ScrolledWindow();
      //  scrolled_window.add_css_class ("frame");
      scrolled_window.set_child(list_view);
      scrolled_window.vexpand = true;

      var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
      var action_bar = new Gtk.ActionBar();
  
      var button = new Gtk.Button();
      button.set_icon_name("document-save");
      button.clicked.connect(() => {
        data_model.printout();
      });
      action_bar.pack_start(button);
  
      box.append(scrolled_window);
      box.append(action_bar);
  
      window.set_child(box);
      window.present();

      data_model.add(new StructureObject("text/x-raw", {new AttributeObject("format", "IV4L")}));

    });
  }

  private void create_column_view(Gtk.Window window) {
    this.data_model = new DataModel();
    this.selection = new Gtk.SingleSelection(new Gtk.TreeListModel(data_model, false, true, add_tree_node));

    this.list_view = new Gtk.ColumnView(selection);
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
    if (selected_row.get_parent() == null) {
      var selected_object = selected_row.get_item() as DataObject;
      menu_model.append("Add attribute to %s".printf(selected_object.name), "actions.add_structure_attribute");
    }
  }

  private void init_context_actions() {
    var actions_group = new SimpleActionGroup();

    var new_structure_action = new GLib.SimpleAction("new_structure", null);
    new_structure_action.activate.connect(() =>  {
      insert_new_structure();
    });
    actions_group.add_action(new_structure_action);

    var new_attribute_action = new GLib.SimpleAction("add_structure_attribute", null);
    new_attribute_action.activate.connect(() =>  {
      var selected_row = selection.get_selected_item() as Gtk.TreeListRow;
      var selected_object = selected_row.get_item() as DataObject;

      selected_object.add_child(new AttributeObject("unnamed"));
      //  custom_model.add(new DataObject("unnamed"));
    });
    actions_group.add_action(new_attribute_action);

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

      var entry = new Gtk.EditableLabel("");
      entry.set_editable(true);

      list_item.set_child(entry);
  }

  void bind_value(GLib.Object object) {
      var list_item = object as Gtk.ListItem;

      var entry = list_item.get_child() as Gtk.EditableLabel;
      var row = list_item.get_item() as Gtk.TreeListRow;
      var data_obj = row.get_item() as DataObject;

      if (row.get_parent() == null) {
          entry.set_editable(false);
      }

      entry.set_text(data_obj.value);
      entry.notify["text"].connect(() => {
          data_obj.value = entry.text;
      });
  }

  GLib.ListModel? add_tree_node(GLib.Object object) {
      var data_obj = object as DataObject;
      if (!data_obj.can_have_children) {
        return null;
      }
      return data_obj.children;
  }
}

int main (string[] args) {
  var app = new ColumnViewTestApplication();
  return app.run(args);
}

