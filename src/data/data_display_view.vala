namespace Data {
    public class DataDisplayView : Gtk.Widget {

        private Gtk.Paned node_with_properties;
        private Gtk.Box node_box;
        private Gtk.ActionBar action_bar;
        private Gtk.Box node_children_box;

        private DataDetailsPanel data_details;
        private Gtk.ScrolledWindow details_scroll_window;

        public bool action_bar_visible {
            set {
                action_bar.visible = value;
            }
            get {
                return action_bar.visible;
            }
        }

        construct {
            set_layout_manager(new Gtk.BinLayout());
            vexpand = true;
        }

        ~DataDisplayView() {
            node_with_properties.unparent();
        }

        public DataDisplayView() {
            create_node_with_details();
        }

        private void create_node_with_details() {
            this.node_with_properties = new Gtk.Paned(Gtk.Orientation.HORIZONTAL);
            this.node_with_properties.add_css_class("rounded_bottom");
            this.node_with_properties.set_resize_start_child(false);
            this.node_with_properties.set_shrink_start_child(false);
            this.node_with_properties.set_shrink_end_child(false);

            this.data_details = new DataDetailsPanel();
            this.node_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            node_box.add_css_class("rounded_bottom_right");
            this.node_children_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            node_children_box.add_css_class("rounded_bottom_right");
            node_children_box.vexpand = true;
            node_box.append(node_children_box);
            
            create_action_bar();

            this.details_scroll_window = new Gtk.ScrolledWindow();
            details_scroll_window.hscrollbar_policy = Gtk.PolicyType.NEVER;
            details_scroll_window.set_child(data_details);
            details_scroll_window.visible = false;

            node_with_properties.set_start_child(details_scroll_window);
            node_with_properties.set_end_child(node_box);
            node_with_properties.set_parent(this);
        }

        private void create_action_bar() {
            this.action_bar = new Gtk.ActionBar();
            action_bar.add_css_class("rounded_bottom_right");
            action_bar.add_css_class("rounded_bottom_left");
            node_box.append(action_bar);
        }

        public Gtk.Box add_action_bar_child_start(Gtk.Widget child) {
            var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            wrapper.margin_start = 5;
            wrapper.append(child);
            action_bar.pack_start(wrapper);
            return wrapper;
        }

        public Gtk.Box add_action_bar_child_end(Gtk.Widget child) {
            var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            wrapper.margin_end = 5;
            wrapper.append(child);
            action_bar.pack_end(wrapper);
            return wrapper;
        }

        public void remove_from_actionbar(Gtk.Widget child) {
            action_bar.remove(child);
        }
        
        public PropertyGroup add_property_group(string group_name) {
            return data_details.add_property_group(group_name);
        }

        public void remove_property_group(Data.PropertyGroup? group) {
            data_details.remove_property_group(group);
        }

        public new void add_child(Gtk.Widget child) {
            node_children_box.append(child);
        }

        public new void remove_child(Gtk.Widget child) {
            node_children_box.remove(child);
        }

        public Gtk.ToggleButton create_toggle_details_button () {
            var toggle_button = new Gtk.ToggleButton();
            toggle_button.set_icon_name("open-menu");
            toggle_button.toggled.connect(toggle => {
                details_scroll_window.visible = toggle.active;
                if (toggle.active) {
                    action_bar.remove_css_class("rounded_bottom_left");
                } else {
                    action_bar.add_css_class("rounded_bottom_left");
                }
            });
            toggle_button.active = false;
            return toggle_button;
        }
    }
}