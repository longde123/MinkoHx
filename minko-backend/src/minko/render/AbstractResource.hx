package minko.render;
@:expose("minko.render.AbstractResource")
class AbstractResource {
    var _uuid:String;
    var _context:AbstractContext;
    var _id:Int;

    public var uuid(get, null):String;

    function get_uuid() {
        return _uuid;
    }
    public var context(get, null):AbstractContext;

    function get_context() {
        return _context;
    }
    public var id(get, set):Int;

    function set_id(v) {
        _id = v;

        return _id;
    }

    function get_id() {
        if (_id == -1) {
            throw "";
        }

        return _id;
    }
    public var isReady(get, null):Bool;

    function get_isReady() {
        return _id != -1;
    }

    public function dispose() {

    }

    public function upload() {

    }

    public function new(context:AbstractContext) {
        this._uuid = Uuid.getUuid();
        this._context = context;
        this._id = -1;

    }
}
