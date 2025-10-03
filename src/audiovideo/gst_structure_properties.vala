namespace AudioVideo {

    delegate TypedProperty TypedPropertyBuilder();

    class TypedPropertyWrapper : Gtk.Widget {

        internal signal void value_changed(GLib.Value value);

        private TypedProperties typed_properties;
        private TypedProperty? property;

        ~TypedPropertyWrapper() {
            if (property != null) {
                property.unparent();
            }
        }

        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        public TypedPropertyWrapper(TypedProperties typed_properties) {
            this.typed_properties = typed_properties;
        }

        public void set_value(GLib.Value value) {
            if (property == null) {
                return;
            }
            property.set_value_from_model(value);
        }

        public void change_type(GLib.Type type) {
            if (this.property != null) {
                this.property.unparent();
            }

            this.property = typed_properties.build(type);
            property.changed.connect(this.property_changed);

            if (property != null) {
                property.set_parent(this);
            }
        }

        private void property_changed(GLib.Value value) {
            value_changed(value);
        }
    }

    class TypedPropertyFactory : Object {

      private TypedPropertyBuilder builder; 

      public TypedPropertyFactory(TypedPropertyBuilder builder) {
        this.builder = () => {
            return builder();
        };
      }
      
      public TypedProperty build_property() {
        return builder();
      }
    }

    public class TypedProperties : Object {

      private Gee.Map<GLib.Type, TypedPropertyFactory> factories = new Gee.HashMap<GLib.Type, TypedPropertyFactory>();

      construct {
        new_builder(Type.STRING, () => {
          return new StringProperty();
        });

        new_builder(Type.INT, () => {
            return new IntProperty();
          });

        new_builder(typeof(Gst.Fraction), () => {
            return new GstFractionProperty();
        });
      }

      private void new_builder(GLib.Type type, TypedPropertyBuilder builder) {
        factories.set(type, new TypedPropertyFactory(builder));
      }

      public TypedProperty? build(GLib.Type type) {
        var factory = factories.get(type);
        if (factory == null) {
            return null;
        }
        return factory.build_property();
      }

      public Gee.Set<GLib.Type> supported_types() {
        return factories.keys;
      }
    }

    public abstract class TypedProperty : Gtk.Widget {
        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        internal signal void changed(GLib.Value value);
        
        protected bool publish_changes = true;

        protected void property_value_changed(GLib.Value new_value) {
            if (!publish_changes) {
                return;
            }
            changed(new_value);
        }

        internal void set_value_from_model(GLib.Value value) {
            this.publish_changes = false;
            set_property_value(value);
            this.publish_changes = true;
        }

        protected virtual void set_property_value(GLib.Value value) {

        }

        protected void set_child(Gtk.Widget child) {
            child.set_parent(this);
        }
    }

    class StringProperty : TypedProperty {
        
        private Gtk.Entry text_entry;

        ~StringProperty() {
            text_entry.unparent();
        }

        public StringProperty() {
            this.text_entry = new Gtk.Entry();
            text_entry.changed.connect(() => {
                property_value_changed(text_entry.text);
            });
            text_entry.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            if (text_entry != null) {
                text_entry.set_text(value.get_string());
            }
        }
    }

    class IntProperty : TypedProperty {
        
        private Gtk.SpinButton spin_button;

        ~IntProperty() {
            spin_button.unparent();
        }

        public IntProperty() {
            this.spin_button = new Gtk.SpinButton.with_range(0, 999999999, 1.0);
            spin_button.value_changed.connect(() => {
                property_value_changed(spin_button.get_value_as_int());
            });
            spin_button.set_parent(this);
        }

        protected override void set_property_value(GLib.Value value) {
            if (spin_button != null) {
                spin_button.set_value(value.get_int());
            }
        }
    }

    class GstFractionProperty : TypedProperty {

        private Gtk.Box box;
        private Gtk.SpinButton numerator;
        private Gtk.SpinButton denominator;

        ~GstFractionProperty() {
            box.unparent();
        }

        public GstFractionProperty() {
            this.box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);

            this.numerator = new Gtk.SpinButton.with_range(0, 9999, 1);
            numerator.value_changed.connect(this.fraction_changed);
            
            this.denominator = new Gtk.SpinButton.with_range(0, 9999, 1);
            denominator.value_changed.connect(this.fraction_changed);

            box.append(numerator);
            box.append(new Gtk.Label("/"));
            box.append(denominator);

            set_child(box);
        }

        protected override void set_property_value(GLib.Value value) {
            numerator.set_value(Gst.Value.get_fraction_numerator(value));
            denominator.set_value(Gst.Value.get_fraction_denominator(value));
        }

        private void fraction_changed() {
            var numerator_value = numerator.get_value_as_int();
            var denominator_value = denominator.get_value_as_int();

            var fraction = GLib.Value(typeof(Gst.Fraction));
            Gst.Value.set_fraction(ref fraction, numerator_value, denominator_value);

            property_value_changed(fraction);
        }
    }
}