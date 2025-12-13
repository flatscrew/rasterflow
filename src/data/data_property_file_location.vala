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
    
    public class FileInfoGroup : Object {
        
        private FileInfoDelegate info_delegate;
        private Adw.PreferencesGroup info_group;
        private Gee.List<Adw.ActionRow> info_rows = new Gee.ArrayList<Adw.ActionRow>();
        
        public Adw.PreferencesGroup preferences_group {
            get {
                return info_group;
            }
        }
        
        public FileInfoGroup.with_title(string title, FileInfoDelegate info_delegate) {
            this.info_group = new Adw.PreferencesGroup();
            info_group.set_title(title);
            
            this.info_delegate = (file, info_group) => {
                info_delegate(file, info_group);
            };
        }
        
        public void add_simple_row(string contents) {
            var row = new Adw.ActionRow();
            row.set_title(contents);
            info_group.add(row);
            info_rows.add(row);
        }
        
        public void add_file_info_row(
            string title, 
            string value,
            string tooltip = "Copy value",
            string icon = "edit-copy-symbolic",
            FileInfoButtonAction action = copy_value_action
        ) 
        {
            var row = new Adw.ActionRow();
            row.set_title(title);
            row.set_subtitle(value);
            
            var button = new Gtk.Button.from_icon_name(icon);
            button.set_tooltip_text(tooltip);
            button.clicked.connect(() => {
                action(value);
            });
            button.add_css_class("flat");
            button.valign = Gtk.Align.CENTER;
            row.add_suffix(button);
            
            info_group.add(row);
            info_rows.add(row);
        }
        
        public void copy_value_action(string value) {
            var display = Gdk.Display.get_default();
            if (display == null)
                return;
        
            var clipboard = display.get_clipboard();
            clipboard.set_text(value);
        }
        
        public void update(File file) {
            clear();
            info_delegate(file, this);
        }
        
        private void clear() {
            foreach (var row in info_rows) {
                info_group.remove(row);
            }
            info_rows.clear();
        }
    }
    
    public delegate void FileInfoDelegate(File file, FileInfoGroup info_group);
    
    public delegate void FileInfoButtonAction(string value);
    
    class OpenFileLocationProperty : Data.AbstractDataProperty {
        
        private Gtk.Box box;
        private Gtk.Button file_chooser_button;
        private Gtk.MenuButton file_details_button;
        private Gtk.FileDialog file_dialog;
        
        private Gtk.Box file_info_content;
        private Gee.List<FileInfoGroup> info_groups = new Gee.ArrayList<FileInfoGroup>();
        
        ~OpenFileLocationProperty() {
            box.unparent();
        }

        public OpenFileLocationProperty(ParamSpecString string_spec) {
            base(string_spec);

            var all_filter = new Gtk.FileFilter();
            all_filter.name = "Any file";
            all_filter.add_pattern("*");

            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
            filters.append(all_filter);

            setup(string_spec, filters);
        }

        public OpenFileLocationProperty.with_file_filters(ParamSpecString string_spec, GLib.ListStore filters) {
            base(string_spec);
            setup(string_spec, filters);
        }

        private void setup(ParamSpecString string_spec, GLib.ListStore filters) {
            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            box.set_parent(this);
            
            
            this.file_dialog = new Gtk.FileDialog();
            file_dialog.set_filters(filters);
            
            this.file_chooser_button = new Gtk.Button.with_label("Choose a File");
            file_chooser_button.clicked.connect(() => open_dialog());
            
            box.append(file_chooser_button);
            add_file_info_menu();
        }
        
        private void add_file_info_menu() {
            this.file_details_button = new Gtk.MenuButton();
            file_details_button.set_tooltip_text("Show file details");
            file_details_button.set_icon_name("edit-find-symbolic");
            file_details_button.visible = false;
        
            var popover = new Gtk.Popover();
            popover.set_size_request(300, -1);
        
            var scrolled = new Gtk.ScrolledWindow();
            scrolled.set_overlay_scrolling(true);
            scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scrolled.set_vexpand(true);
            scrolled.set_max_content_height(400);
            scrolled.set_min_content_width(300);
            scrolled.set_max_content_width(400);
            scrolled.set_propagate_natural_height(true);
        
            this.file_info_content = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
            file_info_content.set_vexpand(true);
        
            scrolled.set_child(file_info_content);
            popover.set_child(scrolled);
        
            new_file_info_group("File Details", basic_file_info);
            
            file_details_button.set_popover(popover);
            box.append(file_details_button);
        }
        
        private void basic_file_info(File file, FileInfoGroup info_group) {
            try {
                var info = file.query_info("standard::size", FileQueryInfoFlags.NONE);
                var size = info.get_size();
                
                info_group.add_file_info_row("Path", file.get_path(), "Open containing folder", "folder-open-symbolic", open_file_folder);
                info_group.add_file_info_row("Size (bytes)", ("%" + int64.FORMAT).printf(size));
            } catch (Error e) {
                var row = new Adw.ActionRow();
                row.set_title("Could not load image");
            }
        }
        
        public void new_file_info_group(string title, FileInfoDelegate info_delegate) {
            var new_info_group = new FileInfoGroup.with_title(title, info_delegate);
            file_info_content.append(new_info_group.preferences_group);
            
            info_groups.add(new_info_group);
        }
        
        private void open_dialog() {
            var parent_window = base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window;

            file_dialog.open.begin(parent_window, null, (obj, res) => {
                try {
                    var file = file_dialog.open.end(res);
                    if (file != null) {
                        var path = file.get_path();
                        property_value_changed(path);
                        show_file_path(path);
                    }
                } catch (Error e) {
                    warning("File dialog cancelled or failed: %s", e.message);
                }
            });
        }
        
        private void open_file_folder(string file_path) {
            try {
                var file = File.new_for_path(file_path);
                var parent = file.get_parent();
                if (parent == null)
                    return;
        
                var uri = parent.get_uri();
                AppInfo.launch_default_for_uri(uri, null);
            } catch (Error e) {
                warning(e.message);
            }
        }
        
        protected override void set_property_value(GLib.Value value) {
            show_file_path(value.get_string());
        }
        
        private void show_file_path(string path) {
            file_chooser_button.label = GLib.Path.get_basename(path);
            file_details_button.visible = true;
            
            var file = File.new_for_path(path);
            foreach (var group in info_groups) {
                group.update(file);
            }
        }
    }
    
    class SaveFileLocationProperty : Data.AbstractDataProperty {

        private Gtk.Box box;
        private Gtk.Button file_chooser_button;
        private Gtk.Label file_location_label;
        private Gtk.FileDialog file_dialog;

        ~SaveFileLocationProperty() {
            box.unparent();
        }

        public SaveFileLocationProperty(ParamSpecString string_spec) {
            base(string_spec);

            var all_filter = new Gtk.FileFilter();
            all_filter.name = "Any file";
            all_filter.add_pattern("*");

            var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
            filters.append(all_filter);

            setup(string_spec, filters);
        }

        public SaveFileLocationProperty.with_file_filters(ParamSpecString string_spec, GLib.ListStore filters) {
            base(string_spec);
            setup(string_spec, filters);
        }

        private void setup(ParamSpecString string_spec, GLib.ListStore filters) {
            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            this.file_location_label = new Gtk.Label("");
            file_location_label.ellipsize = Pango.EllipsizeMode.END;
            file_location_label.add_css_class("property_label_text");

            this.file_dialog = new Gtk.FileDialog();
            file_dialog.set_filters(filters);

            this.file_chooser_button = new Gtk.Button.with_label("Choose a File");
            file_chooser_button.clicked.connect(() => save_dialog());

            box.append(file_chooser_button);
            box.append(file_location_label);
            box.set_parent(this);
        }

        private void save_dialog() {
            var parent_window = base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window;

            file_dialog.save.begin(parent_window, null, (obj, res) => {
                try {
                    var file = file_dialog.save.end(res);
                    if (file != null) {
                        var path = file.get_path();
                        property_value_changed(path);
                        file_location_label.set_text(path);
                    }
                } catch (Error e) {
                    warning("File dialog cancelled or failed: %s", e.message);
                }
            });
        }

        protected override void set_property_value(GLib.Value value) {
            file_location_label.set_text(value.get_string());
        }
    }
}
