public class CanvasLog : Object {
    private static CanvasLog? instance = null;

    private GLib.ListStore list_model;

    public signal void entry_added(LogEntry entry);
    public signal void error(CanvasNode node, string message, string? debug_info = null);
    public signal void warning(CanvasNode node, string message, string? debug_info = null);
    public signal void info(CanvasNode node, string message, string? debug_info = null);
    public signal void cleared();

    construct {
        this.list_model = new GLib.ListStore(typeof(LogEntry));
    }

    public static CanvasLog get_log() {
        if (CanvasLog.instance == null) {
            CanvasLog.instance = new CanvasLog();
        }
        return CanvasLog.instance;
    }

    public GLib.ListModel get_model() {
        return list_model;
    }

    public void add_error(CanvasNode? node, string message, string? debug_info = null) {
        var msg = debug_info != null ? "%s: %s".printf(message, debug_info) : message;
        var entry = new LogEntry(LogSeverity.ERROR, msg, node);
        list_model.append(entry);
        entry_added(entry);
        error(node, message, debug_info);
    }

    public void add_warning(CanvasNode? node, string message, string? debug_info = null) {
        var msg = debug_info != null ? "%s: %s".printf(message, debug_info) : message;
        var entry = new LogEntry(LogSeverity.WARNING, msg, node);
        list_model.append(entry);
        entry_added(entry);
        warning(node, message, debug_info);
    }

    public void add_info(CanvasNode? node, string message, string? debug_info = null) {
        var msg = debug_info != null ? "%s: %s".printf(message, debug_info) : message;
        var entry = new LogEntry(LogSeverity.INFO, msg, node);
        list_model.append(entry);
        entry_added(entry);
        info(node, message, debug_info);
    }

    public void clear() {
        list_model.remove_all();
        cleared();
    }
}

public enum LogSeverity {
    INFO,
    WARNING,
    ERROR
}

public class LogEntry : Object {

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