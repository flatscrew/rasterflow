public class ZoomableArea : Gtk.Widget {
    public signal void zoom_changed (float new_zoom, float old_zoom);

    private const float ZOOM_TICK = 0.1f;
    
    private Gtk.Widget? child;
    private Gtk.ScrolledWindow scrolled;
    private float zoom;
    private float min_zoom;
    private float max_zoom;
    private bool internal_adjustment;
    private bool mouse_initiated_zoom = false;
    private double last_mouse_x;
    private double last_mouse_y;

    public ZoomableArea (Gtk.ScrolledWindow scrolled_window, Gtk.Widget content,
                         float min_zoom = 0.25f, float max_zoom = 4.0f) {
        this.scrolled = scrolled_window;
        this.min_zoom = min_zoom;
        this.max_zoom = max_zoom;
        this.zoom = 1f;
        
        this.set_layout_manager(new ZoomLayout (this));
        scrolled_window.set_child(this);
        set_content(content);

        setup_scroll_controller();
        setup_motion_controller();
    }

    private void setup_scroll_controller() {
        var scroll = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.VERTICAL);
        scrolled.add_controller (scroll);

        scroll.scroll.connect ((dx, dy) => {
            if (dy < 0)
                zoom_in ();
            else if (dy > 0)
                zoom_out ();
            return true;
        });
    }

    private void setup_motion_controller() {
        var motion_controller = new Gtk.EventControllerMotion ();
        scrolled.add_controller (motion_controller);
        motion_controller.motion.connect((x, y) => {
            last_mouse_x = x;
            last_mouse_y = y;
        });
    }

    public void set_content (Gtk.Widget c) {
        if (this.child != null)
            this.child.unparent ();

        this.child = c;
        this.child.set_parent (this);
        this.queue_resize ();
    }

    protected override void dispose () {
        if (this.child != null) {
            this.child.unparent ();
            this.child = null;
        }
        base.dispose ();
    }

    public void zoom_in () {
        update_zoom (zoom + ZOOM_TICK);
    }

    public void zoom_out () {
        update_zoom (zoom - ZOOM_TICK);
    }

    public void reset_zoom () {
        update_zoom (1.0f);
    }

    private void update_zoom (float z) {
        float old = zoom;
        zoom = z.clamp (min_zoom, max_zoom);
        queue_resize ();
        zoom_changed (zoom, old);

        do_zoom_changed(zoom, old);

        child.queue_resize();
        child.queue_allocate();
    }

    private void do_zoom_changed(double new_zoom, double old_zoom) {
        zoom_changed((float) new_zoom, (float) old_zoom);

        if (mouse_initiated_zoom) {
            // Current position of the viewport
            double viewport_x = scrolled.hadjustment.get_value();
            double viewport_y = scrolled.vadjustment.get_value();

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
            scrolled.hadjustment.set_value(viewport_x + delta_x);
            scrolled.vadjustment.set_value(viewport_y + delta_y);
            mouse_initiated_zoom = false;
            return;
        }

        var allocated_width = scrolled.get_allocated_width();
        var allocated_height = scrolled.get_allocated_height();

        double viewport_center_x = scrolled.hadjustment.get_value() + allocated_width / 2.0;
        double viewport_center_y = scrolled.vadjustment.get_value() + allocated_height / 2.0;
    
        // Calculate the center coordinates in relation to the image.
        double image_center_x = viewport_center_x / old_zoom;
        double image_center_y = viewport_center_y / old_zoom;
    
        // Calculate new offsets to keep the center.
        double new_offset_x = image_center_x * new_zoom - allocated_width / 2.0;
        double new_offset_y = image_center_y * new_zoom - allocated_height / 2.0;
    
        // Apply the new offsets.
        scrolled.hadjustment.set_value(new_offset_x);
        scrolled.vadjustment.set_value(new_offset_y);
    }

    public Gtk.Scale create_scale_widget() {
        var adjustment = new Gtk.Adjustment(1, min_zoom, max_zoom, 0.1, 1, 0);
        var scale_widget = new Gtk.Scale(Gtk.Orientation.HORIZONTAL, adjustment);
        scale_widget.set_value(1);
        scale_widget.set_size_request(150, -1);
        scale_widget.value_changed.connect(() => {
            if (internal_adjustment) {
                internal_adjustment = false;
                return;
            }
            this.update_zoom((float) adjustment.get_value());
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

    private class ZoomLayout : Gtk.LayoutManager {
        private weak ZoomableArea owner;

        public ZoomLayout (ZoomableArea owner) {
            this.owner = owner;
        }

        protected override void measure (Gtk.Widget widget,
                                        Gtk.Orientation o,
                                        int for_size,
                                        out int min, out int nat,
                                        out int min_base, out int nat_base) {
            if (owner.child == null) {
                min = nat = 0;
                min_base = nat_base = -1;
                return;
            }

            int cmin, cnat, d1, d2;
            owner.child.measure (o, -1, out cmin, out cnat, out d1, out d2);

            // layout zgłasza: naturalny rozmiar po zoomie
            nat = (int)(cnat * owner.zoom);
            min = nat;
            min_base = nat_base = -1;
        }

        protected override void allocate (Gtk.Widget widget,
                                  int width, int height,
                                  int baseline) {
            if (owner.child == null)
                return;

            int cminw, cnatw, cminh, cnath, d1, d2;
            owner.child.measure (Gtk.Orientation.HORIZONTAL, -1, out cminw, out cnatw, out d1, out d2);
            owner.child.measure (Gtk.Orientation.VERTICAL, -1, out cminh, out cnath, out d1, out d2);

            float zoom = owner.zoom;

            int scaled_w = (int)(cnatw * zoom);
            int scaled_h = (int)(cnath * zoom);

            if (scaled_w < width)
                scaled_w = width;
            if (scaled_h < height)
                scaled_h = height;

            int child_w = (int)(scaled_w / zoom);
            int child_h = (int)(scaled_h / zoom);

            var transform = new Gsk.Transform ();
            transform = transform.scale (zoom, zoom);

            owner.child.allocate (child_w, child_h, baseline, transform);
        }
    }
}