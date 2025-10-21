public class CanvasGraph : Object {

    public signal void node_added(CanvasDisplayNode node);
    public signal void property_added(CanvasGraphProperty property);
    
    private CanvasNodeFactory node_factory;
    private List<CanvasDisplayNode> all_nodes = new List<CanvasDisplayNode>();
    private List<CanvasGraphProperty> all_properties = new List<CanvasGraphProperty>();

    public CanvasGraph(CanvasNodeFactory node_factory) {
        this.node_factory = node_factory;
    }

    public void add_node(CanvasDisplayNode node) {
        all_nodes.append(node);
        node.removed.connect(this.node_removed);

        node_added(node);
    }

    public void remove_all_nodes() {
        foreach (var node in all_nodes) {
            node.remove();
        }
        all_nodes = new List<CanvasDisplayNode>();
    }

    private void node_removed(CanvasDisplayNode removed_node) {
        all_nodes.remove(removed_node);
    }
 
    public void add_property(CanvasGraphProperty property) {
        all_properties.append(property);
        property_added(property);
    }
    
    public bool has_any_property() {
        return all_properties.length() > 0;
    }
    
    public unowned List<CanvasGraphProperty> get_all_properties() {
        return all_properties;
    }
    
    public string serialize_graph(Serialize.CustomSerializers factory) {
        var serialized_graph = new Serialize.SerializedGraph(factory);
        foreach (var property in all_properties) {
            serialized_graph.serialize_property(property, new Serialize.SerializationContext(this));    
        }
        foreach (var node in all_nodes) {
            serialized_graph.serialize_node(node, new Serialize.SerializationContext(this));
        }
        return serialized_graph.to_json();
    }

    public void deserialize_graph(GLib.File graph_file, Serialize.CustomDeserializers deserializers) {
        var deserialized_graph = new Serialize.DeserializedGraph.from_file(graph_file, deserializers);

        deserialized_graph.foreach_property(property_object => {
            var name = property_object.get_string("name");
            var property_value = property_object.get_value("value", "type");
            
            add_property(new CanvasGraphProperty.from_value(name, property_value));
        });
        
        deserialized_graph.foreach_node(node_object => {
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
        });

        deserialized_graph.foreach_link(link_object => {
            var source_name = link_object.get_string("source_name");
            var sinks = link_object.get_array("sinks");

            var source_display_node = all_nodes.nth_data(link_object.get_int("node_index"));
            var source_node = source_display_node.n as CanvasNode; 

            foreach (var source in source_node.get_sources()) {
                if (source.name == source_name) {

                    sinks.for_each(sink_object => {

                        var sink_node = all_nodes.nth_data(sink_object.get_int("node_index"));
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