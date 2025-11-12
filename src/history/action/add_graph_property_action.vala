// Copyright (C) 2025 activey
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

namespace History {

    public class AddGraphPropertyAction : Object, IAction {
        private weak CanvasGraph canvas_graph;
        private CanvasGraphProperty new_property;
        
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
        
        public string get_label() {
            return "Add graph property";
        }
    }
}
