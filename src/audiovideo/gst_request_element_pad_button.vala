namespace AudioVideo {

    public class RequestElementPadButton : Gtk.Widget {

        public signal void pad_added(Gst.Pad pad);

        private Gst.Element element;
        private Gtk.MenuButton toggle_button;
        private Gtk.PopoverMenu request_pad_menu;
        private GLib.Menu menu_model;

        ~RequestElementPadButton() {
            toggle_button.unparent ();
        }

        construct {
            set_layout_manager (new Gtk.BinLayout ());
        }

        public RequestElementPadButton(Gst.Element element, Gst.PadDirection direction) {
            this.element = element;
            this.menu_model = new GLib.Menu();

            var actions_group = new SimpleActionGroup();
            foreach (var template in this.element.get_pad_template_list()) {
                if (template.direction == direction && template.presence == Gst.PadPresence.REQUEST) {
                    var add_pad_item = new GLib.MenuItem(template.name_template, null);
                    add_pad_item.set_action_and_target_value("actions.add_pad.%".printf(template.name_template), template.name_template);
                    menu_model.append_item(add_pad_item);
                
                    var add_pad_action = new GLib.SimpleAction("add_pad.%".printf(template.name_template), VariantType.STRING);
                    add_pad_action.activate.connect(this.add_pad_activated);
                    actions_group.add_action(add_pad_action);
                }
            }
            this.insert_action_group("actions", actions_group);
            
            this.request_pad_menu = new Gtk.PopoverMenu.from_model (this.menu_model);
            
            this.toggle_button = new Gtk.MenuButton ();
            toggle_button.set_icon_name ("list-add");
            toggle_button.set_parent (this);
            toggle_button.set_popover (request_pad_menu);
        }

        private void add_pad_activated(GLib.Variant? pad_name_attribute) {
            size_t length;
            var pad_name = pad_name_attribute.get_string(out length);
            var added_pad = element.request_pad_simple(pad_name);
            if (added_pad == null) {
                return;
            }
            this.pad_added(added_pad);
        }
    }
}