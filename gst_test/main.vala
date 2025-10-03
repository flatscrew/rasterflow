class TestApplication : Gtk.Application {

  const string VIDEO_LOCATION = "/home/activey/Videos/brain.mp4";

  private Gst.Pipeline pipeline;
  private Gtk.Box main_box;
  private Gdk.Paintable? paintable;

  public TestApplication() {
    build_pipeline();

    activate.connect (() => {
      var window = new Gtk.ApplicationWindow(this);
      window.set_default_size(800, 600);
      
      create_main_box (window);

      window.present();
  });
  }

  private void build_pipeline() {
    this.pipeline = new Gst.Pipeline ("test");

    var filesrc = Gst.ElementFactory.make("filesrc", "filesrc0");
    var decodebin = Gst.ElementFactory.make("decodebin", "decodebin0");
    var pulsesink = Gst.ElementFactory.make("pulsesink", "pulsesink0");
    var streamsync = Gst.ElementFactory.make("streamsynchronizer", "streamsynchronizer0");
    var videoconvert = Gst.ElementFactory.make("videoconvert", "videoconvert0");
    var gtk4sink = Gst.ElementFactory.make("gtk4paintablesink", "gtk4paintablesink0");
    pipeline.add_many (filesrc, decodebin, streamsync, videoconvert, gtk4sink, pulsesink);
    
    var videoconvert_src = videoconvert.get_static_pad("src");
    var videoconvert_sink = videoconvert.get_static_pad("sink");
    
    var audio_sink = pulsesink.get_static_pad("sink");
    var decodebin_sink = decodebin.get_static_pad ("sink");

    var videosink = gtk4sink.get_static_pad("sink"); 
    var paintable_value = Value(typeof(Gdk.Paintable));
    gtk4sink.get_property("paintable", ref paintable_value);
    this.paintable = paintable_value as Gdk.Paintable;

    
    if (videoconvert_src.can_link(videosink)) {
      print("linking videoconverter...\n");
      videoconvert_src.link(videosink);
    } else {
      print("cannot link videoconverter...\n");
    }


    Queue<Gst.Pad> decoded_pads = new Queue<Gst.Pad>();
    Queue<Gst.Pad> sync_pads = new Queue<Gst.Pad>();

    streamsync.pad_added.connect (pad => {
      print("got new pad from streamsync: %s\n", pad.name);

      if (pad.direction == Gst.PadDirection.SINK) {
        var decoded_source = decoded_pads.pop_head();
        var sync_pad = sync_pads.pop_head();

        if (pad.can_link(decoded_source)) {
          decoded_source.link(pad);
        } else {
          print("CANNOT LINK %s with %s\n", decoded_source.name, pad.name);
        }

        if (sync_pad.can_link (audio_sink)) {
          print("connecting audio: %s -> %s\n", pad.name, audio_sink.name);
          sync_pad.link(audio_sink);
        }

        if (sync_pad.can_link (videoconvert_sink)) {
          print("connecting video: %s -> %s\n", pad.name, videosink.name);
          sync_pad.link(videoconvert_sink);
        }

        return;
      }

      sync_pads.push_head(pad);
    });

    filesrc.set_property ("location", VIDEO_LOCATION);
    var file_src = filesrc.get_static_pad ("src");
    file_src.link (decodebin_sink);

    decodebin.pad_added.connect (pad => {
      print("new decodebin pad added: %s\n", pad.name);
      decoded_pads.push_tail(pad);

      foreach (var stream_sync_pad_template in streamsync.get_pad_template_list()) {
        if (stream_sync_pad_template.direction == Gst.PadDirection.SINK && stream_sync_pad_template.presence == Gst.PadPresence.REQUEST) {
          print("requesting pad from template: %s\n", stream_sync_pad_template.name);
          var stream_sync_pad = streamsync.request_pad(stream_sync_pad_template, null, null);

          print("ADDED NEW PAD: %s\n", stream_sync_pad.name);

          
        }
      }
      
    });

    
  }

  private void create_main_box(Gtk.ApplicationWindow app_window) {
    this.main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
    app_window.set_child(main_box);

    create_video_widget();
    create_action_bar();
  }

  private void create_video_widget() {
    var picture = new Gtk.Picture();
    picture.vexpand = true;
    picture.set_paintable(this.paintable);
    main_box.append(picture);
  }

  private void create_action_bar() {
    var action_bar = new Gtk.ActionBar();

    var playback_toggle = new Gtk.ToggleButton();
    playback_toggle.set_icon_name("media-play");
    playback_toggle.toggled.connect(() => {
      if (playback_toggle.active) {
        pipeline.set_state(Gst.State.PLAYING);
      } else {
        pipeline.set_state(Gst.State.PAUSED);
      }
    });

    action_bar.pack_start(playback_toggle);


    var save_button = new Gtk.Button.with_label("save");
    save_button.clicked.connect(() => {
      Gst.Debug.bin_to_dot_file(pipeline, Gst.DebugGraphDetails.VERBOSE, "gsttest");
    });
    action_bar.pack_end(save_button);

    main_box.append(action_bar);
  }
}

int main (string[] args) {
  Gst.init(ref args);

  var app = new TestApplication();
  return app.run(args);
}

