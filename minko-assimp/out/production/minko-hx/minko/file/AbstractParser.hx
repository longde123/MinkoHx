package minko.file;
import haxe.io.Bytes;
import minko.signal.Signal2;
import minko.signal.Signal;
@:expose("minko.file.AbstractParser")
class AbstractParser {

    public var _progress:Signal2<AbstractParser, Float>;
    public var _complete:Signal<AbstractParser>;
    public var _error:Signal2<AbstractParser, String>;

    public function dispose() {

    }


    public var progress(get, null):Signal2<AbstractParser, Float>;
    public var complete(get, null):Signal<AbstractParser>;
    public var error(get, null):Signal2<AbstractParser, String>;

    function get_progress() {
        return _progress;
    }

    function get_complete() {
        return _complete;
    }

    function get_error() {
        return _error;
    }

    public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {

    }

    public function new() {
        this._progress = new Signal2<AbstractParser, Float>();
        this._complete = new Signal<AbstractParser>();
        this._error = new Signal2<AbstractParser, String>();

    }

}
