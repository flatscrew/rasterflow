string get_label_from_path(Gegl.Operation op, string name) {
    GLib.Value val = GLib.Value(typeof(string));
    op.get_property(name, ref val);
    var path = (string) val;

    if (path == null || path.strip() == "")
        return "Load file";

    return GLib.Path.get_basename(path);
}

private Gtk.Widget gegl_load_title_override(Gegl.Operation operation) {
    var label = new Gtk.Label("Load file");
    label.label = get_label_from_path(operation, "path");
    label.ellipsize = Pango.EllipsizeMode.MIDDLE;
    label.set_size_request(120, -1);
    operation.notify["path"].connect(() => {
        label.label = get_label_from_path(operation, "path");
    });
    return label;
}

private GLib.ListStore build_pixbuf_filters() {
    var filters = new GLib.ListStore(typeof(Gtk.FileFilter));

    var all_images_filter = new Gtk.FileFilter();
    all_images_filter.name = "All supported image files";
    foreach (var fmt in Gdk.Pixbuf.get_formats()) {
        foreach (var ext in fmt.get_extensions()) {
            all_images_filter.add_pattern(@"*.$ext");
        }
    }
    filters.append(all_images_filter);

    foreach (var fmt in Gdk.Pixbuf.get_formats()) {
        var f = new Gtk.FileFilter();
        f.name = fmt.get_description();

        foreach (var ext in fmt.get_extensions()) {
            f.add_pattern(@"*.$ext");
        }

        foreach (var mime in fmt.get_mime_types()) {
            f.add_mime_type(mime);
        }

        filters.append(f);
    }
    return filters;
}

public string initialize_image_plugin(Plugin.PluginContribution plugin_contribution, string[] args) {
    Gegl.config().application_license = "GPL3";
    Gegl.init(ref args);

    new Image.GeglOperationOverrides();

    plugin_contribution.contribute_file_data_node_factory(node_factory => {
        string[] mime_types = {};
        foreach (var format in Gdk.Pixbuf.get_formats ()) {
          foreach (var mimetype in format.get_mime_types()) {
            mime_types += mimetype;
          }
        }
        node_factory.register(
          new Image.ImageFileDataDisplayNodeBuilder(),
          mime_types
        );

        // GEGL XML files
        node_factory.register(
            new Image.GeglXmlFileOriginNodeBuilder(), 
            {"application/xml"}
        );
    });

    plugin_contribution.contribute_canvas_node_factory(node_factory => {
        node_factory.register(new Image.GeglXmlDisplayNodeBuilder());

        Image.GeglOperationsFactory.register_gegl_operations(node_factory);
    });

    // serializers
    plugin_contribution.contribute_canvas_serializer((serializers, deserializers) => {
      serializers.register_custom_type(typeof(Gegl.Color), (value, serialized_object) => {
          var color = value as Gegl.Color;
          serialized_object.set_string("color", color.string);
      });
  
      deserializers.register_custom_type(typeof(Gegl.Color), deserialized_object => {
        var color_string = deserialized_object.get_string("color");
          if (color_string == null)
              return null;
          return new Gegl.Color(color_string);
      });
    });

    plugin_contribution.contribute_canvas_headerbar(headerbar_widgets => {
        headerbar_widgets.add_widget(new Image.ImageProcessingRealtimeModeSwitch());
    });

#if LINUX
    plugin_contribution.contribute_app_window(app_window => {
        Image.ColorProber.init(app_window);
    });
#endif

    // overrides
    Image.GeglOperationOverrides.override_operation("gegl:load", overrides => {
        overrides.override_title(gegl_load_title_override);
        overrides.override_property("path", (param_spec) => {
            var filters = build_pixbuf_filters();
            return new Data.FileLocationProperty.with_file_filters(param_spec as ParamSpecString, filters);
        });
    });
    Image.GeglOperationOverrides.override_operation("gegl:save-pixbuf", overrides => {
        overrides.override_content((display_node, node) => {
            var image_view = new Image.ImageDataView(display_node, node);
            
            display_node.add_action_bar_child_start(image_view.create_save_button());
            display_node.add_action_bar_child_end(image_view.create_zoom_control());
            return image_view;
        });
    });
    
    // TODO make it in plugin contribution instead?
    // custom data types for property editor
    Data.DataPropertyFactory.instance.register(typeof(Gegl.Color), param_spec => {
        return new Image.ColorProperty(param_spec);
    });

	return "image";
}