namespace Image {

    public class ImageResizeNodeBuilder : CanvasNodeBuilder, Object {

        public CanvasDisplayNode create() throws Error{
            return new ImageResizeNodeView(id(), new ImageResizeNode());
        }

        public string name() {
            return "Resize image";
        }

        public string id() {
            return "image:resize";
        }
    }

    public class ImageResizeNode : CanvasNode {
        
        private Gdk.Pixbuf? pixbuf;
        private CanvasNodeSource resized_image_source;
        private CanvasNodeSink input_data_sink;
        internal CanvasNodeSink image_width_sink;
        internal CanvasNodeSink image_height_sink;

        private double width_percentage = 100d;
        private double height_percentage = 100d;
        
        public ImageResizeNode() {
            base("Resize image");
            resizable = false;

            image_width_sink = new_sink_with_type("Width", typeof(int));
            image_width_sink.changed.connect(value => {
                if (value == null) {
                    return;
                }
                width_changed(value.get_double());
            });
            image_height_sink = new_sink_with_type("Height", typeof(int));
            image_height_sink.changed.connect(value => {
                if (value == null) {
                    return;
                }
                height_changed(value.get_double());
            });

            input_data_sink = new_sink_with_type ("Input image data", typeof(Gdk.Pixbuf));
            input_data_sink.changed.connect(value => {
                this.pixbuf = value as Gdk.Pixbuf;
                resize_image();
            });
            resized_image_source = new_source_with_type("Resized image", typeof(Gdk.Pixbuf));
        }

        private void width_changed(double new_with) {
            this.width_percentage = new_with;
            resize_image();
        }

        private void height_changed(double new_height) {
            this.height_percentage = new_height;
            resize_image();
        }

        private void resize_image() {
            if (pixbuf == null) {
                try{
                    resized_image_source.set_value(null);
                } catch (Error e) {
                    error(e.message);                    
                }
                return;
            }
            var new_width = (int) (width_percentage / 100 * pixbuf.get_width());
            var new_height = (int) (height_percentage / 100 * pixbuf.get_height());
            var resized = pixbuf.scale_simple(new_width, new_height, Gdk.InterpType.BILINEAR);
            
            try {
                resized_image_source.set_value(resized);
            } catch (Error e) {
                error(e.message);                    
            }
        } 

        protected override void serialize(Serialize.SerializedObject object) {
            base.serialize(object);

            object.set_double("width", width_percentage);
            object.set_double("height", height_percentage);
        }

        protected override void deserialize(Serialize.DeserializedObject object) {
            var width = 0d;
            width = object.get_double("width");

            var height = 0d;
            height = object.get_double("height");

            image_width_sink.changed(width);
            image_height_sink.changed(height);
        }
    }

    class ImageResizeDockLabelFactory : GtkFlow.NodeDockLabelWidgetFactory {
       
        private Gtk.SizeGroup label_size_group = new Gtk.SizeGroup(Gtk.SizeGroupMode.HORIZONTAL);
        private Gtk.SpinButton width_range;
        private Gtk.SpinButton height_range;

        private ImageResizeNode image_resize_node;

        public ImageResizeDockLabelFactory(GFlow.Node node) {
            base(node);
            this.image_resize_node = node as ImageResizeNode;
        }

        public override Gtk.Widget create_dock_label(GFlow.Dock dock) {
            if (dock == image_resize_node.image_width_sink) {
                var width_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
                this.width_range = new Gtk.SpinButton.with_range(1d, 1000d, 1d);
                width_range.set_value(100d);

                //  unowned Gtk.SpinButton weak_range = width_range;
                width_range.value_changed.connect(() => {
                    image_resize_node.image_width_sink.changed(width_range.value);
                });
                image_resize_node.image_width_sink.changed.connect(value => {
                    if (value == null) {
                        return;
                    }
                    width_range.set_value(value.get_double());
                });
                width_box.append(property_label("Width:"));
                width_box.append(width_range);
                width_box.append(new Gtk.Label("%"));
                return width_box;
            } else if (dock == image_resize_node.image_height_sink) {
                var height_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
                this.height_range = new Gtk.SpinButton.with_range(1d, 1000d, 1d);
                height_range.set_value(100d);
                height_range.value_changed.connect(() => {
                    image_resize_node.image_height_sink.changed(height_range.value);
                });
                image_resize_node.image_height_sink.changed.connect(value => {
                    if (value == null) {
                        return;
                    }
                    height_range.set_value(value.get_double());
                });
                height_box.append(property_label("Height:"));
                height_box.append(height_range);
                height_box.append(new Gtk.Label("%"));
                return height_box;
            }
            return base.create_dock_label(dock);
        }

        private Gtk.Label property_label(string text) {
            var label = new Gtk.Label(text);
            label.halign = Gtk.Align.END;
            label.justify = Gtk.Justification.RIGHT;
            label_size_group.add_widget(label);
            return label;
        }
    }

    class ImageResizeNodeView : CanvasDisplayNode {

        public ImageResizeNodeView(string builder_id, ImageResizeNode node) {
            base.with_icon(builder_id, node, null, new ImageResizeDockLabelFactory(node));
        }
    }
}