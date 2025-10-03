namespace AudioVideo {
    class GstElementOverrideCallback {
        
        private GstElementOverrideFunc element_func;
        
        public GstElementOverrideCallback(GstElementOverrideFunc element_func) {
            this.element_func = (element) => {
                return element_func(element);
            };
        }

        public Gtk.Widget build_element(Gst.Element gst_element) {
            return this.element_func(gst_element);
        }
    }

    delegate Gtk.Widget GstElementOverrideFunc (Gst.Element element);

    delegate void GstElementOverridesFunc (GstElementOverridesComposer composer); 

    class GstElementOverridesCallback {
        private GstElementOverridesComposer composer;

        internal GstElementOverridesCallback(GstElementOverridesFunc overrides_func) {
            this.composer = new GstElementOverridesComposer();

            overrides_func(composer);
        }

        public Gtk.Widget? build_element(Gst.Element element) {
            return composer.build_element(element);
        }

        public void copy_property_overrides(Data.PropertyOverridesComposer composer) {
            this.composer.copy_to(composer);
        }
    }

    internal class GstElementOverridesComposer : Data.PropertyOverridesComposer {
        private GstElementOverrideCallback? element_override_callback;

        internal void override_whole(GstElementOverrideFunc element_override_func) {
            this.element_override_callback = new GstElementOverrideCallback(element_override_func);
        }

        internal Gtk.Widget? build_element(Gst.Element element) {
            if (element_override_callback != null) {
                return element_override_callback.build_element(element);
            }
            return null;
        }
    }

    class GstElementOverrides : Object {

        static Gee.Map<string, GstElementOverridesCallback> element_overrides = new Gee.HashMap<string, GstElementOverridesCallback>();

        internal static void override_element(string gst_element, GstElementOverridesFunc overrides_func) {
            GstElementOverrides.element_overrides.set(gst_element, new GstElementOverridesCallback(overrides_func));
        }

        internal static GstElementOverridesCallback? find_element_overrides(string element_name) {
            return GstElementOverrides.element_overrides.get(element_name);
        }
    }
}