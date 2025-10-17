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
        
        public override string? description() {
            return "Displays the image data at this point in the graph. Useful for inspecting intermediate results or debugging node connections.";
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

        private Gtk.Switch window_switch;
        private bool window_switch_listen_events;
        private Gtk.Entry window_title_entry;
        private Gtk.Label title_label;
        private ExternalImageWindow? external_window;
        private Gdk.Rectangle? last_window_dimensions;
        private bool external_window_active;
        private Gtk.Box? external_window_info_section;

        private Gdk.Pixbuf? current_image;

        public ImageDataDisplayNode(string builder_id, ImageDataNode data_node) {
            base (builder_id, data_node, new GtkFlow.NodeDockLabelWidgetFactory(data_node));
            base.removed.connect(this.image_node_removed);
            build_default_title();

            this.data_display_view = new Data.DataDisplayView();
            this.action_bar_visible = true;
            add_child(data_display_view);

            create_temporary_label();
            create_external_window_active_info();
            create_image_viewer();
            create_window_display_section();
            create_render_button();

            listen_data_node_changes(data_node);
        }

        private void image_node_removed(CanvasDisplayNode _) {
            if (external_window != null) {
                external_window.destroy();
                external_window = null;
            }
        }

        public override void undo_remove() {
            if (!external_window_active) return;

            disable_local_image_viewer();
            if (external_window == null) {
                external_window = create_external_image_window();
            }

            if (current_image != null)
                    external_window.display_pixbuf(current_image);
        }

        private void create_temporary_label() {
            this.temporary_label = new Gtk.Label("No data yet");
            temporary_label.vexpand = true;
            set_margin(temporary_label, 10);
            data_display_view.add_child(temporary_label);
        }

        private void create_external_window_active_info() {
            this.external_window_info_section = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            external_window_info_section.visible = false;
            
            var info_label = new Gtk.Label("Rendered in external window");
            info_label.hexpand = info_label.vexpand = true;
            set_margin(info_label, 10);
            external_window_info_section.append(info_label);

            data_display_view.add_child(external_window_info_section);
        }

        private void create_window_display_section() {
            var window_label = new Gtk.Label("Show in window");
            window_label.valign = Gtk.Align.CENTER;

            this.title_label = new Gtk.Label("Title:");
            title_label.visible = false;
            title_label.valign = Gtk.Align.CENTER;

            this.window_title_entry = new Gtk.Entry();
            window_title_entry.placeholder_text = "Image window";
            window_title_entry.text = "Image window";
            window_title_entry.hexpand = true;
            window_title_entry.visible = false;
            window_title_entry.valign = Gtk.Align.CENTER;
            window_title_entry.changed.connect(() => {
                if (external_window != null)
                    external_window.set_title_text(window_title_entry.text);
            });

            create_window_switch();

            var window_display_section = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
            window_display_section.valign = Gtk.Align.CENTER;
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

        private void create_window_switch() {
            this.window_switch = new Gtk.Switch();
            window_switch.valign = Gtk.Align.CENTER;
            window_switch.bind_property("active", window_title_entry, "visible", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            window_switch.bind_property("active", title_label, "visible", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            window_switch.notify["active"].connect(external_window_switch_changed);

            this.window_switch_listen_events = true;
        }

        private void external_window_switch_changed() {
            if (!window_switch_listen_events) return;

            if (window_switch.active) {
                this.external_window_active = true;
                disable_local_image_viewer();

                if (external_window == null) {
                    external_window = create_external_image_window();
                }
                if (current_image != null)
                    external_window.display_pixbuf(current_image);
            } else {
                this.external_window_active = false;
                enable_local_image_viewer();

                if (external_window != null) {
                    external_window.destroy();
                    external_window = null;
                }
            }
        }

        private void disable_local_image_viewer() {
            this.temporary_label.visible = false;
            this.panning_area.visible = false;
            this.external_window_info_section.visible = true;

            remove_from_actionbar(this.zoom_control);
            remove_from_actionbar(this.reset_zoom_control);
            remove_from_actionbar(this.save_button_control);
        }

        private void enable_local_image_viewer() {
            external_window_info_section.visible = false;
            if (current_image == null) {
                this.temporary_label.visible = true;
            } else {
                create_zoom_control();
                create_save_button();
                image_viewer.replace_image(current_image);
                panning_area.visible = true;
            }
        }

        private ExternalImageWindow create_external_image_window() {
            var external_window =  new ExternalImageWindow(window_title_entry.text);
            external_window.close_request.connect(handle_window_close);
            external_window.present();

            if (last_window_dimensions != null) {
                external_window.set_dimensions(
                    last_window_dimensions.x,
                    last_window_dimensions.y,
                    last_window_dimensions.width,
                    last_window_dimensions.height
                );
            }

            return external_window;
        }

        private bool handle_window_close() {
            this.last_window_dimensions = read_external_window_state().dimensions;
            window_switch.active = false;
            return false;
        }

        private void create_zoom_control() {
            var scale = image_viewer.create_scale_widget();
            this.zoom_control = add_action_bar_child_end(scale);

            this.reset_zoom_button = image_viewer.create_reset_scale_button();
            this.reset_zoom_control = add_action_bar_child_end(reset_zoom_button);
           
            image_viewer.zoom_changed.connect(zoom_value => {
                reset_zoom_button.sensitive = zoom_value != 1; 
            });
        }

        private void create_render_button() {
            var render_button = new Gtk.Button();
            render_button.clicked.connect(render_image);
            render_button.set_tooltip_text("Render image");
            render_button.set_icon_name("media-playback-start-symbolic");
            this.render_button_control = add_action_bar_child_start(render_button);
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
            replace_image(value as Gdk.Pixbuf);
        }

        private void image_removed() {
            this.current_image = null;
            this.action_bar_visible = false;
            
            this.panning_area.visible = false;
            this.temporary_label.visible = true;

            remove_from_actionbar(this.zoom_control);
            remove_from_actionbar(this.reset_zoom_control);
            remove_from_actionbar(this.save_button_control);
        }
        
        private void image_added(Gdk.Pixbuf added_image) {
            replace_image(added_image);
            if (external_window_active) return;
            
            this.temporary_label.visible = false;
            this.panning_area.visible = true;

            create_zoom_control();
            create_save_button();
        }
        
        private void replace_image(Gdk.Pixbuf replaced_image) {
            this.current_image = replaced_image;
            
            if (external_window_active) {
                external_window.display_pixbuf(replaced_image);
                return;
            }

            image_viewer.replace_image(replaced_image);
            panning_area.refresh();
        }

        private void render_image() {
            var image_data_node = n as ImageDataNode;
            image_data_node.trigger_process_gegl();
        }

        private void create_save_button() {
             var save_button = image_viewer.create_save_image_button();
             save_button.set_icon_name("document-save-symbolic");
             this.save_button_control = add_action_bar_child_start(save_button);
        }

        private ExternalWindowSate? read_external_window_state() {
            return ExternalWindowSate() {
                active = external_window_active,
                title = external_window?.get_title(),
                dimensions = external_window?.get_dimensions()
            };
        }

        public override void serialize(Serialize.SerializedObject serializer) {
            base.serialize(serializer);

            var state = read_external_window_state();

            var external_window_settings = serializer.new_object("external-window");
            external_window_settings.set_bool("active", state.active);

            if (state.title == null) return;
            external_window_settings.set_string("title", state.title);

            if (state.dimensions == null) return;

            var dimensions = state.dimensions;
            var window_dimensions = external_window_settings.new_object("dimensions");
            window_dimensions.set_int("x", dimensions.x);
            window_dimensions.set_int("y", dimensions.y);
            window_dimensions.set_int("width", (int) dimensions.width);
            window_dimensions.set_int("height", (int) dimensions.height);
        }

        public override void deserialize(Serialize.DeserializedObject deserializer) {
            base.deserialize(deserializer);

            this.window_switch_listen_events = false;

            var external_window_settings = deserializer.get_object("external-window");
            var active = external_window_settings.get_bool("active", false);
            if (active) {
                this.external_window_info_section.visible = true;
                this.temporary_label.visible = false;
                this.external_window_active = true;
                this.window_switch.active = true;
                this.window_title_entry.text = external_window_settings.get_string("title");
                
                this.external_window = new ExternalImageWindow(external_window_settings.get_string("title"));
                this.external_window.close_request.connect(handle_window_close);
                this.external_window.present();

                var dimensions = external_window_settings.get_object("dimensions");
                if (dimensions != null) {
                    var x = dimensions.get_int("x", 0);
                    var y = dimensions.get_int("y", 0);
                    var width = dimensions.get_int("width", 0);
                    var height = dimensions.get_int("height", 0);

                    this.last_window_dimensions = Gdk.Rectangle() {
                        x = x,
                        y = y,
                        width = width,
                        height = height
                    };
                    this.external_window.set_dimensions(x, y, width, height);
                }
            }
            this.window_switch_listen_events = true;
        }
    }

    public struct ExternalWindowSate {
        public bool active;
        public string? title;
        public Gdk.Rectangle? dimensions;
    }

    public delegate ExternalWindowSate? ExternalWindowStateDelegate(); 

    class ImageDataNode : CanvasNode, GeglProcessor {

        internal signal void image_changed(Gdk.Pixbuf pixbuf);
        internal signal void processing_started();
        internal signal void processing_finished();
        
        private ImageProcessingRealtimeGuard realtime_guard;
        private bool realtime_processing;

        private PadSink gegl_node_sink;
        private Gegl.Node save_as_pixbuf_node;

        ~ImageDataNode() {
            GeglContext.root_node().remove_child(this.save_as_pixbuf_node);
        }

        public ImageDataNode() {
            base("Image data");
            this.realtime_guard = ImageProcessingRealtimeGuard.instance;
            this.realtime_processing = realtime_guard.enabled;
            this.realtime_guard.mode_changed.connect(this.realtime_mode_changed);
            
            this.save_as_pixbuf_node = GeglContext.root_node().create_child("gegl:save-pixbuf");
            
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