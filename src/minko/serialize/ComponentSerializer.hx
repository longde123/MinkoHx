package minko.serialize;
import Lambda;
import haxe.io.BytesOutput;
import minko.animation.Matrix4x4Timeline;
import minko.component.AbstractComponent;
import minko.component.AmbientLight;
import minko.component.Animation;
import minko.component.BoundingBox;
import minko.component.DirectionalLight;
import minko.component.ImageBasedLight;
import minko.component.MasterAnimation;
import minko.component.Metadata;
import minko.component.PerspectiveCamera;
import minko.component.PointLight;
import minko.component.Renderer;
import minko.component.Skinning;
import minko.component.SpotLight;
import minko.component.Surface;
import minko.component.Transform;
import minko.file.AssetLibrary;
import minko.file.Dependency;
import minko.geometry.Bone;
import minko.math.Box;
import minko.scene.Node;
import minko.serialize.Types.ComponentId;
typedef SimpleProperty = Tuple<String, String> ;
typedef SimplePropertyVector = Array<SimpleProperty>;
class ComponentSerializer {
    public function new() {
    }

    public static function serializeSimplePropertyInt(propertyName:String, value:Int) {
        var serializedValue = TypeSerializer.serializeVectorInt32([value]);
        return new Tuple<String, BytesOutput>(propertyName, serializedValue);
    }

    public static function serializeSimplePropertyBool(propertyName:String, value:Bool) {
        var serializedValue = TypeSerializer.serializeVectorInt8([value ? 1.0 : 0.0]);

        return new Tuple<String, BytesOutput>(propertyName, serializedValue);
    }

    public static function serializeSimplePropertyFloat(propertyName:String, value:Float) {
        var serializedValue = TypeSerializer.serializeVectorFloat([value]);

        return new Tuple<String, BytesOutput>(propertyName, serializedValue);
    }

    public static function serializeSimplePropertyString(propertyName:String, value:String) {
        var serializedValue = TypeSerializer.serializeString(value);
        return new Tuple<String, BytesOutput>(propertyName, value);
    }

    public function serializeTransform(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.TRANSFORM;
        var transform:Transform = cast(component);
        var buffer = new BytesOutput();
        var src = TypeSerializer.serializeMatrix4x4(transform.matrix);
        buffer.writeInt8(type);
        buffer.writeInt32(src.first);
        buffer.writeFullBytes(src.second.getBytes());
        return buffer ;
    }

    public function serializePerspectiveCamera(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.PROJECTION_CAMERA;
        var perspectiveCamera:PerspectiveCamera = cast(component);
        var buffer = new BytesOutput();
        var data = new Array<Float>();

        data.push(perspectiveCamera.aspectRatio);
        data.push(perspectiveCamera.fieldOfView);
        data.push(perspectiveCamera.zNear);
        data.push(perspectiveCamera.zFar);

        var src = TypeSerializer.serializeVectorFloat(data);
        buffer.writeInt8(type);
        buffer.writeFullBytes(src.getBytes());

        return buffer ;
    }

    public function serializeImageBasedLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.IMAGE_BASED_LIGHT;
        var imageBasedLight:ImageBasedLight = cast (component);
        var buffer = new BytesOutput();

        var irradianceMap = assetLibrary.getTextureByUuid(imageBasedLight.irradianceMap.uuid);
        var radianceMap = assetLibrary.getTextureByUuid(imageBasedLight.radianceMap.uuid);

        var src = TypeSerializer.serializeVectorFloat([imageBasedLight.diffuse, imageBasedLight.specular, imageBasedLight.orientation]);
        var src1 = irradianceMap ? dependencies.registerDependency(irradianceMap, "irradianceMap") : 0;
        var src2 = radianceMap ? dependencies.registerDependency(radianceMap, "radianceMap") : 0;

