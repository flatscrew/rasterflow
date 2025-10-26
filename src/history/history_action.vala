namespace History {

    public interface IAction : Object {
        public abstract void undo();
        public abstract void redo();
        public abstract string get_label();
    }
}