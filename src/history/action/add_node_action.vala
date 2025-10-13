namespace History {

    public class AddNodeAction : Object, IAction {
        private weak GtkFlow.NodeView parent_view;
        private weak CanvasDisplayNode node;

        public AddNodeAction(GtkFlow.NodeView parent_view, CanvasDisplayNode node) {
            this.parent_view = parent_view;
            this.node = node;
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
        }
    }

}
