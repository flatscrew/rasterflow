public class CanvasNodeSink : GFlow.SimpleSink {

    private History.HistoryOfChangesRecorder changes_recorder;
    private bool recording_enabled;

    public CanvasNodeSink(GLib.Value value) {
        base(value);
        this.recording_enabled = true;
        
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;

        base.linked.connect(this.connected);
        base.unlinked.connect(this.disconnected);
    }
    
    public CanvasNodeSink.with_type (GLib.Type type) {
        base.with_type(type);
        this.changes_recorder = History.HistoryOfChangesRecorder.instance;

        base.linked.connect(this.connected);
        base.unlinked.connect(this.disconnected);
    }
    
    private void disconnected(GFlow.Dock target) {
        if (!recording_enabled) return;
        
        changes_recorder.record(new History.UnlinkDocksAction(this, target));
    }

    private void connected(GFlow.Dock target) {
        if (!recording_enabled) return;
        
        if (target is CanvasNodeSource) {
            var target_source = target as CanvasNodeSource;
            changes_recorder.record(new History.LinkDocksAction(target_source, this));
        } else {
            warning("Not supported target source: %s\n", target.get_type().name());
        }
    }


    public virtual bool can_serialize() {
        return true;
    }

    public void stop_history_recording() {
        this.recording_enabled = false;
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

public class CanvasOperationProcessor : Object {
    public signal void processing_progress(double progress);
    public signal void finished();
    
    public void update_progress(double progress) {
        processing_progress(progress);
    }
    
    public void finish() {
        finished();
    }
}

public class CanvasNode : GFlow.SimpleNode {

    public signal void processing_started(CanvasOperationProcessor operation_processor);
    
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

    public virtual void serialize(Serialize.SerializedObject serializer) {
    }

    public virtual void deserialize(Serialize.DeserializedObject deserializer) {
    }

    protected void log_error(string error_message) {
        log.add_error(this, error_message);
    }

    protected void log_warning(string warning_message) {
        log.add_warning(this, warning_message);
    }
}