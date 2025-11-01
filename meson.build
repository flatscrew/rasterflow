project('vala app', 'vala', 'c', 'cpp',
  default_options : ['warning_level=3', 'cpp_std=c++17', 'buildtype=debug']
)

app_version = get_option('version') 
conf = configuration_data()
conf.set('version', app_version)

config_vala = configure_file(
  input: 'config.vala.in',
  output: 'config.vala',
  configuration: {
    'APP_VERSION': app_version
  }
)

if host_machine.system() == 'windows'
  add_project_arguments('--define=WIN32', language : 'vala')
elif host_machine.system() == 'linux'
  add_project_arguments('--define=LINUX', language : 'vala')
endif

gnome = import('gnome')

# Dependencies
dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4'),
    dependency('gflow-1.0'),
    dependency('gtkflow4-0.2'),
    dependency('gee-0.8'),
    dependency('gio-2.0'),
    dependency('json-glib-1.0'),
    dependency('gegl-0.4'),
    dependency('libadwaita-1')
]

if host_machine.system() == 'linux'
  dependencies += [
    dependency('gtk4-x11'),
    dependency('x11'),
    dependency('libportal'),
    dependency('libportal-gtk4'),
  ]
endif

# generating runtime binary
resource_files = files('data/rasterflow.gresource.xml')
gresources = gnome.compile_resources('rasterflow-resources', resource_files, source_dir : 'data')

vala_args = [
  '--vapidir', meson.current_source_dir() + '/vapi',
  '--pkg=gegl_wrapper'
]

# VAPI directories
vapi_dirs = [
  'vapi/'
]

include_dirs = [
  'include/'
]

# c sources
c_sources = [
  # gegl wrapper for missing methods in system vapi
  'src/gegl/gegl_wrapper.c'
]

if host_machine.system() == 'windows' 
  c_sources += [
    # windows implementation for getting/setting window size
    'src/image/windows/windows_window_size.c'
  ]

  vala_args += [
    '--vapidir', meson.current_source_dir() + '/vapi', 
    '--pkg=windows_window_size'
  ]
endif

# vala sources
vala_sources = [
    config_vala,
    'src/main.vala',
    'src/application_settings.vala',
    'src/minimap.vala',
    'src/window_geometry.vala',
    'src/window_shortcuts.vala',
    'src/data_drop_handler.vala',
    'src/canvas_view.vala',
    'src/canvas_node.vala',
    'src/canvas_display_node.vala',
    'src/canvas_node_task.vala',
    'src/canvas_node_action_bar.vala',
    'src/canvas_graph_property.vala',
    'src/canvas_graph_property_list.vala',
    'src/canvas_graph.vala',
    'src/canvas_graph_modification_guard.vala',
    'src/canvas_logs.vala',
    'src/canvas_log_button.vala',
    'src/canvas_log_window.vala',
    'src/canvas_menu_button.vala',
    'src/canvas_headerbar.vala',
    'src/canvas_graph_properties_editor.vala',
    'src/add_graph_property_popover.vala',
    'src/colors.vala',
    'src/panning_scrolled_window.vala',
    'src/zoomable_area.vala',

    # serialization
    'src/serialize/canvas_serializer.vala',
    'src/serialize/canvas_deserializer.vala',
    'src/serialize/json_serializer.vala',
    'src/serialize/json_deserializer.vala',

    # property node
    'src/property/canvas_property_node.vala',

    # generic data
    'src/data/data_property.vala',
    'src/data/data_property_factory.vala',
    'src/data/title_bar.vala',
    'src/data/node_data.vala',
    'src/data/data_node_chooser.vala',
    'src/data/data_details_panel.vala',
    'src/data/data_display_view.vala',
    'src/data/data_properties_editor.vala',
    'src/data/data_property_file_location.vala',
    'src/data/file_origin_node_factory.vala',
    'src/data/file_origin_node_chooser.vala',

    # image processing
    'src/image/image_data_node.vala',
    'src/image/image_file_data_node.vala',
    'src/image/image_viewer.vala',
    'src/image/image_processing_realtime_mode_switch.vala',
    'src/image/image_external_window.vala',
    'src/image/gegl_operation_node.vala',
    'src/image/gegl_operation_display_node.vala',
    'src/image/gegl_operation_overrides.vala',
    'src/image/gegl_operation_property_sink.vala',
    'src/image/gegl_file_load_title.vala',
    'src/image/gegl_node_operation_view.vala',
    'src/image/gegl_xml_file_node.vala',
    'src/image/gxml/gxml_export.vala',
    'src/image/color_property.vala',
    'src/image/history/gegl_node_property_control_taken_action.vala',
    'src/image/history/gegl_node_property_control_released_action.vala',
    'src/image/plugin.vala',
    
    # plain text processing
    'src/text/text_node.vala',
    'src/text/plugin.vala',
    
    # plugins
    'src/plugin/plugin_contribution.vala',

    # history
    'src/history/history_action.vala',
    'src/history/history_action_stack.vala',
    'src/history/history_of_changes.vala',
    'src/history/history_buttons_widget.vala',
    'src/history/action/move_node_action.vala',
    'src/history/action/remove_node_action.vala',
    'src/history/action/add_node_action.vala',
    'src/history/action/add_property_node_action.vala',
    'src/history/action/remove_property_node_action.vala',
    'src/history/action/add_graph_property_action.vala',
    'src/history/action/remove_graph_property_action.vala',
    'src/history/action/resize_node_action.vala',
    'src/history/action/toggle_expander_action.vala',
    'src/history/action/change_property_action.vala',
    'src/history/action/link_nodes_action.vala',
    'src/history/action/unlink_nodes_action.vala',
    'src/history/action/change_node_color_action.vala',
    'src/history/action/composite_action.vala',
    
    # about
    'src/about/about_dialog.vala',
    'src/about/shortcuts_window.vala',
    
]

if host_machine.system() == 'linux'
  vala_sources += [
    'src/image/color_prober.vala',
  ]
endif

executable(
  'rasterflow',
  c_sources,
  vala_sources,
  gresources,
  dependencies: dependencies,
  include_directories: include_dirs,
  vala_args: vala_args,
  install: true,
  install_dir: join_paths(get_option('prefix'), 'bin'),
  gui_app: true
)

# Install the .gschema.xml file
install_data('io.flatscrew.RasterFlow.gschema.xml',
             install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'))
gnome.post_install(glib_compile_schemas: true)