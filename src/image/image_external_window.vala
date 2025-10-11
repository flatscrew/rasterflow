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
            int x, y, width, height = 0;

            var surface = get_surface();
            if (surface is Gdk.X11.Surface) {
                var x11_surface = surface as Gdk.X11.Surface;
                var display = get_display() as Gdk.X11.Display;
                var xid = x11_surface.get_xid();
                unowned var xdisplay = display.get_xdisplay();

                X.Window root;
                uint w, h, border, depth;
                xdisplay.get_geometry(xid, out root, out x, out y, out w, out h, out border, out depth);

                int root_x, root_y;
                X.Window child_return;
                xdisplay.translate_coordinates(xid, root, 0, 0, out root_x, out root_y, out child_return);

                width = (int) w;
                height = (int) h;
                x = root_x;
                y = root_y;
            } else {
                x = y = width = height = 0;
            }

            return ExternalWindowDimensions(){
                x = x,
                y = y,
                width = width,
                height = height
            };
        }
    }
}