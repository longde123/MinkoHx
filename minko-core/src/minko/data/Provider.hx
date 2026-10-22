package minko.data;
import haxe.ds.StringMap;
import minko.signal.Signal2;
import minko.Uuid.Enable_uuid;
@:expose("minko.data.Provider")
class Provider extends Enable_uuid {
    private var _values:StringMap<UnsafePointer<Dynamic>>;
    private var _propertyAdded:Signal2<Provider, String>;
    private var _propertyChanged:Signal2<Provider, String>;
    private var _propertyRemoved:Signal2<Provider, String>;

    public function new() {
        super();
        this._values = new StringMap<UnsafePointer<Dynamic>>();
        _propertyAdded = new Signal2<Provider, String>();
        _propertyChanged = new Signal2<Provider, String>();
        _propertyRemoved = new Signal2<Provider, String>();
        enable_uuid();
    }

    public function dispose():Void {
        if (_values != null) {
            _values = null;
        }
        if (_propertyAdded != null) _propertyAdded.dispose();
        if (_propertyChanged != null)  _propertyChanged.dispose();
        if (_propertyRemoved != null)  _propertyRemoved.dispose();
        _propertyAdded=null;
        _propertyChanged=null;
        _propertyRemoved=null;
    }
    public function front() :UnsafePointer<Dynamic>{
        return _values.iterator().next();
    }

    public static function create():Provider {
        var provider = new Provider();

        return provider;
    }

    public static function createbyUuid(uuid:String):Provider {
        var provider = new Provider();
        provider.uuid = uuid;

        return provider;
    }

    public static function createbyStringMap(values:StringMap<Dynamic>):Provider {
        var provider = new Provider();
        provider.setProvider(values);

        return provider;
    }

    public static function createbyProvider(source:Provider):Provider {
        var provider:Provider = create();
        return provider.copyFrom(source);
    }

    public function hasProperty(propertyName:String):Bool {
        return _values.exists(propertyName);
    }
//    public var values(get, null):StringMap<UnsafePointer<Dynamic>>;
//
//    function get_values() {
//        return _values ;
//    }
    public function keys( ):Iterator<String> {
        return _values.keys() ;
    }
    public var propertyAdded(get, null):Signal2<Provider, String>;

    function get_propertyAdded() {
        return _propertyAdded;
    }

    public var propertyChanged(get, null):Signal2<Provider, String>;

    function get_propertyChanged() {
        return _propertyChanged;
    }
    public var propertyRemoved(get, null):Signal2<Provider, String>;

    function get_propertyRemoved() {
        return _propertyRemoved;
    }


    public function get(propertyName:String) :Dynamic{
        return getValue(propertyName) ;
    }


    public function getUnsafePointer(propertyName:String):UnsafePointer<Dynamic> {
        return _values.get(propertyName);
    }
    public function setUnsafePointer(propertyName:String, value:UnsafePointer<Dynamic>):Void{
        return _values.set(propertyName,value);
    }
    public function set(propertyName:String, value:Dynamic):Provider {
        if (hasProperty(propertyName)) {
            var ptr = getValue(propertyName);
            var changed = (ptr != value);
            setValue(propertyName, value);
            if (changed) {
                _propertyChanged.execute(this, propertyName);
            }
        }
        else {
            setUnsafePointer(propertyName,  new UnsafePointer(value));
            _propertyAdded.execute(this, propertyName);
            _propertyChanged.execute(this, propertyName);
        }

        return this;
    }

    public function setProvider(values:StringMap<Dynamic>) :Void{
        for (p in values.keys()) {
            setValue(p, values.get(p));
        }

    }


    public function propertyHasType(propertyName:String) :Bool{
        return getValue(propertyName) != null;
    }

    public function clear():Void {
        _values = new StringMap<UnsafePointer<Dynamic>>();

    }

    public function unset(propertyName:String) :Void{
        var propertyIt = _values.get(propertyName);

        if (propertyIt != null) {
            _values.remove(propertyName);
            _propertyRemoved.execute(this, propertyName);
        }
    }

    public function copyFrom(source:Provider) :Provider{
        for (nameAnd in source.keys()) {
            // if (hasProperty(nameAnd)) {
            //     *getValue(nameAnd) = source.get(nameAnd);
            //}
            // else {
                set(nameAnd, source.get(nameAnd));
            // }
        }

        return this;
    }



   inline function getValue(propertyName:String):Dynamic {
        return getUnsafePointer(propertyName).value;
    }

    inline function setValue(propertyName:String, value:Dynamic):Void {
        getUnsafePointer(propertyName).value= value;
    }
}
