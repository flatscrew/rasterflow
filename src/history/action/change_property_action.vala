namespace History {

    public class ChangePropertyAction : Object, IAction {
        private weak GLib.Object target;
        private string property_name;
        private GLib.Value old_value;
        private GLib.Value new_value;

        public ChangePropertyAction(GLib.Object target, string property_name, GLib.Value old_value, GLib.Value new_value) {
            this.target = target;
            this.property_name = property_name;

            this.old_value = GLib.Value(old_value.type());
            this.new_value = GLib.Value(new_value.type());

            old_value.copy(ref this.old_value);
            new_value.copy(ref this.new_value);
        }

        public void undo() {
            if (target == null)
                return;
            target.set_property(property_name, old_value);
        }

        public void redo() {
            if (target == null)
                return;
            target.set_property(property_name, new_value);
        }
    }
}
