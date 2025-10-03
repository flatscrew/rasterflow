namespace AudioVideo {
    public delegate void GstPipelineOperation(Gst.Pipeline pipeline);

    public class GstPipeline : GLib.Object {
        public signal void pipeline_state_changed(Gst.State pipeline_state);
        public signal void state_changed(Gst.Element element, Gst.State pipeline_state);
        public signal void error_reported(Gst.Object element, GLib.Error error, string debug_info);
        public signal void warning_reported(Gst.Object element, GLib.Error error, string debug_info);
        
        private Gst.Pipeline pipeline {get; private set;}
        private static GstPipeline? instance = null;

        public static GstPipeline get_current() {
            if (GstPipeline.instance == null) {
                GstPipeline.instance = new GstPipeline();
            }
            return GstPipeline.instance;
        }

        private GstPipeline() {
            this.pipeline = new Gst.Pipeline("test");
            var bus = pipeline.get_bus();
            //  bus.add_signal_watch();
            bus.add_watch(0, this.bus_message);
        }

        private bool bus_message(Gst.Bus bus, Gst.Message message) {
            switch (message.type) {
                case Gst.MessageType.ERROR:
                    handle_error_message(message);
                    break;

                case Gst.MessageType.WARNING:
                    handle_warning_message(message);
                    break;

                case Gst.MessageType.STATE_CHANGED:
                    handle_state_change_message(message);
                    break;

                //  case Gst.MessageType.EOS:
                //      pipeline.seek_simple(Gst.Format.BUFFERS, Gst.SeekFlags.FLUSH, 0);
                //      print("got EOS for %s\n", message.src.name);
                //      break;

                default:
                    //  debug("got some other bus message: %s\n", message.type.to_string());
                    break;
            }
            return GLib.Source.CONTINUE;
        }

        private void handle_state_change_message(Gst.Message message) {
            Gst.State old_state, new_state, pending_state;
            message.parse_state_changed(out old_state, out new_state, out pending_state);

            if (message.src is Gst.Element) {
                if (message.src == pipeline) {
                    debug("pipeline state changed from %s to %s.\n", Gst.Element.state_get_name(old_state), Gst.Element.state_get_name(new_state));
                    pipeline_state_changed(new_state);
                    return;
                }
                
                var element = message.src as Gst.Element;
                state_changed(element, new_state);
            }
        }

        private void handle_error_message(Gst.Message message) {
            string debug_info;
            GLib.Error error;
            message.parse_error(out error, out debug_info);

            if (message.src is Gst.Element) {
                if (message.src == pipeline) {
                    warning("pipeline error: %s\n", error.message);
                }
                var element = message.src as Gst.Element;
                error_reported(element, error, debug_info);
            }
        }

        private void handle_warning_message(Gst.Message message) {
            string debug_info;
            GLib.Error warn;
            message.parse_warning(out warn, out debug_info);

            var object = message.src;
            if (object.parent == pipeline) {
                warning_reported(object, warn, debug_info);
            } else {
                var parent_element = find_parent(object);
                warning_reported(parent_element, warn, debug_info);
            }

            warning("Warning received: %s from: %s\n", warn.message, message.src.name);
            warning("Debug info: %s\n", debug_info);
        }

        private Gst.Object find_parent(Gst.Object element) {
            if (element.has_as_parent(pipeline)) {
                return element;
            }
            return find_parent(element.parent);
        }

        public Gst.StateChangeReturn paused() {
            return pipeline.set_state(Gst.State.PAUSED);
        }

        public Gst.StateChangeReturn ready() {
            return pipeline.set_state(Gst.State.READY);
        }

        public Gst.StateChangeReturn playing() {
            return pipeline.set_state(Gst.State.PLAYING);
        }

        public Gst.StateChangeReturn stop() {
            return pipeline.set_state(Gst.State.NULL);
        }
        
        public Gst.State current_state() {
            Gst.State current_state;
            Gst.State pending_state;

            Gst.StateChangeReturn ret = pipeline.get_state(out current_state, out pending_state, Gst.CLOCK_TIME_NONE);
            if (ret != Gst.StateChangeReturn.SUCCESS) {
                warning("Failed to retrieve state\n");
            }
            return current_state;
        }

        public void add(Gst.Element element) {
            pipeline.add_element(element);
        }

        public void remove(Gst.Element element) {
            pipeline.remove(element);
        }

        public void dump_to_dot() {
            Gst.Debug.bin_to_dot_file(pipeline, Gst.DebugGraphDetails.VERBOSE, "test");
        }
    }   

}