namespace AudioVideo {
    
    public class GstStructureElement : Object {
        public string name { get; set; }
        public GLib.Value value { get; set; }
    
        public GstStructureElement(string name, GLib.Value value) {
            this.name = name;
            this.value = value;
        }
    }

    public class GstStructureList : Gtk.Widget {

        private bool editable;
        private Gtk.ColumnView list_view;

        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        ~GstStructureList() {
            list_view.unparent();
        }
        
        public GstStructureList(Gst.Structure? structure, bool editable = false) {
            this.editable = editable;


            this.list_view = new Gtk.ColumnView(null);
            var factory = new Gtk.SignalListItemFactory();
            factory.setup.connect(setup);
            factory.bind.connect(bind);

            var factory1 = new Gtk.SignalListItemFactory();
            factory1.setup.connect(setup1);
            factory1.bind.connect(bind1);

            var store = new ListStore(typeof(GstStructureElement));
            var selection_model = new Gtk.SingleSelection(store);
            list_view.set_model(selection_model);

            var column1 = new Gtk.ColumnViewColumn("Name", factory);
            var column2 = new Gtk.ColumnViewColumn("Value", factory1);
            list_view.append_column(column1);
            list_view.append_column(column2);

            if (structure != null) {
                for (var index = 0; index < structure.n_fields(); index++) {
                    var field_name = structure.nth_field_name(index);
                    var field_value = structure.get_value(field_name);
                    if (field_value.type() == Type.STRING) {
                        store.append(new GstStructureElement(field_name, field_value));
                    }
                }
            }
            list_view.set_parent(this);
        }

        private void setup(Object obj) {
            var item = obj as Gtk.ListItem;
            var label = new Gtk.Text();
            label.editable = this.editable;
            item.set_child(label);
        }
        
        private void bind(Object obj) {
            var item = obj as Gtk.ListItem;
            var label = item.get_child() as Gtk.Text;
            var data_object = (GstStructureElement) item.get_item();
            label.set_text(data_object.name);
        }
        
        private void setup1(Object obj) {
            var item = obj as Gtk.ListItem;
            var label = new Gtk.Text();
            label.editable = this.editable;
            item.set_child(label);
        }
        
        private void bind1(Object obj) {
            var item = obj as Gtk.ListItem;
            var label = item.get_child() as Gtk.Text;
            var data_object = (GstStructureElement) item.get_item();
            label.set_text(data_object.value.get_string());
        }
    }
}