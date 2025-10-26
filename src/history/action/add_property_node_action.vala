namespace History {

    public class AddPropertyNodeAction : Object, IAction {
        private weak GtkFlow.NodeView parent_view;
        private CanvasPropertyDisplayNode node;
        
        private int x;
        private int y;

        public AddPropertyNodeAction(GtkFlow.NodeView parent_view, CanvasPropertyDisplayNode node) {
            this.parent_view = parent_view;
            this.node = node;
            
            node.get_position(out x, out y);
        }
        public void undo() {
            if (parent_view == null || node == null)
                return;

            node.remove();
        }

        public void redo() {
            if (parent_view == null || node == null)
                return;

            parent_view.add(node);
            parent_view.queue_allocate();
            
            node.set_position(x, y);
        }
        
        public string get_label() {
            return "Add property node";
        }
    }
}
