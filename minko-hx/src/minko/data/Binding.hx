package minko.data;

import minko.Uuid.Enable_uuid;
@:expose("minko.data.Source")
@:enum abstract Source(Int) from Int to Int{
    var TARGET = 0;
    var RENDERER = 1;
    var ROOT = 2;
}
@:expose("minko.data.Binding")
class Binding extends Enable_uuid {

    public var propertyName:String;
    public var source:Source;

    public function new() {
        this.propertyName = "";
        this.source = Source.TARGET;
        super();
        enable_uuid();
    }

    public function setBinding(propertyName, source) {
        this.propertyName = propertyName;
        this.source = (source);
        return this;
    }
}
