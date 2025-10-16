public class CanvasNodePropertySink : CanvasNodeSink {

    public CanvasNodePropertySink(ParamSpec param_spec) {
        base.with_type(typeof(CanvasNodePropertyBridge));
        this.name = param_spec.get_nick ();
    }
}