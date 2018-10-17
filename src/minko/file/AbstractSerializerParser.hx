package minko.file;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.component.JobManager.Job;
import minko.file.LinkedAsset.LinkType;
import minko.render.AbstractTexture;
import minko.serialize.Types.AssetType;
import minko.StreamingCommon;
import minko.Tuple.Tuple5;
using minko.utils.BytesTool;
class SceneVersion {
    public var version:Int;
    public var major:Int;
    public var minor:Int;
    public var patch:Int;
}

typedef AssetDeserializeFunction = Int -> AssetLibrary -> Options -> String -> Bytes -> Dependency -> Int -> Array<Job> -> Void;

class AbstractSerializerParser extends AbstractParser {
    private var _dependency:Dependency;
    private var _geometryParser:GeometryParser;
    private var _materialParser:MaterialParser;
    private var _textureParser:TextureParser;

    private var _lastParsedAssetName:String;
    private var _jobList:Array<Job>;

    private var _magicNumber:Int;

    private var _fileSize:Int;
    private var _headerSize:Int;
    private var _dependencySize:Int;
    private var _sceneDataSize:Int;
    private var _linkAssetDataSize:Int;
    private var _version:SceneVersion;

    private var _filename:String;
    private var _resolvedFilename:String;


    public var dependency(null, set):Dependency;

    function set_dependency(dependency) {
        _dependency = dependency;
    }
    public var embedContentOffset(get, null):Int;

    function get_embedContentOffset() {
        return _headerSize;
    }

    public var embedContentLength(get, null):Int;

    function get_embedContentLength() {
        return _dependencySize + _sceneDataSize;
    }
    public var internalLinkedContentOffset(get, null):Int;

    function get_internalLinkedContentOffset() {
        return embedContentOffset + embedContentLength;
    }


    public function new() {
    }

    private var _assetTypeToFunction:IntMap<AssetDeserializeFunction>;

    public function registerAssetFunction(assetTypeId:Int, f:AssetDeserializeFunction) {
        _assetTypeToFunction.set(assetTypeId, f);
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        _filename = filename;
        _resolvedFilename = resolvedFilename;
    }

    public function extractDependencies(assetLibrary:AssetLibrary, data:BytesInput, dataOffset:Int, dependenciesSize:Int, options:Options, assetFilePath:String) {
        data.position = dataOffset;
        var nbDependencies = data.readInt32();
        for (index in 0...nbDependencies) {
            if (data.position > (dataOffset + dependenciesSize)) {
                _error.execute(this, ("DependencyParsingError" + "Error while parsing dependencies"));
                return;
            }

            var serializedAsset:SerializedAsset = new SerializedAsset();
            serializedAsset.first = data.readInt32();
            serializedAsset.second = data.readInt32();
            serializedAsset.thiree = data.readOneBytes();
            deserializeAsset(serializedAsset, assetLibrary, options, assetFilePath);
        }
    }

    private static function loadAssetData(resolvedFilename, options:Options, refout:Bytes) {
        var assetLoader = Loader.create();
        var assetLoaderOptions = options.clone();

        assetLoader.options = (assetLoaderOptions);

        assetLoaderOptions.loadAsynchronously = (false);
        assetLoaderOptions.storeDataIfNotParsed = (false);

        var fileSuccessfullyLoaded = true;

        var errorSlot = assetLoader.error.connect(function(UnnamedParameter1, error) {
            fileSuccessfullyLoaded = false;
        });

        var completeSlot = assetLoader.complete.connect(function(assetLoaderThis:Loader) {
            refout = assetLoaderThis.files.get(resolvedFilename).data;
        });

        assetLoader.queue(resolvedFilename).load();

        return fileSuccessfullyLoaded;
    }
    private var deserializeAsset_nameId = 0;
    private var deserializeAsset_textureId = 0;

