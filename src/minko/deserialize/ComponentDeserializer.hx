package minko.deserialize;
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
import minko.Tuple.Tuple3;
using minko.utils.BytesTool;

typedef SerializedMatrix = Tuple<Int, String> ;
typedef VectorOfSerializedMatrix = Array<SerializedMatrix> ;
typedef SurfaceExtension = Tuple<String, String> ;
class ComponentDeserializer {
    public function new() {
    }

    public function deserializeTransform(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var _0 = packed.readInt8();
        var _1 = new BytesInput(packed.readOneBytes());
        var serializedMatrixTuple = new Tuple<Int, BytesInput>(_0, _1);
        var transformMatrix:Mat4 = TypeDeserializer.deserializeMatrix4x4(serializedMatrixTuple) ;

        return Transform.createbyMatrix4(transformMatrix);
    }

    public function deserializeProjectionCamera(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {


        var dstContent = deserialize.TypeDeserializer.deserializeVectorFloat(packed);

        return PerspectiveCamera.create(dstContent[0], dstContent[1], dstContent[2], dstContent[3]);
    }

    public function deserializeImageBasedLight(sceneVersion:SceneVersion, serializedImageBasedLight:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var deserializedImageBasedLight = new Tuple3<Bytes, Int, Int>();
        var imageBasedLight = ImageBasedLight.create();
        deserializedImageBasedLight.first = serializedImageBasedLight.read();
        deserializedImageBasedLight.second = serializedImageBasedLight.readInt32();
        deserializedImageBasedLight.thiree = serializedImageBasedLight.readInt32();

        var properties = TypeDeserializer.deserializeVectorFloat(new BytesInput(deserializedImageBasedLight.first));

        imageBasedLight.diffuse = (properties[0])
        imageBasedLight.specular = (properties[1])
        imageBasedLight.orientation = (properties[2]);

        var irradianceMapId = deserializedImageBasedLight.second;
        var radianceMapId = deserializedImageBasedLight.thiree;

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

    public function deserializeAmbientLight(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var ambientLight = AmbientLight.create();
        var dstContent = TypeDeserializer.deserializeVectorFloat(packed);
        ambientLight.ambient = (dstContent[0]);
        ambientLight.color = (new Vec3(dstContent[1], dstContent[2], dstContent[3]));
        return ambientLight;
    }

    public function deserializeDirectionalLight(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var directionalLight = DirectionalLight.create();

        var dstContent = deserialize.TypeDeserializer.deserializeVectorFloat(packed);

        directionalLight.diffuse = (dstContent[0]);
        directionalLight.specular = (dstContent[1]);
        directionalLight.color = (new Vec3(dstContent[2], dstContent[3], dstContent[4]));

        return directionalLight;
    }

    public function deserializePointLight(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var pointLight = PointLight.create();


        var dstContent = deserialize.TypeDeserializer.deserializeVectorFloat(packed);

        pointLight.diffuse = (dstContent[0]);
        pointLight.specular = (dstContent[1]);
        pointLight.attenuationCoefficients = new Vec3(dstContent[2], dstContent[3], dstContent[4]);
        pointLight.color = (new Vec3(dstContent[5], dstContent[6], dstContent[7]));

        return pointLight;
    }

    public function deserializeSpotLight(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var spotLight = SpotLight.create();


        var dstContent = TypeDeserializer.deserializeVectorFloat(packed);

        spotLight.diffuse = (dstContent[0]);
        spotLight.specular = (dstContent[1]);
        spotLight.attenuationCoefficients = new Vec3(dstContent[2], dstContent[3], dstContent[4]);
        spotLight.innerConeAngle = (dstContent[5]);
        spotLight.outerConeAngle = (dstContent[6]);
        spotLight.color = (new Vec3(dstContent[7], dstContent[8], dstContent[9]));

        return spotLight;
    }

    public function deserializeSurface(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {

        var geometryId:Int = packed.readInt16();
        var materialId:Int = packed.readInt16();

        var effectId:Int = packed.readInt16();

        var dst:BytesInput = packed.read();

        var geometry:Geometry = dependencies.getGeometryReference(geometryId);
        var material:Material = dependencies.getMaterialReference(materialId);


        var effect = effectId != 0 ? dependencies.getEffectReference(effectId) : null;

        var uuid = "";
        var technique = "default";
        var visible = true;

        if (dst.length > 0) {
            var ext_size = dst.readInt32();

            for (i in 0...ext_size) {
                var extension = new SurfaceExtension(dst.readUTF(), dst.readUTF());

                if (extension.first == "uuid") {
                    uuid = extension.second;
                }
                else if (extension.first == "visible") {
                    visible = TypeDeserializer.deserializeVectorFloat(extension.second)[0] != 0.0;
                    //todo;
                }
                else if (extension.first == "technique") {
                    technique = extension.second;
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

        if (uuid == null) {
            surface = component.Surface.create("", geometry, material, effect, technique);
        }
        else {
            surface = component.Surface.create(uuid, "", geometry, material, effect, technique);
        }

        return surface;
    }

    public function deserializeRenderer(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var renderer = Renderer.create();


        renderer.backgroundColor = packed.readInt32();

        return renderer;
    }

    public function deserializeMasterAnimation(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var masterAnimation:MasterAnimation = MasterAnimation.create();

        var labels = new Array<Tuple<String, Int>>();

        var len = packed.readInt32();
        for (i in 0...len) {
            labels.push(new Tuple<String, Int>(packed.readString(), packed.readInt32()));
        }

        for (label in labels) {
            masterAnimation.addLabel(label.first, label.second);
        }

        return masterAnimation;
    }

    public function deserializeAnimation(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var timelines = new Array<AbstractTimeline>();


        var matrices = new Array<Mat4>();
        var timetable = new Array<Int>();


        var numTimelines = packed.readInt32();
        for (i in 0...numTimelines) {
            var duration = packed.readInt32() ;
            var matrices_length = packed.readInt32() ;
            for (m in 0...matrices_length) {
                var type = packed.readInt8();
                var matrix = TypeDeserializer.deserializeMatrix4x4(packed.read());
                matrices.push(matrix);
            }
            var interpolate = packed.readInt8();
            var timeline:Matrix4x4Timeline = Matrix4x4Timeline.create("matrix", duration, timetable, matrices, interpolate);
            timelines.push(Matrix4x4Timeline.create(timeline));


        }


        return Animation.create(timelines);
    }

    public function deserializeSkinning(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {


        var skeletonName = packed.readString();
        var duration = packed.readInt32();


        var root = dependencies.loadedRoot();

        var numBones = packed.readInt32();
        var numFrames = packed.readInt32();

        var options = assetLibrary.loader.options;
        var context = assetLibrary.context;

        var skin:Skin = Skin.create(numBones, duration, numFrames);

        for (boneId in 0...numBones) {


            for (frameId in 0...numFrames) {
                var type = packed.readInt32();
                var serializedMatrix:BytesInput = new BytesInput(packed.read());
                var matrix = (TypeDeserializer.deserializeMatrix4x4(serializedMatrix));

                skin.setMatrix(frameId, boneId, matrix);
            }

            var nodeName = packed.readString();
            var serializedBone = new BytesInput(packed.read());
            var vertexShortIds = TypeDeserializer.deserializeVectorInt32(serializedBone);
            var serializedBone2 = new BytesInput(packed.read());
            var boneWeight = TypeDeserializer.deserializeVectorFloat(serializedBone2);

            var nodeSet:NodeSet = NodeSet.create(root).descendants(true, false).where(function(n:Node) {
                return n.name == nodeName;
            });

            if (nodeSet.nodes.length > 0) {
                var node = nodeSet.nodes[0];

                var bone = Bone.create(node, new Mat4(), vertexShortIds, boneWeight);

                skin.setBone(boneId, bone);
            }
        }

        var skinning = component.Skinning.create(skin.reorganizeByVertices, options.skinningMethod, context, root, true);

        return skinning;
    }

    public function deserializeBoundingBox(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {


        var componentData = TypeDeserializer.deserializeVectorFloat(packed);

        return BoundingBox.createbyWHDC(componentData[3], componentData[4], componentData[5], new Vec3(componentData[0], componentData[1], componentData[2]));
    }

    public function deserializeMetadata(sceneVersion:SceneVersion, packed:BytesInput, assetLibrary:AssetLibrary, dependencies:Dependency) {
        var data:StringMap<String> = new StringMap<String>();
        var len = packed.readInt32();
        for (i in 0...len) {
            data.set(packed.readString(), packed.readString());
        }


        return Metadata.create(data);
    }

}
