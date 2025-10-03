pkgconfig = import('pkgconfig')

# Dependencies
dependencies = [
  dependency('tesseract'),
  dependency('gdk-pixbuf-2.0'),
  dependency('lept')
]

# Source files
wrapper_sources = files('src/wrapper.cpp')

# Build the shared library
tesseract_wrapper_lib = library('tesseractwrapper', wrapper_sources,
  dependencies : dependencies,
  install : true
)
tesseract_wrapper_inc = include_directories('.')

tesseract_wrapper_dep = declare_dependency(
  include_directories : include_directories('src'),
  link_with : tesseract_wrapper_lib,
  sources : files('vapi/tesseract-wrapper.vapi')
)

# Generate and install a pkg-config file
pkgconfig.generate(
  name : 'tesseract-wrapper',
  description : 'C++ Wrapper for Tesseract',
  version : meson.project_version(),
  libraries : tesseract_wrapper_lib
)

# Install headers
#headerfilename = meson.current_build_dir () + '/src/wrapper.h'
#install_headers(headerfilename, subdir: 'tesseract-wrapper')