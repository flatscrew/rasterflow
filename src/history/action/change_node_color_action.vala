namespace History {

    public class ChangeNodeColorAction : Object, IAction {
        private weak CanvasDisplayNode node;
        private Gdk.RGBA? old_color;
        private Gdk.RGBA? new_color;

        public ChangeNodeColorAction(CanvasDisplayNode node, Gdk.RGBA? old_color, Gdk.RGBA? new_color) {
            this.node = node;
            this.old_color = old_color;
            this.new_color = new_color;
        }
        
        public void undo() {
            if (node == null)
                return;

            node.set_background_color(old_color);
        }

        public void redo() {
            if (node == null)
                return;

            node.set_background_color(new_color);
        }
        
        public string get_label() {
            return "Change node color";
        }
    }
}
