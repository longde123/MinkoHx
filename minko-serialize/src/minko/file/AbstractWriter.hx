package minko.file;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import minko.signal.Signal2;
import minko.signal.Signal;
import minko.StreamingCommon;
typedef SerializedDependency = Array<AbstractStream> ;
class WriterError {
    private var _type:String;

    private var _message:String;

    public function new(type, message) {
        this._type = type;
        this._message = (message);
    }
    public var type(get, null):String;

    function get_type() {
        return _type;
    }
}
class AbstractWriter {

    private var _complete:Signal<AbstractWriter >;

    private var _error:Signal2<AbstractWriter, WriterError>;
    private var _data:Dynamic;

    private var _preprocessors:Array<AbstractWriterPreprocessor>;

    private var _magicNumber:Int;
    public var complete(get, null):Signal<AbstractWriter>;

    function get_complete() {
        return _complete;
    }
    public var error(get, null):Signal2<AbstractWriter, WriterError>;

    function get_error() {
        return _error;
    }
    public var data(get, set):Dynamic;

    function get_data() {
        return _data;
    }

    function set_data(v) {
        _data = v;
        return v;
    }

    public function registerPreprocessor(preprocessor:AbstractWriterPreprocessor) {
        _preprocessors.push(preprocessor);

        return this;
    }

    public function unregisterPreprocessor(preprocessor:AbstractWriterPreprocessor) {
        _preprocessors.remove(preprocessor);

        return this;
    }


    public function embedAll(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Array<SerializedAsset> = null):Bytes {
        //返回 序列化内容 _data
        complete.execute(this);
        return null;
    }

    public function write(filename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Array<SerializedAsset> = null):Void {

        //返回 序列化到本地后 文件头内容 _data
        complete.execute(this);
    }


    public function embed(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency):AbstractStream {
        //
        return null;
    }


    private function preprocess(data:Dynamic, assetLibrary:AssetLibrary) {
        for (preprocessor in _preprocessors) {
            var statusChangedSlot = preprocessor.statusChanged.connect(
                function(preprocessor:AbstractWriterPreprocessor , status:String) {
                    var progressRate = (preprocessor.progressRate * 100.0 );

                    trace(status + " ( " + progressRate + "% )");
                });

            preprocessor.process(data, assetLibrary);
        }
    }

    private function doWrite(filename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:SerializedDependency) {
        preprocess(data, assetLibrary);

        var localDependency:Dependency;
        var globalDependency:Dependency;

        if (dependency == null) {
            globalDependency = Dependency.create();
            localDependency = globalDependency;
        }
        else {
            globalDependency = dependency;
            localDependency = Dependency.create();
        }

        try {

            var serializedDependency:Array<SerializedAsset> = localDependency.serialize(filename, assetLibrary, options, writerOptions);

            if (userDefinedDependency.length > 0) {
                //todo fix
                serializedDependency = serializedDependency.concat(userDefinedDependency);
            }


            var headerSize = StreamingCommon.MINKO_SCENE_HEADER_SIZE;

            //VERSION
            var version = ((StreamingCommon.MINKO_SCENE_VERSION_MAJOR & 0xFF) << 24) | ((StreamingCommon.MINKO_SCENE_VERSION_MINOR << 8) & 0xFFFF) | (StreamingCommon.MINKO_SCENE_VERSION_PATCH & 0xFF);


        }
        catch (exception:WriterError) {
            if (error.numCallbacks > 0) {
                error.execute(this, exception);
            }
            else {
                throw exception;
            }
        }
    }
}