    public function deserializeAsset(asset:SerializedAsset, assetLibrary:AssetLibrary, options:Options, assetFilePath:String) {
        if (asset.first == AssetType.GEOMETRY_ASSET
        || asset.first == AssetType.TEXTURE_ASSET
        || asset.first == AssetType.MATERIAL_ASSET
        || asset.first == AssetType.TEXTURE_PACK_ASSET
        || asset.first == AssetType.EFFECT_ASSET) {
            if (options.preventLoadingFunction(asset.thiree)) {
                return;
            }
        }

        var data:Bytes;
        var assetCompletePath = assetFilePath + "/";
        var resolvedPath = "";
        var metaData = (asset.first & 0xFFFF0000) >> 16;

        asset.first = asset.first & 0x000000FF;

        // Is this an external asset?
        if (asset.first < 10) {
            assetCompletePath += asset.thiree;
            resolvedPath = asset.thiree;
        }
//todo

//data.assign(asset.get<2>().begin(), asset.get<2>().end());

        if ((asset.first == AssetType.GEOMETRY_ASSET
        || asset.first == AssetType.EMBED_GEOMETRY_ASSET)
        && !_dependency.geometryReferenceExists(asset.first)) {// geometry
            if (asset.first == AssetType.GEOMETRY_ASSET && !loadAssetData(assetCompletePath, options, data)) {
                _error.execute(this, ("MissingGeometryDependency" + assetCompletePath));

                return;
            }

            _geometryParser._jobList = [];
            _geometryParser.dependency = (_dependency);

            if (asset.first == AssetType.EMBED_GEOMETRY_ASSET) {
                resolvedPath = "geometry_" + asset.second;
            }

            _geometryParser.parse(resolvedPath, assetCompletePath, options, data, assetLibrary);
            _dependency.registerReferenceGeometry(asset.second, assetLibrary.geometry(_geometryParser._lastParsedAssetName));
            _jobList.splice(_jobList.length, _geometryParser._jobList);
        }
        else if ((asset.first == AssetType.MATERIAL_ASSET
        || asset.first == AssetType.EMBED_MATERIAL_ASSET) && !_dependency.materialReferenceExists(asset.second)) {
            // material
            if (asset.first == AssetType.MATERIAL_ASSET && !loadAssetData(assetCompletePath, options, data)) {
                _error.execute(this, "MissingMaterialDependency" + assetCompletePath);

                return;
            }

            _materialParser._jobList = [];
            _materialParser.dependency = (_dependency);

            if (asset.first == AssetType.EMBED_MATERIAL_ASSET) {
                resolvedPath = "material_" + asset.second;
            }

            _materialParser.parse(resolvedPath, assetCompletePath, options, data, assetLibrary);
            _dependency.registerReferenceMaterial(asset.second, assetLibrary.material(_materialParser._lastParsedAssetName));
            _jobList.splice(_jobList.length, _materialParser._jobList);
        }
        else if (asset.first == AssetType.EFFECT_ASSET) {
            var effectFilename = asset.second;
            var effectCompleteFilename = "effect/" + effectFilename;

            var effect = assetLibrary.effect(effectFilename);

            if (!effect) {
                var effectLoader = Loader.createbyOptions(options.clone());

                effectLoader.options.storeDataIfNotParsed = (false);

                var errorSlot = effectLoader.error.connect(function(loaderThis:Loader, error) {
                    trace(error + ": " + error);
                });
                var completeSlot = effectLoader.complete.connect(function(loaderThis:Loader) {
                    effect = assetLibrary.effect(effectCompleteFilename);
                });

                effectLoader.queue(effectCompleteFilename).load();
            }

            if (effect) {
                _dependency.registerReferenceEffect(asset.second, effect);
            }
        }
        else if ((asset.first == AssetType.EMBED_TEXTURE_ASSET
        || asset.first == AssetType.TEXTURE_ASSET) &&
        (!_dependency.textureReferenceExists(asset.second)
        || _dependency.getTextureReference(asset.second).texture == null)) {
            // texture
            if (asset.first == AssetType.EMBED_TEXTURE_ASSET) {
                var imageFormat:ImageFormat = metaData;

                var extension = Types.extensionFromImageFormat(imageFormat);

                resolvedPath = (asset.second) + "." + extension;
                assetCompletePath += resolvedPath;
            }
            else {
                if (!loadAssetData(assetCompletePath, options, data)) {
                    _error.execute(this, ("MissingTextureDependency" + assetCompletePath));

                    return;
                }
            }

            var extension = resolvedPath.substring(resolvedPath.lastIndexOf(".") + 1);

            var parser:AbstractParser = assetLibrary.loader.options.getParser(extension);


            var uniqueName = resolvedPath;

            while (assetLibrary.texture(uniqueName) != null) {
                uniqueName = "texture" + (deserializeAsset_nameId++);
            }

            parser.parse(uniqueName, assetCompletePath, options, data, assetLibrary);

            var texture = assetLibrary.texture(uniqueName);

            if (options.disposeTextureAfterLoading) {
                texture.disposeData();
            }

            _dependency.registerReferenceTexture(asset.second, texture);
        }
        else if (asset.first == AssetType.EMBED_TEXTURE_PACK_ASSET
        && (!_dependency.textureReferenceExists(asset.second) || _dependency.getTextureReference(asset.second).texture == null)) {
            var textureName = "texture_" + (asset.second);

            var uniqueTextureName = textureName;

            while (assetLibrary.texture(uniqueTextureName) != null) {
                //			static auto textureId = 0;

                uniqueTextureName = textureName + (deserializeAsset_textureId++);
            }

            var hasTextureHeaderSize = (((metaData & 0xf000) >> 15) == 1 ? true : false);
            var textureHeaderSize = (metaData & 0x0fff);

            _textureParser.textureHeaderSize(textureHeaderSize);
            _textureParser.dataEmbed(true);

            _textureParser.parse(uniqueTextureName, assetCompletePath, options, data, assetLibrary);

            var texture = assetLibrary.texture(uniqueTextureName);

            if (options.disposeTextureAfterLoading) {
                texture.disposeData();
            }

            _dependency.registerReferenceTexture(asset.second, texture);
        }
        else if (asset.first == AssetType.TEXTURE_PACK_ASSET) {
            deserializeTexture(metaData, assetLibrary, options, assetCompletePath, data, _dependency, asset.second, _jobList);
        }
        else if (asset.first == AssetType.EFFECT_ASSET && !_dependency.effectReferenceExists(asset.second)) {
            // effect

            assetLibrary.loader.queue(assetCompletePath);
            _dependency.registerReferenceEffect(asset.second, assetLibrary.effect(assetCompletePath));
        }
        else if (asset.first == AssetType.LINKED_ASSET) {

            var linkedAssetdata = new Tuple5<Int, Int, String, Bytes, LinkType>(0, 0, "", null, 0);

            var assetData:BytesInput = new BytesInput(asset.thiree);
            linkedAssetdata.first = assetData.readInt32();
            linkedAssetdata.second = assetData.readInt32();
            linkedAssetdata.thiree = assetData.readUTF();
            linkedAssetdata.four = assetData.readOneBytes();
            linkedAssetdata.five = assetData.readInt8();
            //linkedAsset.offset, linkedAsset.length, linkedAsset.filename, null, linkedAsset.linkType

            var linkedAssetOffset = linkedAssetdata.first;
            var linkedAssetFilename = linkedAssetdata.thiree;
            var linkedAssetAbsoluteFilename = linkedAssetFilename;

            if (linkedAssetFilename == "") {
                linkedAssetAbsoluteFilename = _resolvedFilename;
            }
            else {
                linkedAssetAbsoluteFilename = assetCompletePath + "/" + linkedAssetAbsoluteFilename;
            }

            var linkedAssetLinkType:LinkType = (linkedAssetdata.five);

            if (linkedAssetLinkType == LinkType.Internal) {
                linkedAssetOffset += internalLinkedContentOffset;

                if (linkedAssetFilename != "") {
                    linkedAssetAbsoluteFilename = assetCompletePath + File.removePrefixPathFromFilename(_resolvedFilename);
                }
            }

            var linkedAsset:LinkedAsset = LinkedAsset.create();
            linkedAsset.offset = (linkedAssetOffset);
            linkedAsset.length = (linkedAssetdata.second);
            linkedAsset.filename = (linkedAssetAbsoluteFilename);
            linkedAsset.data = (linkedAssetdata.four);
            linkedAsset.linkType = (linkedAssetLinkType);

            _dependency.registerReferenceLinkedAsset(asset.second, linkedAsset);
        }
        else {
            if (_assetTypeToFunction.exists(asset.first)) {
                _assetTypeToFunction.get(asset.first)(metaData, assetLibrary, options, assetCompletePath, data, _dependency, asset.second, _jobList);
            }
        }
    }

