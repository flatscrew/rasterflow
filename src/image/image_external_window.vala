namespace Image {

    public struct ExternalWindowDimensions {
        public int x;
		public int y;
		public int width;
		public int height;
    }

    public class ExternalImageWindow : Gtk.Window {
        private Data.DataDisplayView data_display_view;
        private ImageViewerPanningArea panning_area;
        private ImageViewer image_viewer;
        private Gtk.ScrolledWindow scroller;
        private Gtk.Box zoom_control;
        private Gtk.Box reset_zoom_control;
        private Gtk.Button reset_zoom_button;

        public ExternalImageWindow(string title) {
            Object(title: title);
            this.set_default_size(600, 400);

            this.data_display_view = new Data.DataDisplayView();
            this.data_display_view.action_bar_visible = true;

            create_image_viewer();
            create_zoom_control();

            this.scroller = new Gtk.ScrolledWindow();
            this.scroller.set_child(panning_area);
            this.scroller.hexpand = true;
            this.scroller.vexpand = true;

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.append(data_display_view);


            set_child(box);
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

            data_display_view.add_child(panning_area);
        }

        private void create_zoom_control() {
            var scale = image_viewer.create_scale_widget();
            this.zoom_control = data_display_view.add_action_bar_child_end(scale);

            this.reset_zoom_button = new Gtk.Button.from_icon_name("zoom-original");
            reset_zoom_button.tooltip_text = "Reset to original size";
            reset_zoom_button.clicked.connect(image_viewer.reset_zoom);
            this.reset_zoom_control = data_display_view.add_action_bar_child_end(reset_zoom_button);
           
            image_viewer.zoom_changed.connect(zoom_value => {
                reset_zoom_button.sensitive = zoom_value != 1; 
            });
        }

        public ExternalWindowDimensions get_dimensions() {
            var geom = WindowGeometryManager.get_geometry(this);
            return ExternalWindowDimensions() {
                x = geom.x,
                y = geom.y,
                width = geom.width,
                height = geom.height
            };
        }
    }
}