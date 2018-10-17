package minko.data;
class ResolvedBinding {
    public var binding:Binding;
    public var propertyName:String;
    public var store:Store;

    public function new(binding:Binding,
                        propertyName:String,
                        store:Store) {
        this.binding = (binding);
        this.propertyName = (propertyName);
        this.store = (store);
    }
}
