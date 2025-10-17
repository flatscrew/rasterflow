public class ZoomableArea : Gtk.Widget {
    public signal void zoom_changed (float new_zoom, float old_zoom);

    private Gtk.Widget? child;
    private Gtk.ScrolledWindow scrolled;
    private float zoom = 1.0f;
    private float min_zoom;
    private float max_zoom;

    private const float ZOOM_TICK = 0.1f;

    public ZoomableArea (Gtk.ScrolledWindow scrolled_window, Gtk.Widget content,
                         float min_zoom = 0.25f, float max_zoom = 4.0f) {
        this.scrolled = scrolled_window;
        this.min_zoom = min_zoom;
        this.max_zoom = max_zoom;

        this.set_layout_manager (new ZoomLayout (this));
        scrolled_window.set_child (this);
        set_content (content);

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