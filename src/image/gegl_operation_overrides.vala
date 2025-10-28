namespace Image {

    class GeglOperationOverrideCallback {
        
        private GeglWholeOperationOverrideFunc operation_func;
        
        public GeglOperationOverrideCallback(GeglWholeOperationOverrideFunc element_func) {
            this.operation_func = (display_node, node) => {
                return element_func(display_node, node);
            };
        }

        public Gtk.Widget build_operation(GeglOperationDisplayNode display_node, GeglOperationNode node) {
            return this.operation_func(display_node, node);
        }
    }

    delegate Gtk.Widget GeglWholeOperationOverrideFunc(GeglOperationDisplayNode display_node, GeglOperationNode node);

    class GeglTitleOverrideCallback {
        private GeglOperationTitleOverrideFunc title_func;

        public GeglTitleOverrideCallback(GeglOperationTitleOverrideFunc title_func) {
            this.title_func = (operation) => {
                return title_func(operation);
            };
        }

        public Gtk.Widget build_title(Gegl.Operation operation) {
            return this.title_func(operation);
        }
    }
    delegate Gtk.Widget GeglOperationTitleOverrideFunc (Gegl.Operation operation);

    delegate void GeglOperationOverridesFunc (GeglOperationOverridesComposer composer); 

    class GeglOperationOverridesCallback {
        private GeglOperationOverridesComposer composer;

        internal GeglOperationOverridesCallback(GeglOperationOverridesFunc overrides_func) {
            this.composer = new GeglOperationOverridesComposer();

            overrides_func(composer);
        }

        public Gtk.Widget? build_title(Gegl.Operation operation) {
            return composer.build_title(operation);
        }

        public Gtk.Widget? build_operation(GeglOperationDisplayNode display_node, GeglOperationNode node) {
            return composer.build_operation(display_node, node);
        }

        public void copy_property_overrides(Data.PropertyOverridesComposer composer) {
            this.composer.copy_to(composer);
        }
    }

    internal class GeglOperationOverridesComposer : Data.PropertyOverridesComposer {
        private GeglOperationOverrideCallback? content_override_callback;
        private GeglTitleOverrideCallback? title_override_callback;

        internal void override_title(GeglOperationTitleOverrideFunc title_override_func) {
            this.title_override_callback = new GeglTitleOverrideCallback(title_override_func);
        }

        internal void override_content(GeglWholeOperationOverrideFunc operation_override_func) {
            this.content_override_callback = new GeglOperationOverrideCallback(operation_override_func);
        }

        internal Gtk.Widget? build_title(Gegl.Operation operation) {
            if (title_override_callback != null) {
                return title_override_callback.build_title(operation);
            }
            return null;
        }

        internal Gtk.Widget? build_operation(GeglOperationDisplayNode display_node, GeglOperationNode node) {
            if (content_override_callback != null) {
                return content_override_callback.build_operation(display_node, node);
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