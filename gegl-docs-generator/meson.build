project_name = 'gegl_docs_generator'

executable(
  project_name,
  'main.vala',
  dependencies: [
    dependency('glib-2.0'),
    dependency('gee-0.8'),
    dependency('gegl-0.4'),
  ],
  vala_args: [
    '--pkg=gegl-0.4'
  ],
  install: false
)
