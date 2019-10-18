package minko.file;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal2;
import minko.signal.Signal;
@:expose("minko.file.Loader")
class Loader {
    private var _options:Options;

    private var _filesQueue:Array<String>;
    private var _loading:Array<String>;
    private var _filenameToOptions:StringMap<Options>;
    private var _files:StringMap<File> ;

    private var _progress:Signal2<Loader, Float>;
    private var _parsingProgress:Signal2<Loader, Float>;
    private var _complete:Signal<Loader>;
    private var _error:Signal2<Loader, String>;

    private var _protocolErrorSlots:ObjectMap< AbstractProtocol, SignalSlot2<AbstractProtocol, String>>;
    private var _protocolCompleteSlots:ObjectMap< AbstractProtocol, SignalSlot<AbstractProtocol>>;
    private var _protocolProgressSlots:ObjectMap< AbstractProtocol, SignalSlot2<AbstractProtocol, Float> >;
    private var _parserProgressSlots:ObjectMap< AbstractParser, SignalSlot2<AbstractParser, Float> >;
    private var _parserCompleteSlots:ObjectMap<AbstractParser, SignalSlot<AbstractParser>> ;
    private var _parserErrorSlots:ObjectMap<AbstractParser, SignalSlot2<AbstractParser, String>>;

    private var _protocolToProgress:ObjectMap<AbstractProtocol, Float>;
    private var _parserToProgress:ObjectMap<AbstractParser, Float>;

    private var _numFiles:Int;

    private var _numFilesToParse:Int;
    private var _numFilesToParseComplete:Int;
    public static function create():Loader {
        return new Loader();
    }

    public static function createbyOptions(options):Loader {
        var copy:Loader = Loader.create();

        copy._options = options;

        return copy;
    }

    public static function createbyLoader(loader:Loader):Loader {
        var copy:Loader = Loader.create();

        copy._options = loader._options;

        return copy;
    }
    public var options(get, set):Options;

    function get_options() {
        return _options;
    }

    function set_options(v) {
        _options = v;
        return v;
    }
    public var complete(get, null):Signal<Loader>;

    function get_complete() {
        return _complete;
    }
    public var progress(get, null):Signal2<Loader, Float>;

    function get_progress() {
        return _progress;
    }
    public var parsingProgress(get, null):Signal2<Loader, Float>;

    function get_parsingProgress() {
        return _parsingProgress;
    }
    public var error(get, null):Signal2<Loader, String>;

    function get_error() {
        return _error;
    }
    public var filesQueue(get, null):Array< String>;

    function get_filesQueue() {
        return _filesQueue;
    }

    public var loading(get, null):Bool;

    function get_loading() {
        return _filesQueue.length > 0 || _loading.length > 0;
    }

    public function queue(filename):Loader {
        return setQueue(filename, null);
    }

    public function setQueue(filename, options):Loader {
        if (StringTools.trim(filename) == "") {
            return (this);
        }

        _filesQueue.push(filename);
        _filenameToOptions.set(filename, (options != null ? options : _options));

        return (this);
    }

    public function load() {
        if (_filesQueue.length == 0) {
            _complete.execute((this));
        }
        else {
            _numFiles = _filesQueue.length;
            _protocolToProgress = new ObjectMap<AbstractProtocol, Float>();

            var queue = _filesQueue.concat([]);

            for (filename in queue) {
                var options = _filenameToOptions.get(filename);

                var includePaths:Array<String> = options.includePaths;

                var loadFile = false;

                var resolvedFilename = options.uriFunction(File.sanitizeFilename(filename));

                var protocol:AbstractProtocol = options.protocolFunction(resolvedFilename)();

                protocol.options = (options);

                if (includePaths.length == 0 || protocol.isAbsolutePath(resolvedFilename)) {
                    loadFile = true;
                }
                else {
                    inline function checkFileExists() {
                        for (includePath in includePaths) {
                            resolvedFilename = options.uriFunction(File.sanitizeFilename(includePath + '/' + filename));

                            protocol = options.protocolFunction(resolvedFilename)();

                            protocol.options = (options);

                            //only hl  not html
                            //todo
                            if (protocol.fileExists(resolvedFilename)) {
                                loadFile = true;

                                break;
                            }
                        }
                    }
                    checkFileExists();
                    if (loadFile == false) {
                        includePaths = Options.includePaths_clear();
                        checkFileExists();
                    }
                }

                if (loadFile) {
                    _files.set(filename, protocol.file);

                    _filesQueue.remove(filename);
                    _loading.push(filename);

                    var that = this;

                    _protocolErrorSlots.set(protocol, protocol.error.connect(function(protocol:AbstractProtocol, err:String) {
                        that.protocolErrorHandler(protocol, err);
                    }));

                    _protocolCompleteSlots.set(protocol, protocol.complete.connect(function(protocol:AbstractProtocol) {
                        that.protocolCompleteHandler(protocol);
                    }));

                    _protocolProgressSlots.set(protocol, protocol.progress.connect(function(protocol:AbstractProtocol, progress:Float) {
                        that.protocolProgressHandler(protocol, progress);
                    }));

                    protocol.loadFile(filename, resolvedFilename, options);
                }
                else {
                    var error = ("ProtocolError" + "File does not exist: " + filename + ", include paths: " + _options.includePaths.join(","));

                    errorThrown(error);
                }
            }
        }
    }
    public var files(get, null):StringMap<File>;

    function get_files() {
        return _files;
    }

