namespace History {

    public class RemovePropertyNodeAction : Object, IAction {
        private unowned CanvasGraph graph;
        private CanvasPropertyDisplayNode node;
        private int pos_x;
        private int pos_y;
        private int width;
        private int height;

        private class LinkRecord {
            public GFlow.Source source;
            public GFlow.Sink sink;

            public LinkRecord(GFlow.Source source, GFlow.Sink sink) {
                this.source = source;
                this.sink = sink;
            }
        }

        public RemovePropertyNodeAction(CanvasGraph graph, CanvasPropertyDisplayNode node, int previous_x, int previous_y) {
            this.graph = graph;
            this.node = node;
            this.pos_x = previous_x;
            this.pos_y = previous_y;
            this.width = node.get_width();
            this.height = node.get_height();
        }

        public void undo() {
            if (graph == null || node == null)
                return;

            graph.add_property_node(node);
            node.set_position(pos_x, pos_y);
            //  node.set_size_request(width, height);
        }

        public void redo() {
            if (node == null)
                return;

            node.remove();
        }
        
        public string get_label() {
            return "Remove property node";
        }
    }

}
