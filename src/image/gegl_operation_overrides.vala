namespace Image {

    class GeglOperationOverrideCallback {
        
        private GeglOperationOverrideFunc operation_func;
        
        public GeglOperationOverrideCallback(GeglOperationOverrideFunc element_func) {
            this.operation_func = (operation) => {
                return element_func(operation);
            };
        }

        public Gtk.Widget build_operation(Gegl.Operation operation) {
            return this.operation_func(operation);
        }
    }

    delegate Gtk.Widget GeglOperationOverrideFunc (Gegl.Operation operation);

    delegate void GeglOperationOverridesFunc (GeglOperationOverridesComposer composer); 

    class GeglOperationOverridesCallback {
        private GeglOperationOverridesComposer composer;

        internal GeglOperationOverridesCallback(GeglOperationOverridesFunc overrides_func) {
            this.composer = new GeglOperationOverridesComposer();

            overrides_func(composer);
        }

        public Gtk.Widget? build_operation(Gegl.Operation operation) {
            return composer.build_operation(operation);
        }

        public void copy_property_overrides(Data.PropertyOverridesComposer composer) {
            this.composer.copy_to(composer);
        }
    }

    internal class GeglOperationOverridesComposer : Data.PropertyOverridesComposer {
        private GeglOperationOverrideCallback? element_override_callback;

        internal void override_whole(GeglOperationOverrideFunc operation_override_func) {
            this.element_override_callback = new GeglOperationOverrideCallback(operation_override_func);
        }

        internal Gtk.Widget? build_operation(Gegl.Operation operation) {
            if (element_override_callback != null) {
                return element_override_callback.build_operation(operation);
            }
            return null;
        }
    }

    class GeglOperationOverrides : Object {

        static Gee.Map<string, GeglOperationOverridesCallback> element_overrides = new Gee.HashMap<string, GeglOperationOverridesCallback>();

        internal static void override_operation(string gegl_operation, GeglOperationOverridesFunc overrides_func) {
            GeglOperationOverrides.element_overrides.set(gegl_operation, new GeglOperationOverridesCallback(overrides_func));
        }

        internal static GeglOperationOverridesCallback? find_operation_overrides(string element_name) {
            return GeglOperationOverrides.element_overrides.get(element_name);
        }
    }
}