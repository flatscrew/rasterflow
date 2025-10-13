namespace History {

    public class UnlinkDocksAction : Object, IAction {
        private weak GFlow.Dock source;
        private weak GFlow.Dock target;

        public UnlinkDocksAction(GFlow.Dock source, GFlow.Dock target) {
            this.source = source;
            this.target = target;
        }

        public void undo() {
            if (source == null || target == null)
                return;
            try {
                target.link(source);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }

        public void redo() {
            if (source == null || target == null)
                return;
            try {
                source.unlink(target);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }
    }
}
