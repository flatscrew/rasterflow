namespace Image {
    
    public class ImageFileDetails {
        
        public void file_details(File file, Data.FileInfoGroup info_group) {
            try {
                var pixbuf = new Gdk.Pixbuf.from_file(file.get_path());
                info_group.add_file_info_row("Width", "%d".printf(pixbuf.width));
                info_group.add_file_info_row("Height", "%d".printf(pixbuf.height));
                info_group.add_file_info_row("Channels", "%d (%s)".printf(
                    pixbuf.n_channels,
                    pixbuf.has_alpha ? "RGBA" : (pixbuf.n_channels == 3 ? "RGB" : "Gray")
                ));
                info_group.add_file_info_row("Bits per sample", pixbuf.bits_per_sample.to_string());
            } catch (Error e) {
                warning(e.message);
            }
        }
        
        public void exif_details(File file, Data.FileInfoGroup info_group) {
            Exif.Data? data = Exif.Data.new_from_file(file.get_path());
            if (data == null) {
                info_group.add_simple_row("No EXIF data");
                return;
            }
        
            for (int i = 0; i < Exif.IFD_COUNT; i++) {
                Exif.Content content = data.ifd[i];
                if (content == null)
                    continue;
        
                for (int j = 0; j < content.count; j++) {
                    Exif.Entry entry = content.entries[j];
                    if (entry == null)
                        continue;
        
                    unowned string? name = entry.tag.get_name_in_ifd((Exif.Ifd) i);
                    if (name == null)
                        continue;
        
                    string value = entry.get_string().strip();
                    if (value == "")
                        continue;
        
                    var row = new Adw.ActionRow();
                    row.set_title(name);
                    row.set_subtitle(value);
                    
                    var button = new Gtk.Button.from_icon_name("edit-copy-symbolic");
                    button.set_tooltip_text("Copy value");
                    button.clicked.connect(() => {
                        var display = Gdk.Display.get_default();
                        if (display == null)
                            return;
                    
                        var clipboard = display.get_clipboard();
                        clipboard.set_text(value);
                    });
                    button.add_css_class("flat");
                    button.valign = Gtk.Align.CENTER;
                    row.add_suffix(button);
                    
                    
                    info_group.add_file_info_row(name, value);
                }
            }
        }
    }
    
}