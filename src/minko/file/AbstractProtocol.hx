package minko.file;
import haxe.io.Bytes;
import minko.signal.Signal2;
import minko.signal.Signal;
class AbstractProtocol {

    private var _file:File;
    private var _options:Options;
    private var _progress:Signal2<AbstractProtocol, Float>;
    private var _complete:Signal<AbstractProtocol>;
    private var _error:Signal2<AbstractProtocol, String>;

    public function dispose() {

    }


    static function create() {
        return new AbstractProtocol();
    }

    public var file(get, null):File;

    function get_file() {
        return _file;
    }
    public var options(get, set):Options;

    function get_options() {
        return _options;
    }

    function set_options(v) {
        _options = v;
        return v;
    }
    public var progress(get, null):Signal2<AbstractProtocol, Float>;
    public var complete(get, null):Signal<AbstractProtocol>;
    public var error(get, null):Signal2<AbstractProtocol, String>;

    function get_complete() {
        return _complete;
    }

    function get_progress() {
        return _progress;
    }

    function get_error() {
        return _error;
    }

    public function loadFile(filename, resolvedFilename, options) {
        _options = options;
        _file.filename = filename;
        _file.resolvedFilename = resolvedFilename;

        load();
    }

    public function load() {

    }

    public function fileExists(filename) {
        return false;
    }

    public function isAbsolutePath(filename) {
        return false;
    }

    public function new() {
        this._file = File.create();
        this._options = Options.empty();
        this._complete = new Signal<AbstractProtocol>();
        this._progress = new Signal2<AbstractProtocol, Float>();
        this._error = new Signal2<AbstractProtocol, String>();
    }
    public var resolvedFilename(get, null):String;


    function get_resolvedFilename() {

        return _file._resolvedFilename;
    }
    public var data(get, set):Bytes;

    function get_data() {
        return _file._data;
    }

    function set_data(d) {
        _file._data = d;
        return d;
    }

}
