package minko.file;

//
import glm.Vec3;
import minko.serialize.Types.ComponentId;
import glm.Mat4;
import minko.serialize.Types.MinkoTypes;
import haxe.io.Bytes;
import minko.serialize.Types.ImageFormat;


class AbstractStream {
    public var type:ComponentId;

    public function AbstractStreamed() {
    }
}
class POPTextureHeader{
    public var width:Int;
    public var height:Int;
    public var numFaces:Int;
    public var numMipMaps:Int;
    public var linkedAssetId:Int;
}
class POPTextureLodHeader{
    public var mipLevelDatas:Array<Bytes>;
}
class POPTextureFormatHeader{
    public var textureFormat:Int;
    public var blobOffset:Int;
    public var blobSize:Int;

}
class POPTextureStream extends AbstractStream {
    public var header:POPTextureHeader;
    public var formatHeaders:Array<POPTextureFormatHeader>;
    public var lodDatas:Array<POPTextureLodHeader>;
}
class POPGeometryLODHeader {
    public var level:Int;
    public var precisionLevel:Int;
    public var indexCount:Int;
    public var vertexCount:Int;
    public var blobOffset:Int;
    public var blobSize:Int;
}
class POPGeometryHeader {
    public var linkedAssetId:Int;
    public var levelCount:Int;
    public var minLevel:Int;
    public var maxLevel:Int;
    public var fullPrecisionLevel:Int;
    public var bounds:Array<Float>;
    public var vertexAttributes:Array<Array<GeometryStreamVertexBufferAttributes>>;
    public var numVertexBuffers:Int;
    public var vertexSize:Int;
    public var isSharedPartition:Int;
    public var borderMinPrecision:Int;
    public var borderMaxDeltaPrecision:Int;
    public var lods:Array<POPGeometryLODHeader>;

}
class POPGeometryLOD {
    public var indices:GeometryStreamIndexBuffer;
    public var vertexBuffers:GeometryStreamVertexBufferData;
    public var vertexSizes:Array<Int>;

}
class POPGeometryStream extends AbstractStream {
    public var header:POPGeometryHeader;
    public var lodDatas:Array<POPGeometryLOD>;

}
typedef GeometryStreamIndexBuffer = Array<Int>;
typedef GeometryStreamVertexBufferData = Array<Float>;
class GeometryStreamVertexBuffer {
    public var data:GeometryStreamVertexBufferData;
    public var attributes:Array<GeometryStreamVertexBufferAttributes>;
}
class GeometryStreamVertexBufferAttributes {
    public var name:String;
    public var size:Int;
    public var offset:Int;
}


typedef GeometryStreamVertexBuffers = Array<GeometryStreamVertexBuffer>;
class GeometryStream extends AbstractStream {
    public var name:String;
    public var indexBufferFunctionId:Int;
    public var vertexBufferFunctionId:Int;
    public var metaData:Int;
    public var indices:GeometryStreamIndexBuffer;
    public var vertexBuffers:GeometryStreamVertexBuffers;

    public function new() {
        super();
    }
}

class SceneStream extends AbstractStream {
    public var nodePack:Array<SerializedNode>;
    public var serializedControllerList:Array<AbstractStream>;

    public function new() {

        super();
        nodePack = new Array<SerializedNode>();
        serializedControllerList = new Array<AbstractStream>();
    }
}
class PerspectiveCameraStream extends AbstractStream {
    public var aspectRatio:Float;
    public var fieldOfView:Float;
    public var zNear:Float;
    public var zFar:Float;

    public function new() {
        super();
        type = ComponentId.PROJECTION_CAMERA;
    }
}
class TransformStream extends AbstractStream {
    public var matrix:Mat4;

    public function new() {
        super();
        type=ComponentId.TRANSFORM;
    }
}
class ImageBasedLightStream extends AbstractStream {
    public var irradianceMap:Int;
    public var radianceMap:Int;
    public var diffuse:Float;
    public var specular:Float;
    public var orientation:Float;

    public function new() {
        super();
        type = ComponentId.IMAGE_BASED_LIGHT;
    }
}
class AmbientLightStream extends AbstractStream {
    public var ambient:Float;
    public var color:Vec3;

