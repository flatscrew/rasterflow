namespace History {

    public interface IAction : Object {
        public abstract void undo();
        public abstract void redo();
        public abstract string get_label();
        
        public virtual void add_child(IAction child) {}
        public virtual Gee.List<IAction> get_children() { 
            return new Gee.ArrayList<IAction>();
        }
    }
}