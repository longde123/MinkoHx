package minko.deserialize;
import minko.file.AbstractStream.MetadataStream;
import minko.file.AbstractStream.BoundingBoxStream;
import minko.file.AbstractStream.BoneStream;
import minko.file.AbstractStream.SkinningStream;
import minko.file.AbstractStream.AnimationStream;
import minko.file.AbstractStream.MasterAnimationStream;
import minko.file.AbstractStream.RendererStream;
import minko.file.AbstractStream.SurfaceStream;
import minko.file.AbstractStream.SpotLightStream;
import minko.file.AbstractStream.PointLightStream;
import minko.file.AbstractStream.DirectionalLightStream;
import minko.file.AbstractStream.AmbientLightStream;
import minko.file.AbstractStream.ImageBasedLightStream;
import minko.file.AbstractStream.PerspectiveCameraStream;
import minko.file.AbstractStream.TransformStream;
import glm.Mat4;
import glm.Vec3;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.animation.AbstractTimeline;
import minko.animation.Matrix4x4Timeline;
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
import minko.file.AbstractSerializerParser.SceneVersion;
import minko.file.AssetLibrary;
import minko.file.Dependency;
import minko.geometry.Bone;
import minko.geometry.Geometry;
import minko.geometry.Skin;
import minko.material.Material;
import minko.scene.Node;
import minko.scene.NodeSet;
using minko.utils.BytesTool;

class ComponentDeserializer {
    public function new() {
    }

    public function deserializeTransform(sceneVersion:SceneVersion, packed:TransformStream, assetLibrary:AssetLibrary, dependencies:Dependency) :Transform{
        var transformMatrix:Mat4 = packed.matrix;
        return Transform.createbyMatrix4(transformMatrix);
    }

    public function deserializeProjectionCamera(sceneVersion:SceneVersion, packed:PerspectiveCameraStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        return PerspectiveCamera.create(packed.aspectRatio, packed.fieldOfView, packed.zNear, packed.zFar);
    }

    public function deserializeImageBasedLight(sceneVersion:SceneVersion, serializedImageBasedLight:ImageBasedLightStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var imageBasedLight = ImageBasedLight.create();
        imageBasedLight.diffuse = serializedImageBasedLight.diffuse;
        imageBasedLight.specular = serializedImageBasedLight.specular;
        imageBasedLight.orientation = serializedImageBasedLight.orientation;
        var irradianceMapId = serializedImageBasedLight.irradianceMap;
        var radianceMapId = serializedImageBasedLight.radianceMap;
        if (irradianceMapId != 0) {
            var irradianceMap = dependencies.getTextureReference(irradianceMapId).texture;
            if (irradianceMap) {
                imageBasedLight.irradianceMap = (irradianceMap);
            }
        }
        if (radianceMapId != 0) {
            var radianceMap = dependencies.getTextureReference(radianceMapId).texture;
            if (radianceMap) {
                imageBasedLight.radianceMap = (radianceMap);
            }
        }
        return imageBasedLight;
    }

    public function deserializeAmbientLight(sceneVersion:SceneVersion, packed:AmbientLightStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var ambientLight = AmbientLight.create();
        ambientLight.ambient = packed.ambient;
        ambientLight.color = packed.color;
        return ambientLight;
    }

    public function deserializeDirectionalLight(sceneVersion:SceneVersion, packed:DirectionalLightStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var directionalLight = DirectionalLight.create();
        directionalLight.diffuse = packed.diffuse;
        directionalLight.specular = packed.specular;
        directionalLight.color =packed.color;
        return directionalLight;
    }

    public function deserializePointLight(sceneVersion:SceneVersion, packed:PointLightStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var pointLight = PointLight.create();
        pointLight.diffuse = packed.diffuse;
        pointLight.specular = packed.specular;
        pointLight.attenuationCoefficients = packed.attenuationCoefficients;
        pointLight.color = packed.color;
        return pointLight;
    }

    public function deserializeSpotLight(sceneVersion:SceneVersion, packed:SpotLightStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var spotLight = SpotLight.create();
        spotLight.diffuse =packed.diffuse;
        spotLight.specular = packed.specular;
        spotLight.attenuationCoefficients = packed.attenuationCoefficients;
        spotLight.innerConeAngle = packed.innerConeAngle;
        spotLight.outerConeAngle = packed.outerConeAngle;
        spotLight.color = packed.color;
        return spotLight;
    }

