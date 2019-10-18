package minko.extension;
import minko.serialize.Types.StreamingComponentId;
import minko.signal.Signal2;
import minko.signal.Signal;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import Lambda;
import minko.component.JobManager.Job;
import minko.component.POPGeometryLodScheduler;
import minko.component.TextureLodScheduler;
import minko.data.Provider;
import minko.deserialize.LodSchedulerDeserializer;
import minko.file.AbstractParser;
import minko.file.AbstractSerializerParser;
import minko.file.AbstractStreamedAssetParser;
import minko.file.AssetLibrary;
import minko.file.Dependency;
import minko.file.File;
import minko.file.LinkedAsset;
import minko.file.Options;
import minko.file.POPGeometryParser;
import minko.file.POPGeometryWriter;
import minko.file.SceneParser;
import minko.file.SceneWriter;
import minko.file.SerializedAsset;
import minko.file.StreamedAssetParserScheduler;
import minko.file.StreamedTextureParser;
import minko.file.StreamedTextureWriter;
import minko.file.StreamingOptions;
import minko.file.WriterOptions;
import minko.geometry.Geometry;
import minko.render.AbstractTexture;
import minko.render.Texture;
import minko.serialize.LodSchedulerSerializer;
import minko.serialize.Types.StreamedAssetType;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import minko.StreamingCommon;
class ParserEntry {
    public var readySlot:SignalSlot<AbstractStreamedAssetParser>;
    public var completeSlots:Array<SignalSlot<AbstractParser>> ;
    public var progressSlot:SignalSlot2<AbstractStreamedAssetParser, Float>;
    public var progressRate:Float;

    public function new() {
        this.progressRate = 0.0;
    }
}

class StreamingExtension extends AbstractExtension {
    private var deserializePOPGeometry_geometryId = 0;


    private var deserializeStreamedTexture_textureId = 0;
    private var _parserSchedulerDefaultPriority:Float;

    private var _streamingOptions:StreamingOptions;

    private var _sceneStreamingComplete:Signal<StreamingExtension>;
    private var _sceneStreamingProgress:Signal2<StreamingExtension, Float>;
    private var _sceneStreamingActive:Signal<StreamingExtension>;
    private var _sceneStreamingInactive:Signal<StreamingExtension>;

    private var _parserSchedulerActiveSlot:SignalSlot<StreamedAssetParserScheduler>;
    private var _parserSchedulerInactiveSlot:SignalSlot<StreamedAssetParserScheduler>;

    private var _parsers:ObjectMap< AbstractStreamedAssetParser, ParserEntry >;

    private var _numActiveParsers:Int;
    private var _totalProgressRate:Float;

    private var _parserScheduler:StreamedAssetParserScheduler;

    public static function create() {
        var instance = new StreamingExtension() ;

        return instance;
    }
    public var sceneStreamingComplete(get, null):Signal<StreamingExtension>;

    function get_sceneStreamingComplete() {
        return _sceneStreamingComplete;
    }
    public var sceneStreamingProgress(get, null):Signal<StreamingExtension>;

    function get_sceneStreamingProgress() {
        return _sceneStreamingProgress;
    }
    public var sceneStreamingActive(get, null):Signal<StreamingExtension>;

    function get_sceneStreamingActive() {
        return _sceneStreamingActive;
    }
    public var sceneStreamingInactive(get, null):Signal<StreamingExtension>;

    function get_sceneStreamingInactive() {
        return _sceneStreamingInactive;
    }
    public var streamingOptions(get, set):Signal<StreamingExtension>;

    function get_streamingOptions() {
        return _streamingOptions ;
    }

    function set_streamingOptions(value) {
        _streamingOptions = value;
        return value;
    }


    public function new() {
        super();
        this._sceneStreamingComplete = new Signal<StreamingExtension>();
        this._sceneStreamingProgress = new Signal2<StreamingExtension, Float>();
        this._sceneStreamingActive = new Signal<StreamingExtension>();
        this._sceneStreamingInactive = new Signal<StreamingExtension>();
        this._numActiveParsers = 0;
        this._totalProgressRate = 0.0;
    }

