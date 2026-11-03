package minko.material;

import haxe.ds.StringMap;
import minko.Uuid.Enable_uuid;

@:expose("minko.material.Material")
class Material extends Enable_uuid {
    private var _name:String;
    private var _values:StringMap<Dynamic>;
    public var version:Int;

    public function new(name:String) {
        super();
        enable_uuid();
        _name = name;
        _values = new StringMap<Dynamic>();
        version = 0;
    }

    public static function create(name = "material"):Material {
        var instance = new Material(name);
        instance.initialize();
        return instance;
    }

    public static function createbyMaterial(source:Material):Material {
        return create(source.name).copyFrom(source);
    }

    public function dispose():Void {
        _values = null;
    }

    public var name(get, null):String;

    function get_name() {
        return _name;
    }

    public function hasProperty(propertyName:String):Bool {
        return _values.exists(propertyName);
    }

    public function get(propertyName:String):Dynamic {
        return _values.get(propertyName);
    }

    public function unset(propertyName:String):Void {
        if (_values.exists(propertyName)) {
            _values.remove(propertyName);
            version++;
        }
    }

    public function setbyKeyObject(values:Dynamic):Material {
        var fields = Reflect.fields(values);
        for (key in fields) {
            _values.set(key, Reflect.field(values, key));
        }
        if (fields.length > 0) {
            version++;
        }
        return this;
    }

    public function set(key:String, value:Dynamic):Material {
        _values.set(key, value);
        version++;
        return this;
    }

    public function copyFrom(source:Material):Material {
        _name = source._name;
        _values = new StringMap<Dynamic>();
        for (key in source._values.keys()) {
            _values.set(key, source._values.get(key));
        }
        version++;
        return this;
    }

    public function initialize() {
    }
}
