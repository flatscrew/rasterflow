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

    public class ToggleExpanderAction : Object, IAction {
        private weak CanvasNodeDetailsView expander;
        private weak CanvasDisplayNode node;
        private bool was_expanded;
        private int old_width;
        private int old_height;

        public ToggleExpanderAction(CanvasNodeDetailsView expander, CanvasDisplayNode node, int old_width, int old_height) {
            this.expander = expander;
            this.node = node;
            this.was_expanded = expander.expanded;
            this.old_width = old_width;
            this.old_height = old_height;
        }

        public void undo() {
            if (expander == null)
                return;

            expander.expanded = !was_expanded;
            if (!was_expanded) {
                node.set_size_request(old_width, old_height);
            }
        }

        public void redo() {
            if (expander == null)
                return;

            expander.expanded = was_expanded;
            if (!was_expanded) {
                node.set_size_request(old_width, old_height);
            }
        }
        
        public string get_label() {
            return "Expand node details";
        }
    }
}
