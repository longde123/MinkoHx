package minko.file;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import minko.data.Provider;
import minko.file.LinkedAsset.LinkType;
import minko.file.WriterOptions.EmbedMode;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.render.AbstractTexture;
import minko.render.Effect;
import minko.scene.Node;
import minko.serialize.Types.AssetType;
import minko.Tuple.Tuple3;
using minko.utils.BytesTool;
class TextureDependency {
    public var dependencyId:Int;
    public var texture:AbstractTexture ;
    public var textureType:String;

    public function new():Void {

        this.dependencyId = 0 ;
    }
}

class TextureReference {
    public var texture:AbstractTexture ;
    public var textureType:String;
    public var dependentMaterialDataSet:Array<Provider>;

    public function new():Void {
        this.dependentMaterialDataSet = [];
    }
}
typedef GeometryWriterFunction = Dependency -> AssetLibrary -> Geometry -> Int -> Options -> WriterOptions -> Bytes -> SerializedAsset;
typedef TextureWriterFunction = Dependency -> AssetLibrary -> TextureDependency -> Options -> WriterOptions -> SerializedAsset;
typedef MaterialWriterFunction = material.Material -> Int -> Options -> WriterOptions -> SerializedAsset;
typedef GeometryTestFunc = Geometry -> Bool;

class Dependency {


    private var _textureDependencies:ObjectMap<AbstractTexture, TextureDependency> ;
    private var _materialDependencies:ObjectMap<Material, Int>;
    private var _subSceneDependencies:ObjectMap<Node, Int>;
    private var _geometryDependencies:ObjectMap<Geometry, Int>;
    private var _effectDependencies:ObjectMap<Effect, Int>;
    private var _linkedAssetDependencies:ObjectMap<LinkedAsset, Int>;

    private var _textureReferences:IntMap< TextureReference>;
    private var _materialReferences:IntMap< Material>;
    private var _subSceneReferences:IntMap< Node>;
    private var _geometryReferences:IntMap< Geometry>;
    private var _effectReferences:IntMap< Effect>;
    private var _linkedAssetReferences:IntMap<LinkedAsset>;

    private var _currentId:Int;
    private var _options:Options;
    private var _loadedRoot:Node;

    private static var _geometryWriteFunctions:IntMap<GeometryWriterFunction> = new IntMap<GeometryWriterFunction>();
    private static var _geometryTestFunctions:IntMap<GeometryTestFunc> = new IntMap<GeometryTestFunc>();

    private static var _textureWriteFunction:TextureWriterFunction;
    private static var _materialWriteFunction:MaterialWriterFunction;

    public static function create() {
        return new Dependency();
    }
    public var loadedRoot(get, set):Node;

    function get_loadedRoot() {
        return _loadedRoot;
    }

    function set_loadedRoot(value) {
        _loadedRoot = value;
        return value;
    }
    public var options(get, set):Options;

    function get_options() {
        return _options;
    }

    function set_options(value) {

        _options = value;
        return value;
    }

    public static function setMaterialFunction(materialFunc:MaterialWriterFunction) {
        _materialWriteFunction = materialFunc;
    }

    public static function setTextureFunction(textureFunc:TextureWriterFunction) {
        _textureWriteFunction = textureFunc;
    }

    public static function setGeometryFunction(geometryFunc:GeometryWriterFunction, testFunc:GeometryTestFunc, priority:Int) {
        _geometryTestFunctions.set(priority, testFunc);
        _geometryWriteFunctions.set(priority, geometryFunc);
    }

    public function new() {

        _currentId = 1;


        setGeometryFunction(Dependency.serializeGeometry, function(geometry) {
            return true;
        }, 0);

        if (_textureWriteFunction == null) {
            _textureWriteFunction = Dependency.serializeTexture ;
        }

        if (_materialWriteFunction == null) {
            _materialWriteFunction = Dependency.serializeMaterial;
        }
    }

    public function hasDependencyEffect(effect:Effect) {
        return _effectDependencies.exists(effect) ;
    }

    public function registerDependencyEffect(effect:Effect) {
        if (!hasDependencyEffect(effect)) {
            _effectDependencies.set(effect, _currentId++);
        }

        return _effectDependencies.get(effect);
    }

    public function hasDependencyGeometry(geometry:Geometry) {
        return _geometryDependencies.exists(geometry) ;
    }

