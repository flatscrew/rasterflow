namespace Data {
    public class DataPropertyFactory : Object {

        private static DataPropertyFactory? _instance;
        public static DataPropertyFactory instance {
            get {
                if (_instance == null)
                    _instance = new DataPropertyFactory();
                return _instance;
            }
        }

        private Gee.Map<GLib.Type, DataPropertyBuilder> typed_builders = new Gee.HashMap<GLib.Type, DataPropertyBuilder>();

        public DataPropertyFactory register(GLib.Type type, DataPropertyBuilderFunc property_func) {
            typed_builders.set(type, new DataPropertyBuilder(property_func));
            return this;
        }

        public Data.AbstractDataProperty? build(ParamSpec? param_spec) {
            if (param_spec == null) {
                warning("Passed null param_spec");
                return null;
            }
            
            var property_type = param_spec.value_type;
            if (param_spec is ParamSpecGType) {
                var gtype = param_spec as ParamSpecGType;
                property_type = gtype.is_a_type;
            }
            
            var builder = typed_builders.get(property_type);
            if (builder == null) {
                if (param_spec is ParamSpecEnum) {
                    // special case for enums
                    var property = new Data.EnumProperty(param_spec as ParamSpecEnum);
                    property.halign = Gtk.Align.START;
                    return property;
                }
            }
        
            if (builder == null)
                return null;
        
            return builder.build_property(param_spec);
        }
        
        public List<GLib.Type> available_types() {
            var list = new List<GLib.Type>();
            foreach (var type in typed_builders.keys)
                list.append(type);
            return list;
        }
    }
    
    public void register_standard_types() {
        var factory = DataPropertyFactory.instance;
        factory.register(typeof(double), create_double_property_widget);
        factory.register(typeof(string), create_string_property_widget);
        factory.register(typeof(bool), create_bool_property_widget);
        factory.register(typeof(int), create_int_property_widget);
        factory.register(typeof(uint), create_uint_property_widget);
        factory.register(typeof(uint64), create_uint64_property_widget);
    }
    
    private Data.AbstractDataProperty create_double_property_widget(ParamSpec double_specs) {
        var property = new Data.DoubleProperty(double_specs as ParamSpecDouble);
        property.halign = Gtk.Align.START;
        return property;
    }

    private Data.AbstractDataProperty create_int_property_widget(ParamSpec int_spec) {
        var property = new Data.IntProperty(int_spec as ParamSpecInt);
        return property;
    }

    private Data.AbstractDataProperty create_uint_property_widget(ParamSpec uint_spec) {
        var property = new Data.UIntProperty(uint_spec as ParamSpecUInt);
        return property;
    }

    private Data.AbstractDataProperty create_uint64_property_widget(ParamSpec uint64_spec) {
        var property = new Data.UInt64Property(uint64_spec as ParamSpecUInt64);
        return property;
    }

    private Data.AbstractDataProperty create_string_property_widget(ParamSpec string_spec) {
        var property = new Data.StringProperty(string_spec as ParamSpecString);
        return property;
    }

    private Data.AbstractDataProperty create_bool_property_widget(ParamSpec bool_spec) {
        var property = new Data.BoolProperty(bool_spec as ParamSpecBoolean);
        property.halign = Gtk.Align.START;
        return property;
    }
}