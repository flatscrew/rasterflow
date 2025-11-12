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

    public class AddPropertyNodeAction : Object, IAction {
        private weak GtkFlow.NodeView parent_view;
        private CanvasPropertyDisplayNode node;
        
        private int x;
        private int y;

        public AddPropertyNodeAction(GtkFlow.NodeView parent_view, CanvasPropertyDisplayNode node) {
            this.parent_view = parent_view;
            this.node = node;
            
            node.get_position(out x, out y);
        }
        public void undo() {
            if (parent_view == null || node == null)
                return;

            node.remove();
        }

        public void redo() {
            if (parent_view == null || node == null)
                return;

            parent_view.add(node);
            parent_view.queue_allocate();
            
            node.set_position(x, y);
        }
        
        public string get_label() {
            return "Add property node";
        }
    }
}
