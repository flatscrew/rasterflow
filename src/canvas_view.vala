delegate void LongOperationDelegate();

public class CanvasView : Gtk.Widget {

    private History.HistoryOfChangesRecorder changes_recorder;

    private Gtk.Box node_view_box;
    private Gtk.Paned main_pane;
    private Gtk.ScrolledWindow scrolled_window;
    private ScrollPanner scroll_panner;
    private ZoomableArea zoomable_area;
    private GtkFlow.NodeView node_view;

    private Data.FileOriginNodeFactory file_origin_node_factory;
    private Gtk.Popover file_origin_popover;

    private CanvasNodeFactory node_factory;
    private CanvasNodes canvas_nodes;
    private CanvasSignals canvas_signals;
    private CanvasLogsArea logs_area;
    private Gtk.Button save_button;

    private Serialize.CustomSerializers serializers;
    private Serialize.CustomDeserializers deserializers;

    private DataDropHandler data_drop_handler;
    private string current_graph_file;

    construct {
        set_layout_manager(new Gtk.BinLayout());
    }

    ~CanvasView() {
        main_pane.unparent();
    }

    public CanvasView(
            CanvasSignals canvas_signals,
            CanvasNodeFactory node_factory, 
            Data.FileOriginNodeFactory file_data_node_factory, 
            Serialize.CustomSerializers serializers,
            Serialize.CustomDeserializers deserializers) {
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;

        this.file_origin_node_factory = file_data_node_factory;
        this.file_origin_popover = new Gtk.Popover();
        file_origin_popover.set_parent(this);

        this.canvas_signals = canvas_signals;
        this.node_factory = node_factory;
        this.serializers = serializers;
        this.deserializers = deserializers;

        this.data_drop_handler = new DataDropHandler();
        data_drop_handler.file_dropped.connect(this.add_file_data_node);
        data_drop_handler.text_dropped.connect(this.add_text_data_node);
        add_controller (data_drop_handler.data_drop_target);

        this.canvas_nodes = new CanvasNodes(node_factory);
        canvas_nodes.node_added.connect_after(this.node_added);
        
        this.node_view_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        create_node_view();
        create_minimap_overlay();
        create_logs_area();

        this.main_pane = new Gtk.Paned(Gtk.Orientation.VERTICAL);
        main_pane.set_shrink_end_child(false);
        main_pane.set_resize_end_child(false);
        main_pane.set_wide_handle(true);
        main_pane.set_start_child(node_view_box);
        main_pane.set_end_child(logs_area);
        main_pane.set_parent(this);
        main_pane.set_position(main_pane.max_position);
    }

    private void create_node_view() {
        this.node_view = new GtkFlow.NodeView();
        this.scrolled_window = new Gtk.ScrolledWindow();
        scrolled_window.set_kinetic_scrolling(false);
        scrolled_window.set_policy(Gtk.PolicyType.EXTERNAL, Gtk.PolicyType.EXTERNAL);
        scrolled_window.add_css_class("canvas_view");
        scrolled_window.vexpand = scrolled_window.hexpand = true;
        this.node_view_box.append(scrolled_window);
        
        this.scroll_panner = new ScrollPanner();
        scroll_panner.enable_panning(scrolled_window);

        create_zoom_control_overlay();
    }

    private void create_zoom_control_overlay() {
        this.zoomable_area = new ZoomableArea(scrolled_window, node_view);

        var overlay = new Gtk.Overlay();
        var scale_widget = zoomable_area.create_scale_widget();
        scale_widget.set_can_focus(false);

        var reset_scale = zoomable_area.create_reset_scale_button();

        var control_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        control_box.append(scale_widget);
        control_box.append(reset_scale);
        control_box.set_valign(Gtk.Align.END);
        control_box.set_halign(Gtk.Align.START);
        control_box.add_css_class("canvas_scale");

        overlay.add_overlay(control_box);
        node_view_box.append(overlay);
    }

