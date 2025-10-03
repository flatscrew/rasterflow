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
    });

    plugin_contribution.contribute_canvas_node_factory(node_factory => {
        node_factory.register(new Image.ImageDataDisplayNodeBuilder(),
          typeof(Gdk.Pixbuf)
        );
        node_factory.register(new Image.ImageResizeNodeBuilder(),
          typeof(Gdk.Pixbuf)
        );
        //  node_factory.register(new Image.ImageOCRNodeBuilder(),
        //    typeof(Gdk.Pixbuf)
        //  );

        Image.GeglOperationsFactory.register_gegl_operations(args, node_factory);
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

    // overrides
    Image.GeglOperationOverrides.override_operation("gegl:load", overrides => {
        overrides.override_property("path", (param_spec) => {
          return new Data.FileLocationProperty(param_spec as ParamSpecString);
        });
    });

    // custom data types
    Data.CustomPropertyFactory.get_instance()
        .register(typeof(Gegl.Color), param_spec => {
            return new Data.ColorProperty(param_spec);
        });

	return "image";
}