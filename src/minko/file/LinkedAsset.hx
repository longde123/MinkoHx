package minko.file;
import haxe.io.Bytes;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2;
@:enum abstract LinkType(Int) from Int to Int {

    var Copy = 0;
    var Internal = 1;
    var External = 2;
}
class LinkedAsset {


    private var _offset:Int;
    private var _length:Int;

    private var _filename:String;
    private var _lastResolvedFilename:String;
    private var _data:Bytes;

    private var _linkType:LinkType;

    private var _complete:Signal2<LinkedAsset, Bytes>;
    private var _progress:Signal2<LinkedAsset, Float>;
    private var _error:Signal2<LinkedAsset, String >;

    private var _loaderCompleteSlot:SignalSlot<Loader>;
    private var _loaderProgressSlot:SignalSlot2<Loader, Float>;
    private var _loaderErrorSlot:SignalSlot2<Loader, String>;

    public static function create():LinkedAsset {
        var instance = (new LinkedAsset());

        return instance;
    }

    public var offset(get, set):Int;

    function get_offset() {
        return _offset;
    }

    function set_offset(value) {
        _offset = value;

        return value;
    }
    public var length(get, set):Int;

    function get_length() {
        return _length;
    }

    function set_length(value) {
        _length = value;

        return value;
    }
    public var filename(get, set):String;

    function get_filename() {
        return _filename;
    }

    function set_filename(value) {
        _filename = value;

        return value;
    }
    public var lastResolvedFilename(get, null):String;

    function get_lastResolvedFilename() {
        return _lastResolvedFilename;
    }
    public var data(get, set):Bytes;

    function get_data() {
        return _data;
    }

    function set_data(v) {
        _data = v;

        return v;
    }
    public var linkType(get, set):LinkType;

    function get_linkType() {
        return _linkType;
    }

    function set_linkType(value) {
        _linkType = value;

        return value;
    }
    public var complete(get, null):Signal2<LinkedAsset, Bytes>;

    function get_complete() {
        return _complete;
    }
    public var progress(get, null):Signal2<LinkedAsset, Float>;

    function get_progress() {
        return _progress;
    }
    public var error(get, null):Signal2<LinkedAsset, String>;

    function get_error() {
        return _error;
    }


    public function new() {
        this._offset = 0;
        this._length = 0;
        this._filename = "";
        this._lastResolvedFilename = "";
        this._data = null;
        this._linkType = LinkType.Internal;
        this._complete = new Signal2<LinkedAsset, Bytes>();
        this._progress = new Signal2<LinkedAsset, Float>();
        this._error = new Signal2<LinkedAsset, String>();
    }
    public function resolve(options:Options){

    }


}
