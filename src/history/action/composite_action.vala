namespace History {
    
    public class CompositeAction : Object, IAction {
        private Gee.List<IAction> children = new Gee.ArrayList<IAction>();
        private string label;
    
        public CompositeAction(string label) {
            this.label = label;
        }
    
        public void add_child(IAction child) {
            message("adding child> %s", child.get_label());
            children.add(child);
        }
    
        public Gee.List<IAction> get_children() {
            return children;
        }
    
        public void undo() {
            children.foreach(child => {
                message("undoing child> %s", child.get_type().name());
                child.undo();
                return true;
            });
        }
    
        public void redo() {
            // redo only first at will trigger all children again
            children.first().redo();
        }
    
        public string get_label() {
            return label;
        }
    }
}