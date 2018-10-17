package minko.data;
import haxe.ds.StringMap;
import minko.signal.Signal2;
import minko.Uuid.Enable_uuid;
class Provider extends Enable_uuid {
    private var _values:StringMap<Dynamic>;
    private var _propertyAdded:Signal2<Provider, String>;
    private var _propertyChanged:Signal2<Provider, String>;
    private var _propertyRemoved:Signal2<Provider, String>;

    public function new() {
        super();
        this._values = new StringMap<Dynamic>();
        _propertyAdded = new Signal2<Provider, String>();
        _propertyChanged = new Signal2<Provider, String>();
        _propertyRemoved = new Signal2<Provider, String>();
        enable_uuid();
    }

    public function dispose() {
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
    public function front() {
        return _values.iterator().next();
    }

    public static function create():Provider {
        var provider = new Provider();

        return provider;
    }

    public static function createbyUuid(uuid) {
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

    public function hasProperty(propertyName:String) {
        return _values.exists(propertyName);

    }
    public var values(get, null):StringMap<Dynamic>;

    function get_values() {
        return _values ;
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


    public function get(propertyName:String) {
        return getValue(propertyName) ;
    }


    public function getUnsafePointer(propertyName:String) {
        return getValue(propertyName) ;
    }

    public function set(propertyName:String, value:Dynamic) {
        if (hasProperty(propertyName)) {
            var ptr = getValue(propertyName) ;

#if DEBUG
					if (ptr == null)
					{
						throw  ("Property `" + propertyName.Indirection() + "` does not exist or has an incorrect type.");
					}
#end

            var changed = (ptr != value);
            setValue(propertyName, value);
            if (changed) {
                _propertyChanged.execute(this, propertyName);
            }
        }
        else {
            setValue(propertyName, value);
            _propertyAdded.execute(this, propertyName);
            _propertyChanged.execute(this, propertyName);
        }

        return this;
    }

    public function setProvider(values:StringMap<Dynamic>) {
        for (p in values.keys()) {
            setValue(p, values.get(p));
        }

        return this;
    }


    public function propertyHasType(propertyName:String) {
        return getValue(propertyName) != null;
    }

    public function clear() {
        _values = new StringMap<Dynamic>();

        return this;
    }

    public function unset(propertyName:String) {
        var propertyIt = _values.get(propertyName);

        if (propertyIt != null) {
            _values.remove(propertyName);
            _propertyRemoved.execute(this, propertyName);
        }

        return this;
    }

    public function copyFrom(source:Provider) {
        for (nameAnd in source._values.keys()) {
            // if (hasProperty(nameAnd)) {
            //     *getValue(nameAnd) = source.get(nameAnd);
            //}
            // else {
            _values.set(nameAnd, source.get(nameAnd));
            // }
        }

        return this;
    }



    function getValue(propertyName:String) {
        return _values.get(propertyName);
    }

    function setValue(propertyName:String, value:Dynamic) {
        return _values.set(propertyName, value);
    }
}
