# Building RasterFlow

## Requirements

The following tools must be installed and available in your system:

- Meson
- Ninja
- Vala compiler (`valac`)
- pkg-config

Required libraries:
- GTK4
- Libadwaita
- [libgflow](https://www.github.com/flatscrew/libgflow) and [libgtkflow4](https://www.github.com/flatscrew/libgtkflow4) (must be built and installed before RasterFlow)
- GEGL
- BABL
- GLib / GObject / GIO
- JSON-GLib
- LibGee
- GObject Introspection

---

## Linux

Install build dependencies (package names may vary by distribution):

### Fedora

```bash
sudo dnf install gtk4-devel libadwaita-devel gegl-devel babl-devel \
                 vala json-glib-devel libgee-devel meson ninja-build \
                 gobject-introspection-devel
```

### Debian / Ubuntu

```bash
sudo apt install valac meson ninja-build libgtk-4-dev libadwaita-1-dev \
                 libgegl-0.4-dev libbabl-dev libgee-0.8-dev \
                 libjson-glib-dev gobject-introspection libglib2.0-dev
```

Then build and install **libgtkflow**:

```bash
git clone https://github.com/flatscrew/libgtkflow.git
cd libgtkflow
meson setup build -Denable_gtk3=false
meson compile -C build
sudo meson install -C build
```

Build RasterFlow:
```bash
git clone https://github.com/flatscrew/rasterflow.git
cd rasterflow
meson setup build
meson compile -C build
sudo meson install -C build
```

To run without installing, execute the binary directly from the build directory:
```bash
./build/rasterflow
```

## Local Installation
If you prefer to install locally without root privileges:

```bash
meson setup build --prefix=$HOME/.local
meson install -C build
```

## Notes
- On Linux, libportal and libportal-gtk4 may be required for full XDG integration,
- On Windows, ensure all commands are executed inside the MINGW64 environment,
- The .desktop file and GSettings schema are installed automatically during meson install
