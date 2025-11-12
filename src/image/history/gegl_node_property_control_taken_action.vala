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

namespace Image {
    
    public class PropertyControlContractAcquiredAction : Object, History.IAction {
        private weak Data.PropertyControlContract control_contract;
        private weak GeglOperationNode gegl_node;
        
        public PropertyControlContractAcquiredAction(
            Data.PropertyControlContract control_contract,
            GeglOperationNode gegl_node
        ) {
            this.control_contract = control_contract;
            this.gegl_node = gegl_node;
        }
        
        public void undo() {
            this.control_contract.release();
        }

        public void redo() {
            this.control_contract.renew();
        }
        
        public string get_label() {
            return "Take property control";
        }
    }
}