    public function registerDependencyGeometry(geometry:Geometry) {
        if (!hasDependencyGeometry(geometry)) {
            _geometryDependencies.set(geometry, _currentId++);
        }

        return _geometryDependencies.get(geometry);
    }

    public function hasDependencyMaterial(material:Material) {
        return _materialDependencies.exists(material) ;
    }

    public function registerDependencyMaterial(material:Material) {
        if (!hasDependencyMaterial(material)) {
            _materialDependencies.set(material, _currentId++);
        }

        return _materialDependencies.get(material);
    }

    public function hasDependencyTexture(texture:AbstractTexture) {
        return _textureDependencies.exists(texture) ;
    }

    public function registerDependencyTexture(texture:AbstractTexture, textureType:String) {


        if (!hasDependencyTexture(texture)) {
            var dependencyId = _currentId++;

            var textureDependency:TextureDependency = new TextureDependency();

            textureDependency.dependencyId = dependencyId;
            textureDependency.texture = texture;
            textureDependency.textureType = textureType;
            _textureDependencies.set(texture, textureDependency) ;
            return textureDependency.dependencyId;
        }
        var dependencyIt = _textureDependencies.get(texture);
        return dependencyIt.dependencyId;
    }

    public function hasDependencyNode(subScene:Node) {
        return _subSceneDependencies.exists(subScene) ;
    }

    public function registerDependencyNode(subScene:Node) {
        if (!hasDependencyNode(subScene)) {
            _subSceneDependencies[subScene] = _currentId++;
        }

        return _subSceneDependencies[subScene];
    }

    public function hasDependencyLinkedAsset(linkedAsset:LinkedAsset) {
        return _linkedAssetDependencies.exists(linkedAsset) ;
    }

    public function registerDependencyLinkedAsset(linkedAsset:LinkedAsset) {
        if (!hasDependencyLinkedAsset(linkedAsset)) {
            _linkedAssetDependencies.set(linkedAsset, _currentId++);
        }

        return _linkedAssetDependencies.get(linkedAsset);
    }

    public function getGeometryReference(geometryId) {
        return _geometryReferences.get(geometryId);
    }

    public function registerReferenceGeometry(referenceId, geometry:Geometry) {
        _geometryReferences.set(referenceId, geometry);
    }

    public function getMaterialReference(materialId) {
        return _materialReferences.get(materialId);
    }

    public function registerReferenceMaterial(referenceId, material:Material) {
        _materialReferences.set(referenceId, material);
    }

    public function getTextureReference(textureId):TextureReference {
        return _textureReferences.get(textureId);
    }

    public function registerReferenceTexture(referenceId, texture:AbstractTexture) {
        var textureReference = new TextureReference();
        _textureReferences.set(referenceId, textureReference);
        textureReference.texture = texture;
    }

    public function getSubsceneReference(subSceneId) {
        return _subSceneReferences.get(subSceneId);
    }

    public function registerReferenceNode(referenceId, subScene:Node) {
        _subSceneReferences.set(referenceId, subScene);
    }

    public function registerReferenceEffect(referenceId, effect:Effect) {
        _effectReferences.set(referenceId, effect);
    }

    public function registerReferenceLinkedAsset(referenceId, linkedAsset:LinkedAsset) {
        _linkedAssetReferences.set(referenceId, linkedAsset);
    }

    public function getEffectReference(effectId) {
        return _effectReferences.get(effectId);
    }

    public function getLinkedAssetReference(referenceId) {
        return _linkedAssetReferences.get(referenceId);
    }

    public function geometryReferenceExists(referenceId) {
        return _geometryReferences.exists(referenceId) ;
    }

    public function textureReferenceExists(referenceId) {
        return _textureReferences.exists(referenceId) ;
    }

    public function materialReferenceExists(referenceId) {
        return _materialReferences.exists(referenceId) ;
    }

    public function effectReferenceExists(referenceId) {
        return _effectReferences.exists(referenceId) ;
    }

    public function linkedAssetReferenceExists(referenceId) {
        return _linkedAssetReferences.exists(referenceId) ;
    }

