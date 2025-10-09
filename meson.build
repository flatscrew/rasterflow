project('vala app', 'vala', 'c', 'cpp',
  default_options : ['warning_level=3', 'cpp_std=c++17', 'buildtype=debug']
)

app_version = get_option('version') 
conf = configuration_data()
conf.set('version', app_version)

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
    dependency('gegl-0.4')
]

# generating runtime binary
resource_files = files('rasterflow.gresource.xml')
gresources = gnome.compile_resources('rasterflow-resources', resource_files, source_dir : ['data'])

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

# vala sources
vala_sources = [
    'src/main.vala',
    'src/theme_variant_switch.vala',
    'src/data_drop_handler.vala',
    'src/canvas_view.vala',
    'src/canvas_node.vala',
    'src/canvas_nodes.vala',
    'src/canvas_logs.vala',
    'src/canvas_headerbar.vala',
    'src/minimap.vala',
    'src/colors.vala',

    'src/serialize/canvas_serializer.vala',
    'src/serialize/canvas_deserializer.vala',
    'src/serialize/json_serializer.vala',
    'src/serialize/json_deserializer.vala',

    # generic data
    'src/data/data_property.vala',
    'src/data/title_bar.vala',
    'src/data/node_data.vala',
    'src/data/data_node_chooser.vala',
    'src/data/data_details_panel.vala',
    'src/data/data_display_view.vala',
    'src/data/data_properties_editor.vala',
    'src/data/data_properties_toggle.vala',
    'src/data/data_property_file_location.vala',
    'src/data/file_origin_node_factory.vala',
    'src/data/file_origin_node_chooser.vala',

    # image processing
    'src/image/image_data_node.vala',
    'src/image/image_file_data_node.vala',
    'src/image/image_viewer.vala',
    'src/image/gegl_operation_node.vala',
    'src/image/gegl_operation_overrides.vala',
    'src/image/gegl_file_load_title.vala',
    'src/image/gegl_node_operation_view.vala',
    'src/image/plugin.vala',
    
    # plain text processing
    'src/text/text_node.vala',
    'src/text/plugin.vala',
    
    # plugins
    'src/plugin/plugin_contribution.vala'
]

executable(
  'rasterflow',
  c_sources,
  vala_sources,
  gresources,
  dependencies: dependencies,
  include_directories: include_dirs,
  vala_args: [
    '--vapidir', meson.current_source_dir() + '/vapi',
    '--pkg=gegl_wrapper'
  ],
  install: true,
  install_dir: join_paths(get_option('prefix'), 'bin'),
  gui_app: true
)

# Install the .gschema.xml file
install_data('io.flatscrew.RasterFlow.gschema.xml',
             install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'))
gnome.post_install(glib_compile_schemas: true)