namespace Image {

    protected struct ImageDimensions {
        int width;
        int height;
    }

    public class ImageViewer : Gtk.DrawingArea {

        private const double ZOOM_TICK = 0.01;
        private const double DEFAULT_ZOOM_MAX = 3.0;
        private const double ZOOM_MIN = 1.0;

        public signal void zoom_changed(double new_zoom_value, double old_zoom_value);

        private Gdk.Texture texture;
        private Gdk.Pixbuf pixbuf;

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
    
        private bool internal_adjustment;
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

        construct {
            hexpand = vexpand = true;
        }

        public ImageViewer(Gdk.Pixbuf pixbuf) {
            this.with_max_zoom(DEFAULT_ZOOM_MAX, pixbuf);
        }

        public ImageViewer.with_max_zoom(double zoom_max, Gdk.Pixbuf? pixbuf = null) {
            this.zoom_max = zoom_max;
            if (pixbuf != null) {
                this.pixbuf = pixbuf;
                this.texture = Gdk.Texture.for_pixbuf (this.pixbuf);
            }

            this.realize.connect(() => {
                this.queue_draw();
            });
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

        protected override void snapshot(Gtk.Snapshot snapshot) {
            if (texture == null) return;
            
            int width = get_allocated_width();
            int height = get_allocated_height();
            draw_checker_board(snapshot, width, height);
            
            var dimensions = get_dimensions();
            int x_offset = (width - dimensions.width) / 2;
            int y_offset = (height - dimensions.height) / 2;

            var rect = Graphene.Rect();
            rect.init(x_offset, y_offset, dimensions.width, dimensions.height);
            snapshot.append_texture(texture, rect);
        }
        
        private void draw_checker_board (Gtk.Snapshot snapshot, int width, int height) {
            int square_size = 20;
            Gdk.RGBA color1 = Gdk.RGBA() { red = 0.8f, green = 0.8f, blue = 0.8f, alpha = 0.6f }; // light gray
            Gdk.RGBA color2 = Gdk.RGBA() { red = 0.6f, green = 0.6f, blue = 0.6f, alpha = 0.6f }; // darker gray

            bool useFirstColor;
            
            for (int x = 0; x < width; x += square_size) {
                useFirstColor = (x / square_size) % 2 == 0;
                
                for (int y = 0; y < height; y += square_size) {
                    var rect = Graphene.Rect();
                    rect.init(x, y, square_size, square_size);
                    snapshot.append_color(useFirstColor ? color1 : color2, rect);
                    useFirstColor = !useFirstColor;
                }
            }
        }

        protected override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
            minimum_baseline = natural_baseline = -1;
            var dimensions = get_dimensions();
            if (orientation == Gtk.Orientation.HORIZONTAL) {
                minimum = natural = dimensions.width;
            } else {
                minimum = natural = dimensions.height;
            }
        }

        internal void update_fit_scale (int width, int height) {
            if (texture == null || texture.get_width () == 0 || texture.get_height () == 0)
                return;
            if (width == 0 || height == 0)
                return;

            double width_scale  = (double) width  / texture.get_width ();
            double height_scale = (double) height / texture.get_height ();

            double new_scale = min (width_scale, height_scale);
            fit_scale = max (new_scale, 0.01); 
        }

        public ImageDimensions get_dimensions () {
            if (texture == null) {
                return {
                    width: 0,
                    height: 0
                };
            }
            
            var tex_w = texture.get_width ();
            var tex_h = texture.get_height ();

            var w_d = tex_w * zoom_level * fit_scale;
            var h_d = tex_h * zoom_level * fit_scale;

            return { 
                width: (int) max (1.0, w_d), 
                height: (int) max (1.0, h_d) 
            };
        }

        private double max(double first, double second) {
            if (first > second) return first;
            return second;
        }

        private double min(double first, double second) {
            if (first < second) return first;
            return second;
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

        public Gtk.Button create_reset_scale_button() {
            var reset_zoom_button = new Gtk.Button.from_icon_name("zoom-original-symbolic");
            reset_zoom_button.tooltip_text = "Reset to original size";
            reset_zoom_button.clicked.connect(this.reset_zoom);
            return reset_zoom_button;
        }

        private void save_button_clicked() {
            var dialog = new Gtk.FileChooserDialog("Save image", base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window, Gtk.FileChooserAction.SAVE);
            dialog.add_button ("Cancel", Gtk.ResponseType.CANCEL);
            dialog.add_button ("Save", Gtk.ResponseType.OK);

            foreach (var format in Gdk.Pixbuf.get_formats ()) {
                var filter = new Gtk.FileFilter();
                filter.set_filter_name(format.get_description());
                foreach (var mimetype in format.get_mime_types()) {
                    filter.add_mime_type(mimetype);
                }
                
                foreach (var ext in format.get_extensions()) {
                    filter.add_suffix(ext);
                }

                dialog.add_filter(filter);
            }

            dialog.response.connect((response_id) => {
                if (response_id == Gtk.ResponseType.OK) {
                    var selected_file = dialog.get_file();
                    var selected_filter = dialog.get_filter();

                    string? format = null;

                    if (selected_filter != null) {
                        // Iterate through the formats again to match the filter's name with format description
                        foreach (var fmt in Gdk.Pixbuf.get_formats()) {
                            if (selected_filter.name == fmt.get_description()) {
                                format = fmt.get_name(); // This is the format to save in
                                break;
                            }
                        }
                    }

                    if (selected_file != null && format != null) {
                        try {
                            // Save using the selected format
                            pixbuf.savev(selected_file.get_path(), format, null, null);
                        } catch (Error e) {
                            warning("Failed to save image: %s", e.message);
                        }
                    }
                }
                dialog.destroy(); 
            });
        
            dialog.show();
        }

        public Gtk.Button create_save_image_button() {
            var button = new Gtk.Button();
            button.clicked.connect(save_button_clicked);
            return button;
        }

        public void replace_image(Gdk.Pixbuf new_image) {
            this.pixbuf = new_image;
            this.texture = Gdk.Texture.for_pixbuf (this.pixbuf);
            this.queue_resize();
        }
    }  

    public class ImageViewerPanningArea : Gtk.Widget {

        construct {
            set_layout_manager(new Gtk.BinLayout());
            vexpand = hexpand = true;
        }

        private ImageViewer viewer;
        private Gtk.ScrolledWindow scrolled_window;
        private bool mouse_pressed = false;
        private bool mouse_initiated_zoom = false;
        private double last_mouse_x;
        private double last_mouse_y;

        private int last_width = 0;
        private int last_height = 0;

        ~ImageViewerPanningArea() {
            scrolled_window.set_child(null);
            scrolled_window.unparent();
            scrolled_window = null;
        }

        public ImageViewerPanningArea(ImageViewer viewer) {
            this.viewer = viewer;
            this.scrolled_window = new Gtk.ScrolledWindow ();
            scrolled_window.set_kinetic_scrolling(false);
            scrolled_window.set_parent (this);
            scrolled_window.set_child (viewer);
            scrolled_window.set_policy (Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.EXTERNAL);
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
            button_controller.button = Gdk.BUTTON_MIDDLE;
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
            GLib.Idle.add(() => {
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