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

    public class NodeResizeAction : Object, IAction {
        private weak CanvasDisplayNode node;
        private int old_width;
        private int old_height;
        private int new_width;
        private int new_height;

        public NodeResizeAction(CanvasDisplayNode node, int old_width, int old_height, int new_width, int new_height) {
            this.node = node;
            this.old_width = old_width;
            this.old_height = old_height;
            this.new_width = new_width;
            this.new_height = new_height;
        }

        public void undo() {
            if (node != null)
                node.set_size_request(old_width, old_height);
                node.parent.queue_allocate();
        }

        public void redo() {
            if (node != null)
                node.set_size_request(new_width, new_height);
                node.parent.queue_allocate();
        }
        
        public string get_label() {
            return "Resize node";
        }
    }
}