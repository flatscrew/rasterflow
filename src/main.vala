using Gtk;
using Adw;

public class CanvasSignals : Object {
  public signal void before_file_load();
  public signal void after_file_load();
}

class CanvasApplication : Gtk.Application {

  private AppSettings settings;
  private History.HistoryOfChangesRecorder changes_recorder;
  private CanvasView canvas_view;
  private Adw.ApplicationWindow? window;

  construct {
    base.application_id = "io.canvas.Canvas";
    base.flags = ApplicationFlags.FLAGS_NONE;
    this.settings = new AppSettings(this.application_id);
    this.changes_recorder = History.HistoryOfChangesRecorder.instance;

    Adw.init();
  }
  
  public CanvasApplication(string[] args) {
    var header_widgets = new CanvasHeaderbarWidgets();
    var data_node_factory = new CanvasNodeFactory();
    var file_origin_node_factory = new Data.FileOriginNodeFactory();
    var serializers = new Serialize.CustomSerializers();
    var deserializers = new Serialize.CustomDeserializers();
    var canvas_signals = new CanvasSignals();

    activate.connect (() => {
      this.window = new Adw.ApplicationWindow(this);
      window.close_request.connect(this.window_closed);
      
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

      Data.register_standard_types();
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

      var toolbar_view = build_toolbar_view(header_widgets);

      add_shortcuts(window);
      
      window.set_default_size(800, 600);
      window.set_content(toolbar_view);
      window.present();
      
      var window_dimensions = settings.read_window_dimensions();
      WindowGeometryManager.set_geometry(window, window_dimensions);
    });
  }
  
  private bool window_closed() {
    var dimensions = WindowGeometryManager.get_geometry(this.window);
    this.settings.write_window_dimensions(dimensions);
    return false;
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
    Gtk.StyleContext.add_provider_for_display(
      Gdk.Display.get_default(),
      css_provider,
      Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    );
  }

  private Adw.ToolbarView build_toolbar_view(CanvasHeaderbarWidgets header_widgets) {
    var headerbar = new Adw.HeaderBar();
    headerbar.show_end_title_buttons = true;
    headerbar.show_start_title_buttons = true;

    var nodes_properties_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    nodes_properties_box.add_css_class("linked");
    nodes_properties_box.append(canvas_view.create_node_chooser().get_menu_button());
    nodes_properties_box.append(canvas_view.create_properties_toggle());
    headerbar.pack_start(nodes_properties_box);

    var load_save_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
    load_save_box.add_css_class("linked");
    load_save_box.append(canvas_view.create_load_graph_button());
    load_save_box.append(canvas_view.create_save_graph_button());
    load_save_box.append(canvas_view.create_save_graph_as_button());
    load_save_box.append(canvas_view.create_export_png_button());

    headerbar.pack_start(load_save_box);
    headerbar.pack_start(new History.HistoryButtonsWidget());

    foreach (var widget in header_widgets.get_widgets()) {
      headerbar.pack_start(widget);
    }

    headerbar.pack_start(new CanvasLogButton());
    
    var toolbar_view = new Adw.ToolbarView();
    toolbar_view.add_top_bar(headerbar);
    toolbar_view.set_content(canvas_view);

    return toolbar_view;
  }
}

int main (string[] args) {
  var app = new CanvasApplication(args);
  return app.run(args);
}
