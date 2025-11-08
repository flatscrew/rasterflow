namespace History {

    public class MoveNodeAction : Object, IAction {
        
        private weak GtkFlow.Node node;
        private int old_x;
        private int old_y;
        private int new_x;
        private int new_y;

        public MoveNodeAction(GtkFlow.Node node, int old_x, int old_y, int new_x, int new_y) {
            this.node = node;
            this.old_x = old_x;
            this.old_y = old_y;
            this.new_x = new_x;
            this.new_y = new_y;
        }

        public void undo() {
            if (node != null)
                node.set_position(old_x, old_y);
                node.parent.queue_allocate();
        }

        public void redo() {
            if (node != null)
                node.set_position(new_x, new_y);
                node.parent.queue_allocate();
        }
        
        public string get_label() {
            return "Move node";
        }
    }
}