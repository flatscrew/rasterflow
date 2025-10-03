public delegate void BuilderConsumer(CanvasNodeBuilder builder);

public class CanvasNodeFactory : Object {
    private Gee.MultiMap<GLib.Type, CanvasNodeBuilder> data_type_builders = new Gee.HashMultiMap<GLib.Type, CanvasNodeBuilder> ();
    private Gee.Map<string, CanvasNodeBuilder> all_builders = new Gee.HashMap<string, CanvasNodeBuilder>();

    public void register(CanvasNodeBuilder node_builder, GLib.Type? input_data_type) {
        if (input_data_type == null) {
            return;
        }
        data_type_builders.set(input_data_type, node_builder);

        var builder_id = node_builder.id();
        if (all_builders.has_key(builder_id)) {
            warning("Node builder with id [%s] already registered!\n", builder_id);
            return;
        }
        all_builders.set(builder_id, node_builder);
    }

    public CanvasNodeBuilder[] available_buiders(GLib.Type input_type) {
        return data_type_builders.get(input_type).to_array();
    }

    public CanvasNodeBuilder? find_builder(string id) {
        return this.all_builders.get(id);
    }

    public void consume_all_builders(BuilderConsumer consumer) {
        foreach (var builder in all_builders.values) {
            consumer(builder);
        }
    }
}


public delegate void AfterNodeCreated(CanvasDisplayNode created_node);

public interface CanvasNodeBuilder : Object {
    public abstract string id();

    public virtual string name() {
        return this.get_type().name();
    }
    
    public virtual string? description() {
        return null;
    }

    public abstract CanvasDisplayNode create() throws Error;
}

public class CanvasDisplayNode : GtkFlow.Node {
        
    public signal void removed(CanvasDisplayNode removed_node);

    public Data.TitleBar title_bar {
        get;
        private set;
    }

    private Gtk.Expander node_expander;
    private Gtk.Box node_box;
    private Gtk.Button delete_button;
    private Gtk.ColorButton color_chooser_button;
    private Gtk.CssProvider? custom_backround_css;

    private bool has_any_child;
    private string builder_id;
    private Gdk.RGBA? node_color;

    public bool can_delete {
        set {
            delete_button.sensitive = value;
        }
    }

    ~CanvasDisplayNode() {
        debug("Destroying display node %s\n", name);
    }

    public CanvasDisplayNode(string builder_id, CanvasNode node) {
        this.with_icon(builder_id, node, null);
    }

