namespace History {

    public class ActionStack : Object {
        private Gee.LinkedList<IAction> _list = new Gee.LinkedList<IAction>();
        public int max_size { get; set; default = 100; }

        public void push(IAction action) {
            if (_list.size >= max_size && !_list.is_empty)
                _list.remove_at(0);
            _list.add(action);
        }

        public IAction? pop() {
            if (_list.is_empty)
                return null;
            return _list.remove_at(_list.size - 1);
        }

        public void clear() {
            _list.clear();
        }

        public int size {
            get { return _list.size; }
        }

        public bool is_empty {
            get { return _list.is_empty; }
        }
    }

}
