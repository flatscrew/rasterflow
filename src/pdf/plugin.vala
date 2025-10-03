public string initialize_pdf_plugin(Plugin.PluginContribution plugin_contribution) {
    plugin_contribution.contribute_file_data_node_factory(node_factory => {
        node_factory.register(
            new Pdf.PdfFileDataDisplayNodeBuilder(),
            {
            "application/pdf"
            }
        );
    });

    plugin_contribution.contribute_canvas_node_factory(node_factory => {
        node_factory.register(new Pdf.ExtractPdfPageNodeBuilder(),
          typeof(Poppler.Document)
        );
    });

	return "pdf";
}