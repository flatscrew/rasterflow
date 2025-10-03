public class CanvasLog : Object {
    private static CanvasLog? instance = null;

    public signal void error(CanvasNode node, string message, string? debug_info = null);
    public signal void warning(CanvasNode node, string message, string? debug_info = null);
    public signal void info(CanvasNode node, string message, string? debug_info = null);

    public static CanvasLog get_log() {
        if (CanvasLog.instance == null) {
            CanvasLog.instance = new CanvasLog();
        }
        return CanvasLog.instance;
    }
}

enum LogSeverity {
    WARNING,
    ERROR
}

class LogEntry : Object {

    public unowned CanvasNode? node {
        get;
        private set;
    }

    public LogSeverity severity {
        get;
        private set;
    }

    public string message {
        get;
        private set;
    }   
    
    public DateTime time {
        get;
        private set;
    }

    public LogEntry(LogSeverity severity, string message, CanvasNode node) {
        this.severity = severity;
        this.message = message;
        this.node = node;
        this.time = new DateTime.now_local();
    }
}

public class TimeSorter : Gtk.Sorter {

    public override Gtk.Ordering compare(GLib.Object? item1, GLib.Object? item2) {
        var entry1 = item1 as LogEntry;
        var entry2 = item2 as LogEntry;
        return Gtk.Ordering.from_cmpfunc(entry2.time.compare(entry1.time));
    }

}

public class CanvasLogsArea : Gtk.Widget {

    public signal void logs_collapsed(int header_height);
    public signal void log_node_selected(CanvasNode node);

    private CanvasLog log;
    private Gtk.ColumnView list_view;
    private GLib.ListStore list_model;
    private Gtk.SingleSelection selection;
    private Gtk.Expander expander;
    private Gtk.CenterBox header_box;

    private uint errors_count;
    private uint warnings_count;

    private Gtk.Image errors_icon;
    private Gtk.Label errors_label;
    private Gtk.Image warnings_icon;
    private Gtk.Label warnings_label;

    construct {
        set_layout_manager(new Gtk.BinLayout());
    }

    ~CanvasLogsArea() {
        expander.unparent();
    }

    public CanvasLogsArea() {
        this.log = CanvasLog.get_log();
        log.error.connect(this.error_reported);
        log.warning.connect(this.warning_reported);

        var clear_button = new Gtk.Button.from_icon_name("edit-clear-all-symbolic");
        clear_button.set_tooltip_text("Clear log messages");
        clear_button.clicked.connect(clear_logs);
        
        var summary_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        summary_box.append(clear_button);
        summary_box.append(this.errors_icon = new Gtk.Image.from_icon_name("dialog-error"));
        summary_box.append(this.errors_label = new Gtk.Label("4 error(s)"));
        summary_box.append(this.warnings_icon = new Gtk.Image.from_icon_name("dialog-warning"));
        summary_box.append(this.warnings_label = new Gtk.Label("15 warning(s)"));
        errors_icon.visible = errors_label.visible = warnings_icon.visible = warnings_label.visible = false;

        this.header_box = new Gtk.CenterBox();
        header_box.margin_start = header_box.margin_end = header_box.margin_top = header_box.margin_bottom = 3;
        header_box.set_hexpand(true);
        header_box.set_start_widget(new Gtk.Label("Logs"));
        header_box.set_end_widget(summary_box);

        this.expander = new Gtk.Expander(null);
        expander.set_label_widget(header_box);
        expander.set_child(create_logs_list());
        expander.set_hexpand(true);
        expander.set_vexpand(true);
        expander.set_resize_toplevel(true);
        expander.activate.connect_after(this.expander_activated);
        expander.set_parent(this);
    }

    private void expander_activated() {
        if (!expander.expanded) {
            logs_collapsed(header_box.get_height());
        }
    }

    private void clear_logs() {
        list_model.remove_all();
        list_view.vadjustment.set_upper(0);
        list_view.vadjustment.set_lower(0);

        errors_count = 0;
        warnings_count = 0;

        update_summary();
    }

    private void update_summary() {
        if (errors_count == 0 && warnings_count == 0) {
            errors_icon.visible = false;
            errors_label.visible = false;
            warnings_icon.visible = false;
            warnings_label.visible = false;
            return;
        }
        if (errors_count > 0) {
            errors_icon.visible = true;
            errors_label.label = "%u error(s)".printf(errors_count);
            errors_label.visible = true;
        }
        if (warnings_count > 0) {
            warnings_icon.visible = true;
            warnings_label.label = "%u warnings(s)".printf(warnings_count);
            warnings_label.visible = true;
        }
    }