    public function serializeGeometry(dependency:Dependency, assetLibrary:AssetLibrary, geometry:Geometry, resourceId:Int, options:Options, writerOptions:WriterOptions, userDefinedDependency:Array<SerializedAsset>) {
        var geometryWriter:GeometryWriter = GeometryWriter.create();
        var assetType:AssetType;
        var content:String = "";

        var filename = assetLibrary.geometryName(geometry);

        var outputFilename = writerOptions.geometryNameFunction(filename);
        var writeFilename = writerOptions.geometryUriFunction(outputFilename);

        var targetGeometry:Geometry = writerOptions.geometryFunction(filename, geometry);

        var assetIsNull = writerOptions.assetIsNull(targetGeometry.uuid);

        geometryWriter.data = (writerOptions.geometryFunction(filename, targetGeometry));

        if (!assetIsNull && writerOptions.embedMode & EmbedMode.Geometry) {
            assetType = AssetType.EMBED_GEOMETRY_ASSET;

            content = geometryWriter.embedAll(assetLibrary, options, writerOptions, dependency, userDefinedDependency);
        }
        else {
            assetType = AssetType.GEOMETRY_ASSET;

            if (!assetIsNull) {
                var embeddedHeaderData = new Array<Bytes>();
                geometryWriter.write(writeFilename, assetLibrary, options, writerOptions, dependency, userDefinedDependency, embeddedHeaderData);
            }

            content = outputFilename;
        }

        var res = new SerializedAsset(assetType, resourceId, content);

        return res;
    }

    public function serializeTexture(dependency:Dependency, assetLibrary:AssetLibrary, textureDependency:TextureDependency, options:Options, writerOptions:WriterOptions) {
        var writer:TextureWriter = TextureWriter.create();
        var dependencyId = textureDependency.dependencyId;
        var texture = textureDependency.texture;
        var filename = assetLibrary.textureName(texture);
        var assetType:AssetType = 0;
        var content = "";

        var outputFilename = writerOptions.textureNameFunction(filename);
        var writeFilename = writerOptions.textureUriFunction(outputFilename);

        var targetTexture:AbstractTexture = writerOptions.textureFunction(filename, texture);

        var assetIsNull = writerOptions.assetIsNull(targetTexture.uuid);

        var hasHeaderSize = !assetIsNull;

        writer.data = (writerOptions.textureFunction(filename, targetTexture));
        writer.textureType = (textureDependency.textureType);

        if (!assetIsNull && writerOptions.embedMode & EmbedMode.Texture) {
            assetType = AssetType.EMBED_TEXTURE_PACK_ASSET;

            content = writer.embedAll(assetLibrary, options, writerOptions, dependency);
        }
        else {
            hasHeaderSize = false;

            assetType = AssetType.TEXTURE_PACK_ASSET;

            if (!assetIsNull) {
                writer.write(writeFilename, assetLibrary, options, writerOptions, dependency);
            }

            content = outputFilename;
        }

        var headerSize = writer.headerSize;

        var metadata = (hasHeaderSize ? 1 << 31 : 0 ) + ((headerSize & 0x0fff) << 16) + assetType;

        var res:SerializedAsset = new SerializedAsset(metadata, dependencyId, content);

        return res;
    }

    public function serializeMaterial(dependency:Dependency, assetLibrary:AssetLibrary, material:Material, resourceId:Int, options:Options, writerOptions:WriterOptions) {
        var writer:MaterialWriter = MaterialWriter.create();
        var filename = assetLibrary.materialName(material);
        var assetType:AssetType = 0;
        var content = "";

        var outputFilename = writerOptions.materialNameFunction(filename);
        var writeFilename = writerOptions.materialUriFunction(outputFilename);

        var targetMaterial:Material = writerOptions.materialFunction(filename, material);

        var assetIsNull = writerOptions.assetIsNull(targetMaterial.uuid);

        writer.data = (writerOptions.materialFunction(filename, targetMaterial));

        if (!assetIsNull && writerOptions.embedMode & EmbedMode.Material) {
            assetType = AssetType.EMBED_MATERIAL_ASSET;
            content = writer.embedAll(assetLibrary, options, writerOptions, dependency);
        }
        else {
            assetType = AssetType.MATERIAL_ASSET;

            if (!assetIsNull) {
                writer.write(writeFilename, assetLibrary, options, writerOptions, dependency);
            }

            content = outputFilename;
        }

        var res:SerializedAsset = new SerializedAsset(assetType, resourceId, content);

        return res;
    }