        buffer.writeInt8(type);
        buffer.writeFullBytes(src.getBytes());
        buffer.writeInt32(src1);
        buffer.writeInt32(src2);
        return buffer;
    }

    public function serializeAmbientLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.AMBIENT_LIGHT;
        var ambient:AmbientLight = cast(component);
        var buffer = new BytesOutput();
        var data = new Array<Float>();

        data.push(ambient.ambient);
        data.push(ambient.color.x);
        data.push(ambient.color.y);
        data.push(ambient.color.z);

        var src = TypeSerializer.serializeVectorFloat(data);

        buffer.writeInt8(type);
        buffer.writeFullBytes(src.getBytes());

        return buffer;
    }

    public function serializeDirectionalLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.DIRECTIONAL_LIGHT;
        var directional:DirectionalLight = cast(component);
        var buffer = new BytesOutput();
        var data = new Array<Float>();

        data.push(directional.diffuse);
        data.push(directional.specular);
        data.push(directional.color.x);
        data.push(directional.color.y);
        data.push(directional.color.z);

        var src = TypeSerializer.serializeVectorFloat(data);

        buffer.writeInt8(type);
        buffer.writeFullBytes(src.getBytes());
        return buffer;
    }

    public function serializePointLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.POINT_LIGHT;
        var point:PointLight = cast(component);
        var buffer = new BytesOutput();
        var data = new Array<Float>();

        data.push(point.diffuse);
        data.push(point.specular);
        data.push(point.attenuationCoefficients.x);
        data.push(point.attenuationCoefficients.y);
        data.push(point.attenuationCoefficients.z);
        data.push(point.color.x);
        data.push(point.color.y);
        data.push(point.color.z);

        var src = TypeSerializer.serializeVectorFloat(data);

        buffer.writeInt8(type);
        buffer.writeFullBytes(src.getBytes());
        return buffer;
    }

    public function serializeSpotLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.SPOT_LIGHT;
        var spot:SpotLight = cast(component);
        var buffer = new BytesOutput();
        var data = new Array<Float>();

        data.push(spot.diffuse);
        data.push(spot.specular);
        data.push(spot.attenuationCoefficients.x);
        data.push(spot.attenuationCoefficients.y);
        data.push(spot.attenuationCoefficients.z);
        data.push(spot.innerConeAngle);
        data.push(spot.outerConeAngle);
        data.push(spot.color.x);
        data.push(spot.color.y);
        data.push(spot.color.z);

        var src = TypeSerializer.serializeVectorFloat(data);

        buffer.writeInt8(type);
        buffer.writeFullBytes(src.getBytes());
        return buffer;
    }

    public function serializeSurface(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.SURFACE;
        var surface:Surface = cast(component);
        var buffer = new BytesOutput();

        buffer.writeInt8(type);
        var materialId:Int = dependencies.registerDependency(surface.material);
        var geometryId:Int = dependencies.registerDependency(surface.geometry);
        var effectId:Int = surface.effect != null ? dependencies.registerDependency(surface.effect) : 0;

        var src:BytesOutput = getSurfaceExtension(node, surface) ;

        buffer.writeInt16(geometryId);
        buffer.writeInt16(materialId);
        buffer.writeInt16(effectId);
        //geometryId, materialId, effectId,
        buffer.writeFullBytes(src.getBytes());

        return buffer;
    }

    public function getSurfaceExtension(node:Node, surface:Surface) {
        var properties = new Array<SimpleProperty>();

        properties.push(new SimpleProperty("uuid", surface.uuid));

        var technique = surface.technique;

        if (surface.technique != "default") {
            properties.push(new SimpleProperty("technique", technique));
        }

        /*if (!surface->visible())
			properties.push_back(serializeSimpleProperty(std::string("visible"), surface->visible()));*/

        var buffer = new BytesOutput();
        for (p in properties) {
            buffer.writeString(p.first);
            buffer.writeString(p.second);
        }

        return buffer ;
    }

    public function serializeRenderer(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.RENDERER;
        var renderer:Renderer = cast(component);
        var buffer = new BytesOutput();
        buffer.writeInt8(type);
        buffer.writeInt32(renderer.backgroundColor);

        return buffer;
    }

    public function serializeMasterAnimation(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.MASTER_ANIMATION;
        var masterAnimation:MasterAnimation = cast(component);


        var buffer = new BytesOutput();
        buffer.writeInt8(type);
        for (i in 0... masterAnimation.numLabels) {
            buffer.writeString(masterAnimation.labelName(i));
            buffer.writeInt32(masterAnimation.labelTime(i));
        }


        return buffer ;
    }

    public function serializeAnimation(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.ANIMATION;
        var animation:Animation = cast(component);
        var buffer = new BytesOutput();
        buffer.writeInt8(type);
        buffer.writeInt32(animation.numTimelines) ;
        for (i in 0...animation.numTimelines) {
            var timeline:Matrix4x4Timeline = (animation.getTimeline(i));

            buffer.writeInt32(timeline.duration) ;
            buffer.writeInt32(timeline.matrices.length) ;
            for (timeToMatrixPair in timeline.matrices) {
                var serializedMatrix = TypeSerializer.serializeMatrix4x4(timeToMatrixPair);

                buffer.writeInt32(serializedMatrix.first);
                buffer.writeFullBytes(serializedMatrix.second.getBytes())
            }

            buffer.writeInt8(timeline.interpolate);
        }


        return buffer
    }

    public function serializeSkinning(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.SKINNING;
        var skinning:Skinning = cast(component);
        var buffer = new BytesOutput();
        buffer.writeInt8(type);
        var skin = skinning.skin ;
        buffer.writeString(node.name);
        buffer.writeInt32(skin.duration);

        buffer.writeInt32(skin.numBones);
        buffer.writeInt32(skinning.skin.numFrames);

        for (i in 0...skin.numBones) {
            var bone:Bone = skin.getBone(i);

            for (frameId in 0...skinning.skin.numFrames) {
                var matrix = skin.getMatrices(frameId)[i];
                var serializedMatrix = TypeSerializer.serializeMatrix4x4(matrix);
                buffer.writeInt32(serializedMatrix.first);
                buffer.writeFullBytes(serializedMatrix.second.getBytes());
            }


            buffer.writeString(bone.node.name);

            var serializedOffsetMatrix = TypeSerializer.serializeMatrix4x4(bone.offsetMatrix);
            buffer.writeFullBytes(serializedOffsetMatrix.first);
            buffer.writeFullBytes(serializedOffsetMatrix.second.getBytes());

            var serializedVertexIds = TypeSerializer.serializeVectorInt32(bone.vertexIds);
            buffer.writeFullBytes(serializedVertexIds.getBytes());
            var serializedVertexWeights = TypeSerializer.serializeVectorFloat(bone.vertexWeights);
            buffer.writeFullBytes(serializedVertexWeights.getBytes());

        }


        return buffer;
    }

    public function serializeBoundingBox(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var boundingBox:BoundingBox = cast(component);
        var box:Box = boundingBox.modelSpaceBox;
        var topRight = box.topRight;
        var bottomLeft = box.bottomLeft;

        var type = ComponentId.BOUNDINGBOX;
        var buffer = new BytesOutput();
        buffer.writeInt8(type);

        var data = new Array<Float>();

        var centerX = (topRight.x + bottomLeft.x) / 2.0;
        var centerY = (topRight.y + bottomLeft.y) / 2.0;
        var centerZ = (topRight.z + bottomLeft.z) / 2.0;

        data.push(centerX);
        data.push(centerY);
        data.push(centerZ);
        data.push(box.width);
        data.push(box.height);
        data.push(box.depth);

        var src = serialize.TypeSerializer.serializeVectorFloat(data);
        buffer.writeFullBytes(src.getBytes());


        return buffer ;
    }

    public function serializeMetadata(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var metadata:Metadata = cast(component);
        var buffer = new BytesOutput();
        buffer.writeInt32(ComponentId.METADATA);
        buffer.writeInt32(Lambda.count(metadata.data));
        for (k in metadata.data.keys()) {
            buffer.writeString(k);
            buffer.writeString(metadata.data.get(k));
        }
        return buffer ;
    }

}
