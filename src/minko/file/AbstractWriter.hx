package minko.file;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import minko.signal.Signal2;
import minko.signal.Signal;
import minko.StreamingCommon;
import minko.Tuple.Tuple3;
typedef SerializedDependency = Array<Tuple3< Int, Int, Bytes>> ;
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
class AbstractWriter <T> {


    private var _complete:Signal<AbstractWriter>;

    private var _error:Signal2<AbstractWriter, WriterError>;
    private var _data:T;

    private var _preprocessors:Array<AbstractWriterPreprocessor<T>>;

    private var _magicNumber:Int;
    public var complete(get, null):Signal<AbstractWriter>;

    function get_complete() {
        return _complete;
    }
    public var error(get, null):Signal2<AbstractWriter, WriterError>;

    function get_error() {
        return _error;
    }
    public var data(get, set):T;

    function get_data() {
        return _data;
    }

    function set_data(v) {
        _data = v;
        return v;
    }

    public function registerPreprocessor(preprocessor:AbstractWriterPreprocessor<T>) {
        _preprocessors.push(preprocessor);

        return this;
    }

    public function unregisterPreprocessor(preprocessor:AbstractWriterPreprocessor<T>) {
        _preprocessors.remove(preprocessor);

        return this;
    }


    public function write(filename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency = null) {
        writeEmbedded(filename, assetLibrary, options, writerOptions, dependency, null, null);
    }

    public function writeEmbedded(filename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Bytes, embeddedHeaderData:BytesOutput) {
        var file = sys.io.File.write(filename, true);

        doWrite(filename, assetLibrary, options, writerOptions, dependency, userDefinedDependency, embeddedHeaderData, file);

        complete.execute(this);
    }

    public function getHeader(dependenciesSize:Int, dataSize:Int, linkedSize:Int):BytesOutput {
        var headerSize = StreamingCommon.MINKO_SCENE_HEADER_SIZE;
        var header = new BytesOutput();//Bytes.alloc(headerSize)
        //MAGIC NUMBER
        header.writeInt32(_magicNumber);
        //VERSION
        var version = ((StreamingCommon.MINKO_SCENE_VERSION_MAJOR & 0xFF) << 24) | ((StreamingCommon.MINKO_SCENE_VERSION_MINOR << 8) & 0xFFFF) | (StreamingCommon.MINKO_SCENE_VERSION_PATCH & 0xFF);
        header.writeInt32(version);

        var fileSize = headerSize + dependenciesSize + dataSize + linkedSize + 32;
        header.writeInt32(fileSize);
        header.writeInt32(headerSize + 8);
        header.writeInt32(dependenciesSize + 8);
        header.writeInt32(dataSize + 8);
        header.writeInt32(linkedSize + 8);

        return header;
    }


    public function embedAll(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Bytes) {
        var data = new BytesOutput();

        var embeddedHeaderdata = new BytesOutput();

        doWrite(null, assetLibrary, options, writerOptions, dependency, userDefinedDependency, embeddedHeaderdata, data);

        complete.execute(this);

        return data;
    }

    public function embed(assetLibrary:AssetLibrary, options:Options, dependency:Dependency, writerOptions:WriterOptions, embeddedHeaderData:BytesOutput):BytesOutput {
        return null;
    }


    private function preprocess(data:T, assetLibrary:AssetLibrary) {
        for (preprocessor in _preprocessors) {
            var statusChangedSlot = preprocessor.statusChanged.connect(
                function(preprocessor:AbstractWriterPreprocessor<T>, status:String) {
                    var progressRate = (preprocessor.progressRate * 100.0 );

                    trace(status + " ( " + progressRate + "% )");
                });

            preprocessor.process(data, assetLibrary);
        }
    }

    private function doWrite(filename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:SerializedDependency, embeddedHeaderData:BytesOutput, result:BytesOutput) {
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
            var serializedData = embed(assetLibrary, options, globalDependency, writerOptions, embeddedHeaderData);

            var internalLinkedAssets = new Array<Bytes>();
            var serializedDependency:Array<SerializedAsset> =
            localDependency.serialize(filename, assetLibrary, options, writerOptions, internalLinkedAssets);

            if (userDefinedDependency.length > 0) {
                //todo
                serializedDependency = serializedDependency.concat(userDefinedDependency);
            }

            var serializedDependencyBufs = new BytesOutput();
            serializedDependencyBufs.writeInt32(serializedDependency.length);
            for (serializedDependencyEntry in serializedDependency) {
                serializedDependencyBufs.writeInt32(serializedDependencyEntry.first);
                serializedDependencyBufs.writeInt32(serializedDependencyEntry.second);
                serializedDependencyBufs.writeBytes(serializedDependencyEntry.thiree);
            }
            var sLinkedAssets = new BytesOutput();
            sLinkedAssets.writeInt32(internalLinkedAssets.length);
            for (internalLinkedAsset in internalLinkedAssets) {
                sLinkedAssets.writeBytes(internalLinkedAsset);
            }


            var header = getHeader(serializedDependencyBufs.length, serializedData.length, sLinkedAssets.length);

            result.writeBytes(header.getBytes());
            result.writeBytes(serializedDependencyBufs.getBytes());
            result.writeBytes(serializedData.getBytes());
            result.writeBytes(sLinkedAssets.getBytes());

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

