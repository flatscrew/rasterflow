namespace AudioVideo {

    public class GstPipelineControls : Gtk.Widget {

        private Gtk.ToggleButton pause_pipeline_button;
        private Gtk.ToggleButton configure_pipeline_button;
        
        private Gtk.Box layout_box;
        private Gtk.Box action_buttons;
        private Gtk.Spinner spinner;
        private GstPipeline pipeline;
        private Gst.State awaited_state;

        construct {
            set_layout_manager (new Gtk.BinLayout());
        }

        public GstPipelineControls() {
            this.pipeline = GstPipeline.get_current();
            pipeline.pipeline_state_changed.connect(this.pipeline_state_changed);

            this.action_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            action_buttons.add_css_class("linked");
            add_configure_pipeline_buttton(action_buttons);
            add_pause_pipeline_button(action_buttons);

            this.spinner = new Gtk.Spinner();
            
            this.layout_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            layout_box.append(action_buttons);
            layout_box.append(spinner);
            layout_box.set_parent(this);
            
            pipeline_state_changed(pipeline.current_state());
        }

        private void add_configure_pipeline_buttton(Gtk.Box action_buttons) {
            this.configure_pipeline_button = new Gtk.ToggleButton();
            action_buttons.append(configure_pipeline_button);
        }

        private void add_pause_pipeline_button(Gtk.Box action_buttons) {
            this.pause_pipeline_button = new Gtk.ToggleButton();
            pause_pipeline_button.set_icon_name("media-playback-pause");
            action_buttons.append(pause_pipeline_button);
        }

        private void pipeline_state_changed(Gst.State new_state) {
            pause_pipeline_button.toggled.disconnect(this.pause_pipeline_toggled);
            pause_pipeline_button.active = new_state <= Gst.State.PAUSED;
            pause_pipeline_button.toggled.connect(this.pause_pipeline_toggled);
            
            configure_pipeline_button.toggled.disconnect(this.configure_pipeline_toggled);
            configure_pipeline_button.active = new_state <= Gst.State.READY;
            configure_pipeline_button.toggled.connect(this.configure_pipeline_toggled);

            if (configure_pipeline_button.active) {
                configure_pipeline_button.set_icon_name("changes-allow-symbolic");
                configure_pipeline_button.set_tooltip_text("Lock pipeline. When pipeline is locked it is not possible to edit locked properties and change node connections.");
            } else {
                configure_pipeline_button.set_icon_name("changes-prevent-symbolic");
                configure_pipeline_button.set_tooltip_text("Unlock pipeline. Edit locked properties and change node connections.");
            }

            confirm_pipeline_state_changed(new_state);
        }

        private void pause_pipeline_toggled() {
            var ret = Gst.StateChangeReturn.SUCCESS;
            if (pause_pipeline_button.active) {
                await_pipeline_state_change(Gst.State.PAUSED);
                ret = pipeline.paused();
            } else {
                await_pipeline_state_change(Gst.State.PLAYING);
                ret = pipeline.playing();
            }
            if (ret != Gst.StateChangeReturn.SUCCESS) {
                if (ret == Gst.StateChangeReturn.FAILURE) {
                    finish_waiting_state_change();
                }
                
                pause_pipeline_button.toggled.disconnect(this.pause_pipeline_toggled);
                pause_pipeline_button.active = !pause_pipeline_button.active;
                pause_pipeline_button.toggled.connect(this.pause_pipeline_toggled);
            }
            debug("PAUSED/RESUMED with status> %s\n", ret.to_string());
        }

        private void configure_pipeline_toggled() {
            var ret = Gst.StateChangeReturn.SUCCESS;
            if (configure_pipeline_button.active) {
                await_pipeline_state_change(Gst.State.READY);
                ret = pipeline.ready();
            } else {
                await_pipeline_state_change(Gst.State.PAUSED);
                ret = pipeline.paused();
            }
            if (ret != Gst.StateChangeReturn.SUCCESS) {
                if (ret == Gst.StateChangeReturn.FAILURE) {
                    finish_waiting_state_change();
                }

                configure_pipeline_button.toggled.disconnect(this.configure_pipeline_toggled);
                configure_pipeline_button.active = !configure_pipeline_button.active;
                configure_pipeline_button.toggled.connect(this.configure_pipeline_toggled);
            }
            debug("configuring pipeline with status %s\n", ret.to_string());
        }

        private void await_pipeline_state_change(Gst.State awaited_state) {
            this.awaited_state = awaited_state;
            spinner.start();
            set_sensitive(false);
        } 
        
        private void confirm_pipeline_state_changed(Gst.State new_state) {
            if (new_state != awaited_state) {
                return;
            }
            finish_waiting_state_change();
        }

        private void finish_waiting_state_change() {
            spinner.stop();
            set_sensitive(true);
        }
        
        ~GstPipelineControls() {
            action_buttons.unparent();
        }
    }
}