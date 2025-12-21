public static void init_environment() {
#if WIN32
    init_windows();
#endif
}

#if WIN32
[CCode (cheader_filename = "glib.h", cname = "g_win32_get_package_installation_directory_of_module")]
extern string get_install_dir (void* hmodule);

private static void init_windows() {
    var base_dir = get_install_dir(null);

    message("base dir: %s", base_dir);

    Environment.set_variable("GSETTINGS_SCHEMA_DIR",
        Path.build_filename(base_dir, "share", "glib-2.0", "schemas"), true);
    Environment.set_variable("BABL_PATH",
        Path.build_filename(base_dir, "lib", "babl-0.1"), true);
    Environment.set_variable("GEGL_PATH",
        Path.build_filename(base_dir, "lib", "gegl-0.4"), true);
}
#endif


