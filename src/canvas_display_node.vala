// Copyright (C) 2025 activey
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

public class CanvasNodeDetailsView : Gtk.Widget {
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

    public CanvasNodeDetailsView() {
        vertical_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        vertical_box.vexpand = vertical_box.hexpand = true;

        create_header();
        create_content();
    }

    private void create_header() {
        var header = new Adw.ActionRow();
        header.add_css_class("rounded_top");
        header.set_activatable(true);
        
        var title = new Gtk.Label("Node details");
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

    ~CanvasNodeDetailsView() {
        vertical_box.unparent();
    }
}

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

    public abstract CanvasDisplayNode create(int x = 0, int y = 0) throws Error;
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
    private int x_initial; 
    private int y_initial;
    private Gtk.CssProvider? custom_backround_css;
    
    private CanvasNodeDetailsView details_view;
    private Gtk.Box node_box;
    private CanvasActionBar action_bar;
    private Gtk.Button delete_button;
    private Gtk.ColorDialogButton color_chooser_button;
    
    private Gtk.ProgressBar progress_bar;

    private string builder_id;
    private Gdk.RGBA? node_color;

    public bool can_delete {
        set {
            delete_button.sensitive = value;
        }
    }

    public bool can_expand {
        set {
            details_view.visible = value;
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
        int x_initial = 0, int y_initial = 0,
        GtkFlow.NodeDockLabelWidgetFactory dock_label_factory = new GtkFlow.NodeDockLabelWidgetFactory(node)
    ) {
        base.with_margin(node, 0, dock_label_factory);
        this.x_initial = x_initial;
        this.y_initial = y_initial;
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;
        
        apply_css_provider();

        this.builder_id = builder_id;
        this.position_changed.connect(record_position_changed);
        this.size_changed.connect(record_size_changed);
        
        create_node_content();
        create_action_bar();
    }
    
    public void init_position() {
        set_position(x_initial, y_initial);
    }
    
    private void apply_css_provider() {
        this.custom_backround_css = new Gtk.CssProvider();
        this.get_style_context().add_provider(custom_backround_css, Gtk.STYLE_PROVIDER_PRIORITY_USER);
    
        remove_css_class("gtkflow_node");
        add_css_class("card");
        add_css_class("view");
        add_css_class("canvas_node");
    }
    
    private void reset_background_color() {
        var css = "
        .canvas_node {
        }

        .dark {
            color: white;
        }
        ";
        custom_backround_css.load_from_bytes(new GLib.Bytes(css.data));
    }
    
    private void change_background_color(Gdk.RGBA? new_color) {
        var old_color = node_color;
        set_background_color(new_color);
        changes_recorder.record(new History.ChangeNodeColorAction(this, old_color, new_color));
    }
    
    public void set_background_color(Gdk.RGBA? new_color) {
        this.node_color = new_color;
        base.highlight_color = new_color;
        
        if (node_color == null) {
            reset_background_color();
            return;
        }
    
        var text_color = adjust_for_contrast(new_color);
        
        var css = "
        .canvas_node {
            background-color: %s;
            color: %s;
        }
        ".printf(
            new_color.to_string(),
            text_color.to_string()
        );

        custom_backround_css.load_from_data(css.data);
    
    }
    
    private void record_position_changed(int old_x, int old_y, int new_x, int new_y) {
        changes_recorder.record_node_moved(this, old_x, old_y, new_x, new_y);
    }

    private void record_size_changed(int old_width, int old_height, int new_width, int new_height) {
        this.previous_node_size = Graphene.Size(){ 
            width = new_width, 
            height = new_height
        };
        
        if (new_width == 0 && new_height == 0) {
            // FIXME why is this happening?    
            return;
        }
        
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

        this.details_view = new CanvasNodeDetailsView();
        details_view.vexpand = details_view.hexpand = true;
        details_view.notify["expanded"].connect(node_expanded);

        this.node_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        node_box.hexpand = node_box.vexpand = true;
        details_view.set_child(node_box);
        
        this.progress_bar = new Gtk.ProgressBar();
        progress_bar.set_pulse_step(0.3f);
        progress_bar.add_css_class("osd");
        progress_bar.halign = Gtk.Align.FILL;
        progress_bar.valign = Gtk.Align.END;
        
        var overlay = new Gtk.Overlay();
        overlay.set_child(details_view);
        overlay.add_overlay(progress_bar);
        
        base.add_child(overlay);
    }

