namespace History {

    public class LinkDocksAction : Object, IAction {
        private weak GFlow.Dock source;
        private weak GFlow.Dock target;

        public LinkDocksAction(GFlow.Dock source, GFlow.Dock target) {
            this.source = source;
            this.target = target;
        }

        public void undo() {
            if (source == null || target == null)
                return;
            try {
                target.unlink(source);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }

        public void redo() {
            if (source == null || target == null)
                return;
            try {
                source.link(target);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }
    }
}