    public CanvasDisplayNode.with_icon(string builder_id, CanvasNode node, GLib.Icon? icon, GtkFlow.NodeDockLabelWidgetFactory dock_label_factory = new GtkFlow.NodeDockLabelWidgetFactory(node)) {
        base.with_margin(node, 0, dock_label_factory);
        try {
            base.set_title(this.node_header(icon));
        } catch (GtkFlow.NodeError e) {
            warning(e.message);
        }
        base.set_size_request(250, -1);

        this.custom_backround_css = new Gtk.CssProvider();
        var css = "
        .gtkflow_node {
            background-color: @theme_bg_color;
        }

        .dark {
            color: white;
        }
        ";
        custom_backround_css.load_from_data(css.data);
        this.get_style_context().add_provider(custom_backround_css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

        this.builder_id = builder_id;
        create_node();
    }

    private void create_node() {
        this.node_expander = new Gtk.Expander("Node details");

        node_expander.set_resize_toplevel(true);
        node_expander.vexpand = node_expander.hexpand = true;
        node_expander.notify["expanded"].connect(() => {
            if (!this.node_expander.expanded) {
                set_size_request(-1, -1);
            }
        });

        this.node_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        node_box.add_css_class("rounded_bottom");

        node_expander.set_child(node_box);

        base.add_child(node_expander);
    }

    private Gtk.Widget node_header(GLib.Icon? icon) {
        this.title_bar = new Data.TitleBar(n.name);
        title_bar.hexpand = true;
        add_icon(icon);
        add_delete_button();
        add_color_chooser();

        return title_bar;
    }

    private void add_delete_button () {
        this.delete_button = new Gtk.Button();
        delete_button.add_css_class("destructive-action");
        delete_button.set_icon_name("window-close-symbolic");
        delete_button.set_focusable(false);
        delete_button.set_focus_on_click(false);
        delete_button.clicked.connect(this.remove_node);
        title_bar.append_right(delete_button);
    }

    private void remove_node() {
        debug("references: %u\n", this.ref_count);
        this.remove();
        removed(this);
    }

    private void add_icon(GLib.Icon? icon) {
        if (icon == null) {
            return;
        }
        title_bar.append_left(new Gtk.Image.from_gicon(icon));
    }

    private void add_color_chooser() {
        this.color_chooser_button = new Gtk.ColorButton();
        color_chooser_button.color_set.connect(() => {
            change_background_color(color_chooser_button.get_rgba());
        });
        title_bar.append_right(color_chooser_button);
    }

    public new void add_child(Gtk.Widget child) {
        if (!has_any_child) {
            node_box.append(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
            node_box.append(child);
            has_any_child = true;
            return;
        }
        node_box.append(child);
    }

    public virtual void serialize(Serialize.SerializedObject serializer) {
        var canvas_node = n as CanvasNode;
        canvas_node.serialize(serializer.new_object("model"));
        
        serializer.set_string("builder_id", builder_id);
        serializer.set_int("width", get_width());
        serializer.set_int("height", get_height());
        serializer.set_bool("expanded", node_expander.expanded);

        if (node_color != null) {
            serializer.set_string("color", node_color.to_string());
        }

        Graphene.Rect bounds;
        if (base.compute_bounds(get_parent(), out bounds)) {
            serializer.set_int("position_x", (int) bounds.get_x());
            serializer.set_int("position_y", (int) bounds.get_y());
        }
    }

    public virtual void deserialize(Serialize.DeserializedObject deserializer) {
        var canvas_node = n as CanvasNode;
        canvas_node.deserialize(deserializer.get_object("model"));
        
        var expanded = deserializer.get_bool("expanded", false);
        if (expanded) {
            node_expander.expanded = true;
        }
        set_size_request(deserializer.get_int("width"), deserializer.get_int("height"));
        set_position(deserializer.get_int("position_x"), deserializer.get_int("position_y"));

        var color = deserializer.get_string("color");
        if (color != null) {
            Gdk.RGBA custom_color = {};
            custom_color.parse(color);
            change_background_color(custom_color);
            color_chooser_button.set_rgba(custom_color);
        }
    }

    private bool is_color_light(Gdk.RGBA color) {
        double luminance = 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
        return luminance > 0.5;
    }

    private void change_background_color(Gdk.RGBA new_color) {
        this.node_color = new_color;
        this.highlight_color = new_color;

        var css = "
        .gtkflow_node {
            background-color: %s;
        }

        .dark {
            color: %s;
        }
        ".printf(new_color.to_string(), adjust_saturation(new_color, 2.3f).to_string());

        if (!is_color_light(new_color)) {
            get_style_context().add_class("dark");
        }

        custom_backround_css.load_from_data(css.data);
    }

    protected void make_busy(bool busy) {
        if (busy) {
            //  set_visible(false);
            set_sensitive(false);
        } else {
            //  set_visible(true);
            set_sensitive(true);
        }
    }

}

public class CanvasNodeSink : GFlow.SimpleSink {

    protected GLib.Value? value {
        get;
        private set;
    }

    public CanvasNodeSink (GLib.Value value) {
        base(value);
        this.value = value;
        base.changed.connect(this.value_changed);
    }

    private void value_changed(GLib.Value? new_value) {
        this.value = new_value;
    }

    public CanvasNodeSink.with_type (GLib.Type type) {
        base.with_type(type);
    }

    public virtual bool can_serialize() {
        return true;
    }
}

public class CanvasNodeSource : GFlow.SimpleSource {

    public GLib.Value? value {
        get;
        private set;
    }

    public CanvasNodeSource (GLib.Value value) {
        base(value);
        this.value = value;
        base.changed.connect(this.value_changed);
    }

    public CanvasNodeSource.with_type (GLib.Type type) {
        base.with_type(type);
    }

    private void value_changed(GLib.Value? new_value) {
        this.value = new_value;
    }

    public virtual bool can_serialize_links() {
        return true;
    }
}

public class CanvasNode : GFlow.SimpleNode {

    private CanvasLog log;

    ~CanvasNode() {
        debug("Destroying node %s\n", name);
    }

    public CanvasNode(string name) {
        base.name = name;
        this.log = CanvasLog.get_log();
    }

    public CanvasNodeSource new_source_with_value(string source_name, GLib.Value value) {
        var source = new CanvasNodeSource(value);
        source.name = source_name;
        add_source(source);
        return source;
    }

    public CanvasNodeSource new_source_with_type(string source_name, GLib.Type type) {
        var source = new CanvasNodeSource.with_type(type);
        source.name = source_name;
        add_source(source);
        return source;
    }

    public CanvasNodeSink new_sink_with_value(string sink_name, GLib.Value value) {
        var sink = new CanvasNodeSink(value);
        sink.name = sink_name;
        add_sink(sink);
        return sink;
    }

    public CanvasNodeSink new_sink_with_type(string sink_name, GLib.Type type) {
        var sink = new CanvasNodeSink.with_type(type);
        sink.name = sink_name;
        add_sink(sink);
        return sink;
    }

    public new void add_sink(CanvasNodeSink node_sink) {
        try {
            base.add_sink(node_sink);
        } catch (Error e) {
            log_error(e);
            error(e.message);
        }
    }

    public new void add_source(CanvasNodeSource node_source) {
        try {
            base.add_source(node_source);
        } catch (Error e) {
            log_error(e);
            error(e.message);
        }
    }

    public virtual void serialize(Serialize.SerializedObject serializer) {
    }

    public virtual void deserialize(Serialize.DeserializedObject deserializer) {
    }

    protected void log_error(GLib.Error error) {
        log.error(this, error.message);
    }

    protected void log_warning(GLib.Error warning) {
        log.warning(this, warning.message);
    }
}