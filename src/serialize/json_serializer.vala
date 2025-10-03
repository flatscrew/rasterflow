namespace Serialize {

    public interface JsonSerializer : Object {

        public static JsonArraySerializer array_serializer() {
            return new JsonArraySerializer.as_root();
        } 

        public static JsonObjectSerializer object_serializer() {
            return new JsonObjectSerializer.new_root();
        }

        public abstract void set_string(string? key, string? value);
        public abstract void set_int(string? key, int? value);
        public abstract void set_boolean(string? key, bool? value);
        public abstract void set_object(string? key, Json.Object? value);
        public abstract JsonObjectSerializer new_object(string? key = null);
        public abstract JsonArraySerializer new_array(string? key);
        public abstract Json.Node get_node();
    }

    public class JsonObjectSerializer : Object {

        public Json.Object object_element { public get; private set; }

        public JsonObjectSerializer(Json.Object object_element) {
            this.object_element = object_element;
        }
        
        public JsonObjectSerializer.new_root() {
            this(new Json.Object());
        }

        public JsonObjectSerializer new_object(string? key) {
            var child_object = new Json.Object();
            object_element.set_object_member(key, child_object);
            return new JsonObjectSerializer(child_object);
        }

        public JsonArraySerializer new_array(string? key) {
            var child_array = new Json.Array();
            object_element.set_array_member(key, child_array);
            return new JsonArraySerializer(child_array);
        }

        public Json.Node get_node() {
            var node = new Json.Node(Json.NodeType.OBJECT);
            node.set_object(object_element);
            return node;
        }

        public void set_string(string? key, string? value) {
            if (value == null) {
                object_element.remove_member(key);
                return;
            }
            object_element.set_string_member(key, value);
        }

        public void set_object(string? key, Json.Object? value) {
            if (value == null) {
                object_element.remove_member(key);
                return;
            }
            object_element.set_object_member(key, value);
        }

        public void set_int(string? key, int64? value) {
            if (value == null) {
                object_element.remove_member(key);
                return;
            }
            object_element.set_int_member(key, value);
        }

        public void set_double(string? key, double? value) {
            if (value == null) {
                object_element.remove_member(key);
                return;
            }
            object_element.set_double_member(key, value);
        }


        public void set_boolean(string? key, bool? value) {
            if (value == null) {
                if (object_element.has_member(key)) {
                    object_element.remove_member(key);
                }
                return;
            }
            object_element.set_boolean_member(key, value);
        }
    }

    public class JsonArraySerializer : Object {
        
        private Json.Array array_element;

        public JsonArraySerializer(Json.Array array_element) {
            this.array_element = array_element;
        }

        public JsonArraySerializer.as_root() {
            this(new Json.Array());
        }

        public JsonObjectSerializer new_object() {
            var child_object = new Json.Object();
            array_element.add_object_element(child_object);
            return new JsonObjectSerializer(child_object);
        }

        public JsonArraySerializer new_array() {
            var child_array = new Json.Array();
            array_element.add_array_element(child_array);
            return new JsonArraySerializer(child_array);
        }

        public Json.Node get_node() {
            var array_node = new Json.Node(Json.NodeType.ARRAY);
            array_node.set_array(array_element);
            return array_node;
        }

        public void add_string(string? value) {
            array_element.add_string_element(value);
        }

        public void add_int(int? value) {
            array_element.add_int_element(value);
        }

        public void add_boolean(bool? value) {
            array_element.add_boolean_element(value);
        }

        public void add_object(Json.Object? value) {
            array_element.add_object_element(value);
        }
    }

    public interface JsonSerializable {

        public virtual void serialize(JsonSerializer serializer) {
            
        }
    }
}