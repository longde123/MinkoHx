package minko.material;
import minko.data.Provider;
import minko.Uuid.Has_uuid;
@:expose("minko.material.Material")
class Material extends Has_uuid {
    private var _provider:Provider;

    public function dispose():Void {
        _provider = null;
    }

    public static function create(name = "material"):Material {
        var instance = new Material(name);

        instance.initialize();

        return instance;
    }

    public static function createbyMaterial(source:Material):Material {
        var mat:Material = create();

        mat._provider.copyFrom(source._provider);

        return mat;
    }

    override function get_uuid() {
        return _provider.uuid;
    }

    public var name(get, null):String ;

    function get_name() {
        return _provider.get("name");
    }

    public var data(get, null):Provider ;

    function get_data() {
        return _provider;
    }

    public function hasProperty(propertyName:String):Bool {
        return _provider.hasProperty(propertyName);

    }

    public function get(propertyName:String):Dynamic {
        return _provider.get(propertyName) ;
    }

    public function unset(propertyName:String) :Void{
          _provider.unset(propertyName);

    }

    public function setbyKeyObject(values:Dynamic):Material {

        var fields = Reflect.fields(values);
        for (key in fields) {
            _provider.set(key, Reflect.field(values, key));
        }


        return this;
    }

    public function set(key:String, values:Dynamic):Material {

        _provider.set(key, values);

        return this;
    }

    public function new(name:String) {
        super();
        this._provider = Provider.create();
        _provider.set("name", name);
        _provider.set("uuid", _provider.uuid);
    }

    public function copyFrom(values:Provider) {
        this._provider = Provider.createbyProvider(values);
        _provider.set("uuid", _provider.uuid);
    }

    public function initialize() {
    }

}