    public function new() {
        this._options = Options.empty();
        this._complete = new Signal<Loader>();
        this._progress = new Signal2<Loader, Float>();
        this._parsingProgress = new Signal2<Loader, Float>();
        this._error = new Signal2<Loader, String>();
        this._numFilesToParse = 0;
        this._numFilesToParseComplete=0;
        this._filesQueue = [];
        this._loading = [];
        this._filenameToOptions = new StringMap<Options>();
        this._files = new StringMap<File>() ;


        this._protocolErrorSlots = new ObjectMap< AbstractProtocol, SignalSlot2<AbstractProtocol, String>>();
        this._protocolCompleteSlots = new ObjectMap< AbstractProtocol, SignalSlot<AbstractProtocol>>();
        this._protocolProgressSlots = new ObjectMap< AbstractProtocol, SignalSlot2<AbstractProtocol, Float> >();
        this._parserProgressSlots = new ObjectMap< AbstractParser, SignalSlot2<AbstractParser, Float> >();
        this._parserCompleteSlots = new ObjectMap<AbstractParser, SignalSlot<AbstractParser>> ();
        this._parserErrorSlots = new ObjectMap<AbstractParser, SignalSlot2<AbstractParser, String>>();

        this._protocolToProgress = new ObjectMap<AbstractProtocol, Float>();
        this._parserToProgress = new ObjectMap<AbstractParser, Float>();
    }

    public function protocolErrorHandler(protocol:AbstractProtocol, err:String) {
        var error = ("ProtocolError" + "Protocol error: " + protocol.file.filename + ", include paths: " + _options.includePaths.join(","));

        errorThrown(error);
    }

    public function protocolCompleteHandler(protocol:AbstractProtocol) {
        _protocolToProgress.set(protocol, 1.0);

        var filename = protocol.file.filename;

        _loading.remove(filename);

        _filenameToOptions.remove(filename);
        _protocolErrorSlots.get(protocol).dispose();
        _protocolErrorSlots.remove(protocol);
        _protocolCompleteSlots.get(protocol).dispose();
        _protocolCompleteSlots.remove(protocol);
        _protocolProgressSlots.get(protocol).dispose();
        _protocolProgressSlots.remove(protocol);

        _numFilesToParse++;

        trace("file '" + protocol.file.filename + "' loaded, " + _loading.length + " file(s) still loading, " + _filesQueue.length + " file(s) in the queue");

        var parsed = processData(filename, protocol.file.resolvedFilename, protocol.options, protocol.file.data);
        if (options.storeDataIfNotParsed) {
            if (!parsed) {
                _numFilesToParseComplete++;
                finalize();
            }
        }
    }

    public function protocolProgressHandler(protocol:AbstractProtocol, progress:Float) {
        _protocolToProgress.set(protocol, progress);

        var newTotalProgress = 0.0;

        for (protocolAndProgress in _protocolToProgress.keys()) {
            newTotalProgress += _protocolToProgress.get(protocolAndProgress) / _numFiles;
        }

        if (newTotalProgress > 1.0) {
            newTotalProgress = 1.0 ;
        }

        _progress.execute((this), newTotalProgress);
    }


    public function finalize() {
        if (_loading.length == 0 && _filesQueue.length == 0 && _numFilesToParse == _numFilesToParseComplete) {
            _protocolErrorSlots = new ObjectMap<AbstractProtocol, SignalSlot2<AbstractProtocol, String>>();
            _protocolCompleteSlots = new ObjectMap<AbstractProtocol, SignalSlot<AbstractProtocol>>();
            _protocolProgressSlots = new ObjectMap< AbstractProtocol, SignalSlot2<AbstractProtocol, Float> >();

            _filenameToOptions = new StringMap<Options>();

            _complete.execute(this);
            _parserErrorSlots = new ObjectMap< AbstractParser, SignalSlot2<AbstractParser, String>>();
            _protocolToProgress = new ObjectMap<AbstractProtocol, Float>();
            _files = new StringMap<File>();
        }
    }


    public function processData(filename:String, resolvedFilename:String, options:Options, data:Bytes) {
        var extension = filename.substr(filename.lastIndexOf('.') + 1).toLowerCase();

        var parser:AbstractParser = null;
        try {
            if (options.getParser(extension) != null)
                parser = options.getParser(extension)();
        }
        catch (e:String) {
            trace(e);
        }
        if (parser != null) {
            _parserProgressSlots.set(parser, parser.progress.connect(parserProgressHandler));
            _parserCompleteSlots.set(parser, parser.complete.connect(parserCompleteHandler));
            _parserErrorSlots.set(parser, parser.error.connect(parserErrorHandler));
            parser.parse(filename, resolvedFilename, options, data, options.assetLibrary);
        }
        else {
            if (options.storeDataIfNotParsed) {
                if (extension != "glsl") {
                    trace("no parser found for extension '" + extension + "'");
                }
                options.assetLibrary.setBlob(filename, data);
            }
        }

        return parser != null;
    }

    public function parserProgressHandler(parser:AbstractParser, progress:Float) {
        _parserToProgress.set(parser, progress);

        var newTotalProgress = 0.0 ;

        for (parserAndProgress in _parserToProgress.keys()) {
            newTotalProgress += _parserToProgress.get(parserAndProgress) / _numFiles;
        }

        if (newTotalProgress > 1.0) {
            newTotalProgress = 1.0 ;
        }

        _parsingProgress.execute((this), newTotalProgress);
    }


    public function parserCompleteHandler(parser:AbstractParser) {

        _numFilesToParseComplete++;
        _parserCompleteSlots.remove(parser);

        _parserToProgress.set(parser, 1.0);

        finalize();
    }

    public function parserErrorHandler(parser:AbstractParser, error:String) {
        errorThrown(error);
    }

    public function errorThrown(error:String) {
        if (_error.numCallbacks > 0) {
            _error.execute(this, error);
        }
        else {
            trace(error);

            throw error;
        }
    }


}
