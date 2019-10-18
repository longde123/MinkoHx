package minko.file;
import String;
import js.html.LinkElement;
import minko.serialize.Types;
import minko.serialize.Types.ImageFormat;
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

typedef AssetDeserializeFunction = AssetLibrary -> Options -> String -> Bytes -> Dependency -> Int -> Array<Job> -> Void;

class AbstractSerializerParser extends AbstractParser {
    private var _dependency:Dependency;
    private var _geometryParser:GeometryParser;
    private var _materialParser:MaterialParser;
    private var _textureParser:TextureParser;

    private var _lastParsedAssetName:String;
    private var _jobList:Array<Job>;

    private var _magicNumber:Int;

    private var _version:SceneVersion;

    private var _filename:String;
    private var _resolvedFilename:String;


    public var dependency(null, set):Dependency;

    function set_dependency(dependency) {
        _dependency = dependency;
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

    public function parseStream(filename:String, resolvedFilename:String, options:Options, data:AbstractStream, assetLibrary:AssetLibrary) {

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
            serializedAsset.assetType = data.readInt32();
            serializedAsset.resourceId = data.readInt32();
            serializedAsset.content = data.readOneBytes();
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
        if (asset.assetType == AssetType.GEOMETRY_ASSET
        || asset.assetType == AssetType.MATERIAL_ASSET
        || asset.assetType == AssetType.TEXTURE_PACK_ASSET
        || asset.assetType == AssetType.EFFECT_ASSET
            //  || asset.assetType == AssetType.TEXTURE_ASSET
        ) {
            if (options.preventLoadingFunction(asset.content)) {
                return;
            }
        }

        var data:Bytes=null;
        var assetCompletePath = assetFilePath + "/";
        var resolvedPath = "";


        // Is this an external asset?
        if (asset.assetType < 10) {
            var pathName:String = asset.content.toString() ;
            assetCompletePath += pathName ;
            resolvedPath = pathName;
        }
//todo

        if ((asset.assetType == AssetType.GEOMETRY_ASSET
        || asset.assetType == AssetType.EMBED_GEOMETRY_ASSET)
        && !_dependency.geometryReferenceExists(asset.assetType)) {// geometry
            if (asset.assetType == AssetType.GEOMETRY_ASSET && !loadAssetData(assetCompletePath, options, data)) {
                _error.execute(this, ("MissingGeometryDependency" + assetCompletePath));

                return;
            }
            _geometryParser._jobList = [];
            _geometryParser.dependency = (_dependency);
            if (asset.assetType == AssetType.EMBED_GEOMETRY_ASSET) {
                resolvedPath = "geometry_" + asset.resourceId;
            }
            _geometryParser.parse(resolvedPath, assetCompletePath, options, data, assetLibrary);
            _dependency.registerReferenceGeometry(asset.resourceId, assetLibrary.geometry(_geometryParser._lastParsedAssetName));
            _jobList.splice(_jobList.length, _geometryParser._jobList);
        }
        else if ((asset.assetType == AssetType.MATERIAL_ASSET
        || asset.assetType == AssetType.EMBED_MATERIAL_ASSET) && !_dependency.materialReferenceExists(asset.resourceId)) {
            // material
            if (asset.assetType == AssetType.MATERIAL_ASSET && !loadAssetData(assetCompletePath, options, data)) {
                _error.execute(this, "MissingMaterialDependency" + assetCompletePath);
                return;
            }
            _materialParser._jobList = [];
            _materialParser.dependency = (_dependency);
            if (asset.assetType == AssetType.EMBED_MATERIAL_ASSET) {
                resolvedPath = "material_" + asset.resourceId;
            }

            _materialParser.parse(resolvedPath, assetCompletePath, options, data, assetLibrary);
            _dependency.registerReferenceMaterial(asset.resourceId, assetLibrary.material(_materialParser._lastParsedAssetName));
            _jobList.splice(_jobList.length, _materialParser._jobList);
        }
        else if (asset.assetType == AssetType.EFFECT_ASSET) {

            var effectFilename = asset.resourceId;
            var effectCompleteFilename = "effect/" + effectFilename;
            var effect = assetLibrary.effect(effectFilename);
            if (effect == null) {
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

            if (effect != null) {
                _dependency.registerReferenceEffect(asset.resourceId, effect);
            }

        }
            /*
        else if ((asset.assetType == AssetType.EMBED_TEXTURE_ASSET
        || asset.assetType == AssetType.TEXTURE_ASSET) &&
        (!_dependency.textureReferenceExists(asset.resourceId)
        || _dependency.getTextureReference(asset.resourceId).texture == null)) {
            // texture
            if (asset.assetType == AssetType.EMBED_TEXTURE_ASSET) {
                var imageFormat:ImageFormat = metaData;
                var extension = Types.extensionFromImageFormat(imageFormat);
                resolvedPath = (asset.resourceId) + "." + extension;
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

            _dependency.registerReferenceTexture(asset.resourceId, texture);
        }*/
        else if (asset.assetType == AssetType.EMBED_TEXTURE_PACK_ASSET
        && (!_dependency.textureReferenceExists(asset.resourceId) || _dependency.getTextureReference(asset.resourceId).texture == null)) {
            var textureName = "texture_" + (asset.resourceId);
            var uniqueTextureName = textureName;
            while (assetLibrary.texture(uniqueTextureName) != null) {
                //			static auto textureId = 0;
                uniqueTextureName = textureName + (deserializeAsset_textureId++);
            }

            _textureParser.dataEmbed = (true);
            _textureParser.parse(uniqueTextureName, assetCompletePath, options, data, assetLibrary);
            var texture = assetLibrary.texture(uniqueTextureName);
            if (options.disposeTextureAfterLoading) {
                texture.disposeData();
            }
            _dependency.registerReferenceTexture(asset.resourceId, texture);
        }
        else if (asset.assetType == AssetType.TEXTURE_PACK_ASSET) {
            deserializeTexture(assetLibrary, options, assetCompletePath, data, _dependency, asset.resourceId, _jobList);
        }
        else if (asset.assetType == AssetType.EFFECT_ASSET && !_dependency.effectReferenceExists(asset.resourceId)) {
            assetLibrary.loader.queue(assetCompletePath);
            _dependency.registerReferenceEffect(asset.resourceId, assetLibrary.effect(assetCompletePath));
        }
        else if (asset.assetType == AssetType.LINKED_ASSET || asset.assetType == AssetType.EMBED_LINKED_ASSET) {
             var linkedAsset=deserializeLinkedAsset(assetCompletePath ,assetLibrary, options, asset.content, _dependency, asset.assetType, _jobList);
            _dependency.registerReferenceLinkedAsset(asset.resourceId, linkedAsset);
        }
        else {
            if (_assetTypeToFunction.exists(asset.assetType)) {

                if (  !loadAssetData(assetCompletePath, options, data)) {
                    _error.execute(this, ("MissingDependency" + assetCompletePath));
                    return;
                }
                _assetTypeToFunction.get(asset.assetType)(assetLibrary, options, assetCompletePath, data, _dependency, asset.assetType, _jobList);
            }
        }
    }

    public function deserializeLinkedAsset(assetCompletePath :String,assetLibrary:AssetLibrary, options:Options, data:Bytes, dependency:Dependency, assetType:Int, jobs:Array<Job >) {
        var linkedAsset:LinkedAsset = new LinkedAsset();
        switch (assetType)
        {
            case AssetType.EMBED_LINKED_ASSET:{
                linkedAsset.linkType=LinkType.Internal;
                linkedAsset.data = data;
                break;
            }

            case AssetType.LINKED_ASSET:
                {
                    var inBytes:BytesInput=new BytesInput(data);
                    linkedAsset.linkType=LinkType.External;
                    linkedAsset.offset=inBytes.readInt32();
                    linkedAsset.length=inBytes.readInt32();
                    linkedAsset.filename=inBytes.readUTF();


                    var linkedAssetFilename=     linkedAsset.filename;
                    var linkedAssetAbsoluteFilename="";
                    if (linkedAssetFilename != "") {
                        linkedAssetAbsoluteFilename = assetCompletePath + File.removePrefixPathFromFilename(_resolvedFilename);
                    }


                    //加载
                    break;
                }
            default:
                break;
        }

        return linkedAsset;
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


        return true;
    }

    public function deserializeTexture(assetLibrary:AssetLibrary, options:Options, assetCompletePath:String, data:Bytes, dependency:Dependency, assetId:Int, jobs:Array<Job >) {
        var existingTexture = assetLibrary.texture(assetCompletePath);

        if (existingTexture != null) {
            dependency.registerReferenceTexture(assetId, existingTexture);

            return;
        }


        var textureOptions = options.clone();

        var textureExists = true;


        textureOptions.loadAsynchronously = (false);

        textureOptions.parserFunction = (function(extension) {
            if (extension != "texture") {
                return null;
            }

            var textureParser:TextureParser = TextureParser.create();

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

