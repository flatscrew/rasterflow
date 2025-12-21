public class ZoomPanArea : Gtk.Widget {
    public signal void zoom_changed (float new_zoom, float old_zoom);

    private const float ZOOM_TICK = 0.01f;
    private const double PADDING_STEP = 200.0;
    
    private Gtk.Widget? child;
    private Gtk.ScrolledWindow scrolled;
    private Gtk.EventControllerScroll scroll_controller;
    private Gtk.EventControllerMotion motion_controller;
    private Gtk.GestureClick click_controller;

    private float zoom;
    private float min_zoom;
    private float max_zoom;
    private bool internal_adjustment;
    private bool mouse_initiated_zoom = false;

    private bool panning = false;
    private double last_mouse_x;
    private double last_mouse_y;
    
    private double dynamic_padding_x = 0;
    private double dynamic_padding_y = 0;

    public ZoomPanArea (Gtk.ScrolledWindow scrolled_window, Gtk.Widget content,
                        float min_zoom = 0.25f, float max_zoom = 4.0f) {
        this.scrolled = scrolled_window;
        this.min_zoom = min_zoom;
        this.max_zoom = max_zoom;
        this.zoom = 1f;
        
        this.set_layout_manager(new ZoomLayout (this));
        scrolled_window.set_child(this);
        scrolled_window.set_kinetic_scrolling(false);
        set_content(content);

        setup_scroll_controller();
        setup_motion_controller();
        setup_click_controller();
    }

    private void setup_scroll_controller() {
        this.scroll_controller = new Gtk.EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
        scroll_controller.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
        scrolled.add_controller(scroll_controller);
        scroll_controller.scroll.connect(this.on_scroll);
    }
    
    private bool on_scroll(double dx, double dy) {
        var mods = scroll_controller.get_current_event_state();
        if ((mods & Gdk.ModifierType.CONTROL_MASK) == 0)
            return false;
        
        this.mouse_initiated_zoom = true;
        if (dy < 0)
            zoom_in ();
        else if (dy > 0)
            zoom_out ();
        return true;
    }

    private void setup_motion_controller() {
        this.motion_controller = new Gtk.EventControllerMotion ();
        scrolled.add_controller (motion_controller);
        
        motion_controller.motion.connect(this.perform_motion);
    }
    
    private void perform_motion(double x, double y) {
        if (!panning) {
            return;
        }
        
        double dx = x - last_mouse_x;
        double dy = y - last_mouse_y;

        var hadj = scrolled.hadjustment;
        var vadj = scrolled.vadjustment;

        double new_x = hadj.get_value() - dx;
        double new_y = vadj.get_value() - dy;

        bool changed = false;

        double right_limit = hadj.get_upper() - hadj.get_page_size();
        double bottom_limit = vadj.get_upper() - vadj.get_page_size();

        if (new_x > right_limit) {
            dynamic_padding_x += PADDING_STEP;
            changed = true;
        }

        if (new_y > bottom_limit) {
            dynamic_padding_y += PADDING_STEP;
            changed = true;
        }
        
        if (new_x <= 0 && dynamic_padding_x > 0) {
            dynamic_padding_x = 0;
            changed = true;
            new_x = 0;
        }

        if (new_y <= 0 && dynamic_padding_y > 0) {
            dynamic_padding_y = 0;
            changed = true;
            new_y = 0; 
        }
        
        if (changed) {
            queue_resize();

            if (new_x < 0) new_x = 0;
            if (new_y < 0) new_y = 0;
        }

        hadj.set_value(new_x);
        vadj.set_value(new_y);
    
        last_mouse_x = x;
        last_mouse_y = y;
    }
    
    private void setup_click_controller() {
        click_controller = new Gtk.GestureClick ();
        click_controller.button = Gdk.BUTTON_MIDDLE;
        scrolled.add_controller(click_controller);

        click_controller.pressed.connect((button, x, y) => {
            var mods = click_controller.get_current_event_state();
            if ((mods & Gdk.ModifierType.CONTROL_MASK) == 0)
                return;
            
            panning = true;
            last_mouse_x = x;
            last_mouse_y = y;
        });

        click_controller.released.connect((button, x, y) => {
            panning = false;
        });
    }

    public void set_content (Gtk.Widget c) {
        if (this.child != null)
            this.child.unparent ();

        this.child = c;
        this.child.set_parent (this);
        this.queue_resize ();
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

        do_zoom_changed(zoom, old);

        if (child != null) {
            child.queue_resize();
            child.queue_allocate();
        }
    }

    private void do_zoom_changed(double new_zoom, double old_zoom) {
        zoom_changed((float) new_zoom, (float) old_zoom);

        if (mouse_initiated_zoom) {
            double viewport_x = scrolled.hadjustment.get_value();
            double viewport_y = scrolled.vadjustment.get_value();

            double image_x_before = viewport_x + last_mouse_x;
            double image_y_before = viewport_y + last_mouse_y;

            double image_x_after = (image_x_before / old_zoom) * new_zoom;
            double image_y_after = (image_y_before / old_zoom) * new_zoom;

            double delta_x = image_x_after - image_x_before;
            double delta_y = image_y_after - image_y_before;

            scrolled.hadjustment.set_value(viewport_x + delta_x);
            scrolled.vadjustment.set_value(viewport_y + delta_y);
            mouse_initiated_zoom = false;
            return;
        }

        var allocated_width = scrolled.get_width();
        var allocated_height = scrolled.get_height();

        double viewport_center_x = scrolled.hadjustment.get_value() + allocated_width / 2.0;
        double viewport_center_y = scrolled.vadjustment.get_value() + allocated_height / 2.0;
    
        double image_center_x = viewport_center_x / old_zoom;
        double image_center_y = viewport_center_y / old_zoom;
    
        double new_offset_x = image_center_x * new_zoom - allocated_width / 2.0;
        double new_offset_y = image_center_y * new_zoom - allocated_height / 2.0;
    
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

        zoom_changed.connect((new_zoom, old_zoom) => {
            internal_adjustment = true;
            adjustment.set_value(new_zoom);
        });

        return scale_widget;
    }

    public Gtk.Button create_reset_scale_button() {
        var reset_zoom_button = new Gtk.Button.from_icon_name("zoom-original");
        reset_zoom_button.tooltip_text = "Reset to original size";
        reset_zoom_button.clicked.connect(this.reset_zoom);
        return reset_zoom_button;
    }
    
    public bool to_child_coords(double x, double y,out double cx, out double cy) {
        if (child == null) {
            cx = cy = 0;
            return false;
        }

        Graphene.Point in_p = Graphene.Point() {
            x = (float)x, 
            y = (float)y
        };
        
        Graphene.Point out_p;
        if (!compute_point(child, in_p, out out_p)) {
            cx = cy = 0;
            return false;
        }

        cx = out_p.x;
        cy = out_p.y;
        return true;
    }
    
    public bool child_to_viewport(double x, double y, out double vx, out double vy) {
        vx = vy = 0;
        if (child == null)
            return false;
    
        Graphene.Point input = Graphene.Point() {
            x = (float)x,
            y = (float)y
        };
    
        Graphene.Point out_p;
    
        if (!child.compute_point(this, input, out out_p))
            return false;
    
        var hadj = scrolled.hadjustment;
        var vadj = scrolled.vadjustment;
    
        vx = out_p.x - hadj.get_value();
        vy = out_p.y - vadj.get_value();
    
        return true;
    }

    private class ZoomLayout : Gtk.LayoutManager {
        private weak ZoomPanArea owner;

        public ZoomLayout (ZoomPanArea owner) {
            this.owner = owner;
        }

        protected override void measure(Gtk.Widget widget,
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
            owner.child.measure(o, -1, out cmin, out cnat, out d1, out d2);

            float z = owner.zoom;

            if (o == Gtk.Orientation.HORIZONTAL) {
                nat = (int)(cnat * z + owner.dynamic_padding_x);
            } else {
                nat = (int)(cnat * z + owner.dynamic_padding_y);
            }

            min = nat;
            min_base = nat_base = -1;
        }
        
        protected override void allocate(Gtk.Widget widget, int width, int height, int baseline) {
            if (owner.child == null)
                return;
        
            int cminw, cnatw, cminh, cnath, d1, d2;
            owner.child.measure(Gtk.Orientation.HORIZONTAL, -1, out cminw, out cnatw, out d1, out d2);
            owner.child.measure(Gtk.Orientation.VERTICAL, -1, out cminh, out cnath, out d1, out d2);
        
            float z = owner.zoom;
        
            int scaled_w = (int)(cnatw * z + owner.dynamic_padding_x);
            int scaled_h = (int)(cnath * z + owner.dynamic_padding_y);
        
            if (scaled_w < width)
                scaled_w = width;
            if (scaled_h < height)
                scaled_h = height;
        
            int child_w = (int)(scaled_w / z);
            int child_h = (int)(scaled_h / z);
        
            var t = new Gsk.Transform();
            t = t.scale(z, z);
        
            owner.child.allocate(child_w, child_h, baseline, t);
        }
    }
}
