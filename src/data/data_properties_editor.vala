namespace Data {

    public delegate void DataPropertiesOverrideFunc (PropertyOverridesComposer composer);

    public class DataPropertiesOverrideCallback {
        private PropertyOverridesComposer composer;

        internal DataPropertiesOverrideCallback(DataPropertiesOverrideFunc? overrides_func) {
            this.composer = new PropertyOverridesComposer();

            if (overrides_func != null) {
                overrides_func(composer);
            }
        }

        public Data.DataProperty? build_property(ParamSpec param_spec, GLib.Object data_object) {
            return composer.build_property(param_spec, data_object);
        }
    }

    public class PropertyOverridesComposer {
        private Gee.Map<string, DataPropertyOverrideBuilder> property_builders = new Gee.HashMap<string, DataPropertyOverrideBuilder>();

        internal void override_property(string property_name, DataPropertyBuilderFunc property_func) {
            add_property_override_builder(property_name, new DataPropertyOverrideBuilder(property_func));
        }

        protected void add_property_override_builder(string property_name, DataPropertyOverrideBuilder builder) {
            property_builders.set(property_name, builder);
        }

        internal Data.DataProperty? build_property(ParamSpec param_spec, GLib.Object data_object) {
            var builder = property_builders.get(param_spec.name);
            if (builder == null) {
                return null;
            }
            return builder.build_property(param_spec, data_object);
        }

        internal void copy_to(PropertyOverridesComposer other_composer) {
            foreach (var builder in property_builders) {
                other_composer.add_property_override_builder(builder.key, builder.value);
            }
        }
    }

    protected class DataPropertyOverrideBuilder {
        private DataPropertyBuilderFunc property_func;

        internal DataPropertyOverrideBuilder(DataPropertyBuilderFunc property_func) {
            this.property_func = (param_spec, data_object) => {
                return property_func(param_spec, data_object);
            };
        }

        public Data.DataProperty build_property(GLib.ParamSpec param_spec, GLib.Object data_object) {
            return this.property_func(param_spec, data_object);
        }
    } 

    public delegate Data.DataProperty DataPropertyBuilderFunc (GLib.ParamSpec param_spec, GLib.Object data_object);

    class DataPropertyWrapper : Gtk.Widget {

        public signal void property_value_changed(string property_name, GLib.Value property_value);
        internal signal void object_property_value_changed(GLib.Value new_value);

        private Gtk.Widget property_widget;
        internal bool multiline {
            get;
            private set;
        }

        public bool writable {
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

        public DataPropertyWrapper(GLib.ParamSpec param_spec, GLib.Object data_object, DataPropertiesOverrideCallback? overrides_callback = null) {
            var not_supported_label = new Gtk.Label("");
            not_supported_label.set_markup("<b><span foreground='red'>Not supported type</span></b>: %s".printf(param_spec.value_type.name()));
            not_supported_label.halign = Gtk.Align.START;
            this.property_widget = not_supported_label;

            if ((param_spec.flags & ParamFlags.WRITABLE) == ParamFlags.WRITABLE) {
                this.writable = true;
            }

            var property = override_property(param_spec, data_object, overrides_callback);
            if (property != null) {
                property_widget = property;
            } else {
                if (param_spec is ParamSpecDouble) {
                    property = create_double_property_widget(param_spec as ParamSpecDouble);
                } else if (param_spec is ParamSpecString) {
                    property = create_string_property_widget(param_spec as ParamSpecString);
                } else if (param_spec is ParamSpecBoolean) {
                    property = create_bool_property_widget(param_spec as ParamSpecBoolean);
                } else if (param_spec is ParamSpecInt) {
                    property = create_int_property_widget(param_spec as ParamSpecInt);
                } else if (param_spec is ParamSpecUInt) {
                    property = create_uint_property_widget(param_spec as ParamSpecUInt);
                } else if (param_spec is ParamSpecUInt64) {
                    property = create_uint64_property_widget(param_spec as ParamSpecUInt64);
                } else if (param_spec is ParamSpecEnum) {
                    property = create_enum_property_widget(param_spec as ParamSpecEnum);
                } else {
                    var custom_property_widget = CustomPropertyFactory.get_instance().build(param_spec, data_object);
                    if (custom_property_widget == null) {
                        warning("unhandled property type: %s = %s\n", param_spec.name, param_spec.value_type.name());
                    } else {
                        property = custom_property_widget;
                    }
                }
            }
            if (property != null) {
                property_widget = property;
                multiline = property.multiline;
                
                property.changed.connect(this.property_changed);
                object_property_value_changed.connect(property.set_value_from_model);
            }

            property_widget.valign = Gtk.Align.CENTER;
            property_widget.set_parent(this);

            if (!this.writable) {
                set_tooltip_text("Read only property");
                set_sensitive(false);
            }
        }

        private Data.DataProperty? override_property(ParamSpec param_spec, GLib.Object data_object, DataPropertiesOverrideCallback? overrides_callback) {
            if (overrides_callback == null) {
                return null;
            }
            var property = overrides_callback.build_property(param_spec, data_object);
            if (property != null) {
                var default_value = property.default_value();
                if (default_value != null) {
                    property_changed(param_spec.name, default_value);
                }
                return property;
            }
            return null;
        }

        private Data.DataProperty create_double_property_widget(ParamSpecDouble double_specs) {
            var property = new Data.DoubleProperty(double_specs);
            property.halign = Gtk.Align.START;
            return property;
        }

        private Data.DataProperty create_int_property_widget(ParamSpecInt int_spec) {
            var property = new Data.IntProperty(int_spec);
            return property;
        }

        private Data.DataProperty create_uint_property_widget(ParamSpecUInt uint_spec) {
            var property = new Data.UIntProperty(uint_spec);
            return property;
        }

        private Data.DataProperty create_uint64_property_widget(ParamSpecUInt64 uint64_spec) {
            var property = new Data.UInt64Property(uint64_spec);
            return property;
        }

        private Data.DataProperty create_enum_property_widget(ParamSpecEnum enum_spec) {
            var property = new Data.EnumProperty(enum_spec);
            property.halign = Gtk.Align.START;
            return property;
        }

        private Data.DataProperty create_string_property_widget(ParamSpecString string_spec) {
            var property = new Data.StringProperty(string_spec);
            return property;
        }

        private Data.DataProperty create_bool_property_widget(ParamSpecBoolean bool_spec) {
            var property = new Data.BoolProperty(bool_spec);
            property.halign = Gtk.Align.START;
            return property;
        }

        private void property_changed(string property_name, GLib.Value property_value) {
            property_value_changed(property_name, property_value);
        }
    }

    public delegate bool DataPropertyFilter(GLib.ParamSpec param_spec);

    public delegate Gtk.Widget PropertyDecorator(Gtk.Widget property_widget, GLib.ParamSpec param_spec);

    public class DataPropertiesEditor : Gtk.Widget {

        [Signal (detailed = true)]
		public virtual signal void data_property_changed (string name, GLib.Value value);

        private Gtk.Grid properties_grid;

        private GLib.Object data_object;
        private Gee.Map<string, GLib.Type> changed_properties = new Gee.HashMap<string, GLib.Type>();

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

        public bool populate_properties(DataPropertyFilter filter = param_spec => true, 
                                        DataPropertiesOverrideFunc overrides_func = () => {},
                                        PropertyDecorator property_decorator = widget => widget) {

            int grid_y_count = 0;

            foreach (var param_spec in this.data_object.get_class().list_properties()) {
                if (!filter(param_spec)) {
                    continue;
                }
                this.has_properties = true;

                var property_wrapper = new DataPropertyWrapper(param_spec, data_object, new DataPropertiesOverrideCallback(overrides_func));
                data_object.notify[param_spec.name].connect(property_spec => {
                    GLib.Value value = GLib.Value(property_spec.value_type);
                    data_object.get_property(property_spec.name, ref value);
                    changed_properties.set(property_spec.name, property_spec.value_type);

                    property_wrapper.object_property_value_changed(value);
                });
                property_wrapper.property_value_changed.connect(this.data_property_value_changed);
                property_wrapper.halign = Gtk.Align.FILL;

                properties_grid.attach(property_label(param_spec, property_wrapper.multiline), 0, grid_y_count, 1, 1);
                properties_grid.attach(property_decorator(property_wrapper, param_spec), 1, grid_y_count++, 1, 1);

                var description_label = description_label(param_spec);
                description_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
                if (description_label == null) {
                    continue;
                }
                properties_grid.attach(description_label, 1, grid_y_count++, 1, 1);
            }
        
            return has_properties;
        }

        private void data_property_value_changed(string property_name, GLib.Value property_value) {
            data_object.set_property(property_name, property_value);
            this.data_property_changed(property_name, property_value);
        }

        private Gtk.Label property_label(GLib.ParamSpec param_spec, bool multiline = false) {
            var name = param_spec.get_nick();

            var label = new Gtk.Label("%s:".printf(name[0].to_string().up().concat(name.substring(1))));
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
    }
}