    private Gtk.Widget create_logs_list() {
        this.list_model = new GLib.ListStore(typeof(LogEntry));
        this.selection = new Gtk.SingleSelection(new Gtk.SortListModel(list_model, new TimeSorter()));
    
        this.list_view = new Gtk.ColumnView(selection);
        list_view.set_show_column_separators(true);
        list_view.set_vscroll_policy(Gtk.ScrollablePolicy.NATURAL);
        list_view.hexpand = list_view.vexpand = true;
        list_view.append_column(time_column());
        list_view.append_column(severity_column());
        list_view.append_column(message_column());
        list_view.activate.connect(position => {
            var item = list_model.get_item(position) as LogEntry;
            if (item.node != null) {
                log_node_selected(item.node);
            }
        });

        var scrolled_view = new Gtk.ScrolledWindow();
        scrolled_view.set_child(list_view);
        return scrolled_view;
    }

    private Gtk.ColumnViewColumn time_column() {
        var severity_factory = new Gtk.SignalListItemFactory();
        severity_factory.setup.connect(setup_time);
        severity_factory.bind.connect(bind_time);

        var time_column = new Gtk.ColumnViewColumn("Time", severity_factory);
        time_column.set_resizable(true);
        return time_column;
    }

    private Gtk.ColumnViewColumn severity_column() {
        var severity_factory = new Gtk.SignalListItemFactory();
        severity_factory.setup.connect(setup_severity);
        severity_factory.bind.connect(bind_severity);

        var severity_column = new Gtk.ColumnViewColumn("Severity", severity_factory);
        severity_column.set_resizable(true);
        return severity_column;
    }
    
    private Gtk.ColumnViewColumn message_column() {
        var message_factory = new Gtk.SignalListItemFactory();
        message_factory.setup.connect(setup_message);
        message_factory.bind.connect(bind_message);

        var name_column = new Gtk.ColumnViewColumn("Message", message_factory);
        name_column.expand = true;
        return name_column;
    }

    private void setup_time(GLib.Object object) {
        var list_item = object as Gtk.ListItem;
        var label = new Gtk.Label("");
        list_item.set_child(label);
    }

    private void bind_time(GLib.Object object) {
        var list_item = object as Gtk.ListItem;
        var log_entry = list_item.get_item() as LogEntry;

        var label = list_item.get_child() as Gtk.Label;
        label.set_label(log_entry.time.format_iso8601());
    }
    
    private void setup_severity(GLib.Object object) {
        var list_item = object as Gtk.ListItem;

        var icon = new Gtk.Image();
        var label = new Gtk.Label("");

        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
        box.append(icon);
        box.append(label);

        list_item.set_child(box);
    }

    private void bind_severity(GLib.Object object) {
        var list_item = object as Gtk.ListItem;
        var log_entry = list_item.get_item() as LogEntry;

        var box = list_item.get_child() as Gtk.Box;

        var icon = box.get_first_child() as Gtk.Image;
        var label = icon.get_next_sibling() as Gtk.Label;
        

        if (log_entry.severity == LogSeverity.ERROR) {
            icon.set_from_icon_name("dialog-error");
            label.set_label("Error");
        } else if (log_entry.severity == LogSeverity.WARNING) {
            icon.set_from_icon_name("dialog-warning");
            label.set_label("Warning");
        }
    }

    private void setup_message(GLib.Object object) {
        var list_item = object as Gtk.ListItem;

        var label = new Gtk.Label("");
        label.halign = Gtk.Align.START;
        label.wrap = true;
        label.wrap_mode = Pango.WrapMode.CHAR;
        list_item.set_child(label);
    }

    private void bind_message(GLib.Object object) {
        var list_item = object as Gtk.ListItem;
        var log_entry = list_item.get_item() as LogEntry;

        var label = list_item.get_child() as Gtk.Label;
        label.set_label(log_entry.message);
    }

    private void error_reported(CanvasNode node, string message, string? debug_info) {
        errors_count++;
        list_model.append(new LogEntry(
            LogSeverity.ERROR, 
            debug_info == null ? message : "%s: %s".printf(message, debug_info), 
            node
        ));
        update_summary();
    }

    private void warning_reported(CanvasNode node, string message, string? debug_info) {
        warnings_count++;
        list_model.append(new LogEntry(
            LogSeverity.WARNING, 
            debug_info == null ? message : "%s: %s".printf(message, debug_info), 
            node
        ));  
        update_summary();
    }
}