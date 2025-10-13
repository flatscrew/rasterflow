namespace History {

    public class ToggleExpanderAction : Object, IAction {
        private weak Gtk.Expander expander;
        private weak CanvasDisplayNode node;
        private bool was_expanded;
        private int old_width;
        private int old_height;

        public ToggleExpanderAction(Gtk.Expander expander, CanvasDisplayNode node, int old_width, int old_height) {
            this.expander = expander;
            this.node = node;
            this.was_expanded = expander.get_expanded();
            this.old_width = old_width;
            this.old_height = old_height;
        }

        public void undo() {
            if (expander == null)
                return;

            expander.set_expanded(!was_expanded);
            if (!was_expanded) {
                node.set_size_request(old_width, old_height);
            }
        }

        public void redo() {
            if (expander == null)
                return;

            expander.set_expanded(was_expanded);
            if (!was_expanded) {
                node.set_size_request(old_width, old_height);
            }
        }
    }
}
