namespace History {

    public class NodeResizeAction : Object, IAction {
        private weak CanvasDisplayNode node;
        private int old_width;
        private int old_height;
        private int new_width;
        private int new_height;

        public NodeResizeAction(CanvasDisplayNode node, int old_width, int old_height, int new_width, int new_height) {
            this.node = node;
            this.old_width = old_width;
            this.old_height = old_height;
            this.new_width = new_width;
            this.new_height = new_height;
        }

        public void undo() {
            if (node != null)
                node.set_size_request(old_width, old_height);
                node.parent.queue_allocate();
        }

        public void redo() {
            if (node != null)
                node.set_size_request(new_width, new_height);
                node.parent.queue_allocate();
        }
        
        public string get_label() {
            return "Resize node";
        }
    }
}