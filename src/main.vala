using Gtk;
using Adw;

class CanvasApplication : Adw.Application {

  private AppSettings settings;
  private History.HistoryOfChangesRecorder changes_recorder;
  private CanvasView canvas_view;
  private Adw.ApplicationWindow? window;
  private CanvasGraphModificationGuard modification_guard;
  private bool window_close_confirmed;
  private string? current_file;
  
  private AppMenu menu;
  private AppShortcutsWindowInstance shortcuts_window;
  private About.AboutDialog about_dialog;
  private About.AboutRegistry about_registry;

  construct {
    base.application_id = "io.flatscrew.RasterFlow";
    base.flags = ApplicationFlags.FLAGS_NONE;
    this.settings = new AppSettings(this.application_id);
    this.changes_recorder = History.HistoryOfChangesRecorder.instance;
    
    this.about_registry = new About.AboutRegistry();
    init_about_registry();
    
    Adw.init();
    Data.register_standard_types();
    load_css();
    
    var display = Gdk.Display.get_default();
    var theme = Gtk.IconTheme.get_for_display(display);
    theme.add_resource_path("/icons");
  }
  
  public CanvasApplication(string[] args) {
    var header_widgets = new CanvasHeaderbarWidgets();
    var data_node_factory = new CanvasNodeFactory();
    var file_origin_node_factory = new Data.FileOriginNodeFactory();
    var serializers = new Serialize.CustomSerializers();
    var deserializers = new Serialize.CustomDeserializers();

    activate.connect (() => {
      GtkFlow.init();

      this.window = new Adw.ApplicationWindow(this);
      window.set_title("RasterFlow");
      window.set_icon_name("io.flatscrew.RasterFlow");
      window.close_request.connect(this.window_closed);
      
      this.modification_guard = CanvasGraphModificationGuard.instance;
      this.modification_guard.dirty_state_changed.connect(this.dirty_changed);
      
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

      this.about_dialog = new About.AboutDialog(this.about_registry);
      this.canvas_view = new CanvasView(
        data_node_factory,
        file_origin_node_factory,
        serializers,
        deserializers
      );
      canvas_view.before_file_load.connect_after(this.before_file_load);
      canvas_view.after_file_load.connect_after(this.after_file_load);
      canvas_view.after_file_save.connect_after(this.after_file_save);
      canvas_view.show_properties_sidebar(settings.is_sidebar_visible());

      var toolbar_view = build_toolbar_view(header_widgets);
      window.set_default_size(800, 600);
      window.set_content(toolbar_view);
      window.present();
      
      canvas_view.setup_popovers();

      try {
        add_actions_and_shortcuts();
      } catch (Error e) {
        warning(e.message);
      }
      add_screenshot_window_resize_controller();

      var window_dimensions = settings.read_window_dimensions();
      WindowGeometryManager.set_geometry(window, window_dimensions);
    });
  }
  
  private void add_screenshot_window_resize_controller() {

  }

  private void add_actions_and_shortcuts() throws Error {
    var actions = new SimpleActionGroup();
    
    actions.add_action(create_undo_action());
    actions.add_action(create_redo_action());
    actions.add_action(canvas_view.create_save_action());
    actions.add_action(create_window_resize_action(window));
    window.insert_action_group("app", actions);
    
    set_accels_for_action("app.undo", { "<Control>z" });
    set_accels_for_action("app.redo", { "<Control><Shift>z" });
    set_accels_for_action("app.save", { "<Control>s" });
    set_accels_for_action("app.window_resize", { "<Control><Shift><Alt>q" });
    
    this.shortcuts_window = new AppShortcutsWindowBuilder(this.window)
        .new_section("General")
            .new_group("Editing")
                .add("Undo last operation", "<Ctrl>z")
                .add("Redo last operation", "<Ctrl><Shift>z")
                .add("Save current graph", "<Ctrl>s")
            .end_group()
        .end_section()
        .build();
  }
  
  private void init_about_registry() {
    about_registry.add_entry("GTK Version", "%u.%u.%u".printf(
      Gtk.get_major_version(),
      Gtk.get_minor_version(),
      Gtk.get_micro_version()  
    ));
  }
  
  private void dirty_changed(bool dirty) {
    update_title(dirty);
  }
  
  private async void run_async_window_closed() {
    if (!(yield modification_guard.confirm_discard_if_dirty(window))) {
        return;
    }
    
    this.window_close_confirmed = true;
    var dimensions = WindowGeometryManager.get_geometry(this.window);
    this.settings.write_window_dimensions(dimensions);
    this.settings.write_sidebar_visible(canvas_view.is_properties_sidebar_shown());
    window.close();
  }
  
  private bool window_closed() {
    if (window_close_confirmed) {
      return false;
    }
    
    run_async_window_closed.begin();
    return !window_close_confirmed;
  }

  private void before_file_load() {
    mark_busy();
    window.set_cursor_from_name("wait");
    window.set_sensitive(false);
    changes_recorder.pause();
  }

  private void after_file_load(string file_name) {
    unmark_busy();
    window.set_cursor_from_name(null);
    window.set_sensitive(true);
    
    this.current_file = file_name;
    update_title();
    
    changes_recorder.clear();
    changes_recorder.resume();
  }
  
  private void after_file_save(string file_name) {
    this.current_file = file_name;
    update_title();
  }
  
  private void update_title(bool dirty = false) {
    var title = "RasterFlow";
    if (current_file != null) {
      title = "RasterFlow - %s".printf(current_file);
    }
    
    if (dirty) {
      title += " *";
    }
    
    window.set_title(title);
  }

  private void load_css() {
    var css_provider = new Gtk.CssProvider();
    css_provider.load_from_resource("data/stylesheet.css");
    Gtk.StyleContext.add_provider_for_display(
      Gdk.Display.get_default(),
      css_provider,
      Gtk.STYLE_PROVIDER_PRIORITY_USER
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
    this.menu = new AppMenu();
    menu.about_selected.connect(() => about_dialog.present(window));
    menu.shortcuts_selected.connect(() => shortcuts_window.use_with(window).present());
    return menu.button;
  }
}

int main (string[] args) {
  var app = new CanvasApplication(args);
  return app.run(args);
}
