project('vala app', 'vala', 'c', 'cpp',
version : '0.1',
  default_options : ['warning_level=3', 'cpp_std=c++17', 'buildtype=debug']
)

gnome = import('gnome')

# Tesseract wrapper
#subdir('tesseract_wrapper')

# gstreamer test
subdir('gst_test')

# Gtk.ColumnView test
subdir('columnview_test')

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
    dependency('gstreamer-1.0'),
    dependency('gstreamer-base-1.0'),
    dependency('gstreamer-video-1.0'),

    dependency('gtksourceview-5'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('vala').find_library('linux'),

]

# generating runtime binary
resource_files = files('rasterflow.gresource.xml')
gresources = gnome.compile_resources('rasterflow-resources', resource_files, source_dir : ['data'])

# VAPI directories
vapi_dirs = [
  'vapi/'
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

    'src/guard/extractor.vala',
    'src/guard/frame.vala',
    'src/guard/printer.vala',
    'src/guard/stacktrace.vala',

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
    'src/image/image_resize_node.vala',
    #'src/image/image_ocr_node.vala',
    'src/image/image_viewer.vala',
    'src/image/gegl_operation_node.vala',
    'src/image/gegl_operation_overrides.vala',
    'src/image/plugin.vala',
    
    # plain text processing
    'src/text/text_node.vala',
    'src/text/plugin.vala',
    
    # pdf processing
    #'src/pdf/pdf_file_data_node.vala',
    #'src/pdf/pdf_viewer.vala',
    #'src/pdf/extract_page_as_image_node.vala',
    #'src/pdf/plugin.vala',

    # audio/video processing
    'src/audiovideo/gst_pipeline.vala',
    'src/audiovideo/gst_pipeline_controls.vala',
    'src/audiovideo/gst_element_overrides.vala',
    'src/audiovideo/gst_element_node.vala',
    'src/audiovideo/gst_element_display_node.vala',
    'src/audiovideo/audio_video_file_data_node.vala',
    'src/audiovideo/gst_structure_list.vala',
    'src/audiovideo/gst_caps_view.vala',
    'src/audiovideo/gst_caps_editor.vala',
    'src/audiovideo/gst_structure_properties.vala',
    'src/audiovideo/gst_property_structure.vala',
    'src/audiovideo/gst_property_camera_device.vala',
    'src/audiovideo/gst_property_pad.vala',
    'src/audiovideo/gst_request_element_pad_button.vala',
    'src/audiovideo/gst_gtk4sink_view.vala',
    'src/audiovideo/gst_shader_code_editor.vala',
    'src/audiovideo/gst_geglfilters.vala',
    'src/audiovideo/plugin.vala',

    # plugins
    'src/plugin/plugin_contribution.vala',
    #'src/plugin/plugin_loader.vala',
]

executable(
  'rasterflow', 
  vala_sources, 
  gresources, 
  dependencies: dependencies, 
  vala_args: ['--vapidir', meson.current_source_dir() + '/vapi'],
  install: true,
  install_dir: join_paths(get_option('prefix'), 'bin'),
)

# Install the .gschema.xml file
install_data('io.flatscrew.RasterFlow.gschema.xml',
             install_dir: join_paths(get_option('datadir'), 'glib-2.0', 'schemas'))
gnome.post_install(glib_compile_schemas: true)