    override public function bind() {

        SceneWriter.registerComponent(POPGeometryLodScheduler, LodSchedulerSerializer.serializePOPGeometryLodScheduler);

        SceneParser.registerComponent(StreamingComponentId.POP_GEOMETRY_LOD_SCHEDULER, LodSchedulerDeserializer.deserializePOPGeometryLodScheduler);

        SceneWriter.registerComponent(TextureLodScheduler, LodSchedulerSerializer.serializeTextureLodScheduler);

        SceneParser.registerComponent(StreamingComponentId.TEXTURE_LOD_SCHEDULER, LodSchedulerDeserializer.deserializeTextureLodScheduler);

        return this;
    }

    public function initialize(streamingOptions:StreamingOptions) {
        this.streamingOptions = (streamingOptions);

        if (streamingOptions.geometryStreamingIsActive) {
            AbstractSerializerParser.registerAssetFunction(StreamedAssetType.STREAMED_GEOMETRY_ASSET, StreamingExtension.deserializePOPGeometry);
            Dependency.setGeometryFunction(StreamingExtension.serializePOPGeometry,
            function(geometry:Geometry) {
                return geometry.data.hasProperty("type") && geometry.data.get("type") == "pop";
            },
            11);
        }

        if (streamingOptions.textureStreamingIsActive) {
            AbstractSerializerParser.registerAssetFunction(StreamedAssetType.STREAMED_TEXTURE_ASSET, StreamingExtension.deserializeStreamedTexture);
            Dependency.setTextureFunction(StreamingExtension.serializeStreamedTexture);
        }
    }

    public function loadingContextDisposed() {
        _parserScheduler = null;
    }

    public function pauseStreaming() {
        if (_parserScheduler) {
            _parserScheduler.priority = (0.0);
        }
    }

    public function resumeStreaming() {
        if (_parserScheduler) {
            _parserScheduler.priority = (10.0);
        }
    }

    public function parserScheduler(options:Options, jobList:Array<Job>) {
        if (!_parserScheduler || _parserScheduler.complete) {
            var parameters = new Parameters();
            parameters.maxNumActiveParsers = _streamingOptions.maxNumActiveParsers();
            parameters.useJobBasedParsing = false;
            parameters.requestAbortingEnabled = _streamingOptions.requestAbortingEnabled();
            parameters.abortableRequestProgressThreshold = _streamingOptions.abortableRequestProgressThreshold();

            _parserScheduler = StreamedAssetParserScheduler.create(options, parameters);

            _parserScheduler.priority = (_parserSchedulerDefaultPriority);

            _parserSchedulerActiveSlot = _parserScheduler.active.connect(function(parserScheduler:StreamedAssetParserScheduler) {
                sceneStreamingActive.execute((this));
            });

            _parserSchedulerInactiveSlot = _parserScheduler.inactive.connect(function(parserScheduler:StreamedAssetParserScheduler) {
                sceneStreamingInactive.execute((this));
            });

            jobList.push(_parserScheduler);
        }

        return _parserScheduler;
    }

