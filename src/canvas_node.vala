public delegate void BuilderConsumer(CanvasNodeBuilder builder);

public class CanvasNodeFactory : Object {
    private Gee.Map<string, CanvasNodeBuilder> all_builders = new Gee.HashMap<string, CanvasNodeBuilder>();

    public void register(CanvasNodeBuilder node_builder) {
        var builder_id = node_builder.id();
        if (all_builders.has_key(builder_id)) {
            warning("Node builder with id [%s] already registered!\n", builder_id);
            return;
        }
        all_builders.set(builder_id, node_builder);
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

public interface CanvasNodeTitleWidgetBuilder : Object {

    public abstract Gtk.Widget? build_title_widget(CanvasNode node);
}

public class DefaultTitleWidgetBuilder : CanvasNodeTitleWidgetBuilder, Object {
    
    public Gtk.Widget? build_title_widget(CanvasNode node) {
        return new Gtk.Label(node.name);
    }
}

public class CanvasDisplayNode : GtkFlow.Node {
        
    public signal void removed(CanvasDisplayNode removed_node);

    private History.HistoryOfChangesRecorder changes_recorder;
    private Graphene.Size previous_node_size = {width: 100, height: 200};
    private Gtk.Expander node_expander;
    private Gtk.Box node_box;
    private Gtk.ActionBar action_bar;
    private Gtk.Button delete_button;
    private Gtk.ColorButton color_chooser_button;
    private Gtk.CssProvider? custom_backround_css;

    private string builder_id;
    private Gdk.RGBA? node_color;

    public bool can_delete {
        set {
            delete_button.sensitive = value;
        }
    }

    public bool action_bar_visible {
        set {
            action_bar.visible = value;
        }
        get {
            return action_bar.visible;
        }
    }

    ~CanvasDisplayNode() {
        debug("Destroying display node %s\n", name);
    }

    public CanvasDisplayNode(
        string builder_id, 
        CanvasNode node,
        GtkFlow.NodeDockLabelWidgetFactory dock_label_factory = new GtkFlow.NodeDockLabelWidgetFactory(node)
    ) {
        base.with_margin(node, 0, dock_label_factory);
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;
        this.custom_backround_css = new Gtk.CssProvider();
        var css = "
        .gtkflow_node {
            background-color: @theme_bg_color;
            box-shadow: none;
        }

        .dark {
            color: white;
        }
        ";
        custom_backround_css.load_from_data(css.data);
        this.get_style_context().add_provider(custom_backround_css, Gtk.STYLE_PROVIDER_PRIORITY_USER);

        this.builder_id = builder_id;
        this.position_changed.connect(record_position_changed);
        this.size_changed.connect(record_size_changed);

        create_node_content();
        create_action_bar();
    }
    
    private void record_position_changed(int old_x, int old_y, int new_x, int new_y) {
        changes_recorder.record_node_moved(this, old_x, old_y, new_x, new_y);
    }

    private void record_size_changed(int old_width, int old_height, int new_width, int new_height) {
        this.previous_node_size = Graphene.Size(){ 
            width = new_width, 
            height = new_height
        };
        changes_recorder.record_node_resized(this, old_width, old_height, new_width, new_height);
    }

    public void build_title(CanvasNodeTitleWidgetBuilder title_builder, GLib.Icon? icon = null) {
        try {
            base.set_title(this.node_header(n as CanvasNode, icon, title_builder));
        } catch (GtkFlow.NodeError e) {
            warning(e.message);
        }
    }

    public void build_default_title(GLib.Icon? icon = null) {
        build_title(new DefaultTitleWidgetBuilder(), null);
    }

    private void create_node_content() {
        this.size_changed.connect(this.node_resized);

        this.node_expander = new Gtk.Expander("Node details");
        node_expander.add_css_class("canvas_node_expander");
        node_expander.set_resize_toplevel(true);
        node_expander.vexpand = node_expander.hexpand = true;
        node_expander.notify["expanded"].connect(node_expanded);

        this.node_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        node_box.add_css_class("rounded_bottom");
        node_expander.set_child(node_box);
        base.add_child(node_expander);
    }

    private void node_resized(int old_width, int old_height, int new_width, int new_height) {
        if (old_width < new_width || old_height < new_height) {
            if (!node_expander.expanded) {
                node_expander.expanded = true;
            }
        }
    }

    private void create_action_bar() {
        this.action_bar = new Gtk.ActionBar();
        action_bar.add_css_class("rounded_bottom_right");
        action_bar.add_css_class("rounded_bottom_left");

        base.add_child(action_bar);
    }

    public Gtk.Box add_action_bar_child_start(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.margin_start = 5;
        wrapper.append(child);
        action_bar.pack_start(wrapper);
        return wrapper;
    }

    public Gtk.Box add_action_bar_child_end(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.margin_end = 5;
        wrapper.append(child);
        action_bar.pack_end(wrapper);
        return wrapper;
    }

    public void remove_from_actionbar(Gtk.Widget child) {
        action_bar.remove(child);
    }

    private void node_expanded() {
        changes_recorder.record(new History.ToggleExpanderAction(this.node_expander, this, get_width(), get_height()));
        if (!this.node_expander.expanded) {
            this.previous_node_size = Graphene.Size(){
                width = get_width(),
                height = get_height()
            };
            set_size_request(-1, -1);
        } else {
            set_size_request((int) previous_node_size.width, (int) previous_node_size.height);
        }
    }

    private Gtk.Widget node_header(
        CanvasNode node, 
        GLib.Icon? icon, 
        CanvasNodeTitleWidgetBuilder title_widget_builder) 
    {
        var title_bar = new Data.TitleBar(title_widget_builder.build_title_widget(node));
        title_bar.hexpand = true;
        add_icon(title_bar, icon);
        add_delete_button(title_bar);
        add_color_chooser(title_bar);
        return title_bar;
    }

    private void add_delete_button (Data.TitleBar title_bar) {
        this.delete_button = new Gtk.Button();
        delete_button.add_css_class("destructive-action");
        delete_button.add_css_class("circular");
        delete_button.set_icon_name("window-close-symbolic");
        delete_button.set_focusable(false);
        delete_button.set_focus_on_click(false);
        delete_button.clicked.connect(this.remove_node);
        title_bar.append_right(delete_button);
    }

    private void remove_node() {
        stop_sinks_history_recording();
        {
            this.remove();
            removed(this);
            
            int x, y;
            get_position(out x, out y);
            var parent = this.parent as GtkFlow.NodeView;
            changes_recorder.record(new History.RemoveNodeAction(parent, this, x, y), true);
        }
    }

    private void add_icon(Data.TitleBar title_bar, GLib.Icon? icon) {
        if (icon == null) {
            return;
        }
        title_bar.append_left(new Gtk.Image.from_gicon(icon));
    }

    private void add_color_chooser(Data.TitleBar title_bar) {
        this.color_chooser_button = new Gtk.ColorButton();
        color_chooser_button.color_set.connect(() => {
            change_background_color(color_chooser_button.get_rgba());
        });
        title_bar.append_left(color_chooser_button);
    }

    public new void add_child(Gtk.Widget child) {
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
            Idle.add(() => {
                node_expander.expanded = true;
                return false;
            });
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
            box-shadow: none;
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

    private void stop_sinks_history_recording() {
        var node = n as CanvasNode;
        unowned var sinks = node.get_sinks();
        foreach (var sink in sinks) {
            if (!(sink is CanvasNodeSink)) continue;

            var canvas_sink = sink as CanvasNodeSink;
            canvas_sink.stop_history_recording();
        }
    }

    public virtual void undo_remove() {
        
    }
}

public class CanvasNodeSink : GFlow.SimpleSink {

    private History.HistoryOfChangesRecorder changes_recorder;

    public CanvasNodeSink (GLib.Value value) {
        base(value);
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;

        base.linked.connect(this.connected);
        base.unlinked.connect(this.disconnected);
    }

    private void disconnected(GFlow.Dock target) {
        changes_recorder.record(new History.UnlinkDocksAction(this, target));
    }

    private void connected(GFlow.Dock target) {
        if (target is CanvasNodeSource) {
            var target_source = target as CanvasNodeSource;
            changes_recorder.record(new History.LinkDocksAction(target_source, this));
        } else {
            warning("Not supported target source: %s\n", target.get_type().name());
        }
    }

    public CanvasNodeSink.with_type (GLib.Type type) {
        base.with_type(type);
    }

    public virtual bool can_serialize() {
        return true;
    }

    public void stop_history_recording() {
        base.linked.disconnect(this.connected);
        base.unlinked.disconnect(this.disconnected);
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
            log_error(e.message);
            error(e.message);
        }
    }
    
    public new void remove_sink(CanvasNodeSink node_sink) {
        try {
            base.remove_sink(node_sink);
        } catch (Error e) {
            log_error(e.message);
            error(e.message);
        }
    }

    public new void add_source(CanvasNodeSource node_source) {
        try {
            base.add_source(node_source);
        } catch (Error e) {
            log_error(e.message);
            error(e.message);
        }
    }

    public void set_sinks_silent() {
        
    }

    public virtual void serialize(Serialize.SerializedObject serializer) {
    }

    public virtual void deserialize(Serialize.DeserializedObject deserializer) {
    }

    protected void log_error(string error_message) {
        log.error(this, error_message);
    }

    protected void log_warning(string warning_message) {
        log.warning(this, warning_message);
    }
}