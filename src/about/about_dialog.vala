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
        public AboutDialog(AboutRegistry registry) {
            add_css_class("about");
    
            var tv = new Adw.ToolbarView();
            var hb = new Adw.HeaderBar();
            hb.show_end_title_buttons = true;
            tv.add_top_bar(hb);
    
            var scroller = new Gtk.ScrolledWindow();
            scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
            scroller.add_css_class("main-page"); 
    
            var clamp = new Adw.Clamp();
            clamp.maximum_size = 720;
            clamp.tightening_threshold = 600;
            
            var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            var logo = new Gtk.Image.from_icon_name("io.canvas.Canvas");
            logo.pixel_size = 256;
            logo.halign = Gtk.Align.CENTER;
    
            var title = new Gtk.Label("RasterFlow");
            title.add_css_class("title-1");
            title.halign = Gtk.Align.CENTER;
    
            var author = new Gtk.Label("by activey");
            author.add_css_class("dim-label");
            author.halign = Gtk.Align.CENTER;
    
            var version_btn = new Gtk.Button.with_label(BuildConfig.APP_VERSION);
            version_btn.add_css_class("text-button");
            version_btn.add_css_class("app-version");
            version_btn.halign = Gtk.Align.CENTER;
    
            box.append(logo);
            box.append(title);
            box.append(author);
            box.append(version_btn);
    
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
                page.add(group);
    
                var inner_scroller = new Gtk.ScrolledWindow();
                inner_scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
                inner_scroller.set_child(page);
                inner_scroller.hexpand = true;
                inner_scroller.vexpand = true;
                inner_scroller.set_min_content_height(150);
    
                box.append(inner_scroller);
            }
    
            clamp.set_child(box);
            scroller.set_child(clamp);
            tv.set_content(scroller);
            set_child(tv);
    
            set_content_width(400);
            set_content_height(450);
        }
    }
}