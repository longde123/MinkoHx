package minko.file;
import Array;
import glm.Mat4;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import haxe.io.BytesOutput;
import minko.material.Material;
import minko.render.Blending.Mode;
import minko.render.TriangleCulling;
import minko.serialize.TypeSerializer;
import minko.StreamingCommon;
typedef ComplexPropertyValue = Tuple<Int, BytesOutput> ;
typedef ComplexProperty = Tuple<String, ComplexPropertyValue> ;
typedef BasicProperty = Tuple<String, BytesOutput> ;
class MaterialWriter extends AbstractWriter<Material> {

    private var _typeToWriteFunction:ObjectMap<Class<Any>, Any -> ComplexPropertyValue>;

    public static function create() {
        return new MaterialWriter();
    }

    private function serializeMaterialValueTextureSampler(material:Material, propertyName:String, assets:AssetLibrary, complexSerializedProperties:Array<ComplexProperty>, basicTypeSeriliazedProperties:Array<BasicProperty>, dependency:Dependency) {
        if (material.data.propertyHasType(propertyName)) {
            var serializedTexture:Tuple<Int, BytesOutput> = TypeSerializer.serializeTexture(dependency.registerDependencyMaterial(assets.getTextureByUuid(material.data.get(propertyName).uuid, false), propertyName));
            var serializedProperty = new ComplexProperty(propertyName, serializedTexture);
            complexSerializedProperties.push(serializedProperty);

            return true;
        }

        return false;
    }


    private function serializeMaterialValue(typeid:Class<Any>, material:Material, propertyName:String, assets:AssetLibrary, complexSerializedProperties:Array<ComplexProperty>, basicTypeSeriliazedProperties:Array<BasicProperty>, dependency:Dependency) {
        if (_typeToWriteFunction.exists(typeid) && material.data.propertyHasType(propertyName)) {
            var propertyValue = material.data.get(propertyName);
            var serializedMaterialValue = _typeToWriteFunction.get(typeid)(propertyValue);
            var serializedProperty = new ComplexProperty(propertyName, serializedMaterialValue);
            complexSerializedProperties.push(serializedProperty);
            return true;
        }

        return false;
    }

    private function serializeMaterialValueFloats(material:Material, propertyName:String, assets:AssetLibrary, complexSerializedProperties:Array<ComplexProperty>, basicTypeSeriliazedProperties:Array<BasicProperty>, dependency:Dependency) {
        if (material.data.propertyHasType(propertyName)) {
            var propertyValue:Any = cast(material.data.get(propertyName));
            var propertyValues:Array<Any> = [];
            if (!Std.is(propertyValue, Array)) {
                propertyValues = [propertyValue]
            } else {
                propertyValues = cast propertyValue;
            }
            var serializePropertyValue = TypeSerializer.serializeVectorFloat(propertyValue);
            var basicTypeSerializedProperty = new BasicProperty(propertyName, serializePropertyValue);
            basicTypeSeriliazedProperties.push(basicTypeSerializedProperty);
            return true;
        }

        return false;
    }

    public function new() {
        super();
        _typeToWriteFunction = new ObjectMap<Class<Any>, Any -> Tuple<Int, BytesOutput>>();

        _magicNumber = 0x0000004D | StreamingCommon.MINKO_SCENE_MAGIC_NUMBER;

        _typeToWriteFunction.set(Mat4, TypeSerializer.serializeMatrix4x4);
        _typeToWriteFunction.set(Vec2, TypeSerializer.serializeVector2);
        _typeToWriteFunction.set(Vec3, TypeSerializer.serializeVector3);
        _typeToWriteFunction.set(Vec4, TypeSerializer.serializeVector4);
        _typeToWriteFunction.set(Mode, TypeSerializer.serializeBlending);
        _typeToWriteFunction.set(TriangleCulling, TypeSerializer.serializeCulling);
        _typeToWriteFunction.set(String, TypeSerializer.serializeString);
    }

    override public function embed(assetLibrary:AssetLibrary, options:Options, dependency:Dependency, writerOptions:WriterOptions, embeddedHeaderData:BytesOutput):BytesOutput {

        var material:Material = cast(data);
        var serializedComplexProperties = new Array<ComplexProperty>();
        var serializedBasicProperties = new Array<BasicProperty>();

        for (propertyName in material.data.values.keys()) {
            var value = material.data.values.get(propertyName);
            if (serializeMaterialValue(Type.getClass(value), material, propertyName, assetLibrary, serializedComplexProperties, serializedBasicProperties, dependency)) {
                continue;
            }
            else if (serializeMaterialValueTextureSampler(material, propertyName, assetLibrary, serializedComplexProperties, serializedBasicProperties, dependency)) {
                continue;
            }
            else if (serializeMaterialValueFloats(material, propertyName, assetLibrary, serializedComplexProperties, serializedBasicProperties, dependency)) {
                continue;
            }
            else {
                trace(propertyName << " can't be serialized : missing technique");
            }
        }


        //(serializedComplexProperties, serializedBasicProperties);

        var sbuf = new BytesOutput();

        return sbuf ;
    }

}