    public function extractFolderPath(filepath:String) {
        var found = filepath.lastIndexOf("/");
        if (found == -1) {
            filepath.lastIndexOf("\\");
        }

        return filepath.substring(0, found);
    }

    public function readHeader(filename, data:BytesInput, extension:Int) {
        _magicNumber = data.readInt32();

        // File should start with 0x4D4B03 (MK3). Last byte reserved for extensions (Material, Geometry...)
        if (_magicNumber != StreamingCommon.MINKO_SCENE_MAGIC_NUMBER + (extension & 0xFF)) {
            _error.execute(this, ("InvalidFile" + "Invalid scene file '" + filename + "': magic number mismatch"));
            return false;
        }


        _version.major = data[4];
        data.position = 4;
        _version.minor = data.readInt16();
        _version.patch = data[7];
        data.position = 3;

        _version.version = data.readInt32();

        if (_version.major != StreamingCommon.MINKO_SCENE_VERSION_MAJOR || _version.minor > StreamingCommon.MINKO_SCENE_VERSION_MINOR || (_version.minor == StreamingCommon.MINKO_SCENE_VERSION_MINOR && _version.patch > StreamingCommon.MINKO_SCENE_VERSION_PATCH)) {
            var fileVersion = (_version.major) + "." + (_version.minor) + "." + (_version.patch);
            var sceneVersion = (StreamingCommon.MINKO_SCENE_VERSION_MAJOR) + "." + (StreamingCommon.MINKO_SCENE_VERSION_MINOR) + "." + (StreamingCommon.MINKO_SCENE_VERSION_PATCH);

            var message = "File " + filename + " doesn't match serializer version (file has v" + fileVersion + " while current version is v" + sceneVersion + ")";

            trace(message) ;

            _error.execute(this, ("InvalidFile" + message));
            return false;
        }

        // Versions with the same MAJOR value but different MINOR or PATCH value should be compatible
        if (_version.minor != StreamingCommon.MINKO_SCENE_VERSION_MINOR || _version.patch != StreamingCommon.MINKO_SCENE_VERSION_PATCH) {
            var fileVersion = (_version.major) + "." + (_version.minor) + "." + (_version.patch);
            var sceneVersion = (StreamingCommon.MINKO_SCENE_VERSION_MAJOR) + "." + (StreamingCommon.MINKO_SCENE_VERSION_MINOR) + "." + (StreamingCommon.MINKO_SCENE_VERSION_PATCH);

            trace("Warning: file " + filename + " is v" + fileVersion + " while current version is v" + sceneVersion);
        }

        _fileSize = data.readInt32();
        _headerSize = data.readInt32();
        _dependencySize = data.readInt32();
        _sceneDataSize = data.readInt32();
        _linkAssetDataSize = data.readInt32();
        return true;
    }

