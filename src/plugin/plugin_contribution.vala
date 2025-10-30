namespace Plugin {

    public delegate void FileDataNodeFactoryContribution(Data.FileOriginNodeFactory file_data_node_factory);
    
    public delegate void CanvasNodeFactoryContribution(CanvasNodeFactory node_factory);

    public delegate void CanvasSerializerContribution(Serialize.CustomSerializers serializers, Serialize.CustomDeserializers deserializers);

    public delegate void CanvasHeaderbarContribution(CanvasHeaderbarWidgets header_widgets);

    public delegate void CanvasAppWindowContribution(Gtk.Window app_window);

    public delegate void AboutContribution(About.AboutRegistry registry);
    
    public class PluginContribution {

        private Gtk.Window app_window;
        private CanvasNodeFactory node_factory;
        private CanvasHeaderbarWidgets header_widgets;
        private Data.FileOriginNodeFactory file_data_node_factory;
        private Serialize.CustomSerializers serializers;
        private Serialize.CustomDeserializers deserializers;
        private About.AboutRegistry about_registry;

        public PluginContribution(
            CanvasNodeFactory node_factory,
            CanvasHeaderbarWidgets header_widgets,
            Gtk.Window app_window,
            Data.FileOriginNodeFactory file_data_node_factory, 
            Serialize.CustomSerializers serializers, 
            Serialize.CustomDeserializers deserializers,
            About.AboutRegistry about_registry
        ) {
            this.node_factory = node_factory;
            this.header_widgets = header_widgets;
            this.app_window = app_window;
            this.file_data_node_factory = file_data_node_factory;
            this.serializers = serializers;
            this.deserializers = deserializers;
            this.about_registry = about_registry;
        }

        public void contribute_file_data_node_factory(FileDataNodeFactoryContribution contribution) {
            contribution(file_data_node_factory);
        }

        public void contribute_canvas_node_factory(CanvasNodeFactoryContribution contribution) {
            contribution(node_factory);
        }

        public void contribute_canvas_serializer(CanvasSerializerContribution contribution) {
            contribution(serializers, deserializers);
        }

        public void contribute_canvas_headerbar(CanvasHeaderbarContribution contribution) {
            contribution(header_widgets);
        }

        public void contribute_app_window(CanvasAppWindowContribution contribution) {
            contribution(app_window);
        }
        
        public void contribute_about_dialog(AboutContribution contribution) {
            contribution(about_registry);
        }
    }
}