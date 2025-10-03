namespace Image {

    public class ImageDataDisplayNodeBuilder : CanvasNodeBuilder, Object {

        public CanvasDisplayNode create() throws Error{
            return new ImageDataDisplayNode(id(), new ImageDataNode());
        }

        public string name() {
            return "Display image";
        }

        public string id() {
            return "image:display";
        }
    }

    class ImageDataDisplayNode : CanvasDisplayNode {

        private Data.DataDisplayView data_display_view;

        private ImageViewerPanningArea? panning_area;
        private ImageViewer? image_viewer;
        private Gtk.Label? temporary_label; 

        private Gtk.Box zoom_control;
        private Gtk.Box reset_zoom_control;
        private Gtk.Box save_button_control;
        private Gtk.Box render_button_control;
        private Gtk.Button reset_zoom_button;

        private Gdk.Pixbuf? current_image;
        private Data.PropertyGroup? image_details;

        public ImageDataDisplayNode(string builder_id, ImageDataNode data_node) {
            base (builder_id, data_node);
            this.data_display_view = new Data.DataDisplayView();
            add_child(data_display_view);

            data_node.image_changed.connect(this.image_changed);
            data_node.processing_started.connect(() => {
                make_busy(true);
            });

            data_node.processing_finished.connect(() => {
                make_busy(false);
            });

            this.data_display_view.action_bar_visible = true;
            this.temporary_label = new Gtk.Label("No data yet");
            temporary_label.vexpand = true;
            data_display_view.add_child(temporary_label);

            create_render_button();
        }
        
        private void image_changed(Gdk.Pixbuf value) {
            if (value == null) {
                if (current_image != null) {
                    image_removed();
                }
                return;
            }
            if (current_image == null) {
                var pixbuf = value as Gdk.Pixbuf;
                image_added(pixbuf);
                return;
            }
            image_replaced(value as Gdk.Pixbuf);
        }

        private void image_removed() {
            this.current_image = null;
            this.data_display_view.action_bar_visible = false;
            
            data_display_view.remove_property_group(image_details);
            this.image_details = null;
            
            data_display_view.remove_child(this.panning_area);
            data_display_view.remove_from_actionbar(this.zoom_control);
            data_display_view.remove_from_actionbar(this.reset_zoom_control);
            data_display_view.remove_from_actionbar(this.save_button_control);

            data_display_view.add_child(this.temporary_label);
        }
        
        private void image_added(Gdk.Pixbuf added_image) {
            this.current_image = added_image;
            this.image_viewer = new ImageViewer.with_max_zoom(current_image, 10);
            this.panning_area = new ImageViewerPanningArea(image_viewer);
            
            this.image_details = data_display_view.add_property_group("Image details");
            image_details.set_group_property ("Image width", "%d px".printf (current_image.get_width ()));
            image_details.set_group_property ("Image height", "%d px".printf (current_image.get_height ()));
            image_details.set_group_property ("Bits per sample", "%d".printf (current_image.get_bits_per_sample ()));
            image_details.set_group_property ("Number of channels", "%d".printf (current_image.get_n_channels ()));
            current_image.get_options ().foreach ((key, value) => {
                image_details.set_group_property (key, value);
            });
            image_details.refresh();
            
            data_display_view.remove_child(this.temporary_label);
            data_display_view.add_child(this.panning_area);
            
            create_zoom_control();
            create_save_button();
        }
        
        private void image_replaced(Gdk.Pixbuf replaced_image) {
            this.current_image = replaced_image;

            image_details.clear();
            image_details.set_group_property ("Image width", "%d px".printf (current_image.get_width ()));
            image_details.set_group_property ("Image height", "%d px".printf (current_image.get_height ()));
            image_details.set_group_property ("Bits per sample", "%d".printf (current_image.get_bits_per_sample ()));
            image_details.set_group_property ("Number of channels", "%d".printf (current_image.get_n_channels ()));
            current_image.get_options ().foreach ((key, value) => {
                image_details.set_group_property (key, value);
            });
            image_details.refresh();

            image_viewer.replace_image(replaced_image);
            panning_area.refresh();
        }

        private void create_zoom_control() {
            var scale = image_viewer.create_scale_widget();
            this.zoom_control = data_display_view.add_action_bar_child_end(scale);

            this.reset_zoom_button = new Gtk.Button.from_icon_name("zoom-original");
            reset_zoom_button.tooltip_text = "Reset to original size";
            reset_zoom_button.clicked.connect(image_viewer.reset_zoom);
            this.reset_zoom_control = data_display_view.add_action_bar_child_end(reset_zoom_button);
           
            image_viewer.zoom_changed.connect(zoom_value => {
                reset_zoom_button.sensitive = zoom_value != 1; 
            });
        }

        private void create_render_button() {
            var render_button = new Gtk.Button();
            render_button.clicked.connect(render_image);
            render_button.set_tooltip_text("Render image");
            render_button.set_icon_name("media-playback-start");
            this.render_button_control = data_display_view.add_action_bar_child_start(render_button);
        }

        private void render_image() {
            var image_data_node = n as ImageDataNode;
            image_data_node.process_gegl();
        }

        private void create_save_button() {
             var save_button = image_viewer.create_save_image_button();
             save_button.set_icon_name("document-save");
             this.save_button_control = data_display_view.add_action_bar_child_start(save_button);
        }
    }

    class ImageDataNode : CanvasNode, GeglProcessor {

        internal signal void image_changed(Gdk.Pixbuf pixbuf);
        internal signal void processing_started();
        internal signal void processing_finished();
        
        private GFlow.Sink input_image_sink;

        private PadSink gegl_node_sink;
        internal Gegl.Node save_as_pixbuf_node;

        ~ImageDataNode() {
            GeglContext.rootNode().remove_child(this.save_as_pixbuf_node);
        }

        public ImageDataNode() {
            base("Image data");

            input_image_sink = new_sink_with_type("Input image", typeof(Gdk.Pixbuf));
            input_image_sink.before_linking.connect_after(this.can_link_image_sink);
            input_image_sink.changed.connect(this.change_image);
            
            this.save_as_pixbuf_node = GeglContext.rootNode().create_child("gegl:save-pixbuf");
            
            this.gegl_node_sink = new PadSink(save_as_pixbuf_node, "input");
            //  gegl_node_sink.linked.connect(this.process_gegl);
            //  gegl_node_sink.unlinked.connect(this.process_gegl);
            gegl_node_sink.before_linking.connect_after(this.can_link_gegl_sink);
            gegl_node_sink.name = "GEGL node";
            add_sink(gegl_node_sink);
        }

        private bool can_link_gegl_sink(GFlow.Dock self, GFlow.Dock other) {
            return input_image_sink.sources.length() == 0;
        }

        private bool can_link_image_sink(GFlow.Dock self, GFlow.Dock other) {
            return gegl_node_sink.sources.length() == 0;
        }

        private void change_image(GLib.Value? value) {
            if (value == null) {
                return;
            }
            image_changed(value as Gdk.Pixbuf);
        }

        internal void process_gegl() {
            Gegl.Rectangle bbox;
            Rasterflow.node_get_bounding_box(save_as_pixbuf_node, out bbox);

            if (bbox.is_infinite_plane()) {
                log_error("Infinite plane, use crop before.");
                warning("⚠️ Infinite bbox — skipping process()");
                return;
            } else if (bbox.is_empty()) {
                log_warning("Empty plane, nothing to consume.");
                warning("⚠️ Empty bbox — skipping process()");
                return;
            } 
        
            save_as_pixbuf_node.process();
        
            var oper = save_as_pixbuf_node.get_gegl_operation();
            var value = Value(typeof(Gdk.Pixbuf));
            oper.get_property("pixbuf", ref value);
        
            change_image(value);
        }
    }
}