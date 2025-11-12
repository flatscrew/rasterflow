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

    public class ChangeNodeColorAction : Object, IAction {
        private weak CanvasDisplayNode node;
        private Gdk.RGBA? old_color;
        private Gdk.RGBA? new_color;

        public ChangeNodeColorAction(CanvasDisplayNode node, Gdk.RGBA? old_color, Gdk.RGBA? new_color) {
            this.node = node;
            this.old_color = old_color;
            this.new_color = new_color;
        }
        
        public void undo() {
            if (node == null)
                return;

            node.set_background_color(old_color);
        }

        public void redo() {
            if (node == null)
                return;

            node.set_background_color(new_color);
        }
        
        public string get_label() {
            return "Change node color";
        }
    }
}