    public function serializePOPGeometry(dependency:Dependency, assetLibrary:AssetLibrary, geometry:Geometry, resourceId:Int, options:Options, writerOptions:WriterOptions, includeDependencies:Array<SerializedAsset>) {
        var assetIsNull = writerOptions.assetIsNull(geometry.uuid);

        var writer:POPGeometryWriter = POPGeometryWriter.create();

        writer.streamingOptions = (_streamingOptions);

        var assetType = StreamedAssetType.STREAMED_GEOMETRY_ASSET;

        var filename = assetLibrary.geometryName(geometry);

        var outputFilename = writerOptions.geometryNameFunction(filename);
        var writeFilename = writerOptions.geometryUriFunction(outputFilename);

        writer.data=(writerOptions.geometryFunction(filename, geometry));

        var content:Bytes = null;

        var hasHeader = !assetIsNull;
        var headerSize = 0;

        var linkedAsset = LinkedAsset.create();

        var linkedAssetId = dependency.registerDependencyLinkedAsset(linkedAsset);

        writer.linkedAsset(linkedAsset, linkedAssetId);

        if (!assetIsNull && writerOptions.embedMode & WriterOptions.EmbedMode.Geometry) {
            content = writer.embedAll(assetLibrary, options, writerOptions, dependency);

            headerSize = content.length;

            linkedAsset.linkType=(LinkedAsset.LinkType.Internal);
        }
        else {
            hasHeader = false;

            linkedAsset.filename = (outputFilename);
            linkedAsset.linkType = (LinkedAsset.LinkType.External);

            var headerData = new BytesOutput();

            if (!assetIsNull) {
                writer.write(writeFilename, assetLibrary, options, writerOptions, dependency, null, headerData);

                headerSize = headerData.length;
            }

            if (hasHeader) {
                linkedAsset.offset = (headerSize);

                content = headerData.getBytes();
            }
            else {
                var contentStream = new BytesOutput();

                contentStream.writeInt16(linkedAssetId);

                content = contentStream.getBytes();
            }
        }

        var metadata = (hasHeader ? 1 << 31 : 0) + ((headerSize & 0x0fff) << 16) + assetType;

        return new SerializedAsset(metadata, resourceId, content);
    }
//AssetLibrary -> Options -> String -> Bytes -> Dependency -> Int -> Array<Job> -> Void;
    public function deserializePOPGeometry(  assetLibrary:AssetLibrary, options:Options, completePath:String, data:Bytes, dependencies:Dependency, assetRef:Int, jobList:Array<Job>) {
        var hasHeader = false;
        var streamedAssetHeaderSize = 0;
        var streamedAssetHeaderData = new BytesOutput();
        var linkedAsset:LinkedAsset = null;//buffview  ref to data

        //data 内部就有 linkedAsset  外部就没有linkedAsset
        getStreamedAssetHeader(metaData, data, completePath, dependencies, options, true, streamedAssetHeaderData, hasHeader, streamedAssetHeaderSize, linkedAsset);

        var geometryData = Provider.create();

        var parser:POPGeometryParser = POPGeometryParser.create();

        parser.data = (geometryData);
        parser.streamingOptions = (_streamingOptions);
        parser.dependency = (dependencies);

        if (linkedAsset != null) {
            parser.linkedAsset = (linkedAsset);
        }
        var extensionName = "geometry";

        // TODO serialize geometry name
        var defaultName:String = (deserializePOPGeometry_geometryId++) + "." + extensionName;

        var filenameLastSeparatorPosition = defaultName.lastIndexOf("/");
        var filenameWithExtension = defaultName.substr(filenameLastSeparatorPosition == -1 ? 0 : filenameLastSeparatorPosition + 1);
        var filename = filenameWithExtension.substr(0, filenameWithExtension.lastIndexOf("."));

        var uniqueFilename:String = filenameWithExtension;
        while (assetLibrary.geometry(uniqueFilename)) {
            uniqueFilename = filename + (deserializePOPGeometry_geometryId++) + "." + extensionName;
        }

        parser.parse(uniqueFilename, uniqueFilename, options, streamedAssetHeaderData, assetLibrary);

        var geometry:Geometry = assetLibrary.geometry(uniqueFilename);

        dependencies.registerReferenceGeometry(assetRef, geometry);

        registerPOPGeometryParser(parser, geometry);

        var parserScheduler:StreamedAssetParserScheduler = this.parserScheduler(options, jobList);

        parserScheduler.addParser(parser);

        _streamingOptions.masterLodScheduler.registerGeometry(geometry, geometryData);
    }

