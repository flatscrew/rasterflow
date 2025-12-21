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

    public class AddNodeAction : Object, IAction {
        private weak CanvasGraph graph;
        private weak CanvasDisplayNode node;

        public AddNodeAction(CanvasGraph graph, CanvasDisplayNode node) {
            this.graph = graph;
            this.node = node;
        }
        
        public void undo() {
            if (graph == null || node == null)
                return;

            node.remove_node();
        }

        public void redo() {
            if (graph == null || node == null)
                return;

            graph.add_node(node);
        }
        
        public string get_label() {
            return "Add node";
        }
    }
}
