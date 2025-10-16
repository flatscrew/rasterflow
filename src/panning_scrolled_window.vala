using Gtk;

public class ZoomableArea : Gtk.Fixed {
    
    public signal void zoom_changed(float new_zoom_value, float old_zoom_value);

    private const float ZOOM_TICK = 0.1f;

    private Gtk.ScrolledWindow scrolled_window;
    private float zoom;
    private float min_zoom;
    private float max_zoom;
    private bool internal_adjustment;
    private bool mouse_initiated_zoom = false;
    private double last_mouse_x;
    private double last_mouse_y;
    
    private Gtk.Widget child;

    public ZoomableArea(
        Gtk.ScrolledWindow scrolled_window,
        Gtk.Widget child, 
        float min_zoom = 0.1f, 
        float max_zoom = 10f
    ) {
        this.scrolled_window = scrolled_window;
        this.zoom = 1f;
        this.min_zoom = min_zoom;
        this.max_zoom = max_zoom;
        this.child = child;
        this.put(child, 0, 0);

        scrolled_window.set_child(this);

        setup_scroll_controller();
        setup_motion_controller();
    }

    private void setup_motion_controller() {
        var motion_controller = new Gtk.EventControllerMotion ();
        scrolled_window.add_controller (motion_controller);
        motion_controller.motion.connect((x, y) => {
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
                zoom_in();
            } else if (dy > 0) {
                zoom_out();
            }
            return true;
        });
    }

    private void update_zoom(float new_zoom) {
        float old_zoom = this.zoom;
        this.zoom = new_zoom;
        
        if (this.zoom < min_zoom) this.zoom = min_zoom;
        if (this.zoom > max_zoom) this.zoom = max_zoom;
        
        var transform = new Gsk.Transform().scale(zoom, zoom);
        this.set_child_transform(child, transform);

        do_zoom_changed(zoom, old_zoom);
    }

    private void do_zoom_changed(double new_zoom, double old_zoom) {
        zoom_changed((float) new_zoom, (float) old_zoom);

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

    public void zoom_in() {
        update_zoom(zoom + ZOOM_TICK);
    }
    
    public void zoom_out() {
        update_zoom(zoom - ZOOM_TICK);
    }

    private void reset_zoom() {
        update_zoom(1f);
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
}

public class ScrollPanner : Object {
    private Gtk.ScrolledWindow scrolled;
    private bool panning = false;
    private double last_x = 0;
    private double last_y = 0;

    public void enable_panning(Gtk.ScrolledWindow scrolled_window) {
        scrolled = scrolled_window;
        scrolled.set_kinetic_scrolling(false);
        
        setup_mouse_click_controller();
        setup_motion_controller();
    }

    private void setup_mouse_click_controller() {
        var button_controller = new Gtk.GestureClick ();
        scrolled.add_controller(button_controller);
        button_controller.pressed.connect((button, x, y) => {
            panning = true;
            last_x = x;
            last_y = y;
        });
        button_controller.released.connect((button, x, y) => {
            panning = false;
        });
        button_controller.button = Gdk.BUTTON_MIDDLE;
    }

    private void setup_motion_controller() {
        var motion_controller = new Gtk.EventControllerMotion ();
        scrolled.add_controller (motion_controller);
        motion_controller.motion.connect((x, y) => {
            if (panning) {
                double dx = x - last_x;
                double dy = y - last_y;
        
                scrolled.hadjustment.set_value(scrolled.hadjustment.get_value() - dx);
                scrolled.vadjustment.set_value(scrolled.vadjustment.get_value() - dy);
                
                scrolled.queue_draw ();
            }
            last_x = x;
            last_y = y;
        });
    }
}