    public function new() {
        super();
        type = ComponentId.AMBIENT_LIGHT;
    }
}
class DirectionalLightStream extends AbstractStream {
    public var diffuse:Float;
    public var specular:Float;
    public var color:Vec3;

    public function new() {
        super();
        type = ComponentId.DIRECTIONAL_LIGHT
    }
}
class SpotLightStream extends AbstractStream {
    public var diffuse:Float;
    public var specular:Float;
    public var color:Vec3;
    public var attenuationCoefficients:Vec3;
    public var innerConeAngle:Float;
    public var outerConeAngle:Float;

    public function new() {
        super();
        type = ComponentId.SPOT_LIGHT;
    }
}
class PointLightStream extends AbstractStream {
    public var diffuse:Float;
    public var specular:Float;
    public var color:Vec3;
    public var attenuationCoefficients:Vec3;

    public function new() {
        super();
        type = ComponentId.POINT_LIGHT;
    }
}
class SurfaceStream extends AbstractStream {

    public var materialId:Int ;
    public var geometryId:Int ;
    public var effectId:Int ;
    public var extensions:Array<BasicProperty>;

    public function new() {
        super();
        type = ComponentId.SURFACE;
    }
}
class RendererStream extends AbstractStream {
    public var backgroundColor:Int;

    public function new() {
        super();
        type=ComponentId.RENDERER;
    }
}
class MasterAnimationStream extends AbstractStream {
    public var labels:Array<BasicProperty>;

    public function new() {
        super();
        type=ComponentId.MASTER_ANIMATION;
    }
}
class TimelineLookupStream {
    public var timetable:Int;
    public var mat4:Mat4;
}
class Matrix4x4TimelineStream {
    public var matrices:Array<TimelineLookupStream>;
    public var duration:Int;
    public var interpolate:Bool;
}
class AnimationStream extends AbstractStream {
    public var numTimelines:Array<Matrix4x4TimelineStream>;

    public function new() {
        super();
        type = ComponentId.ANIMATION;
    }
}
class BoneStream {
    public var name:String;
    public var matrices:Array<Mat4>; //numFrames
    public var offsetMatrix:Mat4;  //joint
    public var vertexIds:Array<Int>;  //index
    public var vertexWeights:Array<Float>; //weight
}
class SkinningStream extends AbstractStream {
    public var name:String;
    public var duration:Int;
    public var numFrames:Int;
    public var bones:Array<BoneStream>;

    public function new() {
        super();
        type = ComponentId.SKINNING;
    }
}
class BoundingBoxStream extends AbstractStream {

    public var centerX:Float;
    public var centerY:Float;
    public var centerZ:Float;
    public var width:Float;
    public var height:Float;
    public var depth:Float;

    public function new() {
        super();
        type = ComponentId.BOUNDINGBOX;
    }
}
class MetadataStream extends AbstractStream {
    public var metadatas:Array<BasicProperty>;

    public function new() {
        super();
        type=ComponentId.METADATA
    }
}

//Mat4;
//Vec2;
//Vec3;
//Vec4;
//Mode
//TriangleCulling
//TextureSampler(id:int)
//String

class ComplexProperty<T> {
    public var type:MinkoTypes;
    public var propertyName:String;
    public var propertyValue:T;
}
//Floats
class BasicProperty<T> {
    public var propertyName:String;
    public var propertyValue:T;
}
class MaterialStream extends AbstractStream {
    public var serializedComplexProperties:Array<ComplexProperty>;
    public var serializedBasicProperties:Array<BasicProperty>;

    public function new() {
        super();
        serializedComplexProperties = new Array<ComplexProperty>();
        serializedBasicProperties = new Array<BasicProperty>();
    }
}
class TextureBlobStream  {
    public var textureFormat:ImageFormat ;
    public var textureData:Bytes;

    public function new() {

    }
}
class TextureStream extends AbstractStream {
    public var width:Int ;
    public var height:Int ;
    public var numFaces:Int ;
    public var numMipmaps:Int ;
    public var blobs:Array<TextureBlobStream>;

    public function new() {
        super();
    }
}
class SerializedNode {
    public var name:String;
    public var layout:Int;
    public var children:Int;
    public var componentsId:Array<Int>;
    public var uuid:String;

}