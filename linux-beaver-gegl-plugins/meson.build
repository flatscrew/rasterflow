gegl_dep = dependency('gegl-0.4')

shared_module('weaves',
  sources: ['weaves.c', 'config.h'],
  dependencies: [gegl_dep],
  install: true,
  install_dir: join_paths(get_option('libdir'), 'gegl-0.4', 'plug-ins'),
  include_directories: include_directories('.')
)
