using Gtk;

public class ZoomableArea : Gtk.Fixed {
    public float zoom { get; private set; }
    private Gtk.Widget child;

    public ZoomableArea(Gtk.Widget child) {
        this.child = child;
        this.put(child, 0, 0);
        this.set_child_transform(child, new Gsk.Transform());

        update_zoom(2.0f);
    }

    public void update_zoom(float new_zoom) {
        this.zoom = new_zoom;
        if (this.zoom < 0.1f) this.zoom = 0.1f;
        if (this.zoom > 10.0f) this.zoom = 10.0f;

        var transform = new Gsk.Transform().scale(zoom, zoom);
        this.set_child_transform(child, transform);
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
