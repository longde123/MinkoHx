package minko.serialize;
import minko.geometry.Skin;
import minko.render.Texture;
import minko.file.AbstractStream;
import minko.file.AbstractStream.TransformStream;
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
class ComponentSerializer {

    public function serializeTransform(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) :TransformStream{
        var transform:Transform = cast(component);
        var buffer = new TransformStream();
        buffer.type=ComponentId.TRANSFORM;
        buffer.matrix=transform.matrix;
        return buffer ;
    }

    public function serializePerspectiveCamera(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) :PerspectiveCameraStream{
        var type = ComponentId.PROJECTION_CAMERA;
        var perspectiveCamera:PerspectiveCamera = cast(component);
        var buffer :PerspectiveCameraStream= new PerspectiveCameraStream();
        buffer.type=type;
        buffer.aspectRatio=(perspectiveCamera.aspectRatio);
        buffer.fieldOfView=(perspectiveCamera.fieldOfView);
        buffer.zNear=(perspectiveCamera.zNear);
        buffer.zFar=(perspectiveCamera.zFar);
        return buffer ;
    }

    public function serializeImageBasedLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency):ImageBasedLightStream  {
        var type = ComponentId.IMAGE_BASED_LIGHT;
        var imageBasedLight:ImageBasedLight = cast (component);
        var buffer:ImageBasedLightStream = new ImageBasedLightStream();
        var irradianceMap  :Texture= assetLibrary.getTextureByUuid(imageBasedLight.irradianceMap.uuid);
        var radianceMap  :Texture= assetLibrary.getTextureByUuid(imageBasedLight.radianceMap.uuid);
        buffer.type =type;
        buffer.diffuse=  imageBasedLight.diffuse
        buffer.specular= imageBasedLight.specular
        buffer.orientation= imageBasedLight.orientation;
        var src1 = irradianceMap ? dependencies.registerDependencyTexture(irradianceMap, "irradianceMap") : 0;
        var src2 = radianceMap ? dependencies.registerDependencyTexture(radianceMap, "radianceMap") : 0;
        buffer.irradianceMap=src1;
        buffer.radianceMap = src2;
        return buffer;
    }

    public function serializeAmbientLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency):AmbientLightStream {
        var type = ComponentId.AMBIENT_LIGHT;
        var ambient:AmbientLight = cast(component);
        var buffer = new AmbientLightStream();
        buffer.type=type;
        buffer.ambient=ambient.ambient;
        buffer.color=ambient.color;
        return buffer;
    }

    public function serializeDirectionalLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency):DirectionalLightStream {
        var type = ComponentId.DIRECTIONAL_LIGHT;
        var directional:DirectionalLight = cast(component);
        var buffer = new DirectionalLightStream();
        buffer.type=type;
        buffer.diffuse=(directional.diffuse);
        buffer.specular=(directional.specular);
        buffer.color=directional.color;
        return buffer;
    }

    public function serializePointLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) :PointLightStream{
        var type = ComponentId.POINT_LIGHT;
        var point:PointLight = cast(component);
        var buffer = new PointLightStream();
        buffer.type=type;
        buffer.diffuse=(point.diffuse);
        buffer.specular=(point.specular);
        buffer.color=point.color;
        buffer.attenuationCoefficients=point.attenuationCoefficients;
        return buffer;
    }

    public function serializeSpotLight(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency):SpotLightStream {
        var type = ComponentId.SPOT_LIGHT;
        var spot:SpotLight = cast(component);
        var buffer = new SpotLightStream();
        buffer.type=type;
        buffer.diffuse=(spot.diffuse);
        buffer.specular=(spot.specular);
        buffer.attenuationCoefficients=(spot.attenuationCoefficients);
        buffer.innerConeAngle=(spot.innerConeAngle);
        buffer.outerConeAngle=(spot.outerConeAngle);
        buffer.color=(spot.color);
        return buffer;
    }

    public function serializeSurface(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.SURFACE;
        var surface:Surface = cast(component);
        var buffer = new SurfaceStream();
        buffer.type=type;
        var materialId:Int = dependencies.registerDependencyMaterial(surface.material);
        var geometryId:Int = dependencies.registerDependencyGeometry(surface.geometry);
        var effectId:Int = surface.effect != null ? dependencies.registerDependencyEffect(surface.effect) : 0;
        buffer.materialId=materialId;
        buffer.geometryId=geometryId;
        buffer.effectId=effectId;
        buffer.extensions=getSurfaceExtension(node,surface);
        return buffer;
    }

    public function getSurfaceExtension(node:Node, surface:Surface) {
        var properties = new Array<BasicProperty>();
        properties.push(new BasicProperty("uuid", surface.uuid));
        var technique = surface.technique;
        if (surface.technique != "default") {
            properties.push(new BasicProperty("technique", technique));
        }
        return properties ;
    }

    public function serializeRenderer(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.RENDERER;
        var renderer:Renderer = cast(component);
        var buffer = new RendererStream();
        buffer.type=type;
        buffer.backgroundColor=(renderer.backgroundColor);
        return buffer;
    }

    public function serializeMasterAnimation(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.MASTER_ANIMATION;
        var masterAnimation:MasterAnimation = cast(component);
        var buffer = new MasterAnimationStream();
        buffer.type=(type);
        buffer.labels=new Array<BasicProperty>();
        for (i in 0... masterAnimation.numLabels) {
            buffer.labels.push(new BasicProperty(masterAnimation.labelName(i)),masterAnimation.labelTime(i));
        }
        return buffer ;
    }

    public function serializeAnimation(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.ANIMATION;
        var animation:Animation = cast(component);
        var buffer = new AnimationStream();
        buffer.type=(type);
        buffer.numTimelines=[];
        for (i in 0...animation.numTimelines) {
            var timeline:Matrix4x4Timeline = (animation.getTimeline(i));
            var timelineStream:Matrix4x4TimelineStream=new Matrix4x4TimelineStream();
            timelineStream.duration=(timeline.duration) ;
            timelineStream.matrices=[];
            for(m in timeline.matrices){
                var s:TimelineLookupStream=new TimelineLookupStream();
                s.timetable=m.timetable;
                s.mat4=m.mat4;
                timelineStream.matrices.push(s);
            }
            timelineStream.interpolate=(timeline.interpolate);
            buffer.numTimelines.push(timelineStream);
        }
        return buffer;
    }

    public function serializeSkinning(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var type = ComponentId.SKINNING;
        var skinning:Skinning = cast(component);
        var buffer = new SkinningStream();
        buffer.type=(type);
        var skin:Skin  = skinning.skin;
        buffer.name=(node.name);
        buffer.duration=(skin.duration);
        buffer.bones =[];
        buffer.numFrames=skin.numFrames;
        for (i in 0...skin.numBones) {
            var b:BoneStream=new BoneStream();

            b.matrices=[];
            var bone:Bone = skin.getBone(i);
            for (frameId in 0...skin.numFrames) {
                var matrix = skin.getMatrices(frameId)[i];
                b.matrices.push(matrix); //joints

            }
            //skeleton
            b.name=(bone.node.name);
            b.offsetMatrix=(bone.offsetMatrix); //inverseBindMatrices
            b.vertexIds= (bone.vertexIds);
            b.vertexWeights= (bone.vertexWeights);
            buffer.bones.push(b);
        }
        return buffer;
    }

    public function serializeBoundingBox(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var boundingBox:BoundingBox = cast(component);
        var box:Box = boundingBox.modelSpaceBox;
        var topRight = box.topRight;
        var bottomLeft = box.bottomLeft;
        var type = ComponentId.BOUNDINGBOX;
        var buffer = new BoundingBoxStream();
        buffer.type=(type);
        var centerX = (topRight.x + bottomLeft.x) / 2.0;
        var centerY = (topRight.y + bottomLeft.y) / 2.0;
        var centerZ = (topRight.z + bottomLeft.z) / 2.0;
        buffer.centerX=(centerX);
        buffer.centerY=(centerY);
        buffer.centerZ=(centerZ);
        buffer.width=(box.width);
        buffer.height=(box.height);
        buffer.depth=(box.depth);

        return buffer ;
    }

    public function serializeMetadata(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var metadata:Metadata = cast(component);
        var buffer = new MetadataStream();
        buffer.type=(ComponentId.METADATA);
        buffer.metadatas=[];
        for (k in metadata.data.keys()) {
            buffer.metadatas.push(new BasicProperty(k,metadata.data.get(k)));
        }
        return buffer ;
    }

}
