using Gee;

namespace History {

    public class HistoryOfChangesRecorder : Object {
        private static HistoryOfChangesRecorder? _instance;
        public static HistoryOfChangesRecorder instance {
            get {
                if (_instance == null)
                    _instance = new HistoryOfChangesRecorder();
                return _instance;
            }
        }

        public signal void changed();

        public int max_history_size {
            get { return undo_stack.max_size; }
            set { undo_stack.max_size = value; redo_stack.max_size = value; }
        }

        private ActionStack undo_stack;
        private ActionStack redo_stack;
        private bool recording_enabled = true;

        private HistoryOfChangesRecorder() {
            undo_stack = new ActionStack();
            redo_stack = new ActionStack();
        }

        public void record(IAction action, bool force = false) {
            if (!recording_enabled && !force)
                return;

            message("recording action> %s\n", action.get_type().name());

            undo_stack.push(action);
            redo_stack.clear();
            changed();
        }

        public void record_node_moved(GtkFlow.Node moved_node, int old_x, int old_y, int new_x, int new_y) {
            this.record(new History.MoveNodeAction(moved_node, old_x, old_y, new_x, new_y));
        }

        public void record_node_resized(CanvasDisplayNode moved_node, int old_width, int old_height, int new_width, int new_height) {
            this.record(new History.NodeResizeAction(moved_node, old_width, old_height, new_width, new_height));
        }

        public void undo_last() {
            var action = undo_stack.pop();
            if (action == null) return;
            recording_enabled = false;
            action.undo();
            recording_enabled = true;
            redo_stack.push(action);

            changed();
        }

        public void redo_last() {
            var action = redo_stack.pop();
            if (action == null) return;
            recording_enabled = false;
            action.redo();
            recording_enabled = true;
            undo_stack.push(action);

            changed();
        }

        public void clear() {
            undo_stack.clear();
            redo_stack.clear();

            changed();
        }

        public void pause() {
            this.recording_enabled = false;
        }

        public void resume() {
            this.recording_enabled = true;
        }

        public IAction? peek_undo() {
            return undo_stack.peek();
        }
        
        public IAction? peek_redo() {
            return redo_stack.peek();
        }
        
        public int count_undo { get { return undo_stack.size; } }
        public int count_redo { get { return redo_stack.size; } }
        public bool can_undo { get { return !undo_stack.is_empty; } }
        public bool can_redo { get { return !redo_stack.is_empty; } }
    }
}
