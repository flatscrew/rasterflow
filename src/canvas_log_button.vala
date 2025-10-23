public class CanvasLogButton : Gtk.Widget {
    private weak CanvasLogsWindow? logs_window = null;
    
    private Gtk.Button button;
    private Gtk.Label badge;
    private Gtk.Overlay overlay;
    private CanvasLog log;
    private uint error_count = 0;

    construct {
        set_layout_manager(new Gtk.BinLayout());
    }

    ~CanvasLogButton() {
        overlay.unparent();
    }

    public CanvasLogButton() {
        log = CanvasLog.get_log();

        button = new Gtk.Button();
        button.set_tooltip_text("Show logs");

        var icon = new Gtk.Image.from_icon_name("dialog-warning-symbolic");
        icon.set_pixel_size(18);
        button.set_child(icon);

        badge = new Gtk.Label("");
        badge.add_css_class("badge");
        badge.visible = false; 
        badge.halign = Gtk.Align.END;
        badge.valign = Gtk.Align.END;

        overlay = new Gtk.Overlay();
        overlay.set_child(button);
        overlay.add_overlay(badge);
        overlay.set_parent(this);

        log.entry_added.connect(() => {
            error_count++;
            update_badge();
        });
        log.cleared.connect(() => {
            error_count = 0;
            update_badge();
        });
        
        button.clicked.connect(on_button_clicked);
    }

    private void update_badge() {
        if (error_count > 0) {
            badge.visible = true;
    
            if (error_count > 99)
                badge.set_label("99+");
            else
                badge.set_label("%u".printf(error_count));
    
        } else {
            badge.visible = false;
        }
    }

    private void on_button_clicked() {
        if (logs_window != null && logs_window.get_visible()) {
            logs_window.present();
            return;
        }
    
        var win = new CanvasLogsWindow();
        logs_window = win;
    
        win.close_request.connect(() => {
            logs_window = null;
            return false;
        });
    
        win.present();
    }
}
