package minko.component;
import haxe.ds.StringMap;
class Metadata extends AbstractComponent {
    public function new(__data) {
        super();
        _data = __data;
    }
    private var _data:StringMap<String>;


    public static function create(data) {
        return new Metadata(data);
    }
    public var data(get, null):StringMap<String>;

    function get_data() {
        return _data;
    }

    public function get(propertyName) {
        return _data.get(propertyName) ;
    }


    public function set(propertyName) {
        return _data.set(propertyName) ;
    }


    public function has(propertyName) {
        return _data.exists(propertyName) ;
    }


}
