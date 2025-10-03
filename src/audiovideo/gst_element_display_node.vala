namespace AudioVideo {

    class RemovePadButton : Gtk.Widget {

        private Gst.Pad pad;
        private Gtk.Button remove_button;

        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        public RemovePadButton(Gst.Pad pad) {
            this.pad = pad;
            
            this.remove_button = new Gtk.Button.from_icon_name("edit-delete-symbolic");
            remove_button.add_css_class("destructive");
            remove_button.clicked.connect(this.button_clicked);        
            remove_button.set_parent(this);
        }

        private void button_clicked() {
            var parent = pad.get_parent_element();
            if (parent != null) {
                parent.remove_pad(this.pad);
            } else {
                warning("No parent for pad!!!");
            }
        }

        internal void element_state_changed(Gst.State new_state) {
            sensitive = new_state <= Gst.State.READY;
        }

        ~RemovePadButton() {
            remove_button.unparent();
        }
    }

    class GstElementDockLabelFactory : GtkFlow.NodeDockLabelWidgetFactory {
        
        internal GstElementDockLabelFactory(GstElementNode node) {
            base(node);
        }

        public override Gtk.Widget create_dock_label (GFlow.Dock dock) {
            var dock_label = new Gtk.Label(dock.name);
            dock_label.valign = Gtk.Align.CENTER;

            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            box.margin_bottom = box.margin_top = 5;
            box.hexpand = true;

            if (dock is GFlow.SimpleSink) {
                box.halign = Gtk.Align.START;
                box.append(dock_label);

                if (dock is AudioVideo.GstElementSinkPad) {
                    unowned var pad_sink = dock as AudioVideo.GstElementSinkPad;
                    var caps = pad_sink.current_caps();
    
                    box.append(new GstCapabilitiesViewToggle(caps));
                    box.append(new Data.DataPropertiesToggle(pad_sink.pad));
                    
                    if (pad_sink.requested_by_hand) {
                        var gst_node = node as GstElementNode;
                        var remove_button = new RemovePadButton(pad_sink.pad);
                        gst_node.state_changed.connect(remove_button.element_state_changed);
                        box.append(remove_button);
                    }
                }
            } else if (dock is GFlow.SimpleSource) {
                box.halign = Gtk.Align.END;

                if (dock is AudioVideo.GstElementSourcePad) {
                    var pad_source = dock as AudioVideo.GstElementSourcePad;
                    var caps = pad_source.current_caps();
    
                    if (pad_source.requested_by_hand) {
                        var gst_node = node as GstElementNode;
                        var remove_button = new RemovePadButton(pad_source.pad);
                        gst_node.state_changed.connect(remove_button.element_state_changed);
                        box.append(remove_button);
                    }

                    box.append(new GstCapabilitiesViewToggle(caps));
                    box.append(new Data.DataPropertiesToggle(pad_source.pad));
                } 
                box.append(dock_label);
            }

            if (dock is GstExpectingSinkPad || dock is GstExpectedSourcePad) {
                dock_label.add_css_class("gst_expected_pad_label");
            }
            return box;
        }
    }

    class GstElementPropertyDecorator : Gtk.Widget {

        private Gtk.Box property_box;
        private Gtk.Widget property_widget;
        private Gtk.Image locked_icon;
        
        private bool mutable_when_ready;
        private bool mutable_when_paused;
        private bool mutable_when_playing;
        
        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        ~GstElementPropertyDecorator() {
            property_box.unparent();
        }

        public GstElementPropertyDecorator(Gtk.Widget property_widget, GLib.ParamSpec param_spec) {
            this.property_widget = property_widget;
            this.property_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
            
            if ((param_spec.flags & Gst.PARAM_MUTABLE_READY) == Gst.PARAM_MUTABLE_READY) {
                this.mutable_when_ready = true;
            }
            if ((param_spec.flags & Gst.PARAM_MUTABLE_PAUSED) == Gst.PARAM_MUTABLE_PAUSED) {
                this.mutable_when_paused = true;
            }
            if ((param_spec.flags & Gst.PARAM_MUTABLE_PLAYING) == Gst.PARAM_MUTABLE_PLAYING) {
                this.mutable_when_playing = true;
            }

            this.locked_icon = new Gtk.Image.from_icon_name("changes-prevent-symbolic");
            locked_icon.visible = false;
            locked_icon.set_tooltip_text("Editable only when pipeline is unlocked");
            property_box.append(property_widget);
            property_box.append(locked_icon);
            property_box.set_parent(this);
        }

        internal void element_state_changed(Gst.State new_state) {
            if (mutable_when_ready) {
                sensitive = new_state <= Gst.State.READY;
                locked_icon.visible = !sensitive;
                return;
            }
            locked_icon.visible = false;
            sensitive = true;
        }
    }

    class GstElementDisplayNode : CanvasDisplayNode {

        private const string[] FORBIDDEN_PARAMETERS = {
            "parent"
        };

        private GstElementOverridesCallback? overrides_callback;
        private GstElementNode gst_node;

        public GstElementDisplayNode(string builder_id, GstElementNode node) {
            base.with_icon(builder_id, node, null, new GstElementDockLabelFactory(node));
            this.gst_node = node;
            this.overrides_callback = GstElementOverrides.find_element_overrides(node.gst_operation);

            if (overrides_callback != null) {
                var overriden_widget = overrides_callback.build_element(node.gst_element);
                if (overriden_widget != null) {
                    add_child(overriden_widget);
                } else {
                    add_default_content();
                }
            } else {
                add_default_content();
            }

            color_expected_pads();
            create_request_pads_buttons();
            create_dump_dot_button();

            listen_element_state_changes();
        }
        
        private void add_default_content() {
            var scrolled_window = new Gtk.ScrolledWindow();
            scrolled_window.vexpand = scrolled_window.hexpand = true;
            scrolled_window.set_propagate_natural_height(true);
            scrolled_window.set_min_content_height(150);
            scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC); 
            scrolled_window.set_placement(Gtk.CornerType.TOP_RIGHT);

            var properties_editor = new Data.DataPropertiesEditor(gst_node.gst_element);

            properties_editor.populate_properties(
                is_allowed_property, 
                compose_overrides,
                (property_widget, param_spec) => {
                    var decorator =  new GstElementPropertyDecorator(property_widget, param_spec);
                    gst_node.state_changed.connect(decorator.element_state_changed);
                    decorator.element_state_changed(gst_node.current_state());
                    return decorator;
                }
            );

            if (properties_editor.has_properties) {
                scrolled_window.set_child(properties_editor);
                add_child(scrolled_window);
            } else {
                n.resizable = false;
            }
        }

        private void compose_overrides(Data.PropertyOverridesComposer composer) {
            if (overrides_callback == null) {
                return;
            }
            overrides_callback.copy_property_overrides(composer);
        }

        private void color_expected_pads() {
            var node = n as GstElementNode;
            node.dynamic_source_added.connect(this.source_added);

            var expected_sink = node.expecting_sink;
            if (expected_sink != null) {
                var expeced_dock = retrieve_dock(node.expecting_sink);
                expeced_dock.resolve_color.connect_after((d,v)=>{ return {0.2980392157f, 0.6862745098f, 0.3137254902f, 1.0f};});
            }

            var expected_source = node.expected_source;
            if (expected_source != null) {
                var expeced_dock = retrieve_dock(node.expected_source);
                expeced_dock.resolve_color.connect_after((d,v)=>{ return {0.2980392157f, 0.6862745098f, 0.3137254902f, 1.0f};});
            }
        }

        private void source_added(GstElementSourcePad source_pad) {
            if (source_pad.requested_by_hand) {
                return;
            }
            var dock = retrieve_dock(source_pad);
            dock.resolve_color.connect_after((d,v)=>{ return {0.3607843137f, 0.0f, 0.8235294118f, 1.0f};});
        }

        private void create_request_pads_buttons() {
            var node = n as GstElementNode;
            if (node.has_request_sources) {
                var add_source_button = new RequestElementPadButton(node.gst_element, Gst.PadDirection.SRC);
                add_source_button.tooltip_text = "Add source";
                title_bar.append_right(add_source_button);
            }
            if (node.has_request_sinks) {
                var add_sink_button = new RequestElementPadButton(node.gst_element, Gst.PadDirection.SINK);
                add_sink_button.tooltip_text = "Add sink";
                title_bar.append_left(add_sink_button);
            }
        }

        private void listen_element_state_changes() {
            var node = n as GstElementNode;
            node.state_changed.connect(this.element_state_changed);
            element_state_changed(node.current_state());
        }

        private void element_state_changed(Gst.State new_state) {
            base.can_delete = new_state <= Gst.State.READY;
        }

        private bool is_allowed_property(GLib.ParamSpec param_spec) {
            foreach (var forbidden in FORBIDDEN_PARAMETERS) {
                if (param_spec.name == forbidden) {
                    return false;
                }
            }
            return true;
        }

        private void create_dump_dot_button() {
            if (Environment.get_variable("GST_DEBUG_DUMP_DOT_DIR") == null) {
                return;
            }
            var button = new Gtk.Button();
            button.set_icon_name("document-save");
            button.clicked.connect(() => {
                GstPipeline.get_current().dump_to_dot();
            });

            title_bar.append_left(button);
        }

        internal void set_gst_property(string name, GLib.Value value) {
            gst_node.set_element_property(name, value);
        }
    }
}