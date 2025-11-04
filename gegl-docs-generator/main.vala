using GLib;
using Gegl;

class OperationDocGenerator : Object {
    private string template = """
---
title: {{title}}
description: {{description}}
---

::adwaita-card
---
src: /images/operations/gaussian-blur.png
alt: {{title}}
caption: {{caption}}
has-input: {{has_input}}
has-aux: {{has_aux}}
has-output: {{has_output}}
---
::

::collapsible
---
name: Operation properties
---

    ::field-group
{{properties}}
    ::
::
""";

    private string render(
        string id, 
        string title, 
        string desc, 
        bool has_input, 
        bool has_aux, 
        bool has_output, 
        string props_md
    ) 
    {
        string out_text = template;
        out_text = out_text.replace("{{id}}", id);
        out_text = out_text.replace("{{title}}", title);
        out_text = out_text.replace("{{description}}", desc);
        out_text = out_text.replace("{{caption}}", desc);
        out_text = out_text.replace("{{has_input}}", "%s".printf(has_input ? "true" : "false"));
        out_text = out_text.replace("{{has_aux}}", "%s".printf(has_aux ? "true" : "false"));
        out_text = out_text.replace("{{has_output}}", "%s".printf(has_output ? "true" : "false"));
        out_text = out_text.replace("{{properties}}", props_md);
        return out_text;
    }

    private string build_properties(Gegl.Operation operation) {
        var sb = new StringBuilder();
        foreach (var param_spec in operation.get_class().list_properties()) {
            var description = param_spec.get_blurb();
    
            var value_type = param_spec.value_type;
            var type_name = value_type.name();
    
            string default_string = "";
            string enum_values = "";
    
            if (value_type.is_enum()) {
                var enum_specs = param_spec as GLib.ParamSpecEnum;
                unowned EnumClass enumc = enum_specs.enum_class;
    
                int default_index = enum_specs.default_value;
                EnumValue? def_val = enumc.get_value(default_index);
                if (def_val != null)
                    default_string = def_val.value_name;
    
                for (int index = enumc.minimum; index <= enumc.maximum; index++) {
                    EnumValue? v = enumc.get_value(index);
                    if (v == null) continue;
                    enum_values += "      - %s\n".printf(v.value_name);
                }
                
                type_name = "dictionary";
    
                sb.append_printf("      ::field{name=\"%s\" type=\"%s\"}\n", param_spec.get_nick(), type_name);
                sb.append_printf("        Default to `%s` %s. \n", default_string, description == null ? "" : "- %s".printf(description));
                sb.append_printf("        Possible values:\n%s", enum_values);
                sb.append_printf("      ::\n\n");
    
                continue;
            }
    
            var default_value = param_spec.get_default_value();
            sb.append_printf("      ::field{name=\"%s\" type=\"%s\"}\n", param_spec.get_nick(), type_name);
            sb.append_printf("        Default to `xxx` %s. \n", description == null ? "" : "- %s".printf(description));
            sb.append_printf("      ::\n");
        }
        return sb.str;
    }
    

    public void generate_all(string out_dir) throws Error {
        var tmp_dir = GLib.Path.build_filename("/tmp", "gegl-docs");
        DirUtils.create_with_parents(tmp_dir, 0777);
        
        var root = new Gegl.Node();
        var ops = Gegl.list_operations();
        foreach (string op_name in ops) {
            var operation_node = root.create_child(op_name);
            var title = Gegl.Operation.get_key(op_name, "title") ?? "";
            var desc  = Gegl.Operation.get_key(op_name, "description") ?? "";

            var has_input = false;
            var has_aux = false;
            var has_output = false;
            
            foreach (var input in operation_node.list_input_pads()) {
                if (input.has_prefix("input")) {
                    has_input = true;
                }
                if (input.has_prefix("aux")) {
                    has_aux = true;
                }
            }
            
            foreach (var output in operation_node.list_output_pads()) {
                if (output.has_prefix("output")) {
                    has_output = true;
                }
            }
            
            string props = build_properties(operation_node.get_gegl_operation());
            string md = render(op_name, title, desc, has_input, has_aux, has_output, props);
            
            
            string safe_name = op_name.replace(":", "-");
            string out_path = GLib.Path.build_filename(tmp_dir, "%s.md".printf(safe_name));

            try {
                FileUtils.set_contents(out_path, md);
            } catch (Error e) {
                warning(e.message);
            }
            
            root.remove_child(operation_node);
        }
    }
}

public static int main(string[] args) {
    try {
        Gegl.init(ref args);
        Gegl.config().application_license = "GPL3";

        var gen = new OperationDocGenerator();
        gen.generate_all("docs/operations");
        Gegl.exit();
    } catch (Error e) {
        stderr.printf("Generation failed: %s\n", e.message);
        return 1;
    }
    return 0;
}
