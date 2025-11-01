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

        private string composite_id;
        private CompositeAction composite_action;
        
        private HistoryOfChangesRecorder() {
            undo_stack = new ActionStack();
            redo_stack = new ActionStack();
        }

        public bool begin_composite(string label, out string? id_acquired) {
            if (composite_action != null) {
                id_acquired = null;
                return false;
            }
            
            this.composite_id = Uuid.string_random();
            this.composite_action = new CompositeAction(label);
            
            id_acquired = composite_id;
            return true;
        }
        
        public void end_composite(string composite_id) {
            if (composite_action == null || composite_id != this.composite_id)
                return;
                
            var finished_composite = composite_action;
            this.composite_action = null;
            this.composite_id = null;
            
            record(finished_composite);
        }

        public void record(IAction action) {
            if (!recording_enabled)
                return;
        
            if (composite_action != null) {
                composite_action.add_child(action);
                return;
            }
        
            message("recording action> %s", action.get_label());
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
            message("Undoing> %s", action.get_type().name());
            redo_stack.push(action);

            changed();
            
            Idle.add(() => {
                recording_enabled = true;
                return false;
            });
        }

        public void redo_last() {
            var action = redo_stack.pop();
            if (action == null) return;
            recording_enabled = false;
            action.redo();
            undo_stack.push(action);

            changed();
            
            Idle.add(() => {
                recording_enabled = true;
                return false;
            });
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
