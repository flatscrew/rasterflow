namespace Data{
    
    public class NodeData : Object {

        public string content_type {
            get;
            private set;
        }

        public NodeData(string content_type) {
            this.content_type = content_type;
        }

        
    }
}