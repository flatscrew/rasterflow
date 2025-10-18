public class CanvasNodePropertySink : CanvasNodeSink {
    
    public signal void contract_released();
    public signal void contract_renewed();
    
    private Data.PropertyControlContract control_contract;

    public CanvasNodePropertySink(Data.PropertyControlContract control_contract) {
        base.with_type(typeof(CanvasNodePropertyBridge));
        this.control_contract = control_contract;
        this.name = control_contract.param_spec.get_nick();
        
        control_contract.released.connect(this.on_contract_released);
        control_contract.renewed.connect(this.on_contract_renewed);
    }
    
    private void on_contract_released() {
        contract_released();
    }
    
    private void on_contract_renewed() {
        contract_renewed();
    }
    
    public void release_control_contract() {
        control_contract.release();
    }
}