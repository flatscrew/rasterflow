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
