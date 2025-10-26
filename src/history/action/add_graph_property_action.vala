namespace History {

    public class AddGraphPropertyAction : Object, IAction {
        private weak CanvasGraph canvas_graph;
        private weak CanvasGraphProperty new_property;
        
        public AddGraphPropertyAction(CanvasGraph canvas_graph, CanvasGraphProperty new_property) {
            this.canvas_graph = canvas_graph;
            this.new_property = new_property;
        }
        public void undo() {
            if (canvas_graph == null || new_property == null)
                return;

            new_property.remove();
        }

        public void redo() {
            if (canvas_graph == null || new_property == null)
                return;

            canvas_graph.add_property(new_property);
        }
    }
}
