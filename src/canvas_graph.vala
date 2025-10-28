public class CanvasGraph : Object {

    public signal void node_added(CanvasDisplayNode node);
    public signal void property_added(CanvasGraphProperty property);
    public signal void property_removed(CanvasGraphProperty property);
    public signal void properties_removed();
    public signal void property_node_added(CanvasPropertyDisplayNode node);
    
    private CanvasNodeFactory node_factory;
    private Gee.List<GtkFlow.Node> all_nodes = new Gee.ArrayList<GtkFlow.Node>();
    private Gee.Map<string, CanvasGraphProperty> all_properties = new Gee.HashMap<string, CanvasGraphProperty>();

    public CanvasGraph(CanvasNodeFactory node_factory) {
        this.node_factory = node_factory;
    }

    public void add_node(CanvasDisplayNode node) {
        all_nodes.add(node);
        node.removed.connect(this.node_removed);

        node_added(node);
    }

    public void remove_all_nodes() {
        foreach (var node in all_nodes) {
            node.remove();
        }
        all_nodes.clear();
    }

    private void node_removed(CanvasDisplayNode removed_node) {
        all_nodes.remove(removed_node);
    }
 
    public void add_property(CanvasGraphProperty property) {
        all_properties.set(property.name, property);
        property_added(property);
        
        property.removed.connect(this.remove_property);
    }
    
    public void remove_property(CanvasGraphProperty property) {
        all_properties.unset(property.name);
        property_removed(property);
    }
    
    public void add_property_node(CanvasPropertyDisplayNode node) {
        all_nodes.add(node);
        node.removed.connect(this.property_node_removed);
        
        property_node_added(node);
    }
    
    private void property_node_removed(CanvasPropertyDisplayNode removed_node) {
        all_nodes.remove(removed_node);
    }
    
    public bool has_any_property() {
        return all_properties.size > 0;
    }
    
    public bool has_property(string property_name) {
        return all_properties.has_key(property_name);
    }
    
    public void foreach_property(GLib.Func<CanvasGraphProperty> callback) {
        all_properties.values.foreach(element => {
            callback(element);
            return true;
        });
    }
    
    public void remove_all_properties() {
        if (all_properties == null || all_properties.size == 0) {
            return;
        }
        all_properties.clear();
        
        properties_removed();
    }
    
    public string serialize_graph(Serialize.CustomSerializers factory) {
        var serialized_graph = new Serialize.SerializedGraph(factory);
        foreach (var property in all_properties.values) {
            serialized_graph.serialize_property(property, new Serialize.SerializationContext(this));    
        }
        
        foreach (var node in all_nodes) {
            if (node is CanvasDisplayNode) {
                var canvas_node = node as CanvasDisplayNode;
                serialized_graph.serialize_node(canvas_node, new Serialize.SerializationContext(this));
            } else if (node is CanvasPropertyDisplayNode) {
                var property_node = node as CanvasPropertyDisplayNode;
                serialized_graph.serialize_property_node(property_node, new Serialize.SerializationContext(this));
            }
        }
        return serialized_graph.to_json();
    }

    public void deserialize_graph(GLib.File graph_file, Serialize.CustomDeserializers deserializers) {
        var deserialized_graph = new Serialize.DeserializedGraph.from_file(graph_file, deserializers);

        deserialized_graph.foreach_property(property_object => {
            var property_name = property_object.get_string("name");
            var property_label = property_object.get_string("label");
            var property_type_name = property_object.get_string("type");
            var property_type = GLib.Type.from_name(property_type_name);
            var property_value = property_object.get_value("value", name => {
                return property_type;
            });
            
            if (property_value != null) {
                add_property(new CanvasGraphProperty.from_value(property_name, property_label, property_type, property_value));
            } else {
                add_property(new CanvasGraphProperty(property_name, property_label, property_type));
            }
        });
        
        deserialized_graph.foreach_node(node_object => {
            var node_type = node_object.get_string("_type");
            if (node_type == null || node_type.length == 0) {
                node_type = "canvas_node";
            }
            
            if (node_type == "canvas_node") {
                deserialize_canvas_node(node_object);
            } else if (node_type == "property_node") {
                deserialize_property_node(node_object);
            }
        });

        deserialized_graph.foreach_link(link_object => {
            var source_name = link_object.get_string("source_name");
            var sinks = link_object.get_array("sinks");

            var source_display_node = all_nodes.get(link_object.get_int("node_index"));
            var source_node = source_display_node.n as CanvasNode; 

            foreach (var source in source_node.get_sources()) {
                if (source.name == source_name) {

                    sinks.for_each(sink_object => {

                        var sink_node = all_nodes.get(sink_object.get_int("node_index"));
                        try {
                            foreach (var sink in sink_node.n.get_sinks()) {
                                if (sink.name == sink_object.get_string("sink_name")) {
                                    source.link(sink);
                                }
                            }
                        } catch (Error e) {
                            warning(e.message);
                        }
                    });
                }
            }
        });
    }
    
    private void deserialize_canvas_node(Serialize.DeserializedObject node_object) {
        var builder_id = node_object.get_string("builder_id");
        var builder = node_factory.find_builder(builder_id);
        if (builder == null) {
            warning("Unable to find builder: %s\n", builder_id);
        }
        try {
            var built_node = builder.create();
            add_node(built_node);
            built_node.deserialize(node_object);
        } catch (Error e) {
            warning(e.message);
        }
    }
    
    private void deserialize_property_node(Serialize.DeserializedObject node_object) {
        var graph_property = all_properties.get(node_object.get_string("property_name"));
        
        var property_node = new CanvasPropertyNode(graph_property);
        var display_node = new CanvasPropertyDisplayNode(property_node);
        add_property_node(display_node);
        
        display_node.deserialize(node_object);
    }

    public int node_index(CanvasNode node) {
        var index = 0;
        foreach (var stored_node in all_nodes) {
            var canvas_node = stored_node.n as CanvasNode;
            if (canvas_node == node) {
                return index;
            }
            index++;
        }
        return -1;
    }
}