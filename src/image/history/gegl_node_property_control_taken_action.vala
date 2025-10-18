namespace Image {
    
    public class PropertyControlTakenAction : Object, History.IAction {
        private weak Data.PropertyControlContract control_contract;
        private weak GeglOperationNode gegl_node;
        
        public PropertyControlTakenAction(
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
    }
}
