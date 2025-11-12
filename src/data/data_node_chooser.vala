// Copyright (C) 2025 activey
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

namespace Data {

    public class NodeNameFilter : Gtk.Filter {

        private string? filter;

        protected override bool match (GLib.Object? item) {
            if (filter == null) {
                return true;
            }
            var builder = item as CanvasNodeBuilder;
            var name_with_description = "%s %s".printf(builder.name(), builder.description());
            return name_with_description.down().contains(filter.down());
        }

        public void filter_changed(string new_filter) {
            this.filter = new_filter;
            this.changed(Gtk.FilterChange.DIFFERENT);
        }
    }

    public class StaticNameFilter : Gtk.Filter {

        private string[] ids;

        public StaticNameFilter(string[] ids) {
            this.ids = ids;
        }

        protected override bool match (GLib.Object? item) {
            if (ids.length == 0) {
                return true;
            }
            var builder = item as CanvasNodeBuilder;
            
            foreach (var id in ids) {
                if (id == builder.id()) {
                    return true;
                }
            }
            return false;
        }
    }

    public class DataNodeChooserBox : Gtk.Box {

        public signal void builder_selected(CanvasNodeBuilder builder);

        private CanvasNodeFactory node_factory;
        private Gtk.Filter name_filter;
        private Gtk.SearchEntry? search_entry;

        private NodeNameFilter? node_name_filter;

        private GLib.ListStore list_model;
        private Gtk.FilterListModel filter_model;
        private Gtk.ListView item_list;

        construct {
            orientation = Gtk.Orientation.VERTICAL;
            spacing = 5;
            hexpand = true;
            margin_start = margin_end = margin_top = margin_bottom = 5;
        }

        public DataNodeChooserBox.with_static_filter(CanvasNodeFactory node_factory, string[] ids) {
            this.node_factory = node_factory;
            this.name_filter = new StaticNameFilter(ids);

            create_items_list();
        }

        public DataNodeChooserBox(CanvasNodeFactory node_factory) {
            this.node_factory = node_factory;
            this.node_name_filter = new NodeNameFilter();
            this.name_filter = this.node_name_filter;

            create_search_entry();
            create_items_list();
        }

        private void create_search_entry() {
            this.search_entry = new Gtk.SearchEntry();
            search_entry.placeholder_text = "Search in ";
            search_entry.search_changed.connect(() => {
                this.node_name_filter.filter_changed(this.search_entry.text);
            });
            base.append(search_entry);
        }

        private void create_items_list() {
            this.list_model = new ListStore(typeof(CanvasNodeBuilder));
            this.filter_model = new Gtk.FilterListModel(list_model, name_filter);

            var scrolled_list = new Gtk.ScrolledWindow();
            scrolled_list.vexpand = scrolled_list.hexpand = true;
            scrolled_list.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolled_list.set_max_content_height(400);
            scrolled_list.set_min_content_width(300);
            scrolled_list.set_max_content_width(400);
            scrolled_list.set_propagate_natural_height(true);
            
            var element_factory = new Gtk.SignalListItemFactory();
            element_factory.setup.connect(setup_element);
            element_factory.bind.connect(bind_element);

            this.item_list = new Gtk.ListView(new Gtk.SingleSelection(filter_model), element_factory);
            item_list.activate.connect(this.item_selected);
            item_list.single_click_activate = true;
            item_list.vexpand = true;
            item_list.set_size_request(400, -1);

            scrolled_list.set_child(item_list);
            base.append(scrolled_list);

            populate_items.begin();
        }

        private void item_selected(uint position) {
            var builder = filter_model.get_item(position) as CanvasNodeBuilder;
            this.builder_selected(builder);
        }

        void setup_element(GLib.Object object) {
            var list_item = object as Gtk.ListItem;
      
            var node_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            node_box.margin_top = node_box.margin_bottom = 5;
            node_box.hexpand = true;
            node_box.halign = Gtk.Align.FILL;
            
            var name_label = new Gtk.Label("");
            name_label.halign = Gtk.Align.START;
            name_label.set_wrap(true);
            name_label.set_wrap_mode(Pango.WrapMode.WORD_CHAR);
            node_box.append(name_label);

            var description_label = new Gtk.Label("");
            description_label.visible = false;
            description_label.add_css_class("node_chooser_label_text");
            description_label.halign = Gtk.Align.START;
            description_label.set_ellipsize(Pango.EllipsizeMode.END);

            node_box.append(description_label);

            list_item.set_child(node_box);
        }
      
        void bind_element(GLib.Object object) {
            var list_item = object as Gtk.ListItem;
            var node_box = list_item.get_child() as Gtk.Box;
            var node_builder = list_item.get_item() as CanvasNodeBuilder;

            var label = node_box.get_first_child() as Gtk.Label;
            label.set_text(node_builder.name());

            var description = node_builder.description();
            if (description != null) {
                var description_label = label.get_next_sibling() as Gtk.Label;
                description_label.visible = true;
                description_label.set_markup(description);

                node_box.set_tooltip_markup(description);
            }
        }

        public async void populate_items() {
            new Thread<void> (null, () => {
                var elements_count = 0;
                node_factory.consume_all_builders(builder => {
                    Idle.add(() => {
                        this.list_model.append(builder);
                        return false;
                    });
                    elements_count++;
                });
                if (search_entry != null) {
                    search_entry.placeholder_text= "Search in %d elements".printf(elements_count);
                }
                Idle.add (populate_items.callback);
            });
            yield;
        }
    }

    public class DataNodeChooser : Object {

        public signal void node_created(CanvasDisplayNode data_node);

        private CanvasNodeFactory node_factory;
        private Gtk.MenuButton menu_button;

        private DataNodeChooserBox node_chooser_box;
        private Gtk.Popover popover;

        private DataNodeChooser(CanvasNodeFactory node_factory) {
            this.node_factory = node_factory;
            
            this.popover = new Gtk.Popover();
            popover.add_css_class("menu");
            popover.set_position(Gtk.PositionType.BOTTOM);
            popover.halign = Gtk.Align.START;
            popover.set_offset(-5, 0);
            
            this.menu_button = new Gtk.MenuButton();
            menu_button.set_tooltip_text("Add operation node");
            menu_button.set_child(new Gtk.Image.from_icon_name("insert-object-symbolic"));
            menu_button.set_popover(popover);
            menu_button.add_css_class("button");
            
            this.node_chooser_box = new DataNodeChooserBox(this.node_factory);
            node_chooser_box.builder_selected.connect(this.builder_selected);
            popover.set_child(node_chooser_box);
            
            // ESC key to close popover no mater the child focused
            var key_controller = new Gtk.EventControllerKey();
            key_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
            key_controller.key_pressed.connect((keyval, keycode, state) => {
                if (keyval == Gdk.Key.Escape) {
                    popover.popdown();
                    return true;
                }
                return false;
            });
            ((Gtk.Widget)popover).add_controller(key_controller);
        }

        private void builder_selected(CanvasNodeBuilder builder) {
            try {
                popover.hide();
                node_created(builder.create(10, 10));
            } catch (Error e) {
                warning(e.message);
            }
        }

        public DataNodeChooser.everything(CanvasNodeFactory node_factory) {
            this(node_factory);
        }

        public unowned Gtk.MenuButton get_menu_button() {
            return this.menu_button;
        }
    }
}