    private void create_minimap_overlay() {
        var overlay = new Gtk.Overlay();
        var mini_map = new MiniMap(node_view);
        mini_map.set_valign(Gtk.Align.END);
        mini_map.set_halign(Gtk.Align.END);
        mini_map.set_can_focus(false);

        overlay.add_overlay(mini_map);

        node_view_box.append(overlay);
    }

    private void create_logs_area() {
        this.logs_area = new CanvasLogsArea();
        logs_area.logs_collapsed.connect(this.logs_collapsed);
        logs_area.log_node_selected.connect(node => {
            if (node == null) {
                return;
            }
            print("node=> %s\n", node.name);
        });
    }

    private void logs_collapsed(int height) {
        this.main_pane.set_position(main_pane.get_height() - height);
    }

    private void node_added(CanvasDisplayNode node) {
        node_view.add(node);
        node.set_position((int) scrolled_window.get_hadjustment().get_value(), (int) scrolled_window.get_vadjustment().get_value());

        changes_recorder.record(new History.AddNodeAction(node_view, node));
    }

    private void add_text_data_node(string text) {
        debug("Text: %s\n", text);
    }

    private void add_file_data_node(GLib.File file, double x, double y) {
        try {
            var file_info = file.query_info ("*", FileQueryInfoFlags.NONE);
            var mimetype = ContentType.get_mime_type(file_info.get_content_type());
            var file_node_builders = file_origin_node_factory.available_builders(mimetype);
            
            if (file_node_builders.length == 0) {
                show_error ("Not supported content type: <b>%s</b>".printf(mimetype));
                return;
            }

            if (file_node_builders.length == 1) {
                var builder = file_node_builders[0];
                var node_builder = builder.find_builder(node_factory);
                try {
                    var new_node = node_builder.create();
                    canvas_nodes.add(new_node);

                    builder.apply_file_data(new_node, file, file_info);
                    new_node.set_position((int) x, (int) y);
                } catch (Error e) {
                    warning(e.message);
                }
                return;
            }

            var chooser_box = new Data.FileOriginNodeChooser(
                this.node_factory, 
                file_node_builders,
                file,
                file_info
            );
            chooser_box.node_created.connect_after(node => {
                node_view.add(node);
                node.set_position((int) x, (int) y);

                file_origin_popover.hide();
            });

            file_origin_popover.set_child(chooser_box);
            file_origin_popover.set_pointing_to({
                x: (int)x,
                y: (int)y
            });


            file_origin_popover.popup();

        } catch (Error e) {
            stderr.printf(e.message);
        }
    }

    private void show_error(string error_markup) {
        warning(error_markup);
    }

    private Gtk.FileFilter file_chosse_filter() {
        var filter = new Gtk.FileFilter();
        filter.set_filter_name("Graph file");
        filter.add_mime_type("text/json");
        filter.add_suffix("graph");
        return filter;
    }

    private void save_graph() {
        if (current_graph_file == null) {
            return;
        }

        try {
            var serialized_graph = canvas_nodes.serialize_graph(serializers);
            FileUtils.set_contents_full(current_graph_file, serialized_graph, serialized_graph.length, GLib.FileSetContentsFlags.CONSISTENT);
        } catch (FileError e) {
            warning(e.message);                        
        }
    }

    private void save_graph_as() {
        var file_dialog = new Gtk.FileDialog();

        var filter = new Gtk.FileFilter();
        filter.name = "Graph files";
        filter.add_pattern("*.graph");

        var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
        filters.append(filter);
        file_dialog.set_filters(filters);
        file_dialog.set_initial_name("untitled.graph");
        file_dialog.save.begin(base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window, null, (obj, res) => {
            try {
                var file = file_dialog.save.end(res);
                if (file != null) {
                    current_graph_file = file.get_path();
                    save_button.set_sensitive(true);

                    var serialized_graph = canvas_nodes.serialize_graph(serializers);
                    FileUtils.set_contents_full(
                        current_graph_file,
                        serialized_graph,
                        serialized_graph.length,
                        GLib.FileSetContentsFlags.CONSISTENT
                    );
                }
            } catch (Error e) {
                warning("Save cancelled or failed: %s", e.message);
            }
        });
    }

