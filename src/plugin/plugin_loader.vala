namespace Plugin {

    public errordomain PluginError {
		PLUGINS_FOLDER_MISSING, MODULE_NOT_FOUND_ERROR,
        MODULE_TYPE_FUNCTION_MISSING_ERROR, DEPENDENCY_MISSING,
        GENERIC_ERROR
	}

    public class PluginLoader {
        
		private const string PLUGIN_INIT_METHOD = "initialize_plugin";

        private delegate string PluginInitFunction(PluginContribution contribution);
		public delegate void PluginDelegate(string name, PluginContribution contribution);

		private CanvasNodeFactory node_factory;
        private Data.FileDataNodeFactory file_data_node_factory;
		private Gee.Map<string, PluginContribution> _plugins = new Gee.HashMap<string, PluginContribution>();

		public static PluginLoader create(CanvasNodeFactory node_factory, Data.FileDataNodeFactory file_data_node_factory) {
			return new PluginLoader(node_factory, file_data_node_factory);
		}
		
		private PluginLoader(CanvasNodeFactory node_factory, Data.FileDataNodeFactory file_data_node_factory) {
			this.node_factory = node_factory;
            this.file_data_node_factory = file_data_node_factory;
		}

        public void load_plugins_from_directory(string directory) throws PluginError {
            assert_modules_supported();
            //  var plugins_directory = File.new_for_path(PluginRuntime.resolve_runtime_relative_path(directory));

            var plugins_directory = File.new_for_path(directory);
            if (!plugins_directory.query_exists(null)) {
				throw new PluginError.PLUGINS_FOLDER_MISSING("Plugins folder [%s] missing! Skipping further processing.".printf(plugins_directory.get_path()));
            }
            try {
                print("Loading plugins from directory: %s\n", plugins_directory.get_path());
                FileEnumerator enumerator = plugins_directory.enumerate_children(FileAttribute.STANDARD_NAME, 0);
                FileInfo fileInfo;
                while ((fileInfo = enumerator.next_file()) != null) {
                    File plugin_file = enumerator.get_child(fileInfo);
                    if (fileInfo.get_file_type() == FileType.DIRECTORY) {
                        continue;
					}
					string loaded_plugin_name;
					var plugin_module = load_plugin_module(plugin_file.get_path());
					var plugin_contribution = load_plugin_module_type(plugin_module, out loaded_plugin_name);
					_plugins.set(loaded_plugin_name, plugin_contribution);
                }
            } catch (Error e) {
                throw new PluginError.GENERIC_ERROR(e.message);
            }
		}
		
		public void foreach_contribution(PluginDelegate plugin_delegate) {
			_plugins.foreach(entry => {
				plugin_delegate(entry.key, entry.value);
				return true;
			});
		}
        
        private Module load_plugin_module(string modulePath) throws PluginError {
			Module module = Module.open(modulePath, ModuleFlags.LOCAL);
			if (module == null) {
				throw new PluginError.MODULE_NOT_FOUND_ERROR("Module not found for given path: %s".printf(modulePath));
			}
			module.make_resident();
			return module;
        }
        
        private PluginContribution load_plugin_module_type(Module module, out string plugin_name) throws PluginError {
			var plugin_contribution = new PluginContribution(node_factory, file_data_node_factory);

			unowned PluginInitFunction init_function = (PluginInitFunction) get_module_method(module, PLUGIN_INIT_METHOD);
			plugin_name = init_function(plugin_contribution);
			return plugin_contribution;
		}

        private void *get_module_method(Module module, string method_name) throws PluginError {
			void *method_reference;
			module.symbol(method_name, out method_reference);
			if (method_reference == null) {
				throw new PluginError.MODULE_TYPE_FUNCTION_MISSING_ERROR("'%s' method is missing in plugin module!".printf(method_name));
			}
			return method_reference;
		}

        private void assert_modules_supported() {
            assert(Module.supported());
        }
    }

}