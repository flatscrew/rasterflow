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
    
    //  private class LinkRecord {
    //      public GFlow.Source source;
    //      public GFlow.Sink sink;

    //      public LinkRecord(GFlow.Source source, GFlow.Sink sink) {
    //          this.source = source;
    //          this.sink = sink;
    //      }
    //  }
    
    public class PropertyControlContractReleasedAction : Object, History.IAction {
        private weak Data.PropertyControlContract control_contract;
        private weak CanvasNodePropertySink sink;
        
        //  private List<LinkRecord> saved_links = new List<LinkRecord>();
        
        public PropertyControlContractReleasedAction(
            Data.PropertyControlContract control_contract,
            CanvasNodePropertySink sink
        ) {
            this.control_contract = control_contract;
            this.sink = sink;
            
            //  save_links();
        }
        
        public void undo() {
            this.control_contract.renew();
        }

        public void redo() {
            this.control_contract.release();
        }
        
        public string get_label() {
            return "Release property control";
        }
        
        //  private void save_links() {
        //      foreach (var source in sink.sources) {
        //          saved_links.append(new LinkRecord(source, sink));
        //      }
        //  }
    }
}
