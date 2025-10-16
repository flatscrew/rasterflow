namespace Plugin {

    public delegate void FileDataNodeFactoryContribution(Data.FileOriginNodeFactory file_data_node_factory);
    
    public delegate void CanvasNodeFactoryContribution(CanvasNodeFactory node_factory);

    public delegate void CanvasSerializerContribution(Serialize.CustomSerializers serializers, Serialize.CustomDeserializers deserializers);

    public delegate void CanvasSignalsDelegate(CanvasSignals signals);

    public delegate void CanvasHeaderbarContribution(CanvasHeaderbarWidgets header_widgets);

    public delegate void CanvasAppWindowContribution(Gtk.Window app_window);

    public class PluginContribution {

        private Gtk.Window app_window;
        private CanvasSignals canvas_signals;
        private CanvasNodeFactory node_factory;
        private CanvasHeaderbarWidgets header_widgets;
        private Data.FileOriginNodeFactory file_data_node_factory;
        private Serialize.CustomSerializers serializers;
        private Serialize.CustomDeserializers deserializers;

        public PluginContribution(
            CanvasSignals canvas_signals,
            CanvasNodeFactory node_factory,
            CanvasHeaderbarWidgets header_widgets,
            Gtk.Window app_window,
            Data.FileOriginNodeFactory file_data_node_factory, 
            Serialize.CustomSerializers serializers, 
            Serialize.CustomDeserializers deserializers) {
                this.canvas_signals = canvas_signals;
                this.node_factory = node_factory;
                this.header_widgets = header_widgets;
                this.app_window = app_window;
                this.file_data_node_factory = file_data_node_factory;
                this.serializers = serializers;
                this.deserializers = deserializers;
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

        public void listen_canvas_signals(CanvasSignalsDelegate signals_delegate) {
            signals_delegate(canvas_signals);
        }
    }

}