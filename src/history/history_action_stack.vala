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

    public class ActionStack : Object {
        private Gee.LinkedList<IAction> _list = new Gee.LinkedList<IAction>();
        public int max_size { get; set; default = 100; }

        public void push(IAction action) {
            if (_list.size >= max_size && !_list.is_empty)
                _list.remove_at(0);
            _list.add(action);
        }

        public IAction? pop() {
            if (_list.is_empty)
                return null;
            return _list.remove_at(_list.size - 1);
        }

        public void clear() {
            _list.clear();
        }

        public IAction? peek() {
            if (_list.is_empty)
                return null;
            return _list.last();
        }
        
        public int size {
            get { return _list.size; }
        }

        public bool is_empty {
            get { return _list.is_empty; }
        }
    }

}
