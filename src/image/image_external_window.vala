namespace Image {
    public class ExternalImageWindow : Gtk.Window {
        private ImageViewerPanningArea panning_area;
        private ImageViewer image_viewer;
        private Gtk.ScrolledWindow scroller;

        public ExternalImageWindow(string title) {
            Object(title: title);
            set_default_size(600, 400);

            this.image_viewer = new ImageViewer.with_max_zoom(10);
            this.panning_area = new ImageViewerPanningArea(image_viewer);
            this.panning_area.hexpand = true;
            this.panning_area.vexpand = true;

            this.scroller = new Gtk.ScrolledWindow();
            this.scroller.set_child(panning_area);
            this.scroller.hexpand = true;
            this.scroller.vexpand = true;

            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.append(scroller);

            set_child(box);
        }

        public void set_title_text(string title) {
            this.title = title;
        }

        public void display_pixbuf(Gdk.Pixbuf pixbuf) {
            image_viewer.replace_image(pixbuf);
            panning_area.refresh();
        }
    }
}