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

    public abstract class AbstractDataProperty : Gtk.Widget {
        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        internal signal void changed(string name, GLib.Value? value);
        
        internal GLib.ParamSpec param_spec;
        internal bool multiline {
            get;
            private set;
        }

        private Gtk.Widget? child;
        protected bool publish_changes = true;

        internal string property_name {
            get {
                return param_spec.name;
            }
        }

        ~AbstractDataProperty() {
            if (child == null) return;
            
            child.unparent();
        }
        
        protected AbstractDataProperty(GLib.ParamSpec param_spec, bool multiline = false) {
            this.param_spec = param_spec;
            this.multiline = multiline;

            set_halign(Gtk.Align.START);
        }

        protected void property_value_changed(GLib.Value? new_value) {
            if (!publish_changes) {
                return;
            }
            changed(param_spec.name, new_value);
        }

        internal virtual GLib.Value? default_value() {
            return this.param_spec.get_default_value();
        }

        internal void set_value_from_model(GLib.Value value) {
            this.publish_changes = false;
            set_property_value(value);
            this.publish_changes = true;
        }

        internal virtual void set_property_value(GLib.Value value) {

        }
        
        protected void set_child(Gtk.Widget child) {
            child.set_parent(this);
            this.child = child;
        }
    }
    
    enum NumericPropertyType {
        Double,
        Int,
        UInt,
        UInt64
    }
    
    class NumericProperty : AbstractDataProperty {

        private NumericPropertyType property_type;
        private Data.SpinButtonEntry spin_button;
        private double last_published;
        private uint publish_timeout_id = 0;
        
        ~NumericProperty() {
            spin_button.unparent();
        }
    
        public NumericProperty(ParamSpec param_spec, double min, double max, double default_value, double step) {
            base(param_spec);
            
            this.spin_button = new Data.SpinButtonEntry.with_range(
                min,
                max,
                step
            );
            spin_button.value = default_value;
            spin_button.value_changed.connect(schedule_publish);
            set_child(spin_button);
        }
        
        public NumericProperty.from_double(ParamSpecDouble double_specs) {
            this(double_specs, double_specs.minimum, double_specs.maximum, double_specs.default_value, 0.1);
            this.property_type = NumericPropertyType.Double;
        }
        
        public NumericProperty.from_int(ParamSpecInt int_specs) {
            this(int_specs, int_specs.minimum, int_specs.maximum, int_specs.default_value, 1);
            this.property_type = NumericPropertyType.Int;
        }
        
        public NumericProperty.from_uint(ParamSpecUInt int_specs) {
            this(int_specs, int_specs.minimum, int_specs.maximum, int_specs.default_value, 1);
            this.property_type = NumericPropertyType.UInt;
        }
        
        public NumericProperty.from_uint64(ParamSpecUInt64 int_specs) {
            this(int_specs, int_specs.minimum, int_specs.maximum, int_specs.default_value, 1);
            this.property_type = NumericPropertyType.UInt64;
        }
        
        private void schedule_publish() {
            if (publish_timeout_id > 0)
                GLib.Source.remove(publish_timeout_id);
        
            publish_timeout_id = GLib.Timeout.add(120, () => {
                publish_timeout_id = 0;
                
                double current = spin_button.value;
                if (current != last_published) {
                    last_published = current;
                    property_value_changed(current);
                }
                
                return GLib.Source.REMOVE;
            });
        }
        
        protected override void set_property_value(GLib.Value value) {
            double v = 0;
        
            switch (property_type) {
                case NumericPropertyType.Double: {
                    v = value.get_double();
                    break;
                }
                
                case NumericPropertyType.Int: {
                    v = value.get_int();
                    break;
                }
                
                case NumericPropertyType.UInt: {
                    v = value.get_uint();
                    break;
                }
                
                case NumericPropertyType.UInt64: {
                    v = value.get_uint64();
                    break;
                }
            }
            
            if (v != spin_button.value) {
                //  spin_button.set_value(v);
                spin_button.value = v;
                
                last_published = v;
            }
        }
    }
    
    class EnumProperty : AbstractDataProperty {
        
        private Gtk.ComboBoxText combobox;

        public EnumProperty(ParamSpecEnum enum_specs) {
            base(enum_specs);

            this.combobox = new Gtk.ComboBoxText();

            unowned EnumClass enumc = enum_specs.enum_class;
            for (int i = enumc.minimum; i <= enumc.maximum; i++) {
                EnumValue? v = enumc.get_value(i);
                if (v == null) continue;
                
                combobox.append_text(v.value_name);
            }

            combobox.active = enum_specs.default_value;
            combobox.changed.connect(() => {
                EnumValue? v = enumc.get_value(combobox.get_active());
                property_value_changed(v.value);
            });

            set_child(combobox);
        }
        
        protected override void set_property_value(GLib.Value value) {
            combobox.active = value.get_enum();
        }
    }

    class StringProperty : AbstractDataProperty {
        
        private Gtk.Entry text_entry;
        private string last_published = "";
        
        public StringProperty(ParamSpecString string_specs) {
            base(string_specs);
            base.set_halign(Gtk.Align.FILL);
            
            this.text_entry = new Gtk.Entry();
            if (string_specs.default_value != null) {
                text_entry.text = string_specs.default_value;
            }
            text_entry.activate.connect(update_property_if_changed);

            var focus_ctrl = new Gtk.EventControllerFocus();
            focus_ctrl.leave.connect(update_property_if_changed);
            text_entry.add_controller(focus_ctrl);
            
            set_child(text_entry);
        }
        
        private void update_property_if_changed() {
            var current = text_entry.text;
            if (current != last_published) {
                last_published = current;
                property_value_changed(current);
            }
        }

        protected override void set_property_value(GLib.Value value) {
            if (text_entry.text == value.get_string()) return;
            text_entry.set_text(value.get_string());
            last_published = value.get_string();
        }
    }

    class BoolProperty : AbstractDataProperty {
        
        private Gtk.Switch switch_button;

        ~BoolProperty() {
            switch_button.unparent();
        }

        public BoolProperty(ParamSpecBoolean bool_specs) {
            base(bool_specs);

            this.switch_button = new Gtk.Switch();
            switch_button.active = bool_specs.default_value;
            switch_button.notify["active"].connect(() => {
                property_value_changed(switch_button.active);
            });

            set_child(switch_button);
        }

        protected override void set_property_value(GLib.Value value) {
            switch_button.set_active(value.get_boolean());
        }
    }
}