    public function deserializeSurface(sceneVersion:SceneVersion, packed:SurfaceStream, assetLibrary:AssetLibrary, dependencies:Dependency) {

        var geometryId:Int = packed.geometryId;
        var materialId:Int = packed.materialId;
        var effectId:Int = packed.effectId;



        var geometry:Geometry = dependencies.getGeometryReference(geometryId);
        var material:Material = dependencies.getMaterialReference(materialId);
        var effect = effectId != 0 ? dependencies.getEffectReference(effectId) : null;

        var uuid :String= "";
        var technique = "default";
        var visible = true;

        if (packed.extensions.length > 0) {
            var ext_size =packed.extensions.length;

            for (i in 0...ext_size) {
                var extension = packed.extensions[i];
                if (extension.propertyName == "uuid") {
                    uuid = extension.propertyValue;
                }
                else if (extension.propertyName == "visible") {
                    visible = extension.propertyValue != 0.0;
                    //todo;
                }
                else if (extension.propertyName == "technique") {
                    technique = extension.propertyValue;
                }
            }
        }

        if (material == null && dependencies.options.material != null) {
            material = dependencies.options.material;
        }

        if (effect == null && dependencies.options.effect != null) {
            effect = dependencies.options.effect;
        }

        var surface:Surface;

        material = (material != null ? material : assetLibrary.material("defaultMaterial"));
        effect = (effect != null ? effect : assetLibrary.effect("effect/Phong.effect"));

        if (uuid == "") {
            surface = Surface.create("", geometry, material, effect, technique);
        }
        else {
            surface = Surface.create(uuid, "", geometry, material, effect, technique);
        }

        return surface;
    }

    public function deserializeRenderer(sceneVersion:SceneVersion, packed:RendererStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var renderer = Renderer.create();
        renderer.backgroundColor = packed.backgroundColor;
        return renderer;
    }

    public function deserializeMasterAnimation(sceneVersion:SceneVersion, packed:MasterAnimationStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var masterAnimation:MasterAnimation = MasterAnimation.create();
        for (label in packed.labels) {
            masterAnimation.addLabel(label.propertyName, label.propertyValue);
        }
        return masterAnimation;
    }

    public function deserializeAnimation(sceneVersion:SceneVersion, packed:AnimationStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var timelines = new Array<AbstractTimeline>();
        for (timelineStream in packed.numTimelines) {
            var duration =timelineStream.duration ;
            var matrices = timelineStream.matrices;
            var interpolate = timelineStream.interpolate;
            var timeline:Matrix4x4Timeline = Matrix4x4Timeline.create("matrix", duration, timetable, matrices, interpolate);
            timelines.push(Matrix4x4Timeline.create(timeline));
        }
        return Animation.create(timelines);
    }

    public function deserializeSkinning(sceneVersion:SceneVersion, packed:SkinningStream, assetLibrary:AssetLibrary, dependencies:Dependency) {


        var skeletonName = packed.name;
        var duration = packed.duration;
        var root = dependencies.loadedRoot();
        var numBones = packed.bones.length;
        var numFrames = packed.numFrames;
        var options = assetLibrary.loader.options;
        var context = assetLibrary.context;
        var skin:Skin = Skin.create(numBones, duration, numFrames);

        for (boneId in 0...numBones) {

            var bone:BoneStream=packed.bones[boneId];
            for (frameId in 0...numFrames) {
                var matrix:Mat4=bone.matrices[frameId];
                skin.setMatrix(frameId, boneId, matrix);
            }

            var nodeName = bone.name;
            var vertexShortIds = bone.vertexIds;
            var boneWeight = bone.vertexWeights;

            var nodeSet:NodeSet = NodeSet.create(root).descendants(true, false).where(function(n:Node) {
                return n.name == nodeName;
            });

            if (nodeSet.nodes.length > 0) {
                var node = nodeSet.nodes[0];
                var bone = Bone.create(node, new Mat4(), vertexShortIds, boneWeight);
                skin.setBone(boneId, bone);
            }
        }

        var skinning = Skinning.create(skin.reorganizeByVertices, options.skinningMethod, context, root, true);

        return skinning;
    }

    public function deserializeBoundingBox(sceneVersion:SceneVersion, packed:BoundingBoxStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        return BoundingBox.createbyWHDC(packed.width, packed.height, packed.depth, new Vec3(packed.centerX, packed.centerY, packed.centerZ));
    }

    public function deserializeMetadata(sceneVersion:SceneVersion, packed:MetadataStream, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var data:StringMap<String> = new StringMap<String>();
        for (meta in packed.metadatas) {
            data.set(meta.propertyName, meta.propertyValue);
        }
        return Metadata.create(data);
    }

}
