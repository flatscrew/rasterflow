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

        protected bool publish_changes = true;

        internal string property_name {
            get {
                return param_spec.name;
            }
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
        }
    }

    class DoubleProperty : AbstractDataProperty {
        
        private Gtk.SpinButton spin_button;

        ~DoubleProperty() {
            spin_button.unparent();
        }

        public DoubleProperty(ParamSpecDouble double_specs) {
            base(double_specs);

            this.spin_button = new Gtk.SpinButton.with_range(double_specs.minimum, double_specs.maximum, 0.1);
            spin_button.value = double_specs.default_value;
            spin_button.value_changed.connect(() => {
                property_value_changed(spin_button.value);
            });

            spin_button.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            spin_button.set_value(value.get_double());
        }
    }

    class IntProperty : AbstractDataProperty {
        
        private Gtk.SpinButton spin_button;
        private bool publish = true;

        ~IntProperty() {
            spin_button.unparent();
        }

        public IntProperty(ParamSpecInt int_specs) {
            base(int_specs);

            this.spin_button = new Gtk.SpinButton.with_range(int_specs.minimum, int_specs.maximum, 1);
            spin_button.value = int_specs.default_value;
            spin_button.value_changed.connect(() => {
                if (!publish) {
                    return;
                }
                property_value_changed((int)spin_button.value);
            });

            spin_button.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            publish = false;
            if (value.type() == Type.INT64) {
                var val = (int) value.get_int64();
                spin_button.set_value(val);
                
                return;
            }
            spin_button.set_value(value.get_int());
            publish = true;
        }
    }

    class UIntProperty : AbstractDataProperty {
        
        private Gtk.SpinButton spin_button;

        ~UIntProperty() {
            spin_button.unparent();
        }

        public UIntProperty(ParamSpecUInt uint_specs) {
            base(uint_specs);

            this.spin_button = new Gtk.SpinButton.with_range(uint_specs.minimum, uint_specs.maximum, 1);
            spin_button.value = uint_specs.default_value;
            spin_button.value_changed.connect(() => {
                property_value_changed((uint) spin_button.value);
            });

            spin_button.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            spin_button.set_value(value.get_uint());
        }
    }

    class UInt64Property : AbstractDataProperty {
        
        private Gtk.SpinButton spin_button;

        ~UInt64Property() {
            spin_button.unparent();
        }

        public UInt64Property(ParamSpecUInt64 uint64_specs) {
            base(uint64_specs);

            this.spin_button = new Gtk.SpinButton.with_range(uint64_specs.minimum, uint64_specs.maximum, 1);
            spin_button.value = uint64_specs.default_value;
            spin_button.value_changed.connect(() => {
                property_value_changed((uint64) spin_button.value);
            });

            spin_button.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            spin_button.set_value(value.get_uint64());
        }
    }

    class EnumProperty : AbstractDataProperty {
        
        private Gtk.ComboBoxText combobox;

        ~EnumProperty() {
            combobox.unparent();
        }

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

            combobox.set_parent(this);
        }
        
        protected override void set_property_value(GLib.Value value) {
            combobox.active = value.get_enum();
        }
    }

    class StringProperty : AbstractDataProperty {
        
        private Gtk.Entry text_entry;

        ~StringProperty() {
            text_entry.unparent();
        }

        public StringProperty(ParamSpecString string_specs) {
            base(string_specs);
            base.set_halign(Gtk.Align.FILL);
            
            this.text_entry = new Gtk.Entry();
            if (string_specs.default_value != null) {
                text_entry.text = string_specs.default_value;
            }
            text_entry.changed.connect(() => {
                property_value_changed(text_entry.text);
            });
            text_entry.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            if (text_entry.text == value.get_string()) return;
            text_entry.set_text(value.get_string());
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

            switch_button.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            switch_button.set_active(value.get_boolean());
        }
    }
}