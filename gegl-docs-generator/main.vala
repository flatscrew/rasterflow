using GLib;
using Gegl;

class OperationDocGenerator : Object {
    private string template = 
"""
---
title: {{title}}
description: "{{description}}"
links:
  - label: "{{id}}"
    to: "https://gegl.org/operations/{{normalized_id}}"
    target: "_blank"
    variant: "outline"
    icon: "i-lucide-external-link"
---

::adwaita-card
---
alt: {{title}}
caption: {{caption}}
src: /images/operations/{{normalized_id}}.png
---
::

::collapsible
---
name: Operation pads
---
This operation exposes the following data pads, defining how it receives, processes, and emits image data:

  ::operation-pads
  ---
  has-input: {{has_input}}
  has-aux: {{has_aux}}
  has-output: {{has_output}}
  ---
  ::
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
        string out_text = template.strip();
        out_text = out_text.replace("{{id}}", id);
        out_text = out_text.replace("{{normalized_id}}", id.replace(":", "-"));
        out_text = out_text.replace("{{title}}", title);
        out_text = out_text.replace("{{description}}", desc);
        out_text = out_text.replace("{{caption}}", desc);
        out_text = out_text.replace("{{has_input}}", "%s".printf(has_input ? "true" : "false"));
        out_text = out_text.replace("{{has_aux}}", "%s".printf(has_aux ? "true" : "false"));
        out_text = out_text.replace("{{has_output}}", "%s".printf(has_output ? "true" : "false"));
        out_text = out_text.replace("{{properties}}", props_md);
        return out_text;
    }
    
    string capitalize_first_only(string s) {
        if (s == null || s == "")
            return s;
    
        int first_end = s.index_of_nth_char(1);
        return s.substring(0, first_end).up(1) + s.substring(first_end);
    }
    
    private string build_properties(Gegl.Node node) {
        var operation = node.get_gegl_operation();
        
        var sb = new StringBuilder();
        foreach (var param_spec in operation.get_class().list_properties()) {
            var description = param_spec.get_blurb();
            if (description != null && !description.has_suffix(".")) {
                description = description + ".";
            } 
            
            var param_name = capitalize_first_only(param_spec.get_nick());
            var value_type = param_spec.value_type;
            var type_name = value_type.name();
    
            string default_string = "";
    
            if (value_type.is_enum()) {
                var enum_specs = param_spec as GLib.ParamSpecEnum;
                unowned EnumClass enumc = enum_specs.enum_class;
    
                int default_index = enum_specs.default_value;
                EnumValue? def_val = enumc.get_value(default_index);
                if (def_val != null)
                    default_string = def_val.value_name;
    
                var enum_values_list = new StringBuilder();
                for (int index = enumc.minimum; index <= enumc.maximum; index++) {
                    EnumValue? v = enumc.get_value(index);
                    if (v == null) continue;
                    if (enum_values_list.len > 0)
                        enum_values_list.append(" • ");
                    enum_values_list.append("`%s`".printf(v.value_name));
                }
                var enum_values = enum_values_list.str;
                
                type_name = "dictionary";
    
                sb.append_printf("      ::field{name=\"%s\" type=\"%s\"}\n", param_name, type_name);
                sb.append_printf("        %s", description == null ? "" : "%s  \n".printf(description));
                sb.append_printf("        :icon{name=\"i-lucide-puzzle\"} Default `%s`  \n", default_string);
                sb.append_printf("        :icon{name=\"i-lucide-chart-candlestick\"} Possible values %s \n", enum_values);
                sb.append_printf("      ::\n\n");
    
                continue;
            }
    
            var default_value = get_default_as_string(param_spec);
            var value_range = get_range_as_string(param_spec);
            
            sb.append_printf("      ::field{name=\"%s\" type=\"%s\"}\n", param_name, type_name);
            sb.append_printf("        %s", description == null ? "\n" : "%s  \n".printf(description));
            sb.append_printf("        :icon{name=\"i-lucide-puzzle\"} Default `%s`  %s\n", default_value, value_range);
            sb.append_printf("      ::\n");
        }
        return sb.str;
    }
    
    private string get_range_as_string(GLib.ParamSpec param_spec) {
        var range_template = """
        :icon{name="i-lucide-ruler-dimension-line"} Value range `{{min}}` • :icon{name="i-lucide-arrow-right"} • `{{max}}`. 
        """;
    
    
        if (param_spec is GLib.ParamSpecDouble) {
            var p = param_spec as GLib.ParamSpecDouble;
            if (p.minimum == double.MIN || p.maximum == double.MAX)
                return "";
            return range_template
                .replace("{{min}}", "%.2f".printf(p.minimum))
                .replace("{{max}}", "%.2f".printf(p.maximum));
        }
    
        if (param_spec is GLib.ParamSpecInt) {
            var p = param_spec as GLib.ParamSpecInt;
            //  if (p.minimum <= int.MIN || p.maximum >= int.MAX)
            //      return "";
            return range_template
                .replace("{{min}}", "%d".printf(p.minimum))
                .replace("{{max}}", "%d".printf(p.maximum));
        }
    
        if (param_spec is GLib.ParamSpecUInt) {
            var p = param_spec as GLib.ParamSpecUInt;
            //  if (p.minimum == 0 && p.maximum == uint.MAX)
            //      return "";
            return range_template
                .replace("{{min}}", "%u".printf(p.minimum))
                .replace("{{max}}", "%u".printf(p.maximum));
        }
    
        if (param_spec is GLib.ParamSpecUInt64) {
            var p = param_spec as GLib.ParamSpecUInt64;
            //  if (p.minimum == 0 && p.maximum >= uint64.MAX)
            //      return "";
            return range_template
                .replace("{{min}}", "%llu".printf(p.minimum))
                .replace("{{max}}", "%llu".printf(p.maximum));
        }
    
        return "";
    }
    
    
    private string get_default_as_string(GLib.ParamSpec param_spec) {
        if (param_spec is GLib.ParamSpecDouble) {
            var p = param_spec as GLib.ParamSpecDouble;
            return "%.2f".printf(p.default_value);
        }
    
        if (param_spec is GLib.ParamSpecString) {
            var p = param_spec as GLib.ParamSpecString;
            return p.default_value != null ? "\"%s\"".printf(p.default_value) : "null";
        }
    
        if (param_spec is GLib.ParamSpecBoolean) {
            var p = param_spec as GLib.ParamSpecBoolean;
            return p.default_value ? "true" : "false";
        }
    
        if (param_spec is GLib.ParamSpecInt) {
            var p = param_spec as GLib.ParamSpecInt;
            return "%d".printf(p.default_value);
        }
    
        if (param_spec is GLib.ParamSpecUInt) {
            var p = param_spec as GLib.ParamSpecUInt;
            return "%u".printf(p.default_value);
        }
    
        if (param_spec is GLib.ParamSpecUInt64) {
            var p = param_spec as GLib.ParamSpecUInt64;
            return "%llu".printf(p.default_value);
        }
    
        return "";
    }
    

    public void generate_all(string out_dir) throws Error {
        var tmp_dir = GLib.Path.build_filename("/tmp", "gegl-docs");
        DirUtils.create_with_parents(tmp_dir, 0777);
    
        var root = new Gegl.Node();
        var ops = Gegl.list_operations();
    
        var categories = new HashTable<string, Gee.ArrayList<string>>(str_hash, str_equal);
    
        foreach (string op_name in ops) {
            var category_raw = Gegl.Operation.get_key(op_name, "categories") ?? "uncategorized";
            var base_category = category_raw.split(":")[0].strip();
            if (base_category == "")
                base_category = "uncategorized";
    
            if (!categories.contains(base_category))
                categories[base_category] = new Gee.ArrayList<string>();
    
            categories[base_category].add(op_name);
        }
    
        var sorted_categories = new Gee.ArrayList<string>();
        foreach (var k in categories.get_keys())
            sorted_categories.add(k);
        sorted_categories.sort();
    
        int cat_index = 1;
        foreach (string category in sorted_categories) {
            string category_dirname = "%s".printf(category.replace(" ", "-"));
            string category_dir = GLib.Path.build_filename(tmp_dir, category_dirname);
            DirUtils.create_with_parents(category_dir, 0777);
    
            message("Generating category: %s".printf(category));
    
            var op_list = categories[category];
            op_list.sort();
    
            int op_index = 1;
            foreach (string op_name in op_list) {
                var operation_node = root.create_child(op_name);
                var title = Gegl.Operation.get_key(op_name, "title") ?? "";
                var desc = Gegl.Operation.get_key(op_name, "description") ?? "";
    
                if (desc != null && !desc.has_suffix(".")) {
                    desc = desc + ".";
                } 
                
                var has_input = false;
                var has_aux = false;
                var has_output = false;
    
                foreach (var input in operation_node.list_input_pads()) {
                    if (input.has_prefix("input"))
                        has_input = true;
                    if (input.has_prefix("aux"))
                        has_aux = true;
                }
    
                foreach (var output in operation_node.list_output_pads()) {
                    if (output.has_prefix("output"))
                        has_output = true;
                }
    
                string props = build_properties(operation_node);
                string md = render(op_name, title, desc, has_input, has_aux, has_output, props);
    
                //  string safe_name = "%d.%s".printf(op_index, op_name.replace(":", "-"));
                //  string safe_name = op_name.contains(":") ? op_name.split(":")[1] : op_name;
                
                var safe_name = op_name.substring(op_name.index_of(":", 0) + 1, -1);
                
                string out_path = GLib.Path.build_filename(category_dir, "%s.md".printf(safe_name));
    
                try {
                    FileUtils.set_contents(out_path, md);
                } catch (Error e) {
                    warning("Failed writing %s: %s".printf(out_path, e.message));
                }
    
                root.remove_child(operation_node);
                op_index++;
            }
    
            cat_index++;
        }
    
        message("✅ Generation complete: %s".printf(tmp_dir));
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
