using Gtk;

public class ZoomableArea : Gtk.Fixed {

    public signal void zoom_changed(float new_zoom_value, float old_zoom_value);

    private float zoom;
    private float min_zoom;
    private float max_zoom;
    private bool internal_adjustment;

    private Gtk.Widget child;

    public ZoomableArea(Gtk.Widget child, float min_zoom = 0.1f, float max_zoom = 10f) {
        this.min_zoom = min_zoom;
        this.max_zoom = max_zoom;
        this.child = child;
        this.put(child, 0, 0);
        this.set_child_transform(child, new Gsk.Transform());
    }

    private void update_zoom(float new_zoom) {
        float old_zoom = zoom;
        this.zoom = new_zoom;
        
        if (this.zoom < min_zoom) this.zoom = min_zoom;
        if (this.zoom > max_zoom) this.zoom = max_zoom;
        
        var transform = new Gsk.Transform().scale(zoom, zoom);
        this.set_child_transform(child, transform);

        zoom_changed(zoom, old_zoom);
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
