package minko.file;

import minko.signal.Signal;
import assimp.IOSystem;
import assimp.IOSystem.IOStream;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal.SignalSlot;
import haxe.ds.ObjectMap;
typedef ErrorFunction = IOHandler -> String -> String -> Void;
class IOHandler extends IOSystem {


    private var _options:Options;
    private var _assets:AssetLibrary;
    private var _resolvedFilename:String;
    private var _errorFunction:ErrorFunction;
    private var _loaderCompleteSlots:ObjectMap<Loader, SignalSlot<Loader>>;
    private var _loaderErrorSlots:ObjectMap<Loader, SignalSlot2<Loader, String> >;
    public var complete :Signal<Loader>;
    public function new(options:Options, assets:AssetLibrary, resolvedFilename:String) {
        super();
        this._options = options;
        this._assets = assets;
        this._resolvedFilename = resolvedFilename;
        this.complete=new Signal<Loader>();
    }

    public function errorFunction(errorFunction:ErrorFunction) {
        _errorFunction = errorFunction;
    }

    override public function close(pFile:IOStream) {
        this.complete.dispose();
    }

    override public function exists(file:String):Bool {
        return false;
    }

    public function getOsSeparator():String {
#if _WIN32
				return  '\\';
#else
        return '/';
#end
    }

    override public function open(pFile:String):IOStream {
        var loader = Loader.create();
        loader.options = (_options);

        _options.loadAsynchronously = (false);
        _options.storeDataIfNotParsed = (false);
        _options.parserFunction = (function(UnnamedParameter1) {
            return null;
        });

        var absolutePath = File.extractPrefixPathFromFilename(_resolvedFilename);
        var relativePath:String = File.extractPrefixPathFromFilename(pFile);
        var completePath = absolutePath + '/' + relativePath;
        var filename = File.removePrefixPathFromFilename(pFile);

        // Some relative paths begin with "./"
        if (relativePath != null && !(relativePath.length == 1 && relativePath.charAt(0) == '.')) {
            _options.includePaths.push(completePath);
        }

        var stream:IOStream = null;

        _loaderCompleteSlots.set(loader, loader.complete.connect(function(loaderThis:Loader) {
            _loaderErrorSlots.remove(loader);
            _loaderCompleteSlots.remove(loader);
            this.complete.execute(loader);
            stream = new MemoryIOStream(loaderThis.files.get(filename).data );
        }));

        _loaderErrorSlots.set(loader, loader.error.connect(function(UnnamedParameter1, error) {
            if (_errorFunction != null) {
                _errorFunction(this, filename, error);
            }
            else {
                throw error;
            }
        }));

        loader.queue(filename).load();

        return stream;
    }

}
