namespace Image {

    public class GeglXmlFileOriginNodeBuilder : Data.FileOriginNodeBuilder {

        public GeglXmlFileOriginNodeBuilder() {
            base("image:gegl-xml");
        }

        protected override void apply_file_data(CanvasDisplayNode node, File file, FileInfo file_info) {
            var xml_node = node as GeglXmlDisplayNode;
            xml_node.set_initial_file_path(file.get_path());
        }
    }

    public class GeglXmlDisplayNodeBuilder : CanvasNodeBuilder, Object {

        public CanvasDisplayNode create(int x, int y) throws Error{
            return new GeglXmlDisplayNode(id(), x, y, new GeglXmlDataNode());
        }

        public string name() {
            return "GEGL XML";
        }

        public override string? description() {
            return "Uses GEGL XML file to build a reusable node.";
        }

        public string id() {
            return "image:gegl-xml";
        }
    }

    public class GeglXmlDisplayNode : CanvasDisplayNode {

        private Gtk.Box box;
        private Gtk.Button file_chooser_button;
        private Gtk.Label file_location_label;
        private Gtk.FileDialog file_dialog; 

        public GeglXmlDisplayNode(string builder_id, int x, int y, GeglXmlDataNode data_node) {
            base (builder_id, data_node, x, y, new GtkFlow.NodeDockLabelWidgetFactory(data_node));
        
            build_default_title();

            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            box.hexpand = box.vexpand = true;
            box.halign = box.valign = Gtk.Align.CENTER;
            box.margin_bottom = box.margin_top = box.margin_start = box.margin_end = 8;
            this.file_location_label = new Gtk.Label("");
            file_location_label.ellipsize = Pango.EllipsizeMode.END;
            file_location_label.add_css_class("property_label_text");

            var filter = new Gtk.FileFilter ();
            filter.name = "GEGL XML graph";
            filter.add_pattern ("*.xml");

            var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
            filters.append (filter);

            this.file_dialog = new Gtk.FileDialog();
            file_dialog.set_filters(filters);

            this.file_chooser_button = new Gtk.Button.with_label("Choose a File");
            file_chooser_button.clicked.connect(() => open_dialog());

            box.append(file_chooser_button);
            box.append(file_location_label);

            add_child(box);
        }

        private void open_dialog() {
            var parent_window = base.get_ancestor(typeof(Gtk.Window)) as Gtk.Window;

            file_dialog.open.begin(parent_window, null, (obj, res) => {
                try {
                    var file = file_dialog.open.end(res);
                    if (file != null) {
                        var path = file.get_path();
                        file_location_label.set_text(path);
                        update_file_path(path);
                    }
                } catch (Error e) {
                    warning("File dialog cancelled or failed: %s", e.message);
                }
            });
        }

        public void set_initial_file_path(string file_path) {
            update_file_path(file_path);
            file_location_label.set_text(file_path);
        }

        private void update_file_path(string new_file_path) {
            var xml_node = n as GeglXmlDataNode;
            xml_node.set_xml_path(new_file_path);
        }
    }

    public class GeglXmlDataNode : CanvasNode, GeglProcessor {

        private Gegl.Node output_proxy;
        private Gegl.Node? xml_node;

        private PadSource source;

        public GeglXmlDataNode() {
            base("GEGL XML Node");

            this.output_proxy = GeglContext.root_node().create_child("gegl:nop");

            this.source = new PadSource(output_proxy, "output");
            source.linked.connect(this.process_gegl);
            source.unlinked.connect(this.process_gegl);
            source.name = "Output";
            add_source(source);
        }

        public void set_xml_path(string path) {
            this.xml_node = new Gegl.Node.from_file(path);
            xml_node.connect_to("output", output_proxy, "input");
        }

        internal void process_gegl() {
            foreach (var source in get_sources()) {
                if (!(source is PadSource)) {
                    continue;
                }
                var pad_source = source as PadSource;
                foreach (var sink in pad_source.sinks) {
                    var target_node = sink.node as GeglProcessor;
                    target_node.process_gegl();
                }
            }
        }
    }
}