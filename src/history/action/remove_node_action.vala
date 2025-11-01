namespace History {

    public class RemoveNodeAction : Object, IAction {
        private weak CanvasGraph graph;
        private CanvasDisplayNode node;
        private int pos_x;
        private int pos_y;
        private int width;
        private int height;

        public RemoveNodeAction(CanvasGraph graph, CanvasDisplayNode node, int previous_x, int previous_y) {
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

            graph.add_node(node);
            node.set_position(pos_x, pos_y);
            //  node.set_size_request(width, height);

            node.undo_remove();
        }

        public void redo() {
            if (node == null)
                return;

            node.remove();
        }
        
        public string get_label() {
            return "Remove node";
        }
    }

}
