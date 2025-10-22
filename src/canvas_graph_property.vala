
private class ParamSpecFactory : Object {
    
    private ParamSpecDelegate del;
    
    public ParamSpecFactory(ParamSpecDelegate param_delegate) {
        this.del = (name, nick, blurb) => {
            return param_delegate(name, nick, blurb);
        };
    } 
    
    public ParamSpec create(string name, string nick, string blurb) {
        return del(name, nick, blurb);
    }
}

private delegate ParamSpec ParamSpecDelegate (string name, string nick, string blurb);

public class CanvasGraphProperty : Object {
    
    public string name { public get; construct; }
    public string label { public get; construct; }
    public string readable_name {
        get {
            return label == null || label.length == 0 ? name : label;
        }
    }
    
    public GLib.Type property_type { public get; construct; }
    public GLib.Value property_value {public get; private set; }
    public ParamSpec param_spec { get; private set; }
    
    private static GLib.HashTable<GLib.Type, ParamSpecFactory> param_spec_factories;    
        
    static construct {
        param_spec_factories = new GLib.HashTable<GLib.Type, ParamSpecFactory> (GLib.direct_hash, GLib.direct_equal);
    
        param_spec_factories.insert (typeof (int),
            new ParamSpecFactory ((n, nick, blurb) =>
                new ParamSpecInt (n, nick, blurb, int.MIN, int.MAX, 0, ParamFlags.READWRITE)));
    
        param_spec_factories.insert (typeof (uint),
            new ParamSpecFactory ((n, nick, blurb) =>
                new ParamSpecUInt (n, nick, blurb, 0u, uint.MAX, 0u, ParamFlags.READWRITE)));
    
        param_spec_factories.insert (typeof (uint64),
            new ParamSpecFactory ((n, nick, blurb) =>
                new ParamSpecUInt64 (n, nick, blurb, 0u, uint64.MAX, 0u, ParamFlags.READWRITE)));
    
        param_spec_factories.insert (typeof (float),
            new ParamSpecFactory ((n, nick, blurb) =>
                new ParamSpecFloat (n, nick, blurb, float.MIN, float.MAX, 0f, ParamFlags.READWRITE)));
    
        param_spec_factories.insert (typeof (double),
            new ParamSpecFactory ((n, nick, blurb) =>
                new ParamSpecDouble (n, nick, blurb, -10d, 10d, 0d, ParamFlags.READWRITE)));
    
        param_spec_factories.insert (typeof (bool),
            new ParamSpecFactory ((n, nick, blurb) =>
                new ParamSpecBoolean (n, nick, blurb, false, ParamFlags.READWRITE)));
    
        param_spec_factories.insert (typeof (string),
            new ParamSpecFactory ((n, nick, blurb) =>
                new ParamSpecString (n, nick, blurb, "", ParamFlags.READWRITE)));
    }
    
    public CanvasGraphProperty.from_value(string name, string label, GLib.Value property_value) {
        Object(name: name, label: label, property_type: property_value.type());
        this.param_spec = create_default_param_spec (name, property_value.type());
        this.property_value = property_value;
    }
    
    public CanvasGraphProperty(string name, string label, GLib.Type property_type) {
        Object(name: name, label: label, property_type: property_type);
        this.param_spec = create_default_param_spec (name, property_type);
    }
    
    public bool set_value (GLib.Value new_value) {
        if (new_value.type() != property_type) {
            warning ("Type mismatch when setting value for property '%s': expected %s, got %s",
                     name,
                     property_type.name(),
                     new_value.type().name());
            return false;
        }

        property_value = new_value;
        return true;
    }
    
    public virtual void serialize(Serialize.SerializedObject serializer) {
        serializer.set_string("name", name);
        serializer.set_string("label", label);
        serializer.set_string("type", property_type.name());
        serializer.set_value("value", property_value);
    }
    
    private ParamSpec create_default_param_spec (string name, GLib.Type type) {
        var f = param_spec_factories.lookup (type);
        if (f != null)
            return f.create(name, name, "");
        message ("Could not recognize type: %s, fallback to ParamSpecGType...", type.name ());
        return new ParamSpecGType (name, name, "", type, ParamFlags.READWRITE);
    }
}