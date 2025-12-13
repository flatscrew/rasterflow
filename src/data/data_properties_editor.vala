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

namespace Data {

    public delegate void DataPropertiesOverrideFunc(PropertyOverridesComposer composer);

    public class DataPropertiesOverrideCallback {
        private PropertyOverridesComposer composer;

        internal DataPropertiesOverrideCallback(DataPropertiesOverrideFunc? overrides_func) {
            this.composer = new PropertyOverridesComposer();

            if (overrides_func != null) {
                overrides_func(composer);
            }
        }

        public Data.AbstractDataProperty? build_property(ParamSpec param_spec) {
            return composer.build_property(param_spec);
        }
    }

    public class PropertyOverridesComposer {
        private Gee.Map<string, DataPropertyBuilder> property_builders = new Gee.HashMap<string, DataPropertyBuilder>();

        internal void override_property(string property_name, DataPropertyBuilderFunc property_func) {
            add_property_override_builder(property_name, new DataPropertyBuilder(property_func));
        }

        protected void add_property_override_builder(string property_name, DataPropertyBuilder builder) {
            property_builders.set(property_name, builder);
        }

        internal Data.AbstractDataProperty? build_property(ParamSpec param_spec) {
            var builder = property_builders.get(param_spec.name);
            if (builder == null) {
                return null;
            }
            
            return builder.build_property(param_spec);
        }

        internal void copy_to(PropertyOverridesComposer other_composer) {
            foreach (var builder in property_builders) {
                other_composer.add_property_override_builder(builder.key, builder.value);
            }
        }
    }

    protected class DataPropertyBuilder {
        private DataPropertyBuilderFunc property_func;

        internal DataPropertyBuilder(DataPropertyBuilderFunc property_func) {
            this.property_func = (param_spec) => {
                return property_func(param_spec);
            };
        }

        public Data.AbstractDataProperty build_property(GLib.ParamSpec param_spec) {
            return this.property_func(param_spec);
        }
    } 

    public delegate Data.AbstractDataProperty DataPropertyBuilderFunc(GLib.ParamSpec param_spec);

    class DataPropertyWrapper : Gtk.Widget {

        public signal void property_value_changed(string property_name, GLib.Value? property_value);

        private AbstractDataProperty? property_widget;
        
        internal bool multiline {
            get;
            private set;
        }
        
        construct {
            set_layout_manager(new Gtk.BinLayout());
            set_hexpand(true);
        }

        ~DataPropertyWrapper() {
            property_widget.unparent();
        }

        public DataPropertyWrapper(
            GLib.ParamSpec param_spec, 
            AbstractDataProperty data_property_widget
        )
        {
            var writable = false;
            if ((param_spec.flags & ParamFlags.WRITABLE) == ParamFlags.WRITABLE) {
                writable = true;
            }

            this.property_widget = data_property_widget;
            property_widget.valign = Gtk.Align.CENTER;
            property_widget.set_parent(this);
            property_widget.changed.connect(this.property_changed);
            
            if (!writable) {
                set_tooltip_text("Read only property");
                set_sensitive(false);
            }
        }
        
        internal void object_property_value_changed(GLib.Value new_value) {
            property_widget.set_value_from_model(new_value);
        }
        
        private void property_changed(string property_name, GLib.Value? property_value) {
            property_value_changed(property_name, property_value);
        }
    }

    public delegate bool DataPropertyFilter(GLib.ParamSpec param_spec);

    public delegate Gtk.Widget PropertyDecorator(Gtk.Widget property_widget, GLib.ParamSpec param_spec);

    public class PropertiesGridEntry : Object {
        public Gtk.Label property_label;
        public Gtk.Label? description_label;
        public Gtk.Widget property_widget;
        public Gtk.Button? override_button;
    
        public int row_start { get; private set; }
        public int row_span { get; private set; }
    
        public void attach_to_grid(Gtk.Grid grid, ref int current_row) {
            if (override_button != null) {
                grid.attach(override_button, 0, current_row, 1, 1);
            }
    
            grid.attach(property_label, 1, current_row, 1, 1);
            grid.attach(property_widget, 2, current_row, 1, 1);
            row_start = current_row;
    
            if (description_label != null) {
                grid.attach(description_label, 2, ++current_row, 2, 1);
                row_span = 2;
            } else {
                row_span = 1;
            }
    
            current_row++;
        }
    
        public void hide() {
            property_label.visible = false;
            if (property_widget != null) property_widget.visible = false;
            if (description_label != null) description_label.visible = false;
            if (override_button != null) override_button.visible = false;
        }
    
