using Gtk;


public class CanvasSignals : Object {

  public signal void before_file_load();
  public signal void after_file_load();
}

class CanvasApplication : Gtk.Application {

  private History.HistoryOfChangesRecorder changes_recorder;
  private CanvasView canvas_view;
  private CanvasHeaderbarWidgets header_widgets;
  private Gtk.ApplicationWindow? window;

  construct {
    base.application_id = "io.canvas.Canvas";
    base.flags = ApplicationFlags.FLAGS_NONE;
  }

  public CanvasApplication(string[] args) {
    this.changes_recorder = History.HistoryOfChangesRecorder.instance;
    this.header_widgets = new CanvasHeaderbarWidgets();
    
    var data_node_factory = new CanvasNodeFactory();
    var file_origin_node_factory = new Data.FileOriginNodeFactory();
    var serializers = new Serialize.CustomSerializers();
    var deserializers = new Serialize.CustomDeserializers();
    
    var canvas_signals = new CanvasSignals();

    activate.connect (() => {
      this.window = new Gtk.ApplicationWindow(this);
      
      load_css();

      var plugin_contribution = new Plugin.PluginContribution(
        canvas_signals,
        data_node_factory,
        header_widgets,
        window,
        file_origin_node_factory,
        serializers,
        deserializers
      );

      initialize_image_plugin(plugin_contribution, args);

      this.canvas_view = new CanvasView(
        canvas_signals,
        data_node_factory,
        file_origin_node_factory,
        serializers,
        deserializers
      );

      canvas_signals.before_file_load.connect_after(this.before_file_load);
      canvas_signals.after_file_load.connect_after(this.after_file_load);

      build_header_bar();
      add_shortcuts(window);
      
      window.set_default_size(800, 600);
      window.set_child (canvas_view);
      window.present();
    });
  }

  private void before_file_load() {
    mark_busy();
    window.set_cursor_from_name("wait");
    window.set_sensitive(false);
    
    changes_recorder.pause();
  }

  private void after_file_load() {
    unmark_busy();
    window.set_cursor_from_name(null);
    window.set_sensitive(true);

    changes_recorder.clear();
    changes_recorder.resume();
  }

  private void load_css() {
    var css_provider = new Gtk.CssProvider();
    css_provider.load_from_resource("data/stylesheet.css");
    Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
  }

  private void build_header_bar() {
    var headerbar = new Gtk.HeaderBar ();

    headerbar.pack_start (canvas_view.create_node_chooser());

    var load_save_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    load_save_box.add_css_class("linked");
    load_save_box.append(canvas_view.create_load_graph_button());
    load_save_box.append(canvas_view.create_save_graph_button());
    load_save_box.append(canvas_view.create_save_graph_as_button());
    load_save_box.append(canvas_view.create_export_png_button());

    headerbar.pack_start(load_save_box);
    headerbar.pack_start(new History.HistoryButtonsWidget());
    headerbar.pack_end(create_theme_variant_switch());

    add_header_widgets(headerbar);

    window.set_titlebar(headerbar);
  }

  private void add_header_widgets(Gtk.HeaderBar headerbar) {
    foreach (var widget in header_widgets.get_widgets()) {
      headerbar.pack_start(widget);
    }
  }

  private Gtk.Widget create_theme_variant_switch() {
    return new ThemeVariantSwitch(new GLib.Settings(this.application_id));
  }
}

int main (string[] args) {
  var app = new CanvasApplication(args);
  return app.run(args);
}

