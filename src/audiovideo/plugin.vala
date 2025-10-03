public string initialize_audiovideo_plugin(Plugin.PluginContribution plugin_contribution, string[] args) {
    Gst.init(ref args);
    new AudioVideo.GstElementOverrides();

    // plugin contributions

    plugin_contribution.contribute_canvas_node_factory(node_factory => {
        AudioVideo.GstOperationsFactory.register_gst_operations(args, node_factory);

        node_factory.register(new AudioVideo.GeglSourceDisplayNodeBuilder(), typeof(Gst.Element));
        node_factory.register(new AudioVideo.GeglSinkDisplayNodeBuilder(), typeof(Gst.Element));

    });

    plugin_contribution.contribute_file_data_node_factory(node_factory => {
        node_factory.register(
          new AudioVideo.AudioVideoFileDataDisplayNodeBuilder(),
          {"^video/.*$", "^image/.*$"}
        );
    });


    plugin_contribution.contribute_canvas_headerbar(contribution => {
        contribution.add_widget(new AudioVideo.GstPipelineControls());
    });

    // overrides
    AudioVideo.GstElementOverrides.override_element("v4l2src", overrides => {
        overrides.override_property("device", (param_spec) => {
            return new AudioVideo.CameraDeviceProperty(param_spec as ParamSpecString);
        });
    });

    AudioVideo.GstElementOverrides.override_element("filesrc", overrides => {
        overrides.override_property("location", (param_spec) => {
            return new Data.FileLocationProperty(param_spec as ParamSpecString);
        });
    });

    AudioVideo.GstElementOverrides.override_element("gtk4paintablesink", overrides => {
        overrides.override_whole(element => {
            return new AudioVideo.GstGtk4PaintableSinkView(element);
        });
    });

    AudioVideo.GstElementOverrides.override_element("glshader", overrides => {
        overrides.override_property("fragment", (param_spec) => {
            return new AudioVideo.GstShaderCodeEditor(param_spec as ParamSpecString);
        });

        overrides.override_property("vertex", (param_spec) => {
            return new AudioVideo.GstShaderCodeEditor(param_spec as ParamSpecString);
        });
    });

    AudioVideo.GstElementOverrides.override_element("input-selector", overrides => {
        overrides.override_property("active-pad", (param_spec, data_object) => {
            var gst_element = data_object as Gst.Element;
            return new AudioVideo.PadProperty(param_spec, gst_element, Gst.PadDirection.SINK);
        });
    });

    // custom properties
    Data.CustomPropertyFactory.get_instance()
        .register(typeof(Gst.Caps), param_spec => {
            return new AudioVideo.GstCapsEditorProperty(param_spec);
        }).register(typeof(Gst.Structure), param_spec => {
            return new AudioVideo.GstStructureProperty(param_spec);
        });

    
    // custom serializers
    plugin_contribution.contribute_canvas_serializer((serializers, deserializers) => {
        serializers.register_custom_type(typeof(Gst.Caps), (value, serialized_object) => {
            var caps = value as Gst.Caps;
            serialized_object.set_string("caps_string", caps.serialize(Gst.SerializeFlags.NONE));
        });

        deserializers.register_custom_type(typeof(Gst.Caps), deserialized_object => {
            var caps_string = deserialized_object.get_string("caps_string");
            if (caps_string == null) {
                return null;
            }
            return Gst.Caps.from_string(caps_string);
        });

        serializers.register_custom_type(typeof(Gst.Pad), (value, serialized_object) => {
            var pad = value as Gst.Pad;
            serialized_object.set_string("pad_name", pad.name);
        });

        deserializers.register_custom_type(typeof(Gst.Pad), (deserialized_object, context_object) => {
            var pad_name = deserialized_object.get_string("pad_name");
            if (pad_name == null) {
                return null;
            }
            
            var gst_element = context_object as Gst.Element;
            return gst_element.get_static_pad(pad_name);
        });
        
    });

    plugin_contribution.listen_canvas_signals(signals => {
        signals.before_file_load.connect(() => {
            AudioVideo.GstPipeline.get_current().ready();
        });
    });

	return "audio-video";
}