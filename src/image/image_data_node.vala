namespace Image {
    
    public struct ExternalWindowSate {
        public bool active;
        public string? title;
        public Gdk.Rectangle? dimensions;
    }

    public delegate ExternalWindowSate? ExternalWindowStateDelegate(); 

    public class ImageDataView : Gtk.Widget, GeglOperationNodeDisplayOverride {
        
        private GeglOperationNode node;
        private Data.DataDisplayView data_display_view;
        private ImageViewerPanningArea? panning_area;
        private ImageViewer? image_viewer;
        private Gtk.Label? temporary_label; 

        private Gtk.Box zoom_control;
        private Gtk.Button save_button;

        private Gtk.Switch window_switch;
        private bool window_switch_listen_events;
        private Gtk.Entry window_title_entry;
        private Gtk.Label title_label;
        private ExternalImageWindow? external_window;
        private Gdk.Rectangle? last_window_dimensions;
        private bool external_window_active;
        private Gtk.Box? external_window_info_section;

        private Gdk.Pixbuf? current_image;
        
        construct {
            set_layout_manager(new Gtk.BinLayout());
            vexpand = hexpand = true;
        }
        
        ~ImageDataView() {
            data_display_view.unparent();
        }
        
        public ImageDataView(GeglOperationDisplayNode display_node, GeglOperationNode node) {
            this.node = node;
            this.data_display_view = new Data.DataDisplayView();
            data_display_view.set_parent(this);

            create_temporary_label();
            create_external_window_active_info();
            create_image_viewer();
            create_window_display_section();

            node.processing_started.connect(listen_data_node_changes);
            display_node.removed.connect(this.node_removed);
        }
        
        private void listen_data_node_changes(CanvasOperationProcessor processor) {
            processor.finished.connect(() => {
                var oper = node.get_gegl_operation();
                var value = Value(typeof(Gdk.Pixbuf));
                oper.get_property("pixbuf", ref value);
                
                image_changed(value as Gdk.Pixbuf);
            });
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

        private void create_image_viewer() {
            this.image_viewer = new ImageViewer.with_max_zoom(10);
            this.panning_area = new ImageViewerPanningArea(image_viewer);
            this.panning_area.visible = false;

            data_display_view.add_child(panning_area);
        }
        
        private void create_window_display_section() {
            var window_label = new Gtk.Label("Show in window");
            window_label.valign = Gtk.Align.CENTER;

            this.title_label = new Gtk.Label("Title:");
            title_label.valign = Gtk.Align.CENTER;

            this.window_title_entry = new Gtk.Entry();
            window_title_entry.placeholder_text = "Image window";
            window_title_entry.text = "Image window";
            window_title_entry.hexpand = true;
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

            data_display_view.add_child(window_display_section);
        }
        
        private void set_margin(Gtk.Widget widget, int margin) {
            widget.margin_start = widget.margin_end = widget.margin_top = widget.margin_bottom = margin;
        }
        
        private void create_window_switch() {
            this.window_switch = new Gtk.Switch();
            window_switch.valign = Gtk.Align.CENTER;
            window_switch.bind_property("active", window_title_entry, "sensitive", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
            window_switch.bind_property("active", title_label, "sensitive", BindingFlags.DEFAULT | BindingFlags.SYNC_CREATE);
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
        }

        private void enable_local_image_viewer() {
            external_window_info_section.visible = false;
            if (current_image == null) {
                this.temporary_label.visible = true;
            } else {
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
                external_window.set_dimensions(last_window_dimensions);
            }

            return external_window;
        }

        private bool handle_window_close() {
            this.last_window_dimensions = read_external_window_state().dimensions;
            window_switch.active = false;
            return false;
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

        
        private void node_removed() {
            if (external_window != null) {
                external_window.destroy();
                external_window = null;
            }
            
            this.save_button.visible = false;
            this.zoom_control.visible = false;
        }
        
        private void image_added(Gdk.Pixbuf added_image) {
            replace_image(added_image);
            if (external_window_active) return;
            
            this.temporary_label.visible = false;
            this.panning_area.visible = true;
            this.save_button.visible = true;
            this.zoom_control.visible = true;
        }
        
        private void image_removed() {
            this.current_image = null;
            
            this.save_button.visible = false;
            this.zoom_control.visible = false;
            this.panning_area.visible = false;
            this.temporary_label.visible = true;
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

        public Gtk.Button create_save_button() {
             this.save_button = image_viewer.create_save_image_button();
             save_button.visible = false;
             save_button.set_icon_name("document-save-symbolic");
             return save_button;
        }

        private ExternalWindowSate? read_external_window_state() {
            return ExternalWindowSate() {
                active = external_window_active,
                title = external_window?.get_title(),
                dimensions = external_window?.get_dimensions()
            };
        }
        
        public Gtk.Box create_zoom_control() {
            var scale = image_viewer.create_scale_widget();
            var reset_zoom_button = image_viewer.create_reset_scale_button();
            image_viewer.zoom_changed.connect(zoom_value => {
                reset_zoom_button.sensitive = zoom_value != 1; 
            });
            
            this.zoom_control = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 4);
            zoom_control.append(scale);
            zoom_control.append(reset_zoom_button);
            zoom_control.visible = false;
            return this.zoom_control;
        }
        
        public void serialize(Serialize.SerializedObject serializer) {
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

        public void deserialize(Serialize.DeserializedObject deserializer) {
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
                    this.external_window.set_dimensions(last_window_dimensions);
                }
            }
            this.window_switch_listen_events = true;
        }
        
        public void undo_remove() {
            if (!external_window_active) return;

            disable_local_image_viewer();
            if (external_window == null) {
                external_window = create_external_image_window();
            }

            if (current_image != null)
                    external_window.display_pixbuf(current_image);
        }
    }
}