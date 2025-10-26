namespace History {

    public class RemoveGraphPropertyAction : Object, IAction {
        private weak CanvasGraph canvas_graph;
        private weak CanvasGraphProperty property;
        
        // TODO record position of property in graph properties
        public RemoveGraphPropertyAction(CanvasGraph canvas_graph, CanvasGraphProperty new_property) {
            this.canvas_graph = canvas_graph;
            this.property = new_property;
        }
        
        public void undo() {
            if (canvas_graph == null || property == null)
                return;
                
            canvas_graph.add_property(property);
        }

        public void redo() {
            if (canvas_graph == null || property == null)
                return;

            property.remove();
        }
    }
}
