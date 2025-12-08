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

    public class RemoveNodeAction : Object, IAction {
        private weak CanvasGraph graph;
        private weak CanvasDisplayNode node;
        private int pos_x;
        private int pos_y;
        private int width;
        private int height;

        public RemoveNodeAction(CanvasGraph graph, CanvasDisplayNode node, int previous_x, int previous_y) {
            this.graph = graph;
            this.node = node;
            this.pos_x = previous_x;
            this.pos_y = previous_y;
            this.width = node.get_width();
            this.height = node.get_height();
        }

        public void undo() {
            if (graph == null || node == null)
                return;

            graph.add_node(node);
            node.set_position(pos_x, pos_y);
            //  node.set_size_request(width, height);

            node.undo_remove();
        }

        public void redo() {
            if (node == null)
                return;

            node.remove();
        }
        
        public string get_label() {
            return "Remove node";
        }
    }

}
