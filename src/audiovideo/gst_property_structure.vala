namespace AudioVideo {
    class GstStructureProperty : Data.DataProperty {

        //  private Gtk.ToggleButton toggle_button;
        //  private Gtk.Popover popover;

        //  private Gst.Structure? structure;

        ~GstStructureProperty() {
            //  popover.unparent();
            //  toggle_button.unparent();
        }

        public GstStructureProperty(GLib.ParamSpec param_spec) {
            base(param_spec);
            
            //  var property_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            //  var icon = new Gtk.Image.from_icon_name("open-menu");
            //  icon.valign = Gtk.Align.CENTER;
            //  property_box.append(icon);

            //  var label = new Gtk.Label("Edit");
            //  label.valign = Gtk.Align.CENTER;
            //  property_box.append(label);
            
            //  this.toggle_button = new Gtk.ToggleButton();
            //  toggle_button.set_parent(this);
            //  toggle_button.set_child(property_box);
            //  toggle_button.toggled.connect(this.button_toggled);
        
            //  this.popover = new Gtk.Popover();
            //  //  popover.set_parent(toggle_button);
            //  popover.closed.connect(this.popover_closed);

            //  create_structure_list(gst_element);
        }

        //  private void popover_closed() {
        //      toggle_button.active = false;
        //  }

        //  private void create_structure_list(Gst.Element gst_element) {
        //      var value = GLib.Value(param_spec.value_type);
        //      gst_element.get_property(param_spec.name, ref value);

        //      unowned var structure = value as Gst.Structure;
        //      if (structure == null) {
        //          this.structure = new Gst.Structure.empty("");
        //      } else {
        //          this.structure = new Gst.Structure.empty(structure.get_name());
        //      }

        //      var list_view = new GstStructureList(structure);

        //      popover.set_child(list_view);
        //  }


        //  private void button_toggled() {
        //      if (toggle_button.active) {
        //          popover.popup();
        //      } else {
        //          popover.popdown();
        //      }
        //  }
    }
}