    private void load_graph() {
        var file_dialog = new Gtk.FileDialog();

        var filter = new Gtk.FileFilter();
        filter.name = "Graph files";
        filter.add_pattern("*.graph");

        var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
        filters.append(filter);
        file_dialog.set_filters(filters);

        file_dialog.open.begin(base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window, null, (obj, res) => {
            try {
                var file = file_dialog.open.end(res);
                if (file != null) {
                    current_graph_file = file.get_path();
                    save_button.set_sensitive(true);
                    load_graph_async.begin(file);
                }
            } catch (Error e) {
                warning("File dialog cancelled or failed: %s", e.message);
            }
        });
    }

    async void load_graph_async (GLib.File selected_file) {
        canvas_signals.before_file_load();

        new Thread<void*> (null, () => {
            canvas_nodes.remove_all();
            canvas_nodes.deserialize_graph(selected_file, deserializers);

            Idle.add(() => {
                node_view.queue_allocate();
                node_view.queue_draw();
                return load_graph_async.callback();
            });
            return null;
        });
        yield;
 
        canvas_signals.after_file_load();
    }

    private void export_to_png() {
        var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, node_view.get_width(), node_view.get_height());
        var cairo_context = new Cairo.Context(surface);

        var snapshot = new Gtk.Snapshot();
        node_view.snapshot(snapshot);

        var node = snapshot.free_to_node();
        node.draw(cairo_context);

        var dialog = new Gtk.FileDialog();
        dialog.title = "Export to PNG";

        var png_filter = new Gtk.FileFilter();
        png_filter.name = "PNG image";
        png_filter.add_mime_type("image/png");
        png_filter.add_pattern("*.png");

        var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
        filters.append(png_filter);
        dialog.set_filters(filters);
        dialog.set_initial_name("export.png");

        dialog.save.begin(base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window, null, (obj, res) => {
            try {
                var file = dialog.save.end(res);
                if (file != null) {
                    surface.write_to_png(file.get_path());
                }
            } catch (Error e) {
                warning("PNG export cancelled or failed: %s", e.message);
            }
        });
    }

    public GtkFlow.Dock? find_node_sink_dock_widget(CanvasNodeSink node_sink) {
        message("FETCHING DOCK!!!\n");
        return node_view.retrieve_dock(node_sink);
    }

    public Data.DataNodeChooser create_node_chooser() {
        var node_chooser = new Data.DataNodeChooser.everything(node_factory);
        node_chooser.set_tooltip_text("Add new node");
        node_chooser.node_created.connect(canvas_nodes.add);
        return node_chooser;
    }

    public Gtk.Button create_save_graph_as_button() {
        var save_as_button = new Gtk.Button();
        save_as_button.set_icon_name("document-save-as-symbolic");
        save_as_button.set_tooltip_text("Save graph as");
        save_as_button.clicked.connect(this.save_graph_as);
        return save_as_button;
    }

    public Gtk.Button create_save_graph_button() {
        save_button = new Gtk.Button();
        save_button.set_sensitive(false);
        save_button.set_icon_name("document-save-symbolic");
        save_button.set_tooltip_text("Save graph");
        save_button.clicked.connect(this.save_graph);
        return save_button;
    }

    public Gtk.Button create_load_graph_button() {
        var load_button = new Gtk.Button();
        load_button.set_icon_name("document-open-symbolic");
        load_button.set_tooltip_text("Load graph from file");
        load_button.clicked.connect(this.load_graph);
        return load_button;
    }

    public Gtk.Button create_export_png_button() {
        var export_button = new Gtk.Button();
        export_button.set_icon_name("image-x-generic");
        export_button.set_tooltip_text("Export to PNG");
        export_button.clicked.connect(this.export_to_png);
        return export_button;
    }
}