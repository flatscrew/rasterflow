public string initialize_text_plugin(Plugin.PluginContribution plugin_contribution) {
    plugin_contribution.contribute_canvas_node_factory(node_factory => {
        node_factory.register(new Text.TextDataDisplayNodeBuilder());
    });

	return "text";
}