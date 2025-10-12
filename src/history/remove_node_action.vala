namespace History {

    public class RemoveNodeAction : Object, IAction {
        private weak GtkFlow.NodeView parent_view;
        private CanvasDisplayNode node;
        private int pos_x;
        private int pos_y;
        private int width;
        private int height;

        public RemoveNodeAction(GtkFlow.NodeView parent_view, CanvasDisplayNode node, int previous_x, int previous_y) {
            this.parent_view = parent_view;
            this.node = node;
            this.pos_x = previous_x;
            this.pos_y = previous_y;
            this.width = node.get_width();
            this.height = node.get_height();
        }

        public void undo() {
            if (parent_view == null || node == null)
                return;

            parent_view.add(node);
            node.set_position(pos_x, pos_y);
            node.set_size_request(width, height);
        }

        public void redo() {
            if (parent_view == null || node == null)
                return;

            node.remove();
        }
    }

}
