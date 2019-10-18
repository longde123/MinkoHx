package minko.file;
import minko.serialize.Types.MinkoTypes;
import minko.file.AbstractStream.MaterialStream;
import minko.file.AbstractStream.BasicProperty;
import minko.file.AbstractStream.ComplexProperty;
import minko.render.TextureSampler;
import glm.Mat4;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import minko.material.Material;
import minko.render.Blending.Mode;
import minko.render.TriangleCulling;
import minko.StreamingCommon;


class MaterialWriter extends AbstractWriter {

    private var _typeToWriteFunction:ObjectMap<Class<Any>, MinkoTypes>;

    public static function create() {
        return new MaterialWriter();
    }

    private function serializeMaterialValue(typeid:Class<Any>, material:Material, propertyName:String, assets:AssetLibrary, complexSerializedProperties:Array<ComplexProperty>, basicTypeSeriliazedProperties:Array<BasicProperty>, dependency:Dependency) {
        if (_typeToWriteFunction.exists(typeid) && _typeToWriteFunction.exists(typeid) == MinkoTypes.TEXTURE && material.data.propertyHasType(propertyName)) {
            var sampler:TextureSampler = cast material.data.get(propertyName);
            var serializedTexture:Int = dependency.registerDependencyMaterial(assets.getTextureByUuid(sampler.uuid, false), propertyName) ;
            var serializedProperty = new ComplexProperty(propertyName, serializedTexture);
            serializedProperty.type = MinkoTypes.TEXTURE;
            complexSerializedProperties.push(serializedProperty);
            return true;
        }
        if (_typeToWriteFunction.exists(typeid) && material.data.propertyHasType(propertyName)) {
            var propertyValue = material.data.get(propertyName);
            var serializedProperty = new ComplexProperty(propertyName, propertyValue);
            serializedProperty.type = _typeToWriteFunction.get(typeid);
            complexSerializedProperties.push(serializedProperty);
            return true;
        }
        return false;
    }

    private function serializeMaterialValueFloats(material:Material, propertyName:String, assets:AssetLibrary, complexSerializedProperties:Array<ComplexProperty>, basicTypeSeriliazedProperties:Array<BasicProperty>, dependency:Dependency) {
        if (material.data.propertyHasType(propertyName)) {
            //check
            var propertyValue:Any = cast(material.data.get(propertyName));
            var basicTypeSerializedProperty = new BasicProperty(propertyName, propertyValue);
            basicTypeSeriliazedProperties.push(basicTypeSerializedProperty);
            return true;
        }

        return false;
    }

    public function new() {
        super();
        _typeToWriteFunction = new ObjectMap<Class<Any>, MinkoTypes>();

        _magicNumber = 0x0000004D | StreamingCommon.MINKO_SCENE_MAGIC_NUMBER;

        _typeToWriteFunction.set(Mat4, MinkoTypes.MATRIX4X4);
        _typeToWriteFunction.set(Vec2, MinkoTypes.VECTOR2);
        _typeToWriteFunction.set(Vec3, MinkoTypes.VECTOR3);
        _typeToWriteFunction.set(Vec4, MinkoTypes.VECTOR4);
        _typeToWriteFunction.set(Mode, MinkoTypes.BLENDING);
        _typeToWriteFunction.set(TriangleCulling, MinkoTypes.TRIANGLECULLING);
        _typeToWriteFunction.set(String, MinkoTypes.STRING);
        _typeToWriteFunction.set(TextureSampler, MinkoTypes.TEXTURE);
    }

    override public function embed(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency):AbstractStream {

        var material:Material = cast(data);
        var stream:MaterialStream = new MaterialStream();
        var serializedComplexProperties:Array<ComplexProperty> = stream.serializedComplexProperties;
        var serializedBasicProperties:Array<BasicProperty> = stream.serializedBasicProperties;

        for (propertyName in material.data.values.keys()) {
            var value = material.data.values.get(propertyName);
            if (serializeMaterialValue(Type.getClass(value), material, propertyName, assetLibrary, serializedComplexProperties, serializedBasicProperties, dependency)) {
                continue;
            }
            else if (serializeMaterialValueFloats(material, propertyName, assetLibrary, serializedComplexProperties, serializedBasicProperties, dependency)) {
                continue;
            }
            else {
                trace(propertyName << " can't be serialized : missing technique");
            }
        }


        return stream ;
    }

}