    public function deserializeTexture(metaData:Int, assetLibrary:AssetLibrary, options:Options, assetCompletePath:String, data:Bytes, dependency:Dependency, assetId:Int, jobs:Array<Job >) {
        var existingTexture = assetLibrary.texture(assetCompletePath);

        if (existingTexture != null) {
            dependency.registerReferenceTexture(assetId, existingTexture);

            return;
        }

        var assetHeaderSize = StreamingCommon.MINKO_SCENE_HEADER_SIZE + 2 + 2;

        var hasTextureHeaderSize = (((metaData & 0xf000) >> 15) == 1 ? true : false);
        var textureHeaderSize = (metaData & 0x0fff);

        var textureOptions = options.clone();

        var textureExists = true;

        if (!hasTextureHeaderSize) {
            var textureHeaderLoader = Loader.create();
            var textureHeaderOptions:Options = textureOptions.clone();
            textureHeaderOptions.parserFunction = (function(extension) {
                return null;
            });

            textureHeaderOptions.loadAsynchronously = (false);
            textureHeaderOptions.seekingOffset = (0);
            textureHeaderOptions.seekedLength = (assetHeaderSize);
            textureHeaderOptions.storeDataIfNotParsed = (false);

            textureHeaderLoader.options = (textureHeaderOptions);

            var textureHeaderLoaderErrorSlot = textureHeaderLoader.error.connect(function(textureHeaderLoaderThis, error) {
                textureExists = false;

                this.error.execute(this, ("MissingTextureDependency" + assetCompletePath));
            });

            var textureHeaderLoaderCompleteSlot = textureHeaderLoader.complete.connect(function(textureHeaderLoaderThis:Loader) {
                var headerData = textureHeaderLoaderThis.files.get(assetCompletePath).data;

                var textureHeaderSizeOffset = assetHeaderSize - 2;

                var headerDataStream = new BytesInput( headerData.blit(textureHeaderSizeOffset, textureHeaderSizeOffset + 2));

                textureHeaderSize = headerDataStream.readInt16();
            });

            textureHeaderLoader.queue(assetCompletePath).load();
        }

        textureOptions.loadAsynchronously = (false);
        textureOptions.seekingOffset = (0);
        textureOptions.seekedLength = (assetHeaderSize + textureHeaderSize);
        textureOptions.parserFunction = (function(extension) {
            if (extension != "texture") {
                return null;
            }

            var textureParser:TextureParser = TextureParser.create();

            textureParser.textureHeaderSize = (textureHeaderSize);
            textureParser.dataEmbed = (false);

            return textureParser;
        });

        var textureLoader = Loader.create();
        textureLoader.options = (textureOptions);

        var texture:AbstractTexture = null;

        var textureLoaderErrorSlot = textureLoader.error.connect(function(textureLoaderThis, error) {
            textureExists = false;

            this.error.execute(this, ("MissingTextureDependency" + assetCompletePath));
        });

        var textureLoaderCompleteSlot = textureLoader.complete.connect(function(textureLoaderThis) {
            texture = assetLibrary.texture(assetCompletePath);
        });

        textureLoader.queue(assetCompletePath).load();

        if (!textureExists) {
            return;
        }

        if (textureOptions.disposeTextureAfterLoading) {
            texture.disposeData();
        }

        dependency.registerReferenceTexture(assetId, texture);
    }
}

