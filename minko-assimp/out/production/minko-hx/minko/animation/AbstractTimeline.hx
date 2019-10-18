package minko.animation;
import minko.data.Store;
@:expose
class AbstractTimeline {


    private var _propertyName:String;
    private var _duration:Int;
    private var _isLocked:Bool;

    public function clone() {
        throw ("Missing clone function for a component.");
        return null;
    }

    public var propertyName(get, set):String;

    function get_propertyName() {
        return _propertyName;
    }

    function set_propertyName(value) {
        _propertyName = value;
        return value;
    }
    public var duration(get, set):Int;

    function get_duration() {
        return _duration;
    }

    function set_duration(value) {
        _duration = value;
        return value;
    }

    public var isLocked(get, set):Bool;

    function get_isLocked() {
        return _isLocked;
    }

    function set_isLocked(value) {
        _isLocked = value;
        return value;
    }

    public function update(time:Int, data:Store, ?skipPropertyNameFormatting:Bool = true) {

    }

    public function new(propertyName, duration) {
        this._propertyName = propertyName;
        this._duration = duration;
        this._isLocked = false;

    }

    public function dispose():Void {
        
    }
}
