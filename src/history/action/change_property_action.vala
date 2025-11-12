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

    public class ChangePropertyAction : Object, IAction {
        private weak GLib.Object target;
        private string property_name;
        private GLib.Value old_value;
        private GLib.Value new_value;

        public ChangePropertyAction(GLib.Object target, string property_name, GLib.Value old_value, GLib.Value new_value) {
            this.target = target;
            this.property_name = property_name;

            this.old_value = GLib.Value(old_value.type());
            this.new_value = GLib.Value(new_value.type());

            old_value.copy(ref this.old_value);
            new_value.copy(ref this.new_value);
        }

        public void undo() {
            if (target == null)
                return;
            target.set_property(property_name, old_value);
        }

        public void redo() {
            if (target == null)
                return;
            target.set_property(property_name, new_value);
        }
        
        public string get_label() {
            return "Change property";
        }
    }
}
