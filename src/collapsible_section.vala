public class CollapsibleSectionView : Gtk.Widget {
    private Gtk.Box vertical_box;
    private Gtk.Box content_box;
    private Gtk.Image arrow_icon;
    private bool _expanded;

    public bool expanded {
        get { return _expanded; }
        set { toggle_expanded(value); }
    }

    construct {
        set_layout_manager(new Gtk.BinLayout());
        add_css_class("canvas_node_expander");
        add_css_class("card");
        vexpand = hexpand = true;
    }

    public CollapsibleSectionView(string title) {
        vertical_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vertical_box.vexpand = vertical_box.hexpand = true;

        create_header(title);
        create_content();
    }

    private void create_header(string header_title) {
        var header = new Adw.ActionRow();
        header.add_css_class("rounded_top");
        header.set_activatable(true);
        
        var title = new Gtk.Label(header_title);
        title.halign = Gtk.Align.START;
        title.hexpand = true;
        title.wrap = false;
        header.add_prefix(title);
        
        var click = new Gtk.GestureClick();
        click.released.connect(() => toggle_expanded(!_expanded));
        header.add_controller(click);

        var icon_theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default());
        var paintable = icon_theme.lookup_icon("pan-end-symbolic", null, 16, 1,
            Gtk.TextDirection.NONE,
            Gtk.IconLookupFlags.FORCE_SYMBOLIC);
        arrow_icon = new Gtk.Image.from_paintable(paintable);
        header.add_suffix(arrow_icon);

        vertical_box.append(header);
    }

    private void create_content() {
        content_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        content_box.vexpand = content_box.hexpand = true;
        content_box.visible = false;
        vertical_box.append(content_box);
        vertical_box.set_parent(this);
    }

    private void toggle_expanded(bool expand) {
        _expanded = expand;
        notify_property("expanded");
        
        content_box.visible = expand;

        var icon_name = expand ? "pan-down-symbolic" : "pan-end-symbolic";
        var icon_theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default());
        var paintable = icon_theme.lookup_icon(icon_name, null, 16, 1,
            Gtk.TextDirection.NONE,
            Gtk.IconLookupFlags.FORCE_SYMBOLIC);
        arrow_icon.set_from_paintable(paintable);
    }

    public void set_child(Gtk.Widget child) {
        content_box.append(child);
    }

    ~CollapsibleSectionView() {
        vertical_box.unparent();
    }
}