        public void show() {
            property_label.visible = true;
            if (property_widget != null) property_widget.visible = true;
            if (description_label != null) description_label.visible = true;
            if (override_button != null) override_button.visible = true;
        }
    }

    public class DataPropertiesEditor : Gtk.Widget {

        [Signal (detailed = true)]
		public virtual signal void data_property_changed (string name, GLib.Value value);

        private History.HistoryOfChangesRecorder history_recorder; 
        private Gtk.Grid properties_grid;
        private Gee.Map<string, PropertiesGridEntry> entries = new Gee.HashMap<string, PropertiesGridEntry>();
        private GLib.Object data_object;

        private PropertyControlRequestHandler on_take_control;
        private DataPropertyFilter? control_override_filter;
        private bool property_control_override;
        private string take_control_tooltip;
        
        public bool has_properties {
            get;
            private set;
        }

        construct {
            set_layout_manager (new Gtk.BinLayout ());
        }

        ~DataPropertiesEditor() {
            properties_grid.unparent ();
        }

        public DataPropertiesEditor(GLib.Object data_object, int max_width = -1) {
            this.history_recorder = History.HistoryOfChangesRecorder.instance;
            this.data_object = data_object;
            set_size_request(max_width, -1);
            
            this.properties_grid = new Gtk.Grid();
            properties_grid.column_spacing = 5;
            properties_grid.row_spacing = 5;
            properties_grid.vexpand = properties_grid.hexpand = true;
            properties_grid.halign = properties_grid.valign = Gtk.Align.CENTER;
            properties_grid.margin_bottom = properties_grid.margin_top = properties_grid.margin_start = properties_grid.margin_end = 10;

            properties_grid.set_parent (this);
        }

        public bool populate_properties(
            DataPropertiesOverrideFunc overrides_func = () => {},
            PropertyDecorator property_decorator = widget => widget
        ) {
            int row = 0;
            foreach (var param_spec in data_object.get_class().list_properties()) {
                var data_property_widget = override_property(param_spec, new DataPropertiesOverrideCallback(overrides_func));
                if (data_property_widget == null) {
                    var factored_property_widget = DataPropertyFactory.instance.build(param_spec);
                    if (factored_property_widget == null) {
                        warning("unhandled property type: %s = %s\n", param_spec.name, param_spec.value_type.name());
                    } else {
                        data_property_widget = factored_property_widget;
                    }
                }
                if (data_property_widget == null) {
                    continue;
                }
                    
                this.has_properties = true;

                // TODO check if property is supported here and if its not then dont add it at all
                var entry = create_properties_grid_entry(param_spec, data_property_widget, property_decorator);
                entry.attach_to_grid(properties_grid, ref row);
                entries.set(param_spec.name, entry);
            }

            return has_properties;
        }
        
        private Data.AbstractDataProperty? override_property(ParamSpec param_spec, DataPropertiesOverrideCallback overrides_callback) {
            if (overrides_callback == null) {
                return null;
            }
            return overrides_callback.build_property(param_spec);
        }
        
        private PropertiesGridEntry create_properties_grid_entry(
            ParamSpec param_spec,
            AbstractDataProperty data_property_widget,
            PropertyDecorator property_decorator
        ) {
            var property_wrapper = new DataPropertyWrapper(
                param_spec,
                data_property_widget
            );
        
            data_object.notify[param_spec.name].connect(property_spec => {
                GLib.Value value = GLib.Value(property_spec.value_type);
                data_object.get_property(property_spec.name, ref value);
                property_wrapper.object_property_value_changed(value);
            });
        
            property_wrapper.property_value_changed.connect(this.data_property_value_changed);
            property_wrapper.halign = Gtk.Align.FILL;
        
            var desc_label = description_label(param_spec);
            var label = property_label(param_spec, property_wrapper.multiline);
            var property_widget = property_decorator(property_wrapper, param_spec);
        
            var entry = new PropertiesGridEntry() {
                property_label = label,
                description_label = desc_label,
                property_widget = property_widget
            };
        
            // override property control button
            if (property_control_override && param_type_supported_for_control_override(param_spec)) {
                var override_btn = create_property_control_override_button(param_spec, entry);
                entry.override_button = override_btn;
            }
        
            return entry;
        }
        