    public function serializeEffect(dependency:Dependency, assetLibrary:AssetLibrary, effect:Effect, resourceId:Int, options:Options, writerOptions:WriterOptions) {
        var filename = assetLibrary.effectName(effect);
        var assetType:AssetType = 0 ;
        var content = "";

        assetType = AssetType.EFFECT_ASSET;
        content = File.removePrefixPathFromFilename(filename);

        var res:SerializedAsset = new SerializedAsset(assetType, resourceId, content);

        return res;
    }

    public function serialize(parentFilename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, internalLinkedAssets:Array<BytesOutput>) {
        var serializedAsset = new Array<SerializedAsset>();

        for (itGeometryKey in _geometryDependencies.keys()) {
            var maxPriority = 0;
            var itGeometry = _geometryDependencies.get(itGeometryKey);
            for (testGeomFuncKey in _geometryTestFunctions.keys()) {
                var testGeomFunc = _geometryTestFunctions.get(testGeomFuncKey);
                if (testGeomFunc(testGeomFuncKey) && maxPriority < testGeomFuncKey) {
                    maxPriority = testGeomFuncKey;
                }
            }

            var includeDependencies = new Array<SerializedAsset>();

            var res = _geometryWriteFunctions.get(maxPriority)(this, assetLibrary, itGeometryKey, itGeometry, options, writerOptions, includeDependencies);

            serializedAsset.push(res);
        }

        for (itMaterialKey in _materialDependencies.keys()) {
            var itMaterial = _materialDependencies.get(itMaterialKey);
            var res = _materialWriteFunction(this, assetLibrary, itMaterialKey, itMaterial, options, writerOptions);

            serializedAsset.push(res);
        }

        for (effectDependencyKey in _effectDependencies.keys()) {
            var effectDependency = _effectDependencies.get(effectDependencyKey);
            var result = serializeEffect(this, assetLibrary, effectDependencyKey, effectDependency, options, writerOptions);

            serializedAsset.push(result);
        }

        for (itTextureKey in _textureDependencies.keys()) {
            var itTexture = _textureDependencies.get(itTextureKey);
            var res = _textureWriteFunction(this, assetLibrary, itTexture, options, writerOptions);

            serializedAsset.push(res);
        }

        var internalLinkedAssetDataOffset = 0;

        for (internalLinkedAsset in internalLinkedAssets) {
            internalLinkedAssetDataOffset += internalLinkedAsset.length;
        }

        for (linkedAssetToIdPair in _linkedAssetDependencies.keys()) {
            var linkedAsset = linkedAssetToIdPair;
            var id = _linkedAssetDependencies.get(linkedAssetToIdPair);

            var linkedAssetData = new Tuple5<Int, Int, String, Bytes, LinkType>(linkedAsset.offset, linkedAsset.length, linkedAsset.filename, null, linkedAsset.linkType);

            switch (linkedAsset.linkType)
            {
                case LinkedAsset.LinkType.Copy:
                    linkedAssetData.four = linkedAsset.data;
                    break;

                case LinkedAsset.LinkType.Internal:
                    {
                        linkedAssetData.first = internalLinkedAssetDataOffset;

                        internalLinkedAssets.push(linkedAsset.data);

                        internalLinkedAssetDataOffset += 1;

                        break;
                    }

                case LinkedAsset.LinkType.External:
                    {
                        var validFilename = File.removePrefixPathFromFilename(linkedAssetData.thiree);

                        linkedAssetData.thiree = validFilename;

                        break;
                    }

                default:
                    break;
            }

            var linkedAssetSerializedData = new BytesOutput();
            //Int, Int, String, Bytes, LinkType
            linkedAssetSerializedData.writeInt32(linkedAssetData.first);
            linkedAssetSerializedData.writeInt32(linkedAssetData.second);
            linkedAssetSerializedData.writeUTF(linkedAssetData.thiree);
            linkedAssetSerializedData.writeBytes(linkedAssetData.four);
            linkedAssetSerializedData.writeInt8(linkedAssetData.five);

            var serializedLinkedAsset = new SerializedAsset(AssetType.LINKED_ASSET, id, linkedAssetSerializedData);

            serializedAsset.push(serializedLinkedAsset);
        }

        return serializedAsset;
    }

}