    public function serializeStreamedTexture(dependency:Dependency, assetLibrary:AssetLibrary, textureDependency:TextureDependency, options:Options, writerOptions:WriterOptions) {
        var texture = textureDependency.texture;
        var dependencyId = textureDependency.dependencyId;

        var assetIsNull = writerOptions.assetIsNull(texture.uuid);

        var writer:StreamedTextureWriter = StreamedTextureWriter.create();
        writer.textureType = (textureDependency.textureType);

        var assetType = StreamedAssetType.STREAMED_TEXTURE_ASSET;

        var filename = assetLibrary.textureName(texture);

        var outputFilename = writerOptions.textureNameFunction(filename);
        var writeFilename = writerOptions.textureUriFunction(outputFilename);

        writer.data(writerOptions.textureFunction(filename, texture));

        var content:Bytes = null;

        var hasHeader = !assetIsNull;
        var headerSize = 0;

        var linkedAsset = LinkedAsset.create();

        var linkedAssetId = dependency.registerDependencyLinkedAsset(linkedAsset);

        writer.linkedAsset(linkedAsset, linkedAssetId);

        if (!assetIsNull && writerOptions.embedMode & WriterOptions.EmbedMode.Texture) {
            content = writer.embedAll(assetLibrary, options, writerOptions, dependency);

            headerSize = content.length;

            linkedAsset.linkType = (LinkedAsset.LinkType.Internal);
        }
        else {
            hasHeader = false;

            linkedAsset.filename = (outputFilename);
            linkedAsset.linkType = (LinkedAsset.LinkType.External);

            var headerData = new BytesOutput();

            if (!assetIsNull) {
                writer.write(writeFilename, assetLibrary, options, writerOptions, dependency, null, headerData);

                headerSize = headerData.length;
            }

            if (hasHeader) {
                linkedAsset.offset = (headerSize);

                content = headerData.getBytes();
            }
            else {
                var contentStream = new BytesOutput();

                contentStream.writeInt16(linkedAssetId);

                content = contentStream.getBytes();
            }
        }

        var metadata = (hasHeader ? 1 << 31 : 0) + ((headerSize & 0x0fff) << 16) + assetType;

        return new SerializedAsset(metadata, dependencyId, content);
    }


    //AssetLibrary -> Options -> String -> Bytes -> Dependency -> Int -> Array<Job> -> Void;
    public function deserializeStreamedTexture(  assetLibrary:AssetLibrary, options:Options, assetCompletePath:String, data:Bytes, dependencies:Dependency, assetRef:Int, jobList:Array<Job>) {
        var hasHeader = false;
        var streamedAssetHeaderSize = 0;
        var streamedAssetHeaderData = new BytesInput();
        var linkedAsset:LinkedAsset = null;

        if (!getStreamedAssetHeader(metaData, data, assetCompletePath, dependencies, options, !_streamingOptions.createStreamedTextureOnTheFly, streamedAssetHeaderData, hasHeader, streamedAssetHeaderSize, linkedAsset)) {
            if (linkedAsset != null && _streamingOptions.streamedTextureFunction) {
                var filename = linkedAsset.filename;

                var texture:Texture = cast(_streamingOptions.streamedTextureFunction(filename, null));

                if (texture != null) {
                    dependencies.registerReferenceTexture(assetRef, texture);

                    assetLibrary.texture(filename, texture);
                }
            }

            return;
        }

        var filename = "";

        if (linkedAsset != null) {
            filename = File.removePrefixPathFromFilename(linkedAsset.filename);

            var existingTexture = assetLibrary.texture(filename);

            if (existingTexture) {
                dependencies.registerReferenceTexture(assetRef, existingTexture);

                return;
            }
        }
        else {


            var defaultNamePrefix:String = "@minko_default";

            var uniqueFilename = "";

            do {
                uniqueFilename = (defaultNamePrefix + "_" + (deserializeStreamedTexture_textureId++) + ".texture");

            } while (assetLibrary.texture(uniqueFilename));

            filename = uniqueFilename;
        }

        var texture:AbstractTexture = null;

        var parser:StreamedTextureParser = StreamedTextureParser.create();
        parser.dependency = (dependencies);
        parser.streamingOptions = (_streamingOptions);

        if (linkedAsset != null) {
            parser.linkedAsset = (linkedAsset);
        }

        var textureData = Provider.create();

        parser.data = (textureData);

        if (!hasHeader && _streamingOptions.createStreamedTextureOnTheFly) {
            parser.deferParsing = (assetRef);
        }

        parser.parse(filename, filename, options, streamedAssetHeaderData, assetLibrary);

        texture = assetLibrary.texture(filename);
        dependencies.registerReferenceTexture(assetRef, texture);

        if (texture) {
            // texture is created upong parsing

            _streamingOptions.masterLodScheduler.registerTexture(texture, textureData);
        }
        else {
            // texture parsing is deferred

            _streamingOptions.masterLodScheduler.registerDeferredTexture(textureData);
        }

        registerStreamedTextureParser(parser, texture);

        var parserScheduler:StreamedAssetParserScheduler = this.parserScheduler(options, jobList);

        parserScheduler.addParser(parser);
    }

