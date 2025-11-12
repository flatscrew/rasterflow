// Copyright (C) 2025 activey
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

namespace Image {
    
    public interface GeglOperationNodeDisplayOverride : Object {
        public abstract void serialize(Serialize.SerializedObject serializer);
        public abstract void deserialize(Serialize.DeserializedObject deserializer);
        public abstract void undo_remove();
    }
    
    public class GeglOperationDisplayNode : CanvasDisplayNode {
        
        private GeglOperationNode gegl_operation_node;
        private GeglOperationNodeDisplayOverride? display_override;
        private GeglOperationOverridesCallback? operation_overrides_callback;
        private Data.DataDisplayView data_display_view;
        private Data.DataPropertiesEditor properties_editor;
        private History.HistoryOfChangesRecorder changes_recorder;
        private CanvasNodeTask current_task;

        public GeglOperationDisplayNode(
            string builder_id, GeglOperationNode node, 
            int x_initial = 10, int y_initial = 10
        ) {
            base(builder_id, node, x_initial, y_initial, new GeglNodePropertyBridgeSinkLabelFactory(node));
            
            this.changes_recorder = History.HistoryOfChangesRecorder.instance;
            this.data_display_view = new Data.DataDisplayView();
            this.gegl_operation_node = node;
            this.gegl_operation_node.sink_added.connect_after(this.sink_added);
            this.gegl_operation_node.processing_started.connect(this.processing_started);
            
            if (gegl_operation_node.is_output_node()) {
                create_process_gegl_button();
            } else {
                create_gegl_export_button();
            }
            
            this.operation_overrides_callback = GeglOperationOverrides.find_operation_overrides(builder_id);
            if (operation_overrides_callback != null) {
                var title_widget = operation_overrides_callback.build_title(gegl_operation_node.get_gegl_operation());
                if (title_widget == null) {
                    build_default_title();
                } else {
                    build_title(new OverridenTitleWidgetBuilder(title_widget));
                }
                
                var overriden_widget = operation_overrides_callback.build_operation(this, gegl_operation_node);
                if (overriden_widget != null) {
                    if (overriden_widget is GeglOperationNodeDisplayOverride) {
                        this.display_override = overriden_widget as GeglOperationNodeDisplayOverride;
                    }
                    
                    add_child(overriden_widget);
                } else {
                    add_default_content(gegl_operation_node.get_gegl_operation());
                }
            } else {
                build_default_title();
                add_default_content(gegl_operation_node.get_gegl_operation());
            }
        }
        
        private void processing_started(CanvasOperationProcessor operation_processor) {
            this.current_task = base.begin_long_running_task();
            make_busy(true);
            
            var finished = false;
            Timeout.add(25, () => {
                if (finished ) {
                    return Source.REMOVE;
                }
                current_task.pulse();
                return Source.CONTINUE;
            });
            
            //  operation_processor.processing_progress.connect(current_task.set_progress);
            operation_processor.finished.connect(() => {
                finished = true;
                current_task.finish();
                make_busy(false);
            });
        }
        
        private void process_gegl() {
            gegl_operation_node.process_gegl();
        }
        
        private void create_process_gegl_button() {
            var render_button = new Gtk.Button.from_icon_name("media-playback-start");
            render_button.clicked.connect(this.process_gegl);
            render_button.set_tooltip_text("Process");
            add_action_bar_child_start(render_button);
        }

        private void create_gegl_export_button() {
            var export_button = new Gtk.Button.from_icon_name("document-export-symbolic");
            export_button.clicked.connect(export_graph_as_xml);
            export_button.set_tooltip_text("Export to XML");
            add_action_bar_child_end(export_button);
        }

        public void add_default_content(Gegl.Operation operation) {
            var scrolled_window = new Gtk.ScrolledWindow();
            scrolled_window.vexpand = scrolled_window.hexpand = true;
            scrolled_window.set_propagate_natural_height(true);
            scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC); 
            scrolled_window.set_placement(Gtk.CornerType.TOP_RIGHT);

