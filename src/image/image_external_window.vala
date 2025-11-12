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

namespace Image {

    public class ExternalImageWindow : Adw.Window {
        private ImageViewerPanningArea panning_area;
        private ImageViewer image_viewer;
        private Gtk.ScrolledWindow scroller;
        private Gtk.Box box;
        private Gtk.ActionBar action_bar;
        private Gtk.Box zoom_control;
        private Gtk.Box reset_zoom_control;
        private Gtk.Button reset_zoom_button;

        public ExternalImageWindow(string title = "Image window") {
            Object(title: title);
            this.set_default_size(600, 400);
            
            this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

            this.scroller = new Gtk.ScrolledWindow();
            this.scroller.hexpand = true;
            this.scroller.vexpand = true;

            box.append(scroller);

            create_image_viewer();
            create_action_bar();
            create_zoom_control();

            var header_bar = new Adw.HeaderBar();
            header_bar.set_title_widget(new Gtk.Label(title));

            var toolbar_view = new Adw.ToolbarView();
            toolbar_view.add_top_bar(header_bar);
            toolbar_view.set_content(box);

            set_content(toolbar_view);
        }

        private void create_action_bar() {
            this.action_bar = new Gtk.ActionBar();
            box.append(action_bar);
        }

        public void set_title_text(string title) {
            this.title = title;
        }

        public string get_title_text() {
            return this.title;
        }

        public void display_pixbuf(Gdk.Pixbuf pixbuf) {
            image_viewer.replace_image(pixbuf);
            panning_area.refresh();
        }

        private void create_image_viewer() {
            this.image_viewer = new ImageViewer.with_max_zoom(10);
            this.panning_area = new ImageViewerPanningArea(image_viewer);

            this.scroller.set_child(panning_area);
        }

        private void create_zoom_control() {
            var scale = image_viewer.create_scale_widget();
            this.zoom_control = add_action_bar_child_end(scale);

            this.reset_zoom_button = new Gtk.Button.from_icon_name("zoom-original-symbolic");
            reset_zoom_button.tooltip_text = "Reset to original size";
            reset_zoom_button.clicked.connect(image_viewer.reset_zoom);
            this.reset_zoom_control = add_action_bar_child_end(reset_zoom_button);
           
            image_viewer.zoom_changed.connect(zoom_value => {
                reset_zoom_button.sensitive = zoom_value != 1; 
            });
        }

        public Gdk.Rectangle get_dimensions() {
            var geom = WindowGeometryManager.get_geometry(this);
            return Gdk.Rectangle() {
                x = geom.x,
                y = geom.y,
                width = geom.width,
                height = geom.height
            };
        }

        public void set_dimensions(Gdk.Rectangle dimensions) {
            WindowGeometryManager.set_geometry(this, dimensions);
        }

        private Gtk.Box add_action_bar_child_end(Gtk.Widget child) {
            var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            wrapper.margin_end = 5;
            wrapper.append(child);
            action_bar.pack_end(wrapper);
            return wrapper;
        }
    }
}