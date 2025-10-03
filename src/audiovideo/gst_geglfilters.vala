namespace AudioVideo {
    
    public class GeglSourceDisplayNodeBuilder : CanvasNodeBuilder, Object {

        public CanvasDisplayNode create() throws Error{
            return new GeglSourceDisplayNode(id(), new GeglSourceNode());
        }

        public string name() {
            return "GEGL source";
        }

        public override string? description() {
            return "<b>[%s]</b> %s".printf(id(), "Downloads GEGL buffer as Gstreamer frames.");
        }

        public string id() {
            return "gst:geglsrc";
        }
    }

    class GeglSourceDisplayNode : CanvasDisplayNode {
        public GeglSourceDisplayNode(string builder_id, GeglSourceNode data_node) {
            base (builder_id, data_node);
        }
    }

    class GeglSourceNode : CanvasNode {

        private Gst.Element gst_element;
        private CanvasNodeSink gegl_sink;

        public GeglSourceNode() {
            base("GEGL source");

            this.gst_element = Gst.ElementFactory.make("gegldownload", null);
            AudioVideo.GstPipeline.get_current().add(gst_element);
            add_source (new AudioVideo.GstElementSourcePad (gst_element.get_static_pad ("src")));
    
            this.gegl_sink = new CanvasNodeSink.with_type (typeof(Gegl.Node));
            gegl_sink.linked.connect(dock => {
                if (dock is Image.PadSource) {
                    var pad_source = dock as Image.PadSource;
                    gst_element.set_property ("input-node", pad_source.value);
                }
            });

            gegl_sink.unlinked.connect(dock => {
            });
            gegl_sink.name = "GEGL node";

            add_sink(gegl_sink);

        }
    }


    public class GeglSinkDisplayNodeBuilder : CanvasNodeBuilder, Object {

        public CanvasDisplayNode create() throws Error{
            return new GeglSinkDisplayNode(id(), new GeglSinkNode());
        }

        public string name() {
            return "GEGL sink";
        }

        public override string? description() {
            return "<b>[%s]</b> %s".printf(id(), "Uploads GEGL buffer as Gstreamer frames.");
        }

        public string id() {
            return "gst:geglsink";
        }
    }

    class GeglSinkDisplayNode : CanvasDisplayNode {
        public GeglSinkDisplayNode(string builder_id, GeglSinkNode data_node) {
            base (builder_id, data_node);
        }
    }

    class GeglSinkNode : CanvasNode {

        private Gst.Element gst_element;
        private Image.PadSource gegl_source;

        public GeglSinkNode() {
            base("GEGL sink");

            this.gst_element = Gst.ElementFactory.make("geglupload", null);
            AudioVideo.GstPipeline.get_current().add(gst_element);
            add_sink (new AudioVideo.GstElementSinkPad(gst_element.get_static_pad ("sink")));
    

            GLib.Value output_node = GLib.Value(typeof(Gegl.Node));
            gst_element.get_property("output-node", ref output_node);
            var gegl_buffer_source = output_node as Gegl.Node;
     

            this.gegl_source = new Image.PadSource(gegl_buffer_source, "output");
            //  gegl_source.linked.connect(dock => {
            //      if (dock is Image.PadSink) {
            //          var pad_sink = dock as Image.PadSink;


            //          gst_element.set_property ("input-node", pad_source.gegl_node);
            //      }
            //  });

            //  gegl_source.unlinked.connect(dock => {
            //  });
            gegl_source.name = "GEGL node";

            add_source(gegl_source);

        }
    }
}