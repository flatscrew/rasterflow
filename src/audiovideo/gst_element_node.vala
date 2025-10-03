namespace AudioVideo {

    public class GstOperationsFactory : Object {
        public static void register_gst_operations(string[] args, CanvasNodeFactory node_factory) {

            var registry = Gst.Registry.get();

            var plugins = registry.get_plugin_list();
            foreach (var plugin in plugins) {
                var features = registry.get_feature_list_by_plugin(plugin.get_name());
                foreach (var feature in features) {
                    if (!(feature is Gst.ElementFactory)) {
                        continue;
                    }
                    
                    var factory = feature as Gst.ElementFactory;
                    var title = factory.get_metadata(Gst.ELEMENT_METADATA_LONGNAME);
                    var description = factory.get_metadata(Gst.ELEMENT_METADATA_DESCRIPTION);
                    string pango_compatible_description = description
                        .replace("<code>", "<tt>")
                        .replace("</code>", "</tt>")
                        .replace("<em>", "<i>")
                        .replace("</em>", "</i>")
                        .replace(" > ", " &gt;")
                        .replace(" < ", " &lt;")
                        .replace(" <= ", " &lt;=")
                        .replace("&", "&amp;");
                    var gst_operation = factory.get_name();

                    node_factory.register(new GstOperationNodeBuilder(title, gst_operation, pango_compatible_description), typeof(Gst.Element));
                }
            }
        }
    }

    public class GstOperationNodeBuilder : CanvasNodeBuilder, Object {

        private string node_name;
        private string gst_operation;
        private string? gst_description;

        internal GstOperationNodeBuilder(string name, string gst_operation, string? gst_description = null) {
            this.node_name = name;
            this.gst_operation = gst_operation;
            this.gst_description = gst_description;
        }

        public CanvasDisplayNode create() throws Error {
            return new GstElementDisplayNode(id(), new GstElementNode(node_name, gst_operation));
        }

        public string name() {
            return node_name;
        }

        public override string? description() {
            return "<b>[gst:%s]</b> %s".printf(gst_operation, gst_description);
        }

        public string id() {
            return "gst:%s".printf(gst_operation);
        }
    }

    class GstPadExpectation : Object {

    }
    
    class GstExpectingSinkPad : CanvasNodeSink {
        
        internal delegate void CompatibleSibling(GstElementSinkPad sink_pad);
        
        public GstExpectingSinkPad() {
            base(typeof(GstPadExpectation));
            this.name = "expecting";
            this.max_sources = 1;
        }

        internal GstElementSinkPad? compatible_sibling(Gst.Pad pad) {
            var gst_element_node = base.node as GstElementNode;
            foreach (var sink in gst_element_node.get_sinks()) {
                if (sink == this) {
                    debug("found myself, skipping...\n");
                    continue;
                }
                if (sink is GstElementSinkPad) {
                    var gst_element_sink = sink as GstElementSinkPad;
                    if (gst_element_sink.can_link_source(pad)) {
                        debug("can link gst pad %s with %s from element %s \n", pad.name, sink.name, gst_element_node.name);
                        return gst_element_sink;
                    }   
                }
            }
            return null;
        }
    }

    class GstExpectedSourcePad : CanvasNodeSource {

        internal delegate void ForEachSinkFunc(GstExpectingSinkPad sink_pad);

        public GstExpectedSourcePad() {
            base(typeof(GstPadExpectation));
            this.name = "expected";
        }

        internal void foreach_expecting_sink(ForEachSinkFunc foreach_func) {
            foreach (unowned var sink in sinks) {
                if (sink is GstExpectingSinkPad) {
                    foreach_func(sink as GstExpectingSinkPad);
                }
            }
        }
    }

    public class GstElementSinkPad : CanvasNodeSink {
        
        public signal void updated();
        
        public string padname {get; private set;}
        internal Gst.Pad pad { get; private set;}
        internal bool requested_by_hand {
            get;
            private set;
        }

        private Gee.Map<string, GLib.Type> changed_properties = new Gee.HashMap<string, GLib.Type>();

        public GstElementSinkPad(Gst.Pad pad, bool requested_by_hand = false) {
            base.with_type(typeof(Gst.Pad));
            this.requested_by_hand = requested_by_hand;
            this.pad = pad;
            base.name = pad.name;
            this.padname = pad.name;

            this.before_linking.connect_after(this.check_can_connect);
            this.before_unlinking.connect_after(this.check_can_disconnect);
            this.linked.connect(this.connected);
            this.unlinked.connect(this.disconnected);
            this.changed.connect(this.sink_updated);

            foreach (var param_spec in pad.get_class().list_properties()) {
                pad.notify[param_spec.name].connect(this.pad_property_changed);
            }
        }

        private void pad_property_changed(ParamSpec property_spec) {
            changed_properties.set(property_spec.name, property_spec.value_type);
        }

        private bool check_can_connect(GFlow.Dock self, GFlow.Dock other) {
            if (other is GstElementSourcePad) {
                var source = other as GstElementSourcePad;
                if (source.created_by_expectation) {
                    if (!source.can_connect) {
                        return false;
                    }
                }
                var sink = self as GstElementSinkPad;
                return source.can_connect && source.pad.can_link(sink.pad);
            }
            return true;
        }

        private bool check_can_disconnect(GFlow.Dock self, GFlow.Dock other) {
            if (other is GstElementSourcePad) {
                var source = other as GstElementSourcePad;
                if (source.created_by_expectation) {
                    if (!source.can_disconnect) {
                        return false;
                    }
                }
                return source.can_disconnect;
            } 
            return true;
        }

        private void disconnected(GFlow.Dock target) {
            var source = target as GstElementSourcePad;
            var source_pad = source.pad;
            
            if (!source_pad.unlink(pad)) {
                warning("could not unlink gst pads :(\n");
            } else {
                debug("unlinked: source %s <> sink %s\n", source_pad.name, pad.name);
            }
        }

        private void connected(GFlow.Dock target) {
            var source = target as GstElementSourcePad;
            var source_pad = source.pad;

            var link_result = source_pad.link(pad);
            if (link_result == Gst.PadLinkReturn.OK) {
                debug("correctly linked %s with %s\n", source_pad.name, pad.name);
            } else {
                debug("could not link pads\n");
            }
        }

        private void sink_updated() {
            this.updated();
        }

        public Gst.Caps current_caps() {
            if (pad.has_current_caps()) {
                return pad.get_current_caps();
            }
            return pad.get_pad_template_caps();
        }

        internal bool can_link_source(Gst.Pad source_pad) {
            return source_pad.can_link(this.pad);
        }

        public void remove() {
            var parent = pad.get_parent_element();
            parent.remove_pad(pad);
        }

        internal void serialize(Serialize.SerializedObject serialized_sink) {
            serialized_sink.set_string("name", pad.name);
            var template = pad.get_pad_template();
            if (template != null) {
                serialized_sink.set_string("template_name", template.name_template);
            }

            var properties = serialized_sink.new_object("properties");
            foreach (var changed_property in changed_properties) {
                GLib.Value value = GLib.Value(changed_property.value);
                pad.get_property(changed_property.key, ref value);
                properties.set_value(changed_property.key, value);
            }
        }

        public static void deserialize(Serialize.DeserializedObject requested_sink, Gst.Element gst_element) {
            var template_name = requested_sink.get_string("template_name");
            if (template_name == null) {
                return;
            }
            var template = gst_element.get_pad_template(template_name);
            if (template == null) {
                warning("Cannot find template with name: %s\n", template_name);
                return;
            }

            var name = requested_sink.get_string("name");
            var new_pad = gst_element.request_pad(template, null, null);
            // when using name as method argument it throws some errors
            new_pad.name = name;
            if (new_pad == null) {
                warning("Unable to request pad: %s\n", name);
                return;
            }

            var properties = requested_sink.get_object("properties");
            if (properties == null) {
                return;
            }
            properties.for_each_property(new_pad.set_property);
        }
    }

    public class GstElementSourcePad : CanvasNodeSource {
        public string padname { get; private set;}
        internal Gst.Pad pad { get; private set;}
        internal bool created_by_expectation;
        internal bool can_connect;
        internal bool can_disconnect;

        private Gee.Map<string, GLib.Type> changed_properties = new Gee.HashMap<string, GLib.Type>();

        internal bool requested_by_hand {
            get;
            private set;
        }

        public GstElementSourcePad(Gst.Pad pad, bool created_by_expectation = false, bool requested_by_hand = false) {
            base.with_type(typeof(Gst.Pad));
            
            this.pad = pad;
            this.name = pad.name;
            this.padname = pad.name;
            this.can_disconnect = true;
            this.can_connect = true;
            this.created_by_expectation = created_by_expectation;
            this.requested_by_hand = requested_by_hand;

            foreach (var param_spec in pad.get_class().list_properties()) {
                pad.notify[param_spec.name].connect(this.pad_property_changed);
            }
        }

        private void pad_property_changed(ParamSpec property_spec) {
            changed_properties.set(property_spec.name, property_spec.value_type);
        }

        internal void listen_state_changes() {
            var gst_node = node as GstElementNode;
            gst_node.state_changed.connect(this.state_changed);
        }

        private void state_changed(Gst.State new_state) {
            this.can_disconnect = new_state <= Gst.State.READY;
            this.can_connect = new_state <= Gst.State.READY;
        }

        public Gst.Caps? current_caps() {
            if (pad.has_current_caps()) {
                return pad.get_current_caps();
            }
            return pad.get_pad_template_caps();
        }

        public override bool can_serialize_links() {
            return !this.created_by_expectation;
        }

        public void serialize(Serialize.SerializedObject serialized_source) {
            serialized_source.set_string("name", pad.name);
            var template = pad.get_pad_template();
            if (template != null) {
                serialized_source.set_string("template_name", template.name_template);
            }

            var properties = serialized_source.new_object("properties");
            foreach (var changed_property in changed_properties) {
                GLib.Value value = GLib.Value(changed_property.value);
                pad.get_property(changed_property.key, ref value);
                properties.set_value(changed_property.key, value);
            }
        }

        public static void deserialize(Serialize.DeserializedObject requested_source, Gst.Element gst_element) {
            var template_name = requested_source.get_string("template_name");
            if (template_name == null) {
                return;
            }
            var template = gst_element.get_pad_template(template_name);
            if (template == null) {
                warning("Cannot find template with name: %s\n", template_name);
                return;
            }

            var name = requested_source.get_string("name");
            var new_pad = gst_element.request_pad(template, name, null);
            if (new_pad == null) {
                warning("Unable to request pad: %s\n", name);
                return;
            }

            var properties = requested_source.get_object("properties");
            if (properties == null) {
                return;
            }
            properties.for_each_property(new_pad.set_property);
        }
    }

    public class GstElementNode : CanvasNode {
        
        internal signal void state_changed(Gst.State new_state);
        internal signal void dynamic_source_added(GstElementSourcePad source);
        
        internal Gst.Element gst_element {
            get;
            private set;
        }

        internal string gst_operation {
            get;
            private set;
        }

        internal GstExpectingSinkPad? expecting_sink {
            get;
            private set;
        }

        internal GstExpectedSourcePad? expected_source {
            get;
            private set;
        }

        internal bool has_request_sources {
            get;
            private set;
        }

        internal bool has_request_sinks {
            get;
            private set;
        }

        private CanvasLog log;
        private GstPipeline pipeline;
        private Gee.Map<string, GLib.Type> changed_properties = new Gee.HashMap<string, GLib.Type>();

        ~GstElementNode() {
            remove_from_graph();
        }

        public GstElementNode(string node_name, string gst_operation) {
            base(node_name);
            this.gst_operation = gst_operation;
            this.pipeline = GstPipeline.get_current();
            this.log = CanvasLog.get_log();

            create_gst_element();
            create_pads();
        }

        private void create_gst_element() {
            this.gst_element = Gst.ElementFactory.make(gst_operation, null);
            pipeline.add(gst_element);

            pipeline.error_reported.connect(this.pipeline_error_reported);
            pipeline.warning_reported.connect(this.pipeline_warning_reported);
            pipeline.state_changed.connect(this.pipeline_state_changed);
        
            var properties = gst_element.get_class().list_properties();
            foreach (var param_spec in properties) {
                gst_element.notify[param_spec.name].connect(this.gst_element_property_changed);
            }
        }

        private void gst_element_property_changed(ParamSpec property_spec) {
            changed_properties.set(property_spec.name, property_spec.value_type);
        }

        private void pipeline_state_changed(Gst.Element event_source, Gst.State new_state) {
            if (event_source == this.gst_element) {
                debug("element %s state changed to %s", this.gst_element.name, new_state.to_string());
                state_changed(new_state);
            }
        }

        private void pipeline_warning_reported(Gst.Object event_source, GLib.Error error, string debug_info) {
            if (event_source == this.gst_element) {
                debug("element %s reported warning: %s\n", this.gst_element.name, error.message);
                log.warning(this, error.message, debug_info);
            }
        }

        private void pipeline_error_reported(Gst.Object event_source, GLib.Error error, string debug_info) {
            if (event_source == this.gst_element) {
                debug("element %s reported error: %s\n", this.gst_element.name, error.message);
                log.error(this, error.message, debug_info);
            }
        }

        public Gst.State current_state() {
            return pipeline.current_state();
        }

        private void create_pads() {
            add_non_static_pads();

            // expected sink and source
            if (!gst_element.sinkpads.is_empty() || this.has_request_sinks) {
                add_expecting_sink();
            }

            gst_element.pad_added.connect(this.gst_element_pad_added);
            gst_element.pad_removed.connect(this.gst_element_pad_removed);
            gst_element.pads.foreach(this.add_static_pad);
        }

        private void add_static_pad(Gst.Pad pad) {
            try {
                if (pad.direction == Gst.PadDirection.SRC) {
                    add_source_pad(pad);
                } else if (pad.direction == Gst.PadDirection.SINK) {
                    add_sink_pad(pad);
                }
            } catch (GFlow.NodeError e) {
                warning(e.message);
            }
        }

        // TODO this causes some SEGFAULTs ;/
        private void gst_element_pad_removed(Gst.Pad removed_pad) {
            print("REMOVED PAD: %s FROM ELEMENT: %s \n", removed_pad.name, gst_element.name);

            GstElementSinkPad? sink_to_remove = null;
            foreach (var sink in get_sinks()) {
                if (sink is GstElementSinkPad) {
                    var sink_pad = sink as GstElementSinkPad;
                    if (sink_pad.pad == removed_pad) {
                        sink_to_remove = sink_pad;
                        break;
                    }
                }
            }
            if (sink_to_remove != null) {
                try {
                    sink_to_remove.unlink_all();
                    remove_sink(sink_to_remove);
                } catch (Error e) {
                    warning(e.message);
                }
            }

            GstElementSourcePad? source_to_remove = null;
            foreach (var source in get_sources()) {
                if (source is GstElementSourcePad) {
                    var source_pad = source as GstElementSourcePad;

                    if (source_pad.pad == removed_pad) {
                        source_to_remove = source_pad;
                        break;
                    }
                }
            }
            if (source_to_remove != null) {
                try {
                    source_to_remove.can_disconnect = true;
                    source_to_remove.unlink_all();
                    remove_source(source_to_remove);
                } catch (Error e) {
                    warning(e.message);
                }
            }
        }

        private void add_expecting_sink() {
            if (this.expecting_sink != null) {
                return;
            }
            this.expecting_sink = new GstExpectingSinkPad();
            add_sink(expecting_sink);
        }

        private void add_non_static_pads() {
            foreach (var template in gst_element.get_pad_template_list()) {
                if (template.direction == Gst.PadDirection.SRC) {
                    add_expected_source(template);

                    if (template.presence == Gst.PadPresence.REQUEST) {
                        if (!this.has_request_sources) {
                            this.has_request_sources = true;
                        }
                    }
                } else if (template.direction == Gst.PadDirection.SINK) {

                    if (template.presence == Gst.PadPresence.REQUEST) {
                        if (!this.has_request_sinks) {
                            this.has_request_sinks = true;
                        }
                    }
                }
            }
        }

        private void add_expected_source(Gst.PadTemplate template) {
            if (this.expected_source != null) {
                return;
            }
            if (template.presence == Gst.PadPresence.SOMETIMES) {
                this.expected_source = new GstExpectedSourcePad();
                add_source(expected_source);
            } 
        }

        private void gst_element_pad_added(Gst.Pad pad) {
            print("==================================\n");
            print("NEW PAD ADDED: %s to element: %s\n", pad.name, gst_element.name);

            var template = pad.get_pad_template();
            print("PRESENCE>>>> %s\n", template.presence.to_string());
            
            if (pad.direction == Gst.PadDirection.SRC) {
                try {
                    if (template != null && template.presence == Gst.PadPresence.SOMETIMES) {
                        var new_source = add_source_pad(pad, true);

                        expected_source.foreach_expecting_sink(expecting_sink => {
                            try {
                                var compatible_sink = expecting_sink.compatible_sibling(pad);
                                    if (compatible_sink != null) {
                                        new_source.can_connect = true;
                                        new_source.link(compatible_sink);
                                        new_source.can_connect = false;
                                
                                        dynamic_source_added(new_source);
                                    }
                                } catch (Error e) {
                                    warning(e.message);
                                }
                        });
                        return;
                    }

                    var new_source = add_source_pad(pad, false, true);
                    dynamic_source_added(new_source);
                } catch (Error e) {
                    warning(e.message);
                }
            } 
            else if (pad.direction == Gst.PadDirection.SINK) {
                if (template != null && template.presence == Gst.PadPresence.REQUEST) {
                    /*var new_sink = */ add_sink_pad(pad, true);
                    return;
                }
            }
        }

        private GstElementSourcePad add_source_pad(Gst.Pad pad, bool created_by_expectation = false, bool requested_by_hand = false) throws GFlow.NodeError {
            print("ADDING SOURCE!!\n");

            var new_source_pad = new GstElementSourcePad(pad, created_by_expectation, requested_by_hand);
            add_source(new_source_pad);
            new_source_pad.listen_state_changes();
            return new_source_pad;
        }

        private GstElementSinkPad? add_sink_pad(Gst.Pad pad, bool requested_by_hand = false) { 
            print("ADDING SINK!!\n");

            var sinkpad = new GstElementSinkPad(pad, requested_by_hand);
            add_sink(sinkpad);
            return sinkpad;
        }

        private void remove_from_graph() {
            debug("removing gst element from pipeline...");
            gst_element.set_state(Gst.State.NULL);
            pipeline.remove(gst_element);
        }


        public void set_element_property(string name, GLib.Value value) {
            this.gst_element.set_property(name, value);
        }

        protected override void serialize(Serialize.SerializedObject serializer) {
            base.serialize(serializer);

            foreach (var changed_property in changed_properties) {
                GLib.Value value = GLib.Value(changed_property.value);
                gst_element.get_property(changed_property.key, ref value);
                serializer.set_value(changed_property.key, value);
            }

            var requested_sources = serializer.new_array("requested_sources");
            foreach (var source in get_sources()) {
                if (source is GstElementSourcePad) {
                    var requested_source = source as GstElementSourcePad;
                    if (!requested_source.requested_by_hand) {
                        continue;
                    }

                    var serialized_source = requested_sources.new_object();
                    requested_source.serialize(serialized_source);
                }
            }

            var requested_sinks = serializer.new_array("requested_sinks");
            foreach (var sink in get_sinks()) {
                if (sink is GstElementSinkPad) {
                    var requested_sink = sink as GstElementSinkPad;
                    if (!requested_sink.requested_by_hand) {
                        continue;
                    }

                    var serialized_sink = requested_sinks.new_object();
                    requested_sink.serialize(serialized_sink);
                }
            }
        }

        protected override void deserialize(Serialize.DeserializedObject deserializer) {
            var requested_sources = deserializer.get_array("requested_sources");
            if (requested_sources != null) {
                requested_sources.for_each(requested_source => {
                    GstElementSourcePad.deserialize(requested_source, gst_element);
                });
            }
            
            var requested_sinks = deserializer.get_array("requested_sinks");
            if (requested_sinks != null) {
                requested_sinks.for_each(requested_sink => {
                    GstElementSinkPad.deserialize(requested_sink, gst_element);
                });
            }

            deserializer.for_each_property((name, value) => {
                gst_element.set_property(name, value);
            }, this.gst_element);
        }
        
    }
}