        private Gtk.Button create_property_control_override_button(
            ParamSpec param_spec,
            PropertiesGridEntry properties_grid_entry
        ) {
            // TODO make it possible to use a custom icon
            var take_property_control_button = new Gtk.Button.from_icon_name("list-add-symbolic");
            take_property_control_button.valign = Gtk.Align.CENTER;
            take_property_control_button.focusable = false;
            
            take_property_control_button.add_css_class("flat");
            take_property_control_button.tooltip_text = this.take_control_tooltip;
            take_property_control_button.clicked.connect(() => {
                properties_grid_entry.hide();

                if (on_take_control != null) {
                    var contract = crate_property_control_contract(param_spec);
                    contract.released.connect(properties_grid_entry.show);
                    contract.renewed.connect(properties_grid_entry.hide);
                    
                    on_take_control(contract);
                }
            });

            return take_property_control_button;
        }
        
        public void renew_contract(string property_name) {
            var param_spec = data_object.get_class().find_property(property_name);
            if (param_spec == null) {
                warning("Unable to find property for contract renewal: %s", property_name);
                return;
            }
            
            if (this.on_take_control == null) return;
            
            var entry = entries.get(property_name);
            if (entry == null) return;
            entry.hide();
            
            var contract = crate_property_control_contract(param_spec);
            contract.released.connect(entry.show);
            contract.renewed.connect(entry.hide);
            
            on_take_control(contract);
        }
        
        private PropertyControlContract crate_property_control_contract(ParamSpec param_spec) {
            var contract = new PropertyControlContract(this, data_object, param_spec);
            contract.property_value_changed.connect((name, value) => {
                data_property_changed(name, value);
            });
            return contract;
        }

        private void data_property_value_changed(string property_name, GLib.Value? property_value) {
            var pspec = data_object.get_class().find_property(property_name);
            if (pspec == null)
                return;
        
            GLib.Value old_value = GLib.Value(pspec.value_type);
            data_object.get_property(property_name, ref old_value);
        
            GLib.Value new_value;
        
            if (property_value == null) {
                new_value = GLib.Value(pspec.value_type);
                var default_value = pspec.get_default_value();
                new_value.copy(ref default_value);
            } else {
                new_value = property_value;
            }
        
            data_object.set_property(property_name, new_value);
        
            history_recorder.record(
                new History.ChangePropertyAction(data_object, property_name, old_value, new_value)
            );
        
            this.data_property_changed(property_name, new_value);
        }
        

        private Gtk.Label property_label(GLib.ParamSpec param_spec, bool multiline = false) {
            var name = param_spec.get_nick();

            var label = new Gtk.Label(name[0].to_string().up().concat(name.substring(1)));
            label.justify = Gtk.Justification.RIGHT;
            label.halign = Gtk.Align.END;

            label.valign = Gtk.Align.CENTER;
            if (multiline) {
                label.valign = Gtk.Align.START;
            }

            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD;
            return label;
        }

        private Gtk.Label? description_label(GLib.ParamSpec param_spec) {
            var description = param_spec.get_blurb();
            if (description == null || description.length == 0) {
                return null;
            }

            var description_label = new Gtk.Label(description);
            description_label.halign = Gtk.Align.START;
            description_label.wrap = true;
            description_label.wrap_mode = Pango.WrapMode.CHAR;
            description_label.add_css_class("property_label_text");
            return description_label;
        }

        public void enable_control_override(
            DataPropertyFilter control_override_filter, 
            string take_control_tooltip,
            PropertyControlRequestHandler on_take_control
        ) {
            this.take_control_tooltip = take_control_tooltip;
            this.property_control_override = true;
            this.control_override_filter = (param_spec) => control_override_filter(param_spec);
            this.on_take_control = (contract) => on_take_control(contract);
        }

        private bool param_type_supported_for_control_override(ParamSpec param_spec) {
            if (control_override_filter == null) return false;
            return control_override_filter(param_spec);
        }
    }
    
    public delegate void PropertyControlRequestHandler(PropertyControlContract contract);
    
    public class PropertyControlContract : Object {
        public signal void released();
        public signal void renewed();
        public signal void property_value_changed(string property_name, GLib.Value? property_value);
        
        public ParamSpec param_spec { public get; private set;}
        private GLib.Object data_object;
    
        private unowned DataPropertiesEditor owner;
    
        public PropertyControlContract(DataPropertiesEditor owner,
                                       GLib.Object data_object,
                                       ParamSpec param_spec) {
            this.owner = owner;
            this.data_object = data_object;
            this.param_spec = param_spec;
        }
    
        public GLib.Value get_value() {
            GLib.Value value = GLib.Value(param_spec.value_type);
            data_object.get_property(param_spec.name, ref value);
            return value;
        }
    
        public void set_value(GLib.Value? value) {
            data_object.set_property(param_spec.name, value);
            property_value_changed(param_spec.name, value);
        }
    
        public void release() {
            released();
        }
        
        public void renew() {
            renewed();
        }
    }
}