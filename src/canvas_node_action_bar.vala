public class CanvasActionBar : Gtk.Widget {
    private Adw.Clamp clamp;
    private Gtk.Box container;
    private Gtk.Box start_box;
    private Gtk.Box end_box;

    construct {
        set_layout_manager(new Gtk.BinLayout());

        clamp = new Adw.Clamp();
        clamp.add_css_class("toolbar");

        container = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        container.hexpand = true;
        container.vexpand = false;

        start_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        end_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        end_box.halign = Gtk.Align.END;
        end_box.hexpand = true;

        container.append(start_box);
        container.append(end_box);
        clamp.set_child(container);

        clamp.set_parent(this);
    }

    ~CanvasActionBar() {
        clamp.unparent();
    }

    public Gtk.Box add_action_start(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.margin_start = 5;
        wrapper.append(child);
        start_box.append(wrapper);
        return wrapper;
    }

    public Gtk.Box add_action_end(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.margin_end = 5;
        wrapper.append(child);
        end_box.append(wrapper);
        return wrapper;
    }

    public void remove_action(Gtk.Widget child) {
        start_box.remove(child);
        end_box.remove(child);
    }
}
