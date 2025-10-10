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

        public ImageDataDisplayNode(string builder_id, ImageDataNode data_node) {
            base (builder_id, data_node, new GtkFlow.NodeDockLabelWidgetFactory(data_node));
            build_default_title();
            
            this.data_display_view = new Data.DataDisplayView();
            this.data_display_view.action_bar_visible = true;
            add_child(data_display_view);

            create_temporary_label();
            create_image_viewer();
            create_window_display_section();
            create_render_button();

            listen_data_node_changes(data_node);
        }

        private void create_temporary_label() {
            this.temporary_label = new Gtk.Label("No data yet");
            temporary_label.vexpand = true;
            data_display_view.add_child(temporary_label);
        }

        private void create_window_display_section() {
            var window_switch = new Gtk.Switch();
            window_switch.valign = Gtk.Align.CENTER;

            var window_label = new Gtk.Label("Show in window");
            window_label.valign = Gtk.Align.CENTER;

            var title_label = new Gtk.Label("Title:");
            title_label.visible = false;
            title_label.valign = Gtk.Align.CENTER;

            var window_title_entry = new Gtk.Entry();
            window_title_entry.placeholder_text = "Image window";
            window_title_entry.hexpand = true;
            window_title_entry.visible = false;
            window_title_entry.valign = Gtk.Align.CENTER;

            window_switch.bind_property("active", window_title_entry, "visible", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            window_switch.bind_property("active", title_label, "visible", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);

            var window_display_section = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            set_margin(window_display_section, 8);

            window_display_section.append(window_label);
            window_display_section.append(window_switch);
            window_display_section.append(title_label);
            window_display_section.append(window_title_entry);

            data_display_view.add_child(new Gtk.Separator(Gtk.Orientation.HORIZONTAL));
            data_display_view.add_child(window_display_section);
        }

        private void set_margin(Gtk.Widget widget, int margin) {
            widget.margin_start = widget.margin_end = widget.margin_top = widget.margin_bottom = margin;
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


        private void listen_data_node_changes(ImageDataNode data_node) {
            data_node.image_changed.connect(this.image_changed);
            data_node.processing_started.connect(() => {
                make_busy(true);
            });
            data_node.processing_finished.connect(() => {
                make_busy(false);
            });
        }
        
        private void create_image_viewer() {
            this.image_viewer = new ImageViewer.with_max_zoom(10);
            this.panning_area = new ImageViewerPanningArea(image_viewer);
            this.panning_area.visible = false;

            data_display_view.add_child(panning_area);
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
            
            this.panning_area.visible = false;
            this.temporary_label.visible = true;

            data_display_view.remove_from_actionbar(this.zoom_control);
            data_display_view.remove_from_actionbar(this.reset_zoom_control);
            data_display_view.remove_from_actionbar(this.save_button_control);
        }
        
        private void image_added(Gdk.Pixbuf added_image) {
            this.current_image = added_image;
            this.image_viewer.replace_image(added_image);
            
            this.temporary_label.visible = false;
            this.panning_area.visible = true;
            panning_area.refresh();

            create_zoom_control();
            create_save_button();
        }
        
        private void image_replaced(Gdk.Pixbuf replaced_image) {
            this.current_image = replaced_image;

            image_viewer.replace_image(replaced_image);
            panning_area.refresh();
        }

        private void render_image() {
            var image_data_node = n as ImageDataNode;
            image_data_node.trigger_process_gegl();
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
        
        private ImageProcessingRealtimeGuard realtime_guard;
        private bool realtime_processing;

        private PadSink gegl_node_sink;
        private Gegl.Node save_as_pixbuf_node;

        ~ImageDataNode() {
            GeglContext.rootNode().remove_child(this.save_as_pixbuf_node);
        }

        public ImageDataNode() {
            base("Image data");
            this.realtime_guard = ImageProcessingRealtimeGuard.instance;
            this.realtime_processing = realtime_guard.enabled;
            this.realtime_guard.mode_changed.connect(this.realtime_mode_changed);
            
            this.save_as_pixbuf_node = GeglContext.rootNode().create_child("gegl:save-pixbuf");
            
            this.gegl_node_sink = new PadSink(save_as_pixbuf_node, "input");
            gegl_node_sink.linked.connect(this.process_gegl);
            gegl_node_sink.unlinked.connect(this.process_gegl);
            gegl_node_sink.name = "Input";
            add_sink(gegl_node_sink);
        }

        private void realtime_mode_changed(bool is_realtime) {
            this.realtime_processing = is_realtime;
        }

        public void trigger_process_gegl() {
            var bbox = Rasterflow.node_get_bounding_box(save_as_pixbuf_node);
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

        internal void process_gegl() {
            if (!realtime_processing) return;

            trigger_process_gegl();
        }

        private void change_image(GLib.Value? value) {
            if (value == null) {
                return;
            }
            image_changed(value as Gdk.Pixbuf);
        }
    }
}