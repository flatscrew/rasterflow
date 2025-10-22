namespace Serialize {

    public class JsonNode : Object {

        private Json.Node node;

        public JsonNode(Json.Node node) {
            this.node = node;
        }

        public bool is_object() {
            return node.get_node_type() == Json.NodeType.OBJECT;
        }

        public bool is_array() {
            return node.get_node_type() == Json.NodeType.ARRAY;
        }

        public bool is_value() {
            return node.get_node_type() == Json.NodeType.VALUE;
        }

        public GLib.Value? get_value() {
            return node.get_value();
        }

        public JsonObjectDeserializer object_deserializer() {
            return new JsonObjectDeserializer(node);
        }

        public JsonArrayDeserializer array_deserializer() {
            return new JsonArrayDeserializer(node);
        }
    }

    public delegate void JsonNodeDelegate(JsonNode node, uint? index = -1, string? name = null);

    public interface JsonDeserializer : Object {

        public static JsonArrayDeserializer array_deserializer(Json.Node array_node) {
            return new JsonArrayDeserializer(array_node);
        } 

        public static JsonObjectDeserializer object_deserializer(Json.Node object_node) {
            return new JsonObjectDeserializer(object_node);
        } 

        public virtual void for_each(JsonNodeDelegate node_delegate) {}
        
        public virtual int get_int(string key, int default_value) {
            return 0;
        }
        
        public virtual string? get_string(string key) {
            return null;
        }
        
        public virtual bool get_boolean(string key, bool default_value) {
            return false;
        }
        
        public virtual Json.Object? get_json_object(string key) {
            return null;
        }
        
        public virtual JsonDeserializer? get_array(string key) {
            return null;
        }
    }

    public class JsonObjectDeserializer : Object {

        private Json.Node object_node;

        public JsonObjectDeserializer(Json.Node object_node) {
            this.object_node = object_node;
        }

        public void for_each(JsonNodeDelegate node_delegate) {
            object_node.get_object().foreach_member((object, member_name, member_node) => {
                node_delegate(new JsonNode(member_node), -1, member_name);
            });
        }
        
        public int get_int(string key, int default_value = 0) {
            if (!object_node.get_object().has_member(key)) {
                return default_value;
            }
            return (int) object_node.get_object().get_int_member(key);
        }

        public double get_double(string key, double default_value = 0) {
            if (!object_node.get_object().has_member(key)) {
                return default_value;
            }
            return object_node.get_object().get_double_member(key);
        }

        public string? get_string(string key) {
            if (!object_node.get_object().has_member(key)) {
                return null;
            }
            return object_node.get_object().get_string_member(key);
        }

        public bool get_boolean(string key, bool default_value) {
            if (!object_node.get_object().has_member(key)) {
                return default_value;
            }
            return object_node.get_object().get_boolean_member(key);
        }

        public JsonArrayDeserializer? get_array(string key) {
            if (!object_node.get_object().has_member(key)) {
                return null;
            }
            var member = object_node.get_object().get_member(key);
            if (member.get_node_type() == Json.NodeType.ARRAY) {
                return new JsonArrayDeserializer(member);
            }
            return null;
        }

        public Json.Node? get_object(string key) {
            if (!object_node.get_object().has_member(key)) {
                return null;
            }
            return object_node.get_object().get_member(key);
        }
    }

    public class JsonArrayDeserializer : Object {

        private Json.Node array_node;

        public JsonArrayDeserializer(Json.Node array_node) {
            this.array_node = array_node;
        }

        public void for_each(JsonNodeDelegate node_delegate) {
            array_node.get_array().foreach_element((array, index, element) => {
                node_delegate(new JsonNode(element), index);
            });
        }
    }
}