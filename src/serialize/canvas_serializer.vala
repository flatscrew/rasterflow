namespace Serialize {

    public delegate void SerializerDelegate(GLib.Value value, SerializedObject object);

    public class CustomSerializers : Object {

        class SerializerCallback : Object {
            private SerializerDelegate serializer_delegate;

            public SerializerCallback(SerializerDelegate serializer_delegate) {
                this.serializer_delegate = (value, object) => {
                    serializer_delegate(value, object);
                };
            }

            public void serialize_value(GLib.Value value, SerializedObject object) {
                serializer_delegate(value, object);
            }
        }

        private Gee.Map<GLib.Type, SerializerCallback> serializers = new Gee.HashMap<GLib.Type, SerializerCallback>();

        public void register_custom_type(GLib.Type type, SerializerDelegate deleg) {
            serializers.set(type, new SerializerCallback(deleg));
        }

        public void serialize(GLib.Value value, SerializedObject parent_object, string name) {
            var value_type = value.type();
            if (value_type.is_a(GLib.Type.ENUM)) {
                int enum_value = value.get_enum();
                parent_object.set_int(name, enum_value);
                return;
            }
            
            var callback = serializers.get(value.type());
            if (callback == null) {
                warning("Unable to serialize type: %s\n", value.type_name());
                return;
            }

            var serialized_object = parent_object.new_object(name);
            serialized_object.set_string("type", value.type_name());
            callback.serialize_value(value, serialized_object);
        }
    }

    public class SerializedObject : Object {
        private CustomSerializers serializers;
        private JsonObjectSerializer json_object;

        public SerializedObject(JsonObjectSerializer json_object, CustomSerializers custom_serializers) {
            this.serializers = custom_serializers;
            this.json_object = json_object;
        }

        public void set_string(string name, string? value) {
            if (value == null) {
                message("null for %s\n", name);
                return;
            }
            json_object.set_string(name, value);
        }

        public void set_double(string name, double value) {
            json_object.set_double(name, value);
        }

        public void set_int(string name, int value) {
            json_object.set_int(name, value);
        }

        public void set_bool(string name, bool value) {
            json_object.set_boolean(name, value);
        }

        public void set_value(string name, GLib.Value? value) {
            if (value == null) {
                json_object.remove(name);
                return;
            }
            
            if (value.type() == Type.STRING) {
                json_object.set_string(name, value.get_string());
            } else if (value.type() == Type.INT) {
                json_object.set_int(name, value.get_int());
            } else if (value.type() == Type.INT64) {
                json_object.set_int(name, value.get_int64());
            } else if (value.type() == Type.UINT) {
                json_object.set_int(name, value.get_uint());
            } else if (value.type() == Type.DOUBLE) {
                json_object.set_double(name, value.get_double());
            } else if (value.type() == Type.BOOLEAN) {
                json_object.set_boolean(name, value.get_boolean());
            } else {
                serializers.serialize(value, this, name);
            }
        }

        public SerializedObject new_object(string name) {
            var nested_object = json_object.new_object(name);
            return new SerializedObject(nested_object, serializers);
        }

        public SerializedArray new_array(string name) {
            return new SerializedArray(json_object.new_array(name), serializers);
        }
    }

    public class SerializedArray : Object {
        private CustomSerializers factory;
        private JsonArraySerializer json_array;

        public SerializedArray(JsonArraySerializer json_array, CustomSerializers factory) {
            this.json_array = json_array;
            this.factory = factory;
        }

        public SerializedObject new_object() {
            return new SerializedObject(json_array.new_object(), factory);
        }
    }

    public class SerializationContext : Object {

        private CanvasGraph canvas_nodes;

        public SerializationContext(CanvasGraph canvas_nodes) {
            this.canvas_nodes = canvas_nodes;
        }

        public int node_index(CanvasNode node) {
            return canvas_nodes.node_index(node);
        }
    }

    public class SerializedGraph : Object {

        private CustomSerializers custom_serializers;
        private JsonObjectSerializer json_root;
        private JsonArraySerializer properties_array;
        private JsonArraySerializer nodes_array;
        private JsonArraySerializer links_array;

        public SerializedGraph(CustomSerializers factory) {
            this.custom_serializers = factory;
            this.json_root = new JsonObjectSerializer.new_root();
            this.properties_array = json_root.new_array("properties");
            this.nodes_array = json_root.new_array("nodes");
            this.links_array = json_root.new_array("links");
        }
        
        public void serialize_node(CanvasDisplayNode node, SerializationContext context) {
            node.serialize(new SerializedObject(nodes_array.new_object(), custom_serializers));

            unowned var sources = node.n.get_sources();
            foreach (var source in sources) {
                var canvas_source = source as CanvasNodeSource;
                if (!canvas_source.can_serialize_links()) {
                    continue;
                }

                unowned var connected_sinks = canvas_source.sinks;
                if (connected_sinks.length() == 0) {
                    continue;
                }

                var link = links_array.new_object();
                link.set_int("node_index", context.node_index(node.n as CanvasNode));
                link.set_string("source_name", canvas_source.name);

                var linked_sinks = link.new_array("sinks");

                foreach (var connected_sink in connected_sinks) {
                    var canvas_sink = connected_sink as CanvasNodeSink;
                    if (!canvas_sink.can_serialize()) {
                        continue;
                    }
                    var sink_node = canvas_sink.node as CanvasNode;

                    var linked_sink = linked_sinks.new_object();
                    linked_sink.set_int("node_index", context.node_index(sink_node));
                    linked_sink.set_string("sink_name", canvas_sink.name);
                }
            }
        }
        
        public void serialize_property(CanvasGraphProperty property, SerializationContext context) {
            property.serialize(new SerializedObject(properties_array.new_object(), custom_serializers));
        }

        public string to_json() {
            Json.Generator generator = new Json.Generator();
            generator.pretty = true;
            generator.set_root(json_root.get_node());
            return generator.to_data(null);
        }
    }
}