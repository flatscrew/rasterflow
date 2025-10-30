namespace About {
    
    public class AboutRegistry : Object {
        private Gee.List<Entry> entries = new Gee.ArrayList<Entry>();
    
        public void add_entry(string title, string subtitle) {
            entries.add(new Entry(title, subtitle));
        }
    
        public Gee.List<Entry> get_entries() {
            return entries;
        }
    
        public class Entry : Object {
            public string title { get; construct; }
            public string subtitle { get; construct; }
    
            public Entry(string title, string subtitle) {
                Object(title: title, subtitle: subtitle);
            }
        }
    }
    
    public class AboutDialog : Adw.Dialog {
        
        private const string COFFEE_URL = "https://buymeacoffee.com/rasterflow";
        
        public AboutDialog(AboutRegistry registry) {
            add_css_class("about");
    
            var toolbar_view = new Adw.ToolbarView();
            var headerbar = new Adw.HeaderBar();
            headerbar.show_end_title_buttons = true;
            toolbar_view.add_top_bar(headerbar);
    
            var scroller = new Gtk.ScrolledWindow();
            scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scroller.add_css_class("main-page"); 
    
            var clamp = new Adw.Clamp();
            clamp.maximum_size = 720;
            clamp.tightening_threshold = 600;
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            append_logo(box);
            append_title(box);
            append_author(box);
            append_version(box);
    
            if (registry.get_entries().size > 0) {
                var group = new Adw.PreferencesGroup();
                group.set_title("Additional information");
    
                foreach (var entry in registry.get_entries()) {
                    var row = new Adw.ActionRow();
                    row.set_title(entry.title);
                    row.set_subtitle(entry.subtitle);
                    row.activatable = false;
                    group.add(row);
                }
    
                var page = new Adw.PreferencesPage();
                var page_scroller = page.get_first_child() as Gtk.ScrolledWindow;
                if (page_scroller != null) {
                    page_scroller.vscrollbar_policy = Gtk.PolicyType.NEVER;
                }
                page.add(group);
                box.append(page);
            }
    
            add_coffee_button(box);
            
            
            clamp.set_child(box);
            scroller.set_child(clamp);
            toolbar_view.set_content(scroller);
            set_child(toolbar_view);
    
            set_content_width(400);
            set_content_height(450);
        }
        
        private void append_author(Gtk.Box box) {
            var author = new Gtk.Label("by activey");
            author.add_css_class("dim-label");
            author.halign = Gtk.Align.CENTER;
            box.append(author);
        }
        
        private void append_logo(Gtk.Box box) {
            var logo = new Gtk.Image.from_icon_name("io.canvas.Canvas");
            logo.pixel_size = 256;
            logo.halign = Gtk.Align.CENTER;
            box.append(logo);
        }
        
        private void append_title(Gtk.Box box) {
            var title = new Gtk.Label("RasterFlow");
            title.add_css_class("title-1");
            title.halign = Gtk.Align.CENTER;
            box.append(title);
        }
        
        private void append_version(Gtk.Box box) {
            var version_button = new Gtk.Button.with_label(BuildConfig.APP_VERSION);
            version_button.add_css_class("text-button");
            version_button.add_css_class("app-version");
            version_button.halign = Gtk.Align.CENTER;
            box.append(version_button);
        }
        
        private void add_coffee_button(Gtk.Box box) {
            var button = new Gtk.Button.with_label("☕ Buy me a coffee");
            button.halign = Gtk.Align.CENTER;
            button.add_css_class("pill");
            button.add_css_class("suggested-action");
            button.add_css_class("coffee");
            button.clicked.connect(() => {
                var launcher = new Gtk.UriLauncher(COFFEE_URL);
                launcher.launch.begin(null, null);
            });
            box.append(button);
        }
    }
}