    public function registerPOPGeometryParser(parser:POPGeometryParser, geometry:Geometry) {
        registerParser(parser);
    }

    public function registerStreamedTextureParser(parser:StreamedTextureParser, texture:AbstractTexture) {
        registerParser(parser);
    }

    public function registerParser(parser:AbstractStreamedAssetParser) {
        var parserEntryIt = new ParserEntry() ;
        _parsers.set(parser, parserEntryIt);

        var parserEntry = parserEntryIt ;

        parserEntry.completeSlots.push(parser.complete.connect(function(parserThis:AbstractParser) {
            _parsers.remove(parserThis);

            if (Lambda.count(_parsers)==0) {
                sceneStreamingComplete.execute((this));
            }
        }));

        parserEntry.progressSlot = parser.progress.connect(function(parserThis:AbstractStreamedAssetParser, progressRate:Float) {
            var parserEntry = _parsers.get(parserThis);

            var previousProgressRate = parserEntry.progressRate;

            parserEntry.progressRate = progressRate;

            _totalProgressRate += (progressRate - previousProgressRate) / Lambda.count(_parsers);
        });

        return parserEntry;
    }

    public function getStreamedAssetHeader(metadata:Int, data:Bytes, filename:String, dependency:Dependency, options:Options, requireHeader:Bool, streamedAssetHeaderData:Bytes, hasHeader:Bool, streamedAssetHeaderSize:Int, linkedAsset:LinkedAsset) {
        hasHeader = (((metadata & 0xf000) >> 15) == 1 ? true : false);
        streamedAssetHeaderSize = (metadata & 0x0fff);

        if (hasHeader) {
            streamedAssetHeaderData = data;

            return true;
        }

        var dataStream = new BytesInput(data);

        var linkedAssetId = dataStream.readInt32();

        linkedAsset = dependency.getLinkedAssetReference(linkedAssetId);

        if (options.preventLoadingFunction(linkedAsset.filename)) {
            return false;
        }

        if (!requireHeader) {
            return true;
        }

        var assetHeaderSize = StreamingCommon.MINKO_SCENE_HEADER_SIZE + 2;

        var linkedAssetResolutionSuccessful = true;

        var linkedAssetErrorSlot = linkedAsset.error.connect(function(linkedAssetThis:LinkedAsset, error) {
            linkedAssetResolutionSuccessful = false;
        });

        {
            var headerOptions = options.clone();
            options.loadAsynchronously = (false);
            options.seekingOffset = (0);
            options.seekedLength = (assetHeaderSize);
            options.storeDataIfNotParsed = (false);
            options.parserFunction = (function(UnnamedParameter1) {
                return null;
            });

            var linkedAssetCompleteSlot = linkedAsset.complete.connect(function(linkedAssetThis:LinkedAsset, linkedAssetData:Bytes) {
                linkedAsset.filename = (linkedAsset.lastResolvedFilename);

                var streamedAssetHeaderSizeOffset = assetHeaderSize - 2;

                streamedAssetHeaderSize = assetHeaderSize + (linkedAssetData[streamedAssetHeaderSizeOffset] << 8) + linkedAssetData[streamedAssetHeaderSizeOffset + 1];
            });

            linkedAsset.resolve(headerOptions);
        }

        if (!linkedAssetResolutionSuccessful) {
            return false;
        }

        {

            var headerOptions = options.clone();
            headerOptions.loadAsynchronously = (false);
            headerOptions.seekingOffset = (0);
            headerOptions.seekedLength = (streamedAssetHeaderSize);
            headerOptions.storeDataIfNotParsed = (false);
            headerOptions.parserFunction = (function(UnnamedParameter1) {
                return null;
            });

            var linkedAssetCompleteSlot = linkedAsset.complete.connect(function(linkedAssetThis:LinkedAsset, linkedAssetData:Bytes) {
                streamedAssetHeaderData = linkedAssetData;
            });

            linkedAsset.resolve(headerOptions);
        }

        if (!linkedAssetResolutionSuccessful) {
            return false;
        }

        linkedAsset.offset = (linkedAsset.offset() + streamedAssetHeaderSize + 2);

        return true;
    }

}
