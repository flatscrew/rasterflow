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
            remove_control_button.set_tooltip_text("Turn back property control");
            remove_control_button.clicked.connect(() => {
                message("removing sink...\n");
            });
            
            var label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            label_box.append(new Gtk.Label (dock.name));
            label_box.append(remove_control_button);
            return label_box;
        }
    }
}