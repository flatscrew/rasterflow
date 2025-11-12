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

    public class MoveNodeAction : Object, IAction {
        
        private weak GtkFlow.Node node;
        private int old_x;
        private int old_y;
        private int new_x;
        private int new_y;

        public MoveNodeAction(GtkFlow.Node node, int old_x, int old_y, int new_x, int new_y) {
            this.node = node;
            this.old_x = old_x;
            this.old_y = old_y;
            this.new_x = new_x;
            this.new_y = new_y;
        }

        public void undo() {
            if (node != null)
                node.set_position(old_x, old_y);
                node.parent.queue_allocate();
        }

        public void redo() {
            if (node != null)
                node.set_position(new_x, new_y);
                node.parent.queue_allocate();
        }
        
        public string get_label() {
            return "Move node";
        }
    }
}