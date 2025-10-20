namespace Serialize {

    public delegate GLib.Value? DeserializerDelegate(DeserializedObject object, GLib.Object? context_object);

    public class CustomDeserializers : Object {

        class DeserializerCallback : Object {
            private DeserializerDelegate deserializer_delegate;

            public DeserializerCallback(DeserializerDelegate deserializer_delegate) {
                this.deserializer_delegate = (object, context_object) => {
                    return deserializer_delegate(object, context_object);
                };
            }

            public GLib.Value? deserialize_value(DeserializedObject object, GLib.Object? context_object = null) {
                return deserializer_delegate(object, context_object);
            }
        }

        private Gee.Map<string, DeserializerCallback> deserializers = new Gee.HashMap<string, DeserializerCallback>();

        public void register_custom_type(GLib.Type type, DeserializerDelegate deleg) {
            deserializers.set(type.name(), new DeserializerCallback(deleg));
        }

        public GLib.Value? deserialize(DeserializedObject object, GLib.Object? context_object) {
            var type = object.get_string("type");
            if (type == null) {
                warning("Not recognized type\n");
                return null;
            }
            var deserializer = deserializers.get(type);
            if (deserializer == null) {
                warning("No deserializer for type: %s\n", type);
                return null;
            }
            return deserializer.deserialize_value(object, context_object);
        }
    }


    public delegate void DeserializedObjectDelegate(DeserializedObject object);
    public delegate void DeserializedPropertyDelegate(string name, GLib.Value value);

    public class DeserializedObject : Object {

        private CustomDeserializers deserializers;
        private JsonObjectDeserializer deserializer;

        public DeserializedObject(JsonObjectDeserializer deserializer, CustomDeserializers deserializers) {
            this.deserializer = deserializer;
            this.deserializers = deserializers;
        }

        public string? get_string(string name) {
            return deserializer.get_string(name);
        }

        public double? get_double(string name) {
            return deserializer.get_double(name);
        }

        public int? get_int(string name, int default_value = 0) {
            return deserializer.get_int(name, default_value);
        }

        public bool get_bool(string name, bool default_value) {
            return deserializer.get_boolean(name, default_value);
        }

        public void for_each_property(DeserializedPropertyDelegate property_delegate, GLib.Object context_object) {
            deserializer.for_each((node, index, name) => {
                if (node.is_value()) {
                    var param_spec = context_object.get_class().find_property(name);
                    var value_type = param_spec.value_type;
                    if (value_type.is_a(GLib.Type.ENUM)) {
                        GLib.Value val = GLib.Value(value_type);
                        val.set_enum((int) node.get_value().get_int64());
                        property_delegate(name, val);
                        return;
                    }
                    
                    property_delegate(name, node.get_value());
                } else if (node.is_object()) {
                    var deserializer = node.object_deserializer();
                    var value = deserializers.deserialize(new DeserializedObject(deserializer, deserializers), context_object);
                    if (value == null) {
                        return;
                    }
                    property_delegate(name, value);
                }
            });
        }

        public DeserializedArray? get_array(string name) {
            var array = deserializer.get_array(name);
            if (array == null) {
                return null;
            }
            return new DeserializedArray(array, deserializers);
        }

        public DeserializedObject get_object(string name) {
            var nested_object = deserializer.get_object(name);
            return new DeserializedObject(new JsonObjectDeserializer(nested_object), deserializers);
        }
    }

    public class DeserializedArray : Object {

        private CustomDeserializers deserializers;
        private JsonArrayDeserializer deserializer;

        public DeserializedArray(JsonArrayDeserializer deserializer, CustomDeserializers deserializers) {
            this.deserializer = deserializer;
            this.deserializers = deserializers;
        }

        public void for_each(DeserializedObjectDelegate object_delegate) {
            deserializer.for_each(json_node => {
                object_delegate(new DeserializedObject(json_node.object_deserializer(), deserializers));
            });
        }
    }

    public interface Deserializable : Object {

        public virtual void deserialize(DeserializedObject deserializer) {

        }
    }

    public class DeserializationContext : Object {

        private CanvasGraph canvas_nodes;

        public DeserializationContext(CanvasGraph canvas_nodes) {
            this.canvas_nodes = canvas_nodes;
        }

        public int node_index(CanvasNode node) {
            return canvas_nodes.node_index(node);
        }
    }

    public class DeserializedGraph {

        private DeserializedArray nodes;
        private DeserializedArray links;

        public DeserializedGraph.from_file(GLib.File graph_file, CustomDeserializers deserializers) {
            var parser = new Json.Parser();
            try {
                if (parser.load_from_file(graph_file.get_path())) {
                    var root_node = parser.get_root();

                    var root_object = root_node.get_object();
                    if (root_object == null || !root_object.has_member("nodes")) {
                        warning("Malformed graph file!\n");
                        return;
                    }
                    this.nodes = new DeserializedArray(new JsonArrayDeserializer(root_object.get_member("nodes")), deserializers);
                    this.links = new DeserializedArray(new JsonArrayDeserializer(root_object.get_member("links")), deserializers);
                }
            } catch (Error e) {
                warning(e.message);
            }
        }

        public void foreach_node(DeserializedObjectDelegate object_delegate) {
            nodes.for_each(object_delegate);
        }

        public void foreach_link(DeserializedObjectDelegate object_delegate) {
            links.for_each(object_delegate);
        }
    }
}