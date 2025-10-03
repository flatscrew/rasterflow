namespace Pdf {

    protected struct DocumentDimensions {
        int width;
        int height;
    }

    public class PDFViewer : Gtk.DrawingArea {

        private const double ZOOM_TICK = 0.1;
        private const double DEFAULT_ZOOM_MAX = 3.0;
        private const double ZOOM_MIN = 1.0;

        public signal void zoom_changed(double new_zoom_value, double old_zoom_value);
        public signal void page_changed(int new_page_index);

        public Poppler.Document document {
            get;
            private set;
        }

        private double zoom_level = 1.0;
        public double zoom {
            get { return zoom_level; }
            set {
                if (value < ZOOM_MIN || value > zoom_max) {
                    return;  
                }
                zoom_changed(value, zoom_level);
                zoom_level = value;
                this.queue_resize();
                this.queue_draw();
            }
        }
    
        private double zoom_max = 3.0;

        private double fit_scale_value = 1.0;
        public double fit_scale {
            get { return fit_scale_value; }
            private set { 
                if (value > 1.0) {
                    return;
                }
                fit_scale_value = value;
                this.queue_resize();
                this.queue_draw();
            }
        }

        private int current_page_index = 0;
        public int current_page {
            get { return current_page_index; }
            set {
                if (value < 0) {
                    return;
                }
                if (value + 1 > document.get_n_pages() ) {
                    return;
                }
                this.current_page_index = value;
                this.queue_draw();
                this.page_changed(value);
            }
        }
        private bool internal_adjustment;

        construct {
            hexpand = vexpand = true;
        }

        public PDFViewer(Poppler.Document document) {
            this.with_max_zoom(document, DEFAULT_ZOOM_MAX);
        }

        public PDFViewer.with_max_zoom(Poppler.Document document, double zoom_max) {
            this.document = document;
            this.zoom_max = zoom_max;
            this.realize.connect(() => {
                this.queue_draw();
            });
            this.set_draw_func(this.draw_pdf);
        }


        private void draw_pdf(Gtk.DrawingArea drawing_area, Cairo.Context cr, int width, int height) {
            Poppler.Page page = document.get_page(current_page_index);
            double page_width, page_height;
            page.get_size(out page_width, out page_height);
            
            double scaled_page_width = page_width * zoom_level * fit_scale_value;
            double scaled_page_height = page_height * zoom_level * fit_scale_value;
            
            double x_offset = 0;
            double y_offset = 0;
        
            if (scaled_page_width < width) {
                x_offset = (width - scaled_page_width) / 2;
            }
        
            if (scaled_page_height < height) {
                y_offset = (height - scaled_page_height) / 2;
            }
                
            cr.scale(zoom_level * fit_scale_value, zoom_level * fit_scale_value);
            cr.translate(x_offset / (zoom_level * fit_scale_value), y_offset / (zoom_level * fit_scale_value));  
            
            page.render(cr);
        }
        

        public void zoom_in() {
            zoom = zoom_level + ZOOM_TICK; 
        }
        
        public void zoom_out() {
            zoom = zoom_level - ZOOM_TICK;
        }

        public void reset_zoom() {
            zoom = 1.0;
        }
        
        public void replace_document(Poppler.Document new_document) {
            //  this.texture = Gdk.Texture.for_pixbuf (new_image);
            this.queue_resize();
        }

        internal void update_fit_scale(int width, int height) {
            Poppler.Page page = document.get_page(current_page_index);
            double page_width, page_height;
            page.get_size(out page_width, out page_height);

            double width_scale = (double) width / page_width;
            double height_scale = (double) height / page_height;
            if (width_scale < height_scale) {
                fit_scale = width_scale;
            } else {
                fit_scale = height_scale;
            }
        }

        public DocumentDimensions get_dimensions () {
            Poppler.Page page = document.get_page(current_page_index);
            double page_width, page_height;
            page.get_size(out page_width, out page_height);

            var width = (int)(page_width * zoom_level * fit_scale);
            var height = (int)(page_height * zoom_level * fit_scale);
            return {
                width: width,
                height: height
            };
        }

        protected override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
            minimum_baseline = natural_baseline = -1;
            if (document == null) {
                minimum = natural = 0;
                return;
            }
            var dimensions = get_dimensions();
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                minimum = natural = dimensions.width;
            } else {
                minimum = natural = dimensions.height;
            }
        }

        public Gtk.Scale create_scale_widget() {
            var adjustment = new Gtk.Adjustment(1, ZOOM_MIN, zoom_max, 0.1, 1, 0);
            var scale_widget = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, adjustment);
            scale_widget.set_value(1);
            scale_widget.set_size_request(150, -1);
            scale_widget.value_changed.connect(() => {
                if (internal_adjustment) {
                    internal_adjustment = false;
                    return;
                }
                zoom = adjustment.get_value();
            });
            zoom_changed.connect(zoom_value => {
                internal_adjustment = true;
                adjustment.set_value(zoom_value);
            });
            return scale_widget;
        }

        public void next_page() {
            this.current_page++;
        }

        public void previous_page() {
            this.current_page--;
        }

        public Gtk.Button create_next_page_button() {
            var button = new Gtk.Button.with_label("");
            button.sensitive = current_page_index != document.get_n_pages() - 1;
            button.set_icon_name("go-next");
            button.clicked.connect(next_page);
            this.page_changed.connect(new_page_index => {
                if (new_page_index + 1 >= document.get_n_pages()) {
                    button.sensitive = false;
                    return;
                }
                button.sensitive = true;
            });
            return button;
        }

        public Gtk.Button create_previous_page_button() {
            var button = new Gtk.Button.with_label("");
            button.set_icon_name("go-previous");
            button.sensitive = current_page_index > 0;
            button.clicked.connect(previous_page);
            this.page_changed.connect(new_page_index => {
                if (new_page_index + - 1 < 0) {
                    button.sensitive = false;
                    return;
                }
                button.sensitive = true;
            });
            return button;
        }

        public Gtk.Label create_page_status_label() {
            var label = new Gtk.Label("");
            label.set_markup("Page <b>%d</b> of <b>%d</b>".printf(current_page_index + 1, document.get_n_pages()));
            this.page_changed.connect(new_page_index => {
                label.set_markup("Page <b>%d</b> of <b>%d</b>".printf(current_page_index + 1, document.get_n_pages()));
            });
            return label;
        }
    }  

    public class PDFViewerPanningArea : Gtk.Widget {

        construct {
            set_layout_manager(new Gtk.BinLayout());
            vexpand = hexpand = true;
        }

        private PDFViewer viewer;
        private Gtk.ScrolledWindow scrolled_window;
        private bool mouse_pressed = false;
        private bool mouse_initiated_zoom = false;
        private double last_mouse_x;
        private double last_mouse_y;

        private int last_width = 0;
        private int last_height = 0;

        ~PDFViewerPanningArea() {
            scrolled_window.set_child(null);
            scrolled_window.unparent();
            scrolled_window = null;
        }

        public PDFViewerPanningArea(PDFViewer viewer) {
            this.viewer = viewer;
            this.scrolled_window = new Gtk.ScrolledWindow ();
            scrolled_window.set_kinetic_scrolling(false);
            scrolled_window.set_parent (this);
            scrolled_window.set_child (viewer);
            scrolled_window.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
            scrolled_window.set_min_content_height(150);
            
            setup_mouse_click_controller();
            setup_motion_controller();
            setup_scroll_controller();

            viewer.zoom_changed.connect(zoom_changed);
        }

        private void setup_mouse_click_controller() {
            var button_controller = new Gtk.GestureClick ();
            scrolled_window.add_controller(button_controller);
            button_controller.pressed.connect((button, x, y) => {
                mouse_pressed = true;
                last_mouse_x = x;
                last_mouse_y = y;
            });
            button_controller.released.connect((button, x, y) => {
                mouse_pressed = false;
            });
            button_controller.button = Gdk.BUTTON_SECONDARY;
        }

        private void setup_motion_controller() {
            var motion_controller = new Gtk.EventControllerMotion ();
            scrolled_window.add_controller (motion_controller);
            motion_controller.motion.connect((x, y) => {
                if (mouse_pressed) {
                    double dx = x - last_mouse_x;
                    double dy = y - last_mouse_y;
            
                    scrolled_window.hadjustment.set_value(scrolled_window.hadjustment.get_value() - dx);
                    scrolled_window.vadjustment.set_value(scrolled_window.vadjustment.get_value() - dy);
                    
                    scrolled_window.queue_draw ();
                }
                last_mouse_x = x;
                last_mouse_y = y;
            });
        }

        private void setup_scroll_controller() {
            var scroll_controller = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
            scrolled_window.add_controller(scroll_controller);
            
            scroll_controller.scroll.connect((dx, dy) => {
                mouse_initiated_zoom = true;
                if (dy < 0) {
                    viewer.zoom_in();
                } else if (dy > 0) {
                    viewer.zoom_out();
                }
                return true;
            });
        }
        

        protected override void snapshot(Gtk.Snapshot snapshot) {
            base.snapshot(snapshot);
            int width = get_allocated_width();
            int height = get_allocated_height();

            if (width != last_width || height != last_height) {
                last_width = width;
                last_height = height;
                dimensions_changed(width, height);
            }
        }

        private void dimensions_changed(int width, int height) {
            GLib.Timeout.add(0, () => {
                viewer.update_fit_scale(width, height);
                return false;
            });
        }

        private void zoom_changed(double new_zoom, double old_zoom) {
            if (mouse_initiated_zoom) {
                // Current position of the viewport
                double viewport_x = scrolled_window.hadjustment.get_value();
                double viewport_y = scrolled_window.vadjustment.get_value();

                // Calculate the mouse's position on the image (before zooming)
                double image_x_before = viewport_x + last_mouse_x;
                double image_y_before = viewport_y + last_mouse_y;

                // Find out where that point will be after zooming
                double image_x_after = (image_x_before / old_zoom) * new_zoom;
                double image_y_after = (image_y_before / old_zoom) * new_zoom;

                // Calculate the change in position
                double delta_x = image_x_after - image_x_before;
                double delta_y = image_y_after - image_y_before;

                // Adjust the viewport
                scrolled_window.hadjustment.set_value(viewport_x + delta_x);
                scrolled_window.vadjustment.set_value(viewport_y + delta_y);
                mouse_initiated_zoom = false;
                return;
            }

            var allocated_width = scrolled_window.get_allocated_width();
            var allocated_height = scrolled_window.get_allocated_height();

            double viewport_center_x = scrolled_window.hadjustment.get_value() + allocated_width / 2.0;
            double viewport_center_y = scrolled_window.vadjustment.get_value() + allocated_height / 2.0;
        
            // Calculate the center coordinates in relation to the image.
            double image_center_x = viewport_center_x / old_zoom;
            double image_center_y = viewport_center_y / old_zoom;
        
            // Calculate new offsets to keep the center.
            double new_offset_x = image_center_x * new_zoom - allocated_width / 2.0;
            double new_offset_y = image_center_y * new_zoom - allocated_height / 2.0;
        
            // Apply the new offsets.
            scrolled_window.hadjustment.set_value(new_offset_x);
            scrolled_window.vadjustment.set_value(new_offset_y);
        }

        public void refresh() {
            viewer.update_fit_scale(get_allocated_width(), get_allocated_height());
        }
    }
}