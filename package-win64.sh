#!/usr/bin/env bash
set -e

APP_NAME="rasterflow"
BUILD_DIR="build"
DIST_DIR="dist"

echo "🧹 Cleaning old dist..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
mkdir -p "$DIST_DIR/lib"
mkdir -p "$DIST_DIR/share/glib-2.0/schemas"

echo "📦 Copying main binary..."
cp "$BUILD_DIR/$APP_NAME.exe" "$DIST_DIR/"

# Copy plugin dirs (keep relative layout)
echo "📂 Copying GEGL & BABL plugins..."
cp -r /mingw64/lib/gegl-0.4 "$DIST_DIR/lib/" || true
cp -r /mingw64/lib/babl-0.1 "$DIST_DIR/lib/" || true

# Helper: copy deps of a file
copy_deps() {
    local file="$1"
    echo "🔍 Checking deps for $(basename "$file")"
    ldd "$file" | while read -r line; do
        dep=$(echo "$line" | awk '{print $3}')
        if [[ "$dep" == /mingw64/bin/* && -f "$dep" ]]; then
            cp -u "$dep" "$DIST_DIR/" && echo "   ✅ Copied: $(basename "$dep")"
        elif [[ "$dep" == /c/* || "$dep" == C:\\* ]]; then
            echo "   ⚠️ Skipped system DLL: $dep"
        fi
    done
}

# Collect DLLs for main exe
echo "🔗 Collecting DLLs for $APP_NAME.exe"
copy_deps "$BUILD_DIR/$APP_NAME.exe"

# Collect DLLs for GEGL plugins
for dll in "$DIST_DIR"/lib/gegl-0.4/*.dll; do
    [ -f "$dll" ] && copy_deps "$dll"
done

# Collect DLLs for BABL plugins
for dll in "$DIST_DIR"/lib/babl-0.1/*.dll; do
    [ -f "$dll" ] && copy_deps "$dll"
done

echo "🗂 Copying schemas..."
cp -r /mingw64/share/glib-2.0/schemas/* "$DIST_DIR/share/glib-2.0/schemas/" || true
glib-compile-schemas "$DIST_DIR/share/glib-2.0/schemas/" || true

echo "✅ Done!"
