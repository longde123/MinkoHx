package minko.component;
import haxe.ds.StringMap;
@:expose("minko.component.Metadata")
class Metadata extends AbstractComponent {
    public function new() {
        super();
        _data=new StringMap<String>();
    }
    private var _data:StringMap<String>;


    public static function create(data) {
        var m=  new Metadata();
        m.data=data;
        return m;
    }
    public var data(get, set):StringMap<String>;
    function set_data(__data) {
        _data = __data;
        return _data;
    }
    function get_data() {
        return _data;
    }

    inline public function keys(){
        return _data.keys();
    }
    public function get(propertyName) {
        return _data.get(propertyName) ;
    }


    public function set(propertyName,value) {
        return _data.set(propertyName,value) ;
    }


    public function has(propertyName) {
        return _data.exists(propertyName) ;
    }


}