    private void node_resized(int old_width, int old_height, int new_width, int new_height) {
        if (old_width < new_width || old_height < new_height) {
            if (!details_view.expanded) {
                details_view.expanded = true;
            }
        }
    }

    private void create_action_bar() {
        this.action_bar = new CanvasActionBar();
        base.add_child(action_bar);
    }

    public Gtk.Box add_action_bar_child_start(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.append(child);
        action_bar.add_action_start(wrapper);
        return wrapper;
    }

    public Gtk.Box add_action_bar_child_end(Gtk.Widget child) {
        var wrapper = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        wrapper.margin_end = 5;
        wrapper.append(child);
        action_bar.add_action_end(wrapper);
        return wrapper;
    }

    public void remove_from_actionbar(Gtk.Widget child) {
        action_bar.remove_action(child);
    }

    private void node_expanded() {
        changes_recorder.record(new History.ToggleExpanderAction(this.details_view, this, get_width(), get_height()));
        
        if (!this.details_view.expanded) {
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

    private void add_delete_button(Data.TitleBar title_bar) {
        this.delete_button = new Gtk.Button();
        delete_button.add_css_class("destructive-action");
        delete_button.add_css_class("circular");
        delete_button.set_icon_name("window-close-symbolic");
        delete_button.add_css_class("flat");
        delete_button.set_focusable(false);
        delete_button.set_focus_on_click(false);
        delete_button.clicked.connect(this.remove_node);
        title_bar.append_right(delete_button);
    }

    private void remove_node() {
        //  stop_sinks_history_recording();
        {
            removed(this);
            this.remove();
        }
    }

    private void add_icon(Data.TitleBar title_bar, GLib.Icon? icon) {
        if (icon == null) {
            return;
        }
        title_bar.append_left(new Gtk.Image.from_gicon(icon));
    }
    
    private void add_color_chooser(Data.TitleBar title_bar) {
        var dialog = new Gtk.ColorDialog();
        color_chooser_button = new Gtk.ColorDialogButton(dialog);
        color_chooser_button.set_tooltip_text("Set node color (Ctrl+Click to reset)");
        color_chooser_button.notify["rgba"].connect(() => {
            change_background_color(color_chooser_button.get_rgba());
        });
    
        title_bar.append_left(color_chooser_button);
        
        var gesture = new Gtk.GestureClick();
        gesture.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
        gesture.pressed.connect((n_press, x, y) => {
            var state = gesture.get_current_event_state();
            if ((state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                gesture.set_state(Gtk.EventSequenceState.CLAIMED);
                change_background_color(null);
            }
        });
        color_chooser_button.add_controller(gesture);
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
        serializer.set_bool("expanded", details_view.expanded);

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
            details_view.expanded = true;
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

    protected void make_busy(bool busy) {
        set_sensitive(!busy);
    }

    public virtual void undo_remove() {
        
    }
    
    public CanvasNodeTask begin_long_running_task() {
        var task = new CanvasNodeTask(progress_bar);
        task.on_finished.connect(() => {
            message("DONE!");
        });
        
        progress_bar.set_fraction(0.0);
        return task;
    }
    
    public bool link_sink(string sink_name, GtkFlow.Dock target_dock) {
        foreach (var sink in n.get_sinks()) {
            if (sink.name == sink_name) {
                try {
                    sink.link(target_dock.d);
                    return true;
                } catch (Error e) {
                    warning(e.message);
                    return false;
                }
            }    
        }
        return false;
    }
}