namespace History {

    public class RemoveNodeAction : Object, IAction {
        private weak CanvasGraph graph;
        private CanvasDisplayNode node;
        private int pos_x;
        private int pos_y;
        private int width;
        private int height;

        private List<LinkRecord> saved_links = new List<LinkRecord>();

        private class LinkRecord {
            public GFlow.Source source;
            public GFlow.Sink sink;

            public LinkRecord(GFlow.Source source, GFlow.Sink sink) {
                this.source = source;
                this.sink = sink;
            }
        }

        public RemoveNodeAction(CanvasGraph graph, CanvasDisplayNode node, int previous_x, int previous_y) {
            this.graph = graph;
            this.node = node;
            this.pos_x = previous_x;
            this.pos_y = previous_y;
            this.width = node.get_width();
            this.height = node.get_height();

            save_links();
        }

        private void save_links() {
            var model_node = node.n as CanvasNode;
            if (model_node == null)
                return;

            foreach (var source in model_node.get_sources()) {
                foreach (var sink in source.sinks) {
                    saved_links.append(new LinkRecord(source, sink));
                }
            }

            foreach (var sink in model_node.get_sinks()) {
                foreach (var source in sink.sources) {
                    saved_links.append(new LinkRecord(source, sink));
                }
            }
        }

        public void undo() {
            if (graph == null || node == null)
                return;

            graph.add_node(node);
            node.set_position(pos_x, pos_y);
            //  node.set_size_request(width, height);

            foreach (var link in saved_links) {
                link.sink.link(link.source);
            }

            node.undo_remove();
        }

        public void redo() {
            if (graph == null || node == null)
                return;

            node.remove();
        }
        
        public string get_label() {
            return "Remove node";
        }
    }

}
