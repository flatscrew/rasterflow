namespace Image {

    public class ImageProcessingRealtimeGuard {
        private static ImageProcessingRealtimeGuard? _instance = null;

        public static ImageProcessingRealtimeGuard instance {
            get {
                if (_instance == null)
                    _instance = new ImageProcessingRealtimeGuard();
                return _instance;
            }
        }

        private bool _enabled = false;
        public signal void mode_changed(bool enabled);

        public bool enabled {
            get { return _enabled; }
            set {
                if (_enabled != value) {
                    _enabled = value;
                    mode_changed(_enabled);
                }
            }
        }

        public void toggle() {
            enabled = !enabled;
        }

        private ImageProcessingRealtimeGuard() {}
    }

    public class ImageProcessingRealtimeModeSwitch : Gtk.Widget {
        private Gtk.ToggleButton switch_button;
        private Gtk.Image play_icon;
        private Gtk.Image pause_icon;
        private ImageProcessingRealtimeGuard realtime_guard;

        construct {
            set_layout_manager(new Gtk.BinLayout());
        }

        public ImageProcessingRealtimeModeSwitch() {
            realtime_guard = ImageProcessingRealtimeGuard.instance;

            play_icon = new Gtk.Image.from_icon_name("media-playback-start-symbolic");
            pause_icon = new Gtk.Image.from_icon_name("media-playback-pause-symbolic");

            switch_button = new Gtk.ToggleButton();
            switch_button.set_parent(this);
            switch_button.active = realtime_guard.enabled;

            update_icon();

            switch_button.toggled.connect(() => {
                realtime_guard.enabled = switch_button.active;
                update_icon();
            });

            realtime_guard.mode_changed.connect((enabled) => {
                switch_button.active = enabled;
                update_icon();
            });
        }

        private void update_icon() {
            switch_button.set_child(switch_button.active ? pause_icon : play_icon);
            switch_button.tooltip_text = switch_button.active
                ? "Disable realtime processing"
                : "Enable realtime processing";
        }

        ~ImageProcessingRealtimeModeSwitch() {
            switch_button.unparent();
        }
    }
}