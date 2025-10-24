namespace Serialize {

    public delegate GLib.Type? PropertyTypeResolver(string property_name);
    
    public delegate GLib.Value? DeserializerDelegate(DeserializedObject object);

    public class CustomDeserializers : Object {

        class DeserializerCallback : Object {
            private DeserializerDelegate deserializer_delegate;

            public DeserializerCallback(DeserializerDelegate deserializer_delegate) {
                this.deserializer_delegate = (object) => {
                    return deserializer_delegate(object);
                };
            }

            public GLib.Value? deserialize_value(DeserializedObject object) {
                return deserializer_delegate(object);
            }
        }

        private Gee.Map<string, DeserializerCallback> deserializers = new Gee.HashMap<string, DeserializerCallback>();

        public void register_custom_type(GLib.Type type, DeserializerDelegate deleg) {
            deserializers.set(type.name(), new DeserializerCallback(deleg));
        }

        public GLib.Value? deserialize(DeserializedObject object) {
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
            return deserializer.deserialize_value(object);
        }
    }

    public delegate void DeserializedObjectDelegate(DeserializedObject object);
    public delegate void DeserializedPropertyDelegate(string name, GLib.Value? value);

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

        public GLib.Value? get_value(string property_name, PropertyTypeResolver type_resolver) {
            var json_node = deserializer.get_object(property_name);
            if (json_node == null) {
                return null;
            }
            
            var node = new JsonNode(deserializer.get_object(property_name));
            if (node.is_value()) {
                var value_type = type_resolver(property_name);
                GLib.Value destination_type = GLib.Value(value_type);
                
                if (value_type.is_a(GLib.Type.ENUM)) {
                    destination_type.set_enum((int) node.get_value().get_int64());
                    return destination_type;
                }
                
                node.get_value().transform(ref destination_type);
                return destination_type;
            } else if (node.is_object()) {
                var deserializer = node.object_deserializer();
                var value = deserializers.deserialize(new DeserializedObject(deserializer, deserializers));
                return value;
            }
            return null;
        }
        
        public void for_each_property(DeserializedPropertyDelegate property_delegate, PropertyTypeResolver type_resolver) {
            deserializer.for_each((node, index, name) => {
                if (node.is_value()) {
                    var value_type = type_resolver(name);
                    if (value_type.is_a(GLib.Type.ENUM)) {
                        GLib.Value val = GLib.Value(value_type);
                        val.set_enum((int) node.get_value().get_int64());
                        property_delegate(name, val);
                        return;
                    }
                    
                    property_delegate(name, node.get_value());
                } else if (node.is_object()) {
                    var deserializer = node.object_deserializer();
                    var value = deserializers.deserialize(new DeserializedObject(deserializer, deserializers));
                    property_delegate(name, value);
                }
            });
        }
        
        public void for_each_property_with_context_object(DeserializedPropertyDelegate property_delegate, GLib.Object context_object) {
            for_each_property(property_delegate, name => {
                var param_spec = context_object.get_class().find_property(name);
                return param_spec.value_type;
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
        
        public void for_each_node(GLib.Func<JsonNode> aaa) {
            deserializer.for_each(json_node => {
                aaa(json_node);
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

        private DeserializedArray properties;
        private DeserializedArray nodes;
        private DeserializedArray links;

        public DeserializedGraph.from_file(GLib.File graph_file, CustomDeserializers deserializers) {
            var parser = new Json.Parser();
            try {
                if (parser.load_from_file(graph_file.get_path())) {
                    var root_node = parser.get_root();

                    var root_object = root_node.get_object();
                    // TODO write better validation
                    if (root_object == null || !root_object.has_member("nodes")) {
                        warning("Malformed graph file!\n");
                        return;
                    }
                    
                    this.properties = new DeserializedArray(new JsonArrayDeserializer(root_object.get_member("properties")), deserializers);
                    this.nodes = new DeserializedArray(new JsonArrayDeserializer(root_object.get_member("nodes")), deserializers);
                    this.links = new DeserializedArray(new JsonArrayDeserializer(root_object.get_member("links")), deserializers);
                }
            } catch (Error e) {
                warning(e.message);
            }
        }

        public void foreach_property(DeserializedObjectDelegate object_delegate) {
            if (properties == null) return;
            properties.for_each(object_delegate);
        }
        
        public void foreach_node(DeserializedObjectDelegate object_delegate) {
            nodes.for_each(object_delegate);
        }

        public void foreach_link(DeserializedObjectDelegate object_delegate) {
            links.for_each(object_delegate);
        }
    }
}