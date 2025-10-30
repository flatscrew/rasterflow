using Gtk;
using Adw;

class CanvasApplication : Adw.Application {

  private AppSettings settings;
  private History.HistoryOfChangesRecorder changes_recorder;
  private CanvasView canvas_view;
  private Adw.ApplicationWindow? window;
  
  private About.AboutDialog about_dialog;
  private About.AboutRegistry about_registry;

  construct {
    base.application_id = "io.canvas.Canvas";
    base.flags = ApplicationFlags.FLAGS_NONE;
    this.settings = new AppSettings(this.application_id);
    this.changes_recorder = History.HistoryOfChangesRecorder.instance;

    Adw.init();
    Data.register_standard_types();
    load_css();
    
    var display = Gdk.Display.get_default();
    var theme = Gtk.IconTheme.get_for_display(display);
    theme.add_resource_path("/icons");
  }
  
  public CanvasApplication(string[] args) {
    this.about_registry = new About.AboutRegistry();
    var header_widgets = new CanvasHeaderbarWidgets();
    var data_node_factory = new CanvasNodeFactory();
    var file_origin_node_factory = new Data.FileOriginNodeFactory();
    var serializers = new Serialize.CustomSerializers();
    var deserializers = new Serialize.CustomDeserializers();

    activate.connect (() => {
      this.window = new Adw.ApplicationWindow(this);
      window.set_title("RasterFlow");
      window.set_icon_name("io.canvas.Canvas");
      window.close_request.connect(this.window_closed);
      
      var plugin_contribution = new Plugin.PluginContribution(
        data_node_factory,
        header_widgets,
        window,
        file_origin_node_factory,
        serializers,
        deserializers,
        about_registry
      );

      initialize_image_plugin(plugin_contribution, args);

      this.canvas_view = new CanvasView(
        data_node_factory,
        file_origin_node_factory,
        serializers,
        deserializers
      );
      canvas_view.before_file_load.connect_after(this.before_file_load);
      canvas_view.after_file_load.connect_after(this.after_file_load);
      canvas_view.show_properties_sidebar(settings.is_sidebar_visible());

      this.about_dialog = new About.AboutDialog(this.about_registry);
      
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
    this.settings.write_sidebar_visible(canvas_view.is_properties_sidebar_shown());
    return false;
  }

  private void before_file_load() {
    mark_busy();
    window.set_cursor_from_name("wait");
    window.set_sensitive(false);
    changes_recorder.pause();
  }

  private void after_file_load(string? file_name) {
    unmark_busy();
    
    window.set_cursor_from_name(null);
    window.set_sensitive(true);
    window.set_title("RasterFlow - %s".printf(file_name));
    
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
    headerbar.pack_end(build_menu_button());
    
    var toolbar_view = new Adw.ToolbarView();
    toolbar_view.add_top_bar(headerbar);
    toolbar_view.set_content(canvas_view);
    return toolbar_view;
  }
  
  private Gtk.MenuButton build_menu_button() {
    var menu_button = new Gtk.MenuButton();
    var popover = new Gtk.Popover();
    var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
    var about_button = new Gtk.Button.with_label("About");
    about_button.clicked.connect(() => {
        popover.popdown();
        about_dialog.present(window);
    });
    box.append(about_button);

    popover.set_child(box);
    menu_button.set_popover(popover);

    return menu_button;
  }

}

int main (string[] args) {
  var app = new CanvasApplication(args);
  return app.run(args);
}