            this.properties_editor = new Data.DataPropertiesEditor(operation);
            properties_editor.vexpand = true;
            properties_editor.data_property_changed.connect(this.property_changed);
            properties_editor.enable_control_override(
                this.check_supported_pad_data_type, 
                "Promote as source pad",
                this.on_property_control_taken
            );
            properties_editor.populate_properties(
                () => true,
                compose_overrides
            );

            this.data_display_view.add_child(properties_editor);
            data_display_view.set_margin(10);

            if (properties_editor.has_properties) {
                scrolled_window.set_child(data_display_view);
                add_child(scrolled_window);
            } else {
                n.resizable = false;
                base.can_expand = false;
            }
        }
        
        private void property_changed(string property_name, GLib.Value? property_value) {
            gegl_operation_node.gegl_property_changed();
        }

        private bool check_supported_pad_data_type(GLib.ParamSpec param_spec) {
            return Data.DataPropertyFactory.instance.supports(param_spec);
        }

        private void on_property_control_taken(Data.PropertyControlContract control_contract) {
            var property_sink = gegl_operation_node.add_property_sink(control_contract);
            control_contract.released.connect(() => {
                changes_recorder.record(new PropertyControlContractReleasedAction(
                    control_contract, 
                    property_sink
                ));
            });
            
            changes_recorder.record(new PropertyControlContractAcquiredAction(control_contract, gegl_operation_node));
        }

        private void sink_added(GFlow.Sink new_sink) {
            var canvas_view = get_parent() as GtkFlow.NodeView;
            if (canvas_view == null) {
                return;
            }

            var dock = canvas_view.retrieve_dock(new_sink);
            if (dock == null) {
                warning("Unable to find dock");
            }
            dock.resolve_color.connect_after(this.node_property_sink_edge_color);
        }

        private Gdk.RGBA node_property_sink_edge_color(GtkFlow.Dock dock, Value? value) {
            return {
                red: 0.63f,
                green: 0.63f,
                blue: 0.63f,
                alpha: 1.0f
            };
        }

        private void compose_overrides(Data.PropertyOverridesComposer composer) {
            if (operation_overrides_callback == null) {
                return;
            }
            operation_overrides_callback.copy_property_overrides(composer);
        }

        internal void set_gegl_property(string name, GLib.Value value) {
            gegl_operation_node.get_gegl_operation().set_property(name, value);
        }

        private void export_graph_as_xml () {
            var file_dialog = new Gtk.FileDialog ();
            var filter = new Gtk.FileFilter ();
            filter.name = "GEGL XML graph";
            filter.add_pattern ("*.xml");

            var filters = new GLib.ListStore (typeof (Gtk.FileFilter));
            filters.append (filter);

            file_dialog.set_filters (filters);
            file_dialog.set_initial_name ("untitled.xml");

            file_dialog.save.begin (base.get_ancestor (typeof (Gtk.Window)) as Gtk.Window, null, (obj, res) => {
                try {
                    var file = file_dialog.save.end (res);
                    if (file != null) {
                        string path = file.get_path ();

                        var exporter = new Image.GXml.Exporter ();
                        exporter.export_to (gegl_operation_node.gegl_node, path);

                        message ("Exported graph to: %s", path);
                    }
                } catch (Error e) {
                    warning ("Export cancelled or failed: %s", e.message);
                }
            });
        }
        
        public override void deserialize(Serialize.DeserializedObject deserializer) {
            base.deserialize(deserializer);
            renew_properties_contracts();
            
            if (display_override == null) return;
            display_override.deserialize(deserializer);
        }
        
        public override void serialize(Serialize.SerializedObject serializer) {
            base.serialize(serializer);
            
            if (display_override == null) return;
            display_override.serialize(serializer);
        }
        
        private void renew_properties_contracts() {
            gegl_operation_node.for_each_deserialized_property_as_sink(properties_editor.renew_contract);
        }
        
        public override void undo_remove() {
            if (display_override == null) return;
            display_override.undo_remove();
        }
    }
}