package minko.data;
import haxe.ds.StringMap;
import minko.Uuid.Enable_uuid;
typedef  BindingMap = BindingMapBase<Binding> ;
@:expose("minko.data.MacroBinding")
class MacroBinding extends Binding {
    public var minValue:Float;
    public var maxValue:Float;

    public function new() {
        super();
        minValue = Math.NEGATIVE_INFINITY;
        maxValue = Math.POSITIVE_INFINITY;
    }

    public function setBindingMinMax(min, max) {
        minValue = min;
        maxValue = max;
    }


    public function dispose() {

    }
}
@:expose("minko.data.BindingMapBase")
class BindingMapBase<T :Binding> extends Enable_uuid {
    public var defaultValues:Store;
    public var bindings:StringMap<T>;

    public function new() {
        super();
        defaultValues = new Store();
        bindings = new StringMap<T>();
    }

    public function setBindingsAndStore(bindings:StringMap<T>, defaultValues:Store) {
        this.bindings = (bindings);
        this.defaultValues = (defaultValues);

    }

    static public function copyFrom<T:Binding>(t:BindingMapBase<T>, m:BindingMapBase<T>) {
        t.bindings = new StringMap<T>();
        for (k in m.bindings.keys()) {
            t.bindings.set(k, m.bindings.get(k));
        }
        t.defaultValues = new Store();
        t.defaultValues.copyFrom(m.defaultValues, true);
        return t;
    }

    public function dispose() {

    }

}
@:expose("minko.data.MacroType")
@:enum abstract MacroType(Int) from Int to Int{

    var UNSET = 0;
    var INT = 1;
    var INT2 = 2;
    var INT3 = 3;
    var INT4 = 4;
    var BOOL = 5;
    var BOOL2 = 6;
    var BOOL3 = 7;
    var BOOL4 = 8;
    var FLOAT = 9;
    var FLOAT2 = 10;
    var FLOAT3 = 11;
    var FLOAT4 = 12;
    var FLOAT9 = 13;
    var FLOAT16 = 14;
}
@:expose("minko.data.MacroBindingMap")
class MacroBindingMap extends BindingMapBase<MacroBinding> {


    public var types:StringMap<MacroType>;


    public function new() {
        super();
        this.types = new StringMap<MacroType>();
        enable_uuid();
    }

    static public function copyFrom2(t:MacroBindingMap, m:MacroBindingMap) {
        BindingMapBase.copyFrom(t, m);
        //todo

        var ts = cast(m, MacroBindingMap).types;
        for (key in ts.keys()) {
            t.types.set(key, ts.get(key));
        }
        return t;
    }

    public static function stringToMacroType(s) {
        if (s == "int") {
            return MacroType.INT;
        }
        if (s == "int2") {
            return MacroType.INT2;
        }
        if (s == "int3") {
            return MacroType.INT3;
        }
        if (s == "int4") {
            return MacroType.INT4;
        }

        if (s == "float") {
            return MacroType.FLOAT;
        }
        if (s == "float2") {
            return MacroType.FLOAT2;
        }
        if (s == "float3") {
            return MacroType.FLOAT3;
        }
        if (s == "float4") {
            return MacroType.FLOAT4;
        }

        if (s == "bool") {
            return MacroType.BOOL;
        }
        if (s == "bool2") {
            return MacroType.BOOL2;
        }
        if (s == "bool3") {
            return MacroType.BOOL3;
        }
        if (s == "bool4") {
            return MacroType.BOOL4;
        }

        return MacroType.UNSET;
    }
}
