namespace Pdf {

    public class PdfFileDataDisplayNodeBuilder : Data.FileDataDisplayNodeBuilder, Object {
        public Data.FileDataDisplayNode create (File file, FileInfo file_info) throws Error {
            Poppler.Document document = new Poppler.Document.from_file(file.get_uri(), null);
            return new PdfFileDataDisplayNode(new PdfFileDataNode(file_info.get_name (), document), file.get_path(), file_info);
        }
    }

    class PdfFileDataDisplayNode : Data.FileDataDisplayNode {

        private const string DATE_FORMAT = "%Y.%m.%dT%H:%M:%S";

        private Pdf.PDFViewer pdf_viewer;
        private Gtk.Scale zoom_control;
        private Gtk.Button reset_zoom_button;
        private PdfFileDataNode node;

        public PdfFileDataDisplayNode(PdfFileDataNode node, string file_path, FileInfo file_info) {
            base(node, file_info);

            this.node = node;
            this.pdf_viewer = new Pdf.PDFViewer(node.document);
            pdf_viewer.page_changed.connect(node.page_index_changed);
            var scrolled_window = new Pdf.PDFViewerPanningArea(pdf_viewer);
            scrolled_window.add_css_class("pdf_backround");
            add_child(scrolled_window);

            create_zoom_control();
            create_navigation_controls();

            var document_details = add_property_group("Document details");
            var document = pdf_viewer.document;
            document_details.set_group_property("Title", document.get_title());
            document_details.set_group_property("Author", document.get_author());
            document_details.set_group_property("Subject", document.get_subject());
            document_details.set_group_property("Keywords", document.get_keywords());
            document_details.set_group_property("Producer", document.get_producer());
            document_details.set_group_property("Creator", document.get_creator());
            document_details.set_group_property("Creation Date", new GLib.DateTime.from_unix_local(document.get_creation_date()).format_iso8601());
            document_details.set_group_property("Modification Date", new GLib.DateTime.from_unix_local(document.get_modification_date()).format_iso8601());
            document_details.set_group_property("Number of Pages", document.get_n_pages().to_string());
        }

        private void create_zoom_control() {
            this.zoom_control = pdf_viewer.create_scale_widget();
            add_action_bar_child_end(zoom_control);

            this.reset_zoom_button = new Gtk.Button.from_icon_name("zoom-original");
            reset_zoom_button.tooltip_text = "Reset to original size";
            reset_zoom_button.clicked.connect(pdf_viewer.reset_zoom);
            add_action_bar_child_end(reset_zoom_button);
           
            pdf_viewer.zoom_changed.connect(zoom_value => {
                reset_zoom_button.sensitive = zoom_value != 1; 
            });
        }

        private void create_navigation_controls() {
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.add_css_class("linked");
            box.append(pdf_viewer.create_previous_page_button());
            box.append(pdf_viewer.create_next_page_button());

            add_action_bar_child_start(box);
            add_action_bar_child_start(pdf_viewer.create_page_status_label());
        }
    }

    class PdfFileDataNode : CanvasNode {
        
        public Poppler.Document document {
            get;
            private set;
        }
        
        private GFlow.SimpleSource page_index_source;

        public PdfFileDataNode(string file_name, Poppler.Document document) {
            base(file_name);
            this.document = document;
            
            new_source_with_value("Output document", document);
            this.page_index_source = new_source_with_type("Page index", typeof(int));
        }

        internal void page_index_changed(int new_page_index) {
            try{
                page_index_source.set_value(new_page_index);
            } catch (Error e) {

            }
        }
    }
}