namespace AudioVideo {

    class GstGtk4PaintableSinkView : Gtk.Widget {

        private Gtk.Picture picture;

        construct {
            base.set_layout_manager (new Gtk.BinLayout ());
            vexpand = hexpand = true;
            set_size_request (200, 150);
        }

        ~GstGtk4PaintableSinkView() {
            picture.unparent ();
        }

        public GstGtk4PaintableSinkView(Gst.Element gst_element) {
            var paintable_value = GLib.Value(typeof(Gdk.Paintable));
            gst_element.get_property ("paintable", ref paintable_value);
        
            this.picture = new Gtk.Picture ();
            picture.set_paintable (paintable_value as Gdk.Paintable);
            picture.set_parent (this);
        }
    }
}