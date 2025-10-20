namespace Image {
    public class GeglNodePropertyBridgeSinkLabelFactory : GtkFlow.NodeDockLabelWidgetFactory {
        
        public GeglNodePropertyBridgeSinkLabelFactory(GeglOperationNode gegl_node) {
            base(gegl_node);
        }
		
        public override Gtk.Widget create_dock_label (GFlow.Dock dock) {
            var node_property_sink = dock as CanvasNodePropertySink;
            if (node_property_sink == null) {
                return base.create_dock_label(dock);
            }
        
            var remove_control_button = new Gtk.Button.from_icon_name("list-remove-symbolic");
            remove_control_button.add_css_class("flat");
            remove_control_button.set_tooltip_text("Turn back property control");
            remove_control_button.clicked.connect(node_property_sink.release_control_contract);
        
            var param_spec = node_property_sink.control_contract.param_spec;
            var type_name = param_spec.value_type.name();
        
            var label_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
        
            var name_label = new Gtk.Label(dock.name);
            name_label.halign = Gtk.Align.START;
        
            var type_label = new Gtk.Label("%s".printf(type_name));
            type_label.halign = Gtk.Align.START;
            type_label.add_css_class("dim-label");
        
            label_box.append(name_label);
            label_box.append(type_label);
            label_box.append(remove_control_button);
        
            return label_box;
        }
    }
}