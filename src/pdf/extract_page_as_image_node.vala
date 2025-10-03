namespace Pdf {

    public class ExtractPdfPageNodeBuilder : CanvasDisplayNodeBuilder, Object {

        public CanvasDisplayNode create() throws Error{
            return new ExtractPdfPageDisplayNode(new ExtractPdfPageNode());
        }

        public string name() {
            return "Extract PDF Page";
        }
    }

    public class ExtractPdfPageNode : CanvasNode {
        
        private GFlow.SimpleSource extracted_image_source;
        internal GFlow.SimpleSink document_input_sink;
        internal GFlow.SimpleSink page_index_sink;
        
        private Poppler.Document? document;
        private int page_index = 0;

        public ExtractPdfPageNode() {
            base("Extract PDF Page");
            resizable = false;

            document_input_sink = new_sink_with_type("PDF document", typeof(Poppler.Document));
            document_input_sink.changed.connect(value => {
                this.document = value as Poppler.Document;
                extract_image();
            });

            page_index_sink = new_sink_with_value("Page index", 1);
            page_index_sink.changed.connect(value => {
                if (value == null) {
                    return;
                }
                this.page_index = value.get_int();
                extract_image();
            });
            extracted_image_source = new_source_with_type("Extracted image", typeof(Gdk.Pixbuf));
        }

        private void extract_image(double scale_factor = 3.0) {
            if (document == null) {
                return;
            }
        
            Poppler.Page? page = document.get_page(page_index);
            if (page == null) {
                return;
            }
        
            double width, height;
            page.get_size(out width, out height);
        
            width *= scale_factor;
            height *= scale_factor;
        
            var surface = new Cairo.ImageSurface(Cairo.Format.ARGB32, (int)width, (int)height);
            var cr = new Cairo.Context(surface);
            
            cr.scale(scale_factor, scale_factor);  // scale the context
        
            page.render(cr);
        
            Gdk.Pixbuf? pixbuf = Gdk.pixbuf_get_from_surface(surface, 0, 0, (int)width, (int)height);
            try {
                extracted_image_source.set_value(pixbuf);
            } catch (Error e) {
                warning(e.message);
            }
        }
    }

    class ExctractPdfPageDockLabelFactory : GtkFlow.NodeDockLabelWidgetFactory {

        private ExtractPdfPageNode extract_node;
        private Gtk.SpinButton page_index_spinner;

        public ExctractPdfPageDockLabelFactory(GFlow.Node node) {
            base(node);
            this.extract_node = node as ExtractPdfPageNode;
        }

        public override Gtk.Widget create_dock_label(GFlow.Dock dock) {
            if (dock == extract_node.page_index_sink) {
                
                this.page_index_spinner = new Gtk.SpinButton.with_range(1d, 1000d, 1d);
                extract_node.page_index_sink.changed.connect(value => {
                    if (value == null) {
                        return;
                    }
                    page_index_spinner.set_value(value.get_int() + 1);
                });

                var page_index_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 3);
                page_index_box.append(property_label("Page index:"));
                page_index_box.append(page_index_spinner);

                return page_index_box;
            }
            return base.create_dock_label(dock);
        }

        private Gtk.Label property_label(string text) {
            var label = new Gtk.Label(text);
            label.halign = Gtk.Align.END;
            label.justify = Gtk.Justification.RIGHT;
            return label;
        }

    }

    class ExtractPdfPageDisplayNode : CanvasDisplayNode {

        public ExtractPdfPageDisplayNode(ExtractPdfPageNode node) {
            base.with_icon(node, null, new ExctractPdfPageDockLabelFactory(node));
        }

    }
}