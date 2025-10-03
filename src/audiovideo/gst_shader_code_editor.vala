namespace AudioVideo {
    public class GstShaderCodeEditor : Data.DataProperty {

        private Gtk.ScrolledWindow scrolled_window;
        private GtkSource.Buffer source_buffer;
        private GtkSource.View source_view;

        ~GstShaderCodeEditor() {
            this.scrolled_window.unparent ();
        }
        
        public GstShaderCodeEditor(ParamSpecString param_spec) {
            base(param_spec, true);
            base.hexpand = true;
            base.set_size_request(400, 300);

            var lang_manager = GtkSource.LanguageManager.get_default ();
            var style_manager = GtkSource.StyleSchemeManager.get_default ();

            this.scrolled_window = new Gtk.ScrolledWindow ();

            this.source_buffer = new GtkSource.Buffer.with_language (lang_manager.get_language ("glsl"));
            source_buffer.changed.connect (this.buffer_changed);
            
            this.source_view = new GtkSource.View.with_buffer (source_buffer);
            source_view.vexpand = source_view.hexpand = true;
            source_view.set_monospace (true);
            source_view.set_highlight_current_line (true);
            source_view.set_show_line_numbers (true);
            source_view.add_css_class ("frame");

            source_buffer.set_style_scheme(style_manager.get_scheme("classic"));
            scrolled_window.set_parent (this);

            scrolled_window.set_child (source_view);
        }

        private void buffer_changed() {
            property_value_changed(source_buffer.text);
        }

        protected override void set_property_value(GLib.Value value) {
            source_buffer.set_text(value.get_string());
        }
    }
}