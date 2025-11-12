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

    public class LinkDocksAction : Object, IAction {
        private weak GFlow.Dock source;
        private weak GFlow.Dock target;

        public LinkDocksAction(GFlow.Dock source, GFlow.Dock target) {
            this.source = source;
            this.target = target;
        }

        public void undo() {
            if (source == null || target == null)
                return;
            try {
                target.unlink(source);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }

        public void redo() {
            if (source == null || target == null)
                return;
            try {
                source.link(target);
            } catch (GLib.Error e) {
                warning(e.message);
            }
        }
        
        public string get_label() {
            return "Link nodes";
        }
    }
}
