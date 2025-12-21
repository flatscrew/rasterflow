vala_sources = [
    'main.vala',
    scale_entry
]

dependencies = [
    m,
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk4'),
    dependency('gflow-1.0'),
    dependency('gtkflow4-0.2.3'),
    dependency('gee-0.8'),
    dependency('gio-2.0'),
    dependency('json-glib-1.0'),
    dependency('babl-0.1'),
    dependency('gegl-0.4'),
    dependency('libadwaita-1'),
]

executable(
  'spinner-test',
  vala_sources,
  dependencies: dependencies,
)
