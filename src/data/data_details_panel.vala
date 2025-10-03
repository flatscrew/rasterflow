namespace Data {
    
    protected class PropertyGroup : Gtk.Widget {

        private static int SPACING = 5;

        construct {
            set_layout_manager(new Gtk.BinLayout());
            margin_start = margin_end = margin_bottom = margin_top = SPACING;
            hexpand = true;
        }

        private Gtk.Expander group_expander;
        private Gtk.Grid group_grid;

        private Gee.Map<string,string> model;
        private Gtk.SizeGroup label_size_group;
        private Gtk.SizeGroup value_size_group;
        private int rows = 0;

        public PropertyGroup(string group_name, Gtk.SizeGroup label_size_group, Gtk.SizeGroup value_size_group) {
            this.model = new Gee.HashMap<string, string> ();
            this.label_size_group = label_size_group;
            this.value_size_group = value_size_group;

            this.group_expander = new Gtk.Expander (group_name);
            group_expander.set_parent(this);

            this.group_grid = new Gtk.Grid();
            group_grid.row_spacing = group_grid.column_spacing = SPACING;
            group_expander.set_child (group_grid);
        }

        ~PropertyGroup() {
            group_expander.unparent();
        }

        public void set_group_property (string name, string value) {
            this.model.set(name, value);
        }

        public void clear() {
            this.model.clear();
        }

        public void refresh() {
            for (var row_index = 0; row_index <= this.rows; row_index ++) {
                var old_name = group_grid.get_child_at(0, row_index);
                if (old_name == null) {
                    continue;
                }
                group_grid.remove(old_name);
                group_grid.remove(group_grid.get_child_at(1, row_index));
            }
            this.rows = 0;
    
            foreach (var name in model.keys) {
                var current_row = this.rows++;
                var value = model.get(name);

                var label_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                label_box.hexpand = true;
                var name_label = new Gtk.Label ("");
                name_label.set_markup ("<b>%s</b>".printf (name));
                name_label.halign = Gtk.Align.END;
                name_label.valign = Gtk.Align.START;
                name_label.hexpand = true;
                label_box.append (name_label);
                label_size_group.add_widget (label_box);
                
                var value_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                value_box.hexpand = true;
                var value_label = new Gtk.Label (value);
                value_label.hexpand = true;
                value_label.halign = Gtk.Align.START;
                value_label.wrap = true;
                value_label.wrap_mode = Pango.WrapMode.CHAR;
                value_label.justify = Gtk.Justification.FILL;
                value_box.append (value_label);
                value_size_group.add_widget (value_box);

                group_grid.attach (label_box, 0, current_row, 1, 1);
                group_grid.attach (value_box, 1, current_row, 1, 1);
            }
        }
    }

    protected class DataDetailsPanel : Gtk.Widget {
        
        construct {
            set_layout_manager (new Gtk.BinLayout ());
            hexpand = vexpand = true;
            
            set_size_request (200, -1);
        }

        ~DataDetailsPanel() {
            this.panel_box.unparent();
        }

        private Gtk.Box panel_box;
        private Gtk.SizeGroup label_size_group;
        private Gtk.SizeGroup value_size_group;

        public DataDetailsPanel() {
            this.panel_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
            panel_box.set_parent (this);
            panel_box.add_css_class ("sidebar");
            panel_box.add_css_class("rounded_bottom_left");

            label_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            value_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        }

        public PropertyGroup add_property_group(string group_name) {
            var group = new PropertyGroup (group_name, label_size_group, value_size_group);
            panel_box.append (group);
            return group;
        }

        public void remove_property_group(Data.PropertyGroup? group) {
            if (group == null) {
                return;
            }
            panel_box.remove(group);
        }
    }

}