package minko.file;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.deserialize.TypeDeserializer;
import minko.file.Dependency.TextureReference;
import minko.material.Material;
import minko.render.Blending.Mode;
import minko.render.Priority;
import minko.render.SamplerStates;
import minko.render.States;
import minko.render.Texture;
import minko.serialize.Types.MinkoTypes;
typedef ComplexPropertyValue = Tuple<Int, BytesInput> ;
typedef BasicProperty = Tuple<String, BytesInput>;
typedef ComplexProperty = Tuple<String, ComplexPropertyValue>;
typedef SerializedMaterial = Tuple<Array<ComplexProperty>, Array<BasicProperty>> ;
class MaterialParser extends AbstractSerializerParser {

    private static var _typeIdToReadFunction:IntMap<ComplexPropertyValue -> Any> = new IntMap<ComplexPropertyValue -> Any>();

    public static function create() {
        return new MaterialParser();
    }

    public function new() {

        _typeIdToReadFunction.set(MinkoTypes.VECTOR4, TypeDeserializer.deserializeVector4);
        _typeIdToReadFunction.set(MinkoTypes.MATRIX4X4, TypeDeserializer.deserializeMatrix4x4);
        _typeIdToReadFunction.set(MinkoTypes.VECTOR3, TypeDeserializer.deserializeVector3);
        _typeIdToReadFunction.set(MinkoTypes.VECTOR2, TypeDeserializer.deserializeVector2);
        _typeIdToReadFunction.set(MinkoTypes.BLENDING, TypeDeserializer.deserializeBlending);
        _typeIdToReadFunction.set(MinkoTypes.TRIANGLECULLING, TypeDeserializer.deserializeTriangleCulling);
        _typeIdToReadFunction.set(MinkoTypes.STRING, TypeDeserializer.deserializeString);
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, __data:Bytes, assetLibrary:AssetLibrary) {
        var data = new BytesInput(__data);
        if (!readHeader(filename, data, 0x4D)) {
            return;
        }

        var folderPath = extractFolderPath(resolvedFilename);
        var serializedMaterial:SerializedMaterial = new SerializedMaterial();

        extractDependencies(assetLibrary, data, _headerSize, _dependencySize, options, folderPath);

        unpack(serializedMaterial, data, _sceneDataSize, _headerSize + _dependencySize);

        var complexProperties:Array<ComplexProperty> = serializedMaterial.first;
        var basicProperties:Array<BasicProperty> = serializedMaterial.second;

        var material:Material = options.material != null ? Material.create(options.material) : Material.create();

        for (serializedComplexProperty in complexProperties) {
            deserializeComplexProperty(material, serializedComplexProperty);
        }

        for (serializedBasicProperty in basicProperties) {
            deserializeBasicProperty(material, serializedBasicProperty);
        }

        material = options.materialFunction(material.name, material);

        var uniqueName = material.name;
        var parse_nameId = 0;
        while (assetLibrary.material(uniqueName) != null) {
            uniqueName = "material" + (parse_nameId++);
        }

        assetLibrary.material(uniqueName, material);
        _lastParsedAssetName = uniqueName;
    }

    public function deserializeComplexProperty(material:Material, serializedProperty:ComplexProperty) {
        var type = serializedProperty.second.first >> 24;

        var serializedPropertyTuple = serializedProperty.second;

        if (type == MinkoTypes.VECTOR4) {
            material.data.set(serializedProperty.first, (TypeDeserializer.deserializeVector4(serializedPropertyTuple)));
        }
        else if (type == MinkoTypes.MATRIX4X4) {
            material.data.set(serializedProperty.first, (TypeDeserializer.deserializeMatrix4x4(serializedPropertyTuple)));
        }
        else if (type == MinkoTypes.VECTOR2) {
            material.data.set(serializedProperty.first, (TypeDeserializer.deserializeVector2(serializedPropertyTuple)));
        }
        else if (type == MinkoTypes.VECTOR3) {
            material.data.set(serializedProperty.first, (TypeDeserializer.deserializeVector3(serializedPropertyTuple)));
        }
        else if (type == MinkoTypes.BLENDING) {
            var blendingMode:Mode = (TypeDeserializer.deserializeBlending(serializedPropertyTuple));
            var srcBlendingMode:Source = ( blendingMode & 0x00ff);
            var dstBlendingMode:Destination = ( blendingMode & 0xff00);

            material.data.set("blendingMode", blendingMode);
            material.data.set(States.PROPERTY_BLENDING_SOURCE, srcBlendingMode);
            material.data.set(States.PROPERTY_BLENDING_DESTINATION, dstBlendingMode);

            if ((blendingMode & Destination.ZERO) == 0) {
                material.data.set("priority", Priority.TRANSPARENT);
                material.data.set("zSorted", true);
            }
        }
        else if (type == MinkoTypes.TRIANGLECULLING) {
            material.data.set(serializedProperty.first, (TypeDeserializer.deserializeTriangleCulling(serializedPropertyTuple)));
        }
        else if (type == MinkoTypes.TEXTURE) {
            var textureDependencyId = (TypeDeserializer.deserializeTextureId(serializedPropertyTuple));

            if (_dependency.textureReferenceExists(textureDependencyId)) {
                var textureType = serializedProperty.first;

                var textureReference:TextureReference = _dependency.getTextureReference(textureDependencyId);

                if (textureReference.texture) {
                    var texture:Texture = _dependency.getTextureReference(textureDependencyId).texture;
                    var sampler = texture.sampler;

                    material.data.set(serializedProperty.first, texture);

                    material.data.set(SamplerStates.uniformNameToSamplerStateBindingName(textureType, SamplerStates.PROPERTY_WRAP_MODE), sampler.wrapMode);

                    material.data.set(SamplerStates.uniformNameToSamplerStateBindingName(textureType, SamplerStates.PROPERTY_TEXTURE_FILTER), sampler.textureFilter);

                    material.data.set(SamplerStates.uniformNameToSamplerStateBindingName(textureType, SamplerStates.PROPERTY_MIP_FILTER), sampler.mipFilter);
                }
                else {
                    textureReference.textureType = textureType;
                    textureReference.dependentMaterialDataSet.push(material.data);
                }
            }
        }
        else if (type == MinkoTypes.STRING) {
            var name = (TypeDeserializer.deserializeString(serializedPropertyTuple));

            material.data.set(serializedProperty.first, name);
        }
    }

    public function deserializeBasicProperty(material:Material, serializedProperty:BasicProperty) {
        var serializedPropertyValue = TypeDeserializer.deserializeVectorFloat(serializedProperty.second);

        // TODO remove basic and complex property types and always specify property content type

        if (serializedProperty.first == "zSorted") {
            material.data.set("zSorted", serializedPropertyValue[0]);
        }
        else if (serializedProperty.first == "environmentMap2dType") {
            material.data.set("environmentMap2dType", Math.floor(serializedPropertyValue[0]));
        }
        else {
            material.data.set(serializedProperty.first, serializedPropertyValue[0]);
        }
    }

}
