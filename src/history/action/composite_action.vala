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
    
    public class CompositeAction : Object, IAction {
        private Gee.List<IAction> children = new Gee.ArrayList<IAction>();
        private string label;
    
        public CompositeAction(string label) {
            this.label = label;
        }
    
        public void add_child(IAction child) {
            message("adding child> %s", child.get_label());
            children.add(child);
        }
    
        public Gee.List<IAction> get_children() {
            return children;
        }
    
        public void undo() {
            children.foreach(child => {
                message("undoing child> %s", child.get_type().name());
                child.undo();
                return true;
            });
        }
    
        public void redo() {
            // redo only first as it will trigger all children again
            children.first().redo();
        }
    
        public string get_label() {
            return label;
        }
    }
}