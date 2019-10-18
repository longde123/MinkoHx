package assimp.format.gltf2;
import haxe.ds.IntMap;
import assimp.format.Defs.AiVector3D;
import assimp.format.gltf2.schema.GLTF.TMinFilter;
import glm.Vec3;
import assimp.format.Defs.AiDefines;
import assimp.format.gltf2.types.Accessor;
import assimp.format.Mesh.AiPrimitiveType;
import glm.Mat4;
import assimp.format.AiMatKeys;
import assimp.format.gltf2.schema.GLTF.TMagFilter;
import assimp.format.AiMatKeys.AiPbrmaterial;
import assimp.format.Anim.AiKey;
import assimp.format.Material.AiMaterialProperty;
import assimp.format.Material.AiTexture;
import assimp.format.gltf2.types.Image;
import assimp.format.Anim.AiQuatKey;
import assimp.format.Anim.AiVectorKey;
import assimp.format.gltf2.schema.GLTF.TAnimationChannelTargetPath;
import assimp.format.Anim.AiAnimation;
import haxe.ds.Vector;
import assimp.format.gltf2.types.CameraType;
import assimp.format.Camera.AiCamera;
import assimp.format.gltf2.types.Camera;
import assimp.format.Mesh.AiAnimMesh;
import assimp.IOSystem.IOStream;
import assimp.format.Defs.AiVector4D;
import minko.utils.MathUtil;
import assimp.format.gltf2.types.AnimationChannel;
import assimp.format.Mesh.AiBone;
import assimp.format.gltf2.schema.GLTF.TMeshPrimitiveType;
import assimp.format.Mesh.AiMesh;
import assimp.format.gltf2.types.Animation;
import assimp.format.Anim.AiNodeAnim;
import assimp.format.Scene.AiScene;
import assimp.format.Scene.AiNode;
import assimp.format.Mesh.AiVertexWeight;
import assimp.format.gltf2.types.MeshPrimitive;
import glm.GLM;
import assimp.format.gltf2.types.Node;
import assimp.format.Mesh.AiFace;
import assimp.format.gltf2.types.Material;
import assimp.format.gltf2.schema.GLTF.TWrapMode;
import assimp.format.gltf2.types.Material.NormalTextureInfo;
import assimp.format.Material.AiString;
import assimp.format.gltf2.types.Material.TextureInfo;
import assimp.format.gltf2.types.AnimationChannel.AnimationSample;
import assimp.format.Material.AiTextureType;
import assimp.format.Material.AiMaterial;
import assimp.format.Defs.AiMatrix4x4;
import assimp.format.Defs.AiQuaternion;
import assimp.format.Defs.AiColor4D;
import assimp.format.Material.MapMode;
import assimp.ImporterDesc.AiImporterFlags;
import assimp.ImporterDesc.AiImporterDesc;
import assimp.format.Defs.AiVector3D;
import assimp.format.Defs.Ai_real;

typedef TVec3 = Array<Float>;//[3];
typedef TVec4 = Array<Float>;//[4];
typedef TMat4 = Array<Float>;//[16];
typedef Asset = GLTF2;
typedef Tangent = AiVector4D;

class AnimationSamplers {
    public function new() {
        this.translation = null;
        this.rotation = null;
        this.scale = null;
    }
    public var translation:Vector<AnimationSample>;
    public var rotation:Vector<AnimationSample>;
    public var scale:Vector<AnimationSample>;
}

class GlTF2Importer extends BaseImporter {

    var meshOffsets:Array<Int>;
    var embeddedTexIdxs:Array<Int>;
    var mScene:AiScene = null;


    //
    // glTF2Importer
    //


    public function new() {
        this.meshOffsets = [];
        this.embeddedTexIdxs = [];
        this.mScene = null;
        var desc:AiImporterDesc = new AiImporterDesc();
        desc.name = "glTF2 Importer";
        desc.flags = AiImporterFlags.SupportTextFlavour
        | AiImporterFlags.SupportBinaryFlavour
        | AiImporterFlags.LimitedSupport
        | AiImporterFlags.Experimental;
        desc.fileExtensions = ["gltf", "glb"];
        info = desc;
        // empty
        super();
    }

    function ConvertWrappingMode(gltfWrapMode:TWrapMode):MapMode {
        switch (gltfWrapMode)
        {
            case TWrapMode.MIRROR_REPEAT:
                return MapMode.mirror;
            case TWrapMode.CLAMP_TO_EDGE:
                return MapMode.clamp;
            case TWrapMode.REPEAT:
                return MapMode.wrap;
            default:
                return MapMode.wrap;
        }
    }


    function SetMaterialColorProperty(UnnamedParameter1:Asset, prop:TVec4, mat:AiMaterial, pKey:String, type:Int = 0, idx:Int = 0) {
        var col:AiColor4D = prop;
        var property = new AiMaterialProperty().setProperty(pKey, type, idx).setColor4DValue(col);
        mat.addProperty(property);
    }

    function SetMaterialColorPropertyTVec3(UnnamedParameter1:Asset, prop:TVec3, mat:AiMaterial, pKey:String, type:Int = 0, idx:Int = 0) {
        var tmp = prop.concat([1]);
        SetMaterialColorProperty(UnnamedParameter1, tmp, mat, pKey, type, idx);
    }

    function SetMaterialTextureProperty(embeddedTexIdxs:Array<Int>, UnnamedParameter1:Asset, prop:TextureInfo, mat:AiMaterial, texType:AiTextureType, texSlot:Int = 0) {

        if (prop.texture != null && prop.texture.image != null) {
            var uri = (prop.texture.image.uri);
            mat.addProperty(new AiMaterialProperty().setProperty(AiMatKeys.TEXTURE_BASE, texType, texSlot).setStringValue(uri));
            // mat.addProperty(uri, AI_MATKEY_TEXTURE(texType, texSlot));
            //  mat.addProperty(prop.texCoord, 1, _AI_MATKEY_GLTF_TEXTURE_TEXCOORD_BASE, texType, texSlot);
            mat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_TEXTURE_TEXCOORD_BASE, texType, texSlot).setIntegerValue(prop.texCoord));
            if (prop.texture.sampler != null) {
                var sampler = prop.texture.sampler;
                var name = (sampler.name != null ? sampler.name : sampler.id + "");
                var id = (sampler.id) + "";
                mat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_MAPPINGNAME_BASE, texType, texSlot).setStringValue(name));
                mat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_MAPPINGID_BASE, texType, texSlot).setStringValue(id));
                // mat.addProperty(name, AI_MATKEY_GLTF_MAPPINGNAME(texType, texSlot));
                // mat.addProperty(id, AI_MATKEY_GLTF_MAPPINGID(texType, texSlot));

                var wrapS = ConvertWrappingMode(sampler.wrapS);
                var wrapT = ConvertWrappingMode(sampler.wrapT);

                mat.addProperty(new AiMaterialProperty().setProperty(AiMatKeys.MAPPINGMODE_U_BASE, texType, texSlot).setIntegerValue(wrapS));
                mat.addProperty(new AiMaterialProperty().setProperty(AiMatKeys.MAPPINGMODE_V_BASE, texType, texSlot).setIntegerValue(wrapT));

//                mat.addProperty(wrapS, 1, AI_MATKEY_MAPPINGMODE_U(texType, texSlot));
//                mat.addProperty(wrapT, 1, AI_MATKEY_MAPPINGMODE_V(texType, texSlot));

                if (sampler.magFilter != TMagFilter.UNSET) {
                    mat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_MAPPINGFILTER_MAG_BASE, texType, texSlot).setIntegerValue(sampler.magFilter));
                    // mat.addProperty(sampler.magFilter, 1, AI_MATKEY_GLTF_MAPPINGFILTER_MAG(texType, texSlot));
                }

                if (sampler.minFilter != TMinFilter.UNSET) {
                    mat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_MAPPINGFILTER_MIN_BASE, texType, texSlot).setIntegerValue(sampler.minFilter));
                    //mat.addProperty(sampler.minFilter, 1, AI_MATKEY_GLTF_MAPPINGFILTER_MIN(texType, texSlot));
                }
            }
        }
    }

    function SetMaterialTexturePropertyScale(embeddedTexIdxs:Array<Int>, r:Asset, prop:NormalTextureInfo, mat:AiMaterial, texType:AiTextureType, texSlot:Int = 0) {
        SetMaterialTextureProperty(embeddedTexIdxs, r, prop, mat, texType, texSlot);

        if (prop.texture != null && prop.texture.image != null) {
            mat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_TEXTURE_SCALE_BASE, texType, texSlot).setFloatValue(prop.scale));
            //  mat.addProperty(prop.scale, 1, AI_MATKEY_GLTF_TEXTURE_SCALE(texType, texSlot));
        }
    }

    function SetMaterialTexturePropertyStrength(embeddedTexIdxs:Array<Int>, r:Asset, prop:OcclusionTextureInfo, mat:AiMaterial, texType:AiTextureType, texSlot:Int = 0) {
        SetMaterialTextureProperty(embeddedTexIdxs, r, prop, mat, texType, texSlot);

        if (prop.texture != null && prop.texture.image != null) {
            mat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_TEXTURE_STRENGTH_BASE, texType, texSlot).setFloatValue(prop.strength));
            //  mat.addProperty(prop.strength, 1, AI_MATKEY_GLTF_TEXTURE_STRENGTH(texType, texSlot));
        }
    }

    function ImportMaterial(embeddedTexIdxs:Array<Int>, r:Asset, mat:Material):AiMaterial {
        var aimat = new AiMaterial();

        if (mat.name != null) {
            var str = (mat.name);
            aimat.addProperty(new AiMaterialProperty().setProperty(AiMatKeys.NAME_BASE, 0, 0).setStringValue(str));
            // aimat.addProperty(str, AiMatKeys.NAME);
        }

        SetMaterialColorProperty(r, mat.pbrMetallicRoughness.baseColorFactor, aimat, AiMatKeys.COLOR_DIFFUSE_BASE);
        SetMaterialColorProperty(r, mat.pbrMetallicRoughness.baseColorFactor, aimat, AiPbrmaterial.GLTF_PBRMETALLICROUGHNESS_BASE_COLOR_FACTOR_BASE);

        SetMaterialTextureProperty(embeddedTexIdxs, r, mat.pbrMetallicRoughness.baseColorTexture, aimat, AiTextureType.diffuse);
        SetMaterialTextureProperty(embeddedTexIdxs, r, mat.pbrMetallicRoughness.baseColorTexture, aimat, AiPbrmaterial.GLTF_PBRMETALLICROUGHNESS_BASE_COLOR_TEXTURE, 1);

        SetMaterialTextureProperty(embeddedTexIdxs, r, mat.pbrMetallicRoughness.metallicRoughnessTexture, aimat, AiPbrmaterial.GLTF_PBRMETALLICROUGHNESS_METALLICROUGHNESS_TEXTURE, 0);

        aimat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_PBRMETALLICROUGHNESS_METALLIC_FACTOR_BASE, 0, 0).setFloatValue(mat.pbrMetallicRoughness.metallicFactor));
        aimat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_PBRMETALLICROUGHNESS_ROUGHNESS_FACTOR_BASE, 0, 0).setFloatValue(mat.pbrMetallicRoughness.roughnessFactor));
        //aimat.addProperty(mat.pbrMetallicRoughness.metallicFactor, 1, AI_MATKEY_GLTF_PBRMETALLICROUGHNESS_METALLIC_FACTOR);
        //aimat.addProperty(mat.pbrMetallicRoughness.roughnessFactor, 1, AI_MATKEY_GLTF_PBRMETALLICROUGHNESS_ROUGHNESS_FACTOR);

        var roughnessAsShininess = 1 - mat.pbrMetallicRoughness.roughnessFactor;
        roughnessAsShininess *= roughnessAsShininess * 1000;
        aimat.addProperty(new AiMaterialProperty().setProperty(AiMatKeys.SHININESS_BASE, 0, 0).setFloatValue(roughnessAsShininess));
        //aimat.addProperty(roughnessAsShininess, 1, AI_MATKEY_SHININESS);

        SetMaterialTexturePropertyScale(embeddedTexIdxs, r, mat.normalTexture, aimat, AiTextureType.normals);
        SetMaterialTexturePropertyStrength(embeddedTexIdxs, r, mat.occlusionTexture, aimat, AiTextureType.lightmap);
        SetMaterialTextureProperty(embeddedTexIdxs, r, mat.emissiveTexture, aimat, AiTextureType.emissive);
        SetMaterialColorProperty(r, mat.emissiveFactor, aimat, AiMatKeys.COLOR_EMISSIVE_BASE);
        aimat.addProperty(new AiMaterialProperty().setProperty(AiMatKeys.TWOSIDED_BASE, 0, 0).setIntegerValue(mat.doubleSided ? 1 : 0));
        // aimat.addProperty(mat.doubleSided, 1, AI_MATKEY_TWOSIDED);

        aimat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_ALPHAMODE_BASE, 0, 0).setStringValue(mat.alphaMode));
        aimat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_ALPHACUTOFF_BASE, 0, 0).setFloatValue(mat.alphaCutoff));
        //  var alphaMode = new AiString(mat.alphaMode);
//        aimat.addProperty(alphaMode, AI_MATKEY_GLTF_ALPHAMODE);
//        aimat.addProperty(mat.alphaCutoff, 1, AI_MATKEY_GLTF_ALPHACUTOFF);


        //pbrSpecularGlossiness
        if (mat.pbrSpecularGlossiness != null) {
            var pbrSG = mat.pbrSpecularGlossiness;
            aimat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_PBRSPECULARGLOSSINESS_BASE, 0, 0).setIntegerValue(1));
            //aimat.addProperty(mat.pbrSpecularGlossiness.isPresent, 1, AI_MATKEY_GLTF_PBRSPECULARGLOSSINESS);
            SetMaterialColorProperty(r, pbrSG.diffuseFactor, aimat, AiMatKeys.COLOR_DIFFUSE_BASE);
            SetMaterialColorProperty(r, pbrSG.specularFactor, aimat, AiMatKeys.COLOR_SPECULAR_BASE);

            var glossinessAsShininess = pbrSG.glossinessFactor * 1000.0 ;
            aimat.addProperty(new AiMaterialProperty().setProperty(AiMatKeys.SHININESS_BASE, 0, 0).setFloatValue(glossinessAsShininess));
            aimat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_PBRSPECULARGLOSSINESS_GLOSSINESS_FACTOR_BASE, 0, 0).setFloatValue(pbrSG.glossinessFactor));
//            aimat.addProperty(glossinessAsShininess, 1, AI_MATKEY_SHININESS);
//            aimat.addProperty(pbrSG.glossinessFactor, 1, AI_MATKEY_GLTF_PBRSPECULARGLOSSINESS_GLOSSINESS_FACTOR);

            SetMaterialTextureProperty(embeddedTexIdxs, r, pbrSG.diffuseTexture, aimat, AiTextureType.diffuse);
            SetMaterialTextureProperty(embeddedTexIdxs, r, pbrSG.specularGlossinessTexture, aimat, AiTextureType.specular);
        }
        if (mat.unlit) {
            aimat.addProperty(new AiMaterialProperty().setProperty(AiPbrmaterial.GLTF_UNLIT_BASE, 0, 0).setFloatValue(mat.unlit ? 1 : 0));
//            aimat.addProperty(mat.unlit, 1, AI_MATKEY_GLTF_UNLIT);
        }

        return aimat;
    }


    function SetFace(face:AiFace, a:Int) {
        face.numIndices = 1;
        face.indices = [a];
    }

    function SetFace2(face:AiFace, a:Int, b:Int) {
        face.numIndices = 2;
        face.indices = [a, b];
    }

    function SetFace3(face:AiFace, a:Int, b:Int, c:Int) {
        face.numIndices = 3;
        face.indices = [a, b, c];
    }


    function CheckValidFacesIndices(faces:Array<AiFace>, nFaces:Int, nVerts:Int) {
        for (i in 0... nFaces) {
            for (j in 0...faces[i].numIndices) {
                var idx = faces[i].indices[j];
                if (idx >= nVerts) {
                    return false;
                }
            }
        }
        return true;
    }


    function GetNodeTransform(node:Node) :AiMatrix4x4{
        var matrix:Mat4 = Mat4.identity(new Mat4());
        if (node.matrix != null) {
            // glm mat4 are column-major (so are OpenGL matrices)
            var arr:Array<Float> = node.matrix.toArray();

            matrix = arr;
            //todo
        } else {
//            if (node.translation != null) {
//                var trans = new AiVector3D();
//                trans = node.translation.toArray();
//                GLM.translate(trans, matrix); //todo
//            }
//
//            if (node.rotation != null) {
//                var rot = new AiQuaternion();
//                rot = node.rotation.toArray();
//                //todo
//                matrix = matrix * (Defs.mat4_cast(rot));
//            }
//
//            if (node.scale != null) {
//                var scal = new AiVector3D(1.0, 1, 1);
//                scal = node.scale.toArray();
//                var s = Mat4.identity(new AiMatrix4x4()); //todo
//                GLM.scale(scal, matrix);
//            }

            var rotation=node.rotation ;
            var translation=node.translation ;
            var scale=node.scale ;
            if(node.rotation == null) rotation = Vector.fromArrayCopy([ 0.0, 0.0, 0.0, 1.0 ]);
            if(node.scale == null) scale = Vector.fromArrayCopy([ 1.0, 1.0, 1.0 ]);
            if(node.translation == null) translation = Vector.fromArrayCopy([ 0.0, 0.0, 0.0 ]);

            var x2:Float = rotation[0] + rotation[0];
            var y2:Float = rotation[1] + rotation[1];
            var z2:Float = rotation[2] + rotation[2];

            var xx:Float = rotation[0] * x2;
            var xy:Float = rotation[0] * y2;
            var xz:Float = rotation[0] * z2;
            var yy:Float = rotation[1] * y2;
            var yz:Float = rotation[1] * z2;
            var zz:Float = rotation[2] * z2;
            var wx:Float = rotation[3] * x2;
            var wy:Float = rotation[3] * y2;
            var wz:Float = rotation[3] * z2;
            // glm mat4 are column-major (so are OpenGL matrices)
            matrix = [
                (1 - (yy + zz)) * scale[0],
                (xy + wz) * scale[0],
                (xz - wy) * scale[0],
                0,

                (xy - wz) * scale[1],
                (1 - (xx + zz)) * scale[1],
                (yz + wx) * scale[1],
                0,

                (xz + wy) * scale[2],
                (yz - wx) * scale[2],
                (1 - (xx + yy)) * scale[2],
                0,

                translation[0],
                translation[1],
                translation[2],
                1
            ];
        }

        // Assimp aiMatrix4x4 are row-major meanwhile
        return convertMat4(matrix);
    }

    public function convertMat4(matrix:AiMatrix4x4) {
        // Assimp aiMatrix4x4 are row-major meanwhile
        // glm mat4 are column-major (so are OpenGL matrices)


        var arr = matrix.toFloatArray();

        var m:AiMatrix4x4 = new AiMatrix4x4(
        arr[ 0], arr[ 1], arr[ 2], arr[3],
        arr[ 4], arr[ 5], arr[ 6], arr[7],
        arr[ 8], arr[ 9], arr[10], arr[11],
        arr[ 12], arr[ 13], arr[14], arr[15]
        );
        return m;
    }

    function BuildVertexWeightMapping(primitive:MeshPrimitive, map:Array<Array<AiVertexWeight>>) {
        var attr:TAttributes = primitive.attributes;
        if (attr.weight == null || attr.joint == null) {
            return;
        }
        if (attr.weight[0].accessor.count != attr.joint[0].accessor.count) {
            return;
        }
        var weight:TAttribute = attr.weight[0];
        var joint:TAttribute = attr.joint[0];
        var num_vertices = weight.accessor.count;

        var weights:Array<Float> = weight.accessor.getFloats().toArray();
        var indices :Array<Int> = joint.accessor.getInts().toArray();
        for (i in 0... num_vertices) {
            for (j in 0... 4) {
                var index = i * 4 + j;
                var bone = indices[index];
                var weight = weights[index];
                // if (weight > 0 && bone < map.length) {
                if (weight > 0.0) {
                    //  map[bone].Capacity = 8;
                    var tmp = new AiVertexWeight();
                    tmp.vertexId = i;
                    tmp.weight = weight;
                    map[bone].push(tmp);
                }
            }
        }
    }

    function ImportNode(pScene:AiScene, r:Asset, meshOffsets:Array<Int>, ptr:Node):AiNode {
        var node = ptr;
        var nameOrId = node.name == null ? node.id + "" : node.name;
        var ainode = new AiNode();
        ainode.name = nameOrId;
        if (node.children != null) {
            ainode.numChildren = node.children.length;
            ainode.children = [];// new aiNode[ainode.mNumChildren];
            for (i in 0... ainode.numChildren) {
                var child = ImportNode(pScene, r, meshOffsets, node.children[i]);
                child.parent = ainode;
                ainode.children[i] = child;
            }
        }
        ainode.transformation = GetNodeTransform(node);
        if (node.mesh != null) {
            // GLTF files contain at most 1 mesh per node.
            //   Debug.Assert(node.meshes.size() == 1);
            var mesh_idx = node.mesh.index;
            var count = meshOffsets[mesh_idx + 1] - meshOffsets[mesh_idx];

            ainode.numMeshes = count;
            ainode.meshes = [];//new uint[count];

            if (node.skin != null) {
                for (primitiveNo in 0... count) {
                    var mesh:AiMesh = pScene.meshes[meshOffsets[mesh_idx] + primitiveNo];
                    mesh.numBones = node.skin.joints.length;
                    mesh.bones = [];//new aiBone[mesh.mNumBones];

                    // GLTF and Assimp choose to store bone weights differently.
                    // GLTF has each vertex specify which bones influence the vertex.
                    // Assimp has each bone specify which vertices it has influence over.
                    // To convert this data, we first read over the vertex data and pull
                    // out the bone-to-vertex mapping.  Then, when creating the aiBones,
                    // we copy the bone-to-vertex mapping into the bone.  This is unfortunate
                    // both because it's somewhat slow and because, for many applications,
                    // we then need to reconvert the data back into the vertex-to-bone
                    // mapping which makes things doubly-slow.
                    var weighting = [for (i in 0...mesh.numBones) new Array<AiVertexWeight>()];//(mesh.mNumBones);
                    BuildVertexWeightMapping(node.mesh.primitives[primitiveNo], weighting);

                    for (i in 0...mesh.numBones) {
                        var bone = new AiBone();

                        var joint:Node = node.skin.joints[i];
                        if (joint.name != null) {
                            bone.name = joint.name;
                        }
                        else {
                            // Assimp expects each bone to have a unique name.
                            var kDefaultName = "bone_" + i;
                            bone.name = kDefaultName ;
                        }
                        //todo
                        //bone.offsetMatrix = GetNodeTransform(joint);
                        var arr:Array<Float> = node.skin.inverseBindMatrices[i].toArray();
                        bone.offsetMatrix =new AiMatrix4x4(
                            arr[ 0], arr[ 1], arr[ 2], arr[3],
                            arr[ 4], arr[ 5], arr[ 6], arr[7],
                            arr[ 8], arr[ 9], arr[10], arr[11],
                            arr[ 12], arr[ 13], arr[14], arr[15]
                        );

                        var weights:Array<AiVertexWeight> = weighting[i];


                        if (weights != null && weights.length > 0) {
                            bone.numWeights = weights.length;
                            bone.weights = weights ;
                        }
                        else {
                            // Assimp expects all bones to have at least 1 weight.
                            bone.weights = [new AiVertexWeight()];//Arrays.InitializeWithDefaultInstances<aiVertexWeight>(1);
                            bone.numWeights = 1;
                        }
                        mesh.bones[i] = bone;
                    }
                }
            }

            var k = 0;
            var j = meshOffsets[mesh_idx];
            while (j < meshOffsets[mesh_idx + 1]) {
                ainode.meshes[k] = j;
                ++j;
                ++k;
            }
        }

        if (node.camera != null) {
            pScene.cameras[node.camera.index].name = ainode.name;
        }

        return ainode;
    }

    function GatherSamplers(anim:Animation):IntMap< AnimationSamplers> {
        var samplers = new IntMap<AnimationSamplers>();
        for (c in 0... anim.channels.length) {
            var channel:AnimationChannel = anim.channels[c];


            var node_index = channel.node.index;
            var sampler:AnimationSamplers = null;// samplers[node_index];
            if (samplers.exists(node_index)) {
                sampler = samplers.get(node_index);
            } else {
                sampler = new AnimationSamplers();// samplers[node_index];
                samplers.set(node_index, sampler);
            }

            if (channel.path == TAnimationChannelTargetPath.TRANSLATION) {
                sampler.translation = channel.samples;
            }
            else if (channel.path == TAnimationChannelTargetPath.ROTATION) {
                sampler.rotation = channel.samples;
            }
            else if (channel.path == TAnimationChannelTargetPath.SCALE) {
                sampler.scale = channel.samples;
            }

        }

        return samplers;
    }

    function CreateNodeAnim(r:Asset, node:Node, samplers:AnimationSamplers):AiNodeAnim {
        var anim = new AiNodeAnim();
        anim.nodeName = node.name;
        var kMillisecondsFromSeconds = 1;// 1000.0 ;
        if (samplers.translation != null) {
            anim.numPositionKeys = samplers.translation.length;
            anim.positionKeys = [ for (i in 0...anim.numPositionKeys) new AiVectorKey()];//Arrays.InitializeWithDefaultInstances < aiVectorKey > (anim.mNumPositionKeys);
            for (i in 0...anim.numPositionKeys) {
                var sampler:AnimationSample = samplers.translation[i];
                anim.positionKeys[i].time = sampler.input * kMillisecondsFromSeconds;
                anim.positionKeys[i].value.x = sampler.output[0];
                anim.positionKeys[i].value.y = sampler.output[1];
                anim.positionKeys[i].value.z = sampler.output[2];
            }
        }
        else if (node.translation != null) {
            anim.numPositionKeys = 1;
            var positionKeys = new AiVectorKey();
            positionKeys.time = 0.0;
            positionKeys.value.x = node.translation[0];
            positionKeys.value.y = node.translation[1];
            positionKeys.value.z = node.translation[2];
            anim.positionKeys = [positionKeys];
        }

        if (samplers.rotation != null) {

            anim.numRotationKeys = samplers.rotation.length;
            anim.rotationKeys = [ for (i in 0... anim.numRotationKeys) new AiQuatKey()];//Arrays.InitializeWithDefaultInstances < aiQuatKey > (anim.mNumRotationKeys);
            for (i in 0... anim.numRotationKeys) {
                var sampler:AnimationSample = samplers.rotation[i];
                anim.rotationKeys[i].time = sampler.input * kMillisecondsFromSeconds;
                //todo
                anim.rotationKeys[i].value.x = sampler.output[0];
                anim.rotationKeys[i].value.y = sampler.output[1];
                anim.rotationKeys[i].value.z = sampler.output[2];
                anim.rotationKeys[i].value.w = sampler.output[3];
            }
        }
        else if (node.rotation != null) {
            anim.numRotationKeys = 1;
            var rotationKeys = new AiQuatKey();
            rotationKeys.time = 0.0;
            rotationKeys.value.x = node.rotation[0];
            rotationKeys.value.y = node.rotation[1];
            rotationKeys.value.z = node.rotation[2];
            rotationKeys.value.w = node.rotation[3];
            anim.rotationKeys = [rotationKeys];
        }

        if (samplers.scale != null) {

            anim.numScalingKeys = samplers.scale.length;
            anim.scalingKeys = [for (i in 0 ...anim.numScalingKeys) new AiVectorKey()];//Arrays.InitializeWithDefaultInstances < aiVectorKey > (anim.mNumScalingKeys);
            for (i in 0 ...anim.numScalingKeys) {
                var sampler:AnimationSample = samplers.scale[i];
                anim.scalingKeys[i].time = sampler.input * kMillisecondsFromSeconds;
                anim.scalingKeys[i].value.x = sampler.output[0];
                anim.scalingKeys[i].value.y = sampler.output[1];
                anim.scalingKeys[i].value.z = sampler.output[2];
            }
        }
        else if (node.scale != null) {
            anim.numScalingKeys = 1;
            var scalingKeys = new AiVectorKey();
            scalingKeys.time = 0.0;
            scalingKeys.value.x = node.scale[0];
            scalingKeys.value.y = node.scale[1];
            scalingKeys.value.z = node.scale[2];
            anim.scalingKeys = [scalingKeys];
        }

        return anim;
    }


    public function dispose() {
        // empty
    }


    override public function canRead(file:String, ioStream:IOStream, checkSig:Bool):Bool {
        var extension = getExtension(file);

        if (extension != "gltf" && extension != "glb") {
            return false;
        }

        if (ioStream != null) {


            return true;
        }

        return false;
    }

    public function ImportMaterials(r:Asset) {
        var numImportedMaterials = r.materials.length;
        var defaultMaterial = new Material();

        mScene.numMaterials = numImportedMaterials + 1;
        mScene.materials = [];//new aiMaterial[mScene.mNumMaterials];
        mScene.materials[numImportedMaterials] = ImportMaterial(embeddedTexIdxs, r, defaultMaterial);

        for (i in 0 ... numImportedMaterials) {
            mScene.materials[i] = ImportMaterial(embeddedTexIdxs, r, r.materials[i]);
        }
    }

    function ExtractData2(acc:TAttribute) {
        var t = acc.accessor.getFloats();
        var tmp = [];
        var i = 0;
        while (i < t.length) {
            tmp.push(new AiVector3D(t[i], t[i + 1], 0));
            i += 2;
        }
        return tmp;
    }

    function ExtractData3(acc:TAttribute) {
        var t = acc.accessor.getFloats();
        var tmp = [];
        var i = 0;
        while (i < t.length) {
            tmp.push(new AiVector3D(t[i], t[i + 1], t[i + 2]));
            i += 3;
        }
        return tmp;
    }

    function ExtractData4(acc:TAttribute) {
        var t = acc.accessor.getFloats();
        var tmp = [];
        var i = 0;
        while (i < t.length) {
            tmp.push(new AiVector4D(t[i], t[i + 1], t[i + 2], t[i + 3]));
            i += 4;
        }
        return tmp;
    }


    public function ImportMeshes(r:Asset) {

        //cross product
        inline function crossProduct(v1:Vec3, v2:Vec3):Vec3 {
            return Vec3.cross(v1, v2, new Vec3()) ;
        }

        var meshes = new Array<AiMesh>();
        var k = 0;
        for (m in 0...r.meshes.length) {
            var mesh:assimp.format.gltf2.types.Mesh = r.meshes[m];
            meshOffsets.push(k);
            k += mesh.primitives.length;
            for (p in 0... mesh.primitives.length) {
                var prim:MeshPrimitive = mesh.primitives[p];
                var aim = new AiMesh();
                meshes.push(aim);
                aim.name = mesh.name == null ? mesh.id + "" : mesh.name;

//        if (mesh.primitives.length > 1)
//        {
//
//        var len = aim.name.length;
//        aim.mName.data[len] = '-';
//        len += 1 + ASSIMP_itoa10(aim.mName.data + len + 1, (uint)(MAXLEN - len - 1), p);
//        }

                switch (prim.mode)
                {
                    case TMeshPrimitiveType.POINTS:
                        aim.primitiveTypes |= AiPrimitiveType.POINT;
                    case TMeshPrimitiveType.LINES:
                    case TMeshPrimitiveType.LINE_LOOP:
                    case TMeshPrimitiveType.LINE_STRIP:
                        aim.primitiveTypes |= AiPrimitiveType.LINE;
                    case TMeshPrimitiveType.TRIANGLES:
                    case TMeshPrimitiveType.TRIANGLE_STRIP:
                    case TMeshPrimitiveType.TRIANGLE_FAN:
                        aim.primitiveTypes |= AiPrimitiveType.TRIANGLE;
                    default: trace("");
                }

                var attr = prim.attributes;
                if (attr.position.length > 0 && attr.position[0].accessor.count > 0) {
                    aim.vertices = ExtractData3(attr.position[0]) ;
                    aim.numVertices = aim.vertices.length;
                }

                if (attr.normal.length > 0 && attr.normal[0].accessor.count > 0) {
                    aim.normals = ExtractData3(attr.normal[0]) ;
                    // only extract tangents if normals are present
                    if (attr.tangent.length > 0 && attr.tangent[0].accessor.count > 0) {

                        // generate bitangents from normals and tangents according to spec
                        var tangents:Array<Tangent> = ExtractData4(attr.tangent[0]) ;
                        aim.tangents = [];//Arrays.InitializeWithDefaultInstances<aiVector3D>(aim.mNumVertices);
                        aim.bitangents = [];//Arrays.InitializeWithDefaultInstances<aiVector3D>(aim.mNumVertices);
                        for (i in 0... aim.numVertices) {
                            aim.tangents[i] = MathUtil.vec4_vec3(tangents[i]) ;
                            //todo
                            aim.bitangents[i] = crossProduct(aim.normals[i], aim.tangents[i]) * tangents[i].w;
                        }
                        tangents = null;
                    }
                }
                var c_num = Math.floor(Math.min(attr.color.length, AiDefines.AI_MAX_NUMBER_OF_COLOR_SETS));
                for (c in 0...c_num) {
                    if (attr.color[c].accessor.count != aim.numVertices) {
                        trace("Color stream size in mesh \"" + mesh.name + "\" does not match the vertex count");
                        continue;
                    }
                    aim.colors[c] = ExtractData4(attr.color[c]);// Arrays.InitializeWithDefaultInstances<aiColor4D>(attr.color[c].count);
                }

                var tc_num = Math.floor(Math.min(attr.texcoord.length, AiDefines.AI_MAX_NUMBER_OF_TEXTURECOORDS));
                for (tc in 0...tc_num) {
                    if (attr.texcoord[tc].accessor.count != aim.numVertices) {
                        trace("Texcoord stream size in mesh \"" + mesh.name + "\" does not match the vertex count");
                        continue;
                    }
                    //todo int

                    var numUVCount = attr.texcoord[tc].accessor.getComponentSize();
                    if (numUVCount == 3) {
                        aim.textureCoords[tc] = ExtractData3(attr.texcoord[tc]);
                    } else {
                        aim.textureCoords[tc] = ExtractData2(attr.texcoord[tc]);

                    }

//                    var values = aim.textureCoords[tc];
//                    for (i in 0... aim.numVertices) {
//                        values[i].y = 1 - values[i].y; // Flip Y coords
//                    }
//                    aim.textureCoords[tc]=values;
/// <summary>
                    /// Flip the V component of the UV (1-V)
                    /// </summary>
                    /// <param name="array">The array to copy from and modify</param>
                    /// <returns>Copied Vector2 with coordinates in glTF space</returns>
                    aim.numUVComponents[tc] = numUVCount;

                }


                //target ani
                //todo
                var targets = prim.targets;
                if (targets != null && targets.length > 0) {
                    aim.numAnimMeshes = targets.length;
                    aim.animMeshes = [];// new aiAnimMesh[aim.mNumAnimMeshes];
                    for (i in 0... targets.length) {
                        aim.animMeshes[i] = Assimp.aiCreateAnimMesh(aim);
                        var aiAnimMesh:AiAnimMesh = (aim.animMeshes[i]);
                        var target:TTarget = targets[i];

                        if (target.position.length > 0) {
                            var positionDiff = ExtractData3(target.position[0]);
                            for (vertexId in 0...aim.numVertices) {
                                aiAnimMesh.mVertices[vertexId] += positionDiff[vertexId];
                            }
                            positionDiff = null;
                        }
                        if (target.normal.length > 0) {
                            var normalDiff = ExtractData3(target.normal[0]);
                            for (vertexId in 0...aim.numVertices) {
                                aiAnimMesh.mNormals[vertexId] += normalDiff[vertexId];
                            }
                            normalDiff = null;
                        }
                        if (target.tangent.length > 0) {
                            var tangent:Array<Tangent> = ExtractData4(attr.tangent[0]);

                            var tangentDiff:Array<Tangent> = ExtractData4(target.tangent[0]);

                            for (vertexId in 0...aim.numVertices) {
                                tangent[vertexId].x += tangentDiff[vertexId].x;
                                tangent[vertexId].y += tangentDiff[vertexId].y;
                                tangent[vertexId].z += tangentDiff[vertexId].z;
                                //todo
                                aiAnimMesh.mTangents[vertexId] = new AiVector3D(tangent[vertexId].x, tangent[vertexId].y, tangent[vertexId].z);
                                aiAnimMesh.mBitangents[vertexId] = crossProduct(aiAnimMesh.mNormals[vertexId], aiAnimMesh.mTangents[vertexId]) * tangent[vertexId].w;
                            }
                            tangent = null;
                            tangentDiff = null;
                        }
                        if (mesh.weights.length > i) {
                            aiAnimMesh.mWeight = mesh.weights[i];
                        }
                    }
                }


                var faces:Array<AiFace> = [];
                var nFaces = 0;

                if (prim.indices != null) {
                    var count = prim.indices.count;

                    var data = prim.indices.getInts();
                    // ai_assert(data.IsValid());

                    switch (prim.mode)
                    {
                        case TMeshPrimitiveType.POINTS:
                            {
                                nFaces = count;
                                faces = [for (i in 0...nFaces) new AiFace()];// Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                for (i in 0...count) {
                                    SetFace(faces[i], data[i]);
                                }
                            }

                        case TMeshPrimitiveType.LINES:
                            {
                                nFaces = Math.floor(count / 2);
                                faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                var i = 0;
                                while (i < count) {
                                    SetFace2(faces[ Math.floor(i / 2)], data[i], data[i + 1]);
                                    i += 2;
                                }
                            }

                        case TMeshPrimitiveType.LINE_LOOP:
                        case TMeshPrimitiveType.LINE_STRIP:
                            {
                                nFaces = count - ((prim.mode == TMeshPrimitiveType.LINE_STRIP) ? 1 : 0);
                                faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                SetFace2(faces[0], data[0], data[1]);
                                for (i in 2... count) {
                                    SetFace2(faces[i - 1], faces[i - 2].indices[1], data[i]);
                                }
                                if (prim.mode == TMeshPrimitiveType.LINE_LOOP) { // close the loop
                                    SetFace2(faces[count - 1], faces[count - 2].indices[1], faces[0].indices[0]);
                                }
                            }

                        case TMeshPrimitiveType.TRIANGLES:
                            {
                                nFaces = Math.floor(count / 3);
                                faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                var i = 0;
                                while (i < count) {
                                    SetFace3(faces[Math.floor(i / 3)], data[i], data[i + 1], data[i + 2]);
                                    i += 3;
                                }
                            }

                        case TMeshPrimitiveType.TRIANGLE_STRIP:
                            {
                                nFaces = count - 2;
                                faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                for (i in 0...nFaces) {
                                    //The ordering is to ensure that the triangles are all drawn with the same orientation
                                    if ((i + 1) % 2 == 0) {
                                        //For even n, vertices n + 1, n, and n + 2 define triangle n
                                        SetFace3(faces[i], data[i + 1], data[i], data[i + 2]);
                                    }
                                    else {
                                        //For odd n, vertices n, n+1, and n+2 define triangle n
                                        SetFace3(faces[i], data[i], data[i + 1], data[i + 2]);
                                    }
                                }
                            }
                        case TMeshPrimitiveType.TRIANGLE_FAN:
                            nFaces = count - 2;
                            faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                            SetFace3(faces[0], data[0], data[1], data[2]);
                            for (i in 1... nFaces) {
                                SetFace3(faces[i], faces[0].indices[0], faces[i - 1].indices[2], data[i + 2]);
                            }
                    }
                }
                else { // no indices provided so directly generate from counts

                    // use the already determined count as it includes checks
                    var count = aim.numVertices;

                    switch (prim.mode)
                    {
                        case TMeshPrimitiveType.POINTS:
                            {
                                nFaces = count;
                                faces = [for (i in 0...nFaces) new AiFace()];// Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                for (i in 0... count) {
                                    SetFace(faces[i], i);
                                }
                            }

                        case TMeshPrimitiveType.LINES:
                            {
                                nFaces = Math.floor(count / 2);
                                faces = [for (i in 0...nFaces) new AiFace()];// Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                var i = 0;
                                while (i < count) {
                                    SetFace2(faces[Math.floor(i / 2)], i, i + 1);
                                    i += 2;
                                }
                            }

                        case TMeshPrimitiveType.LINE_LOOP:
                        case TMeshPrimitiveType.LINE_STRIP:
                            {
                                nFaces = count - ((prim.mode == TMeshPrimitiveType.LINE_STRIP) ? 1 : 0);
                                faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                SetFace2(faces[0], 0, 1);
                                for (i in 2 ...count) {
                                    SetFace2(faces[i - 1], faces[i - 2].indices[1], i);
                                }
                                if (prim.mode == TMeshPrimitiveType.LINE_LOOP) { // close the loop
                                    SetFace2(faces[count - 1], faces[count - 2].indices[1], faces[0].indices[0]);
                                }
                            }

                        case TMeshPrimitiveType.TRIANGLES:
                            {
                                nFaces = Math.floor(count / 3);
                                faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                var i = 0;
                                while (i < count) {
                                    SetFace3(faces[Math.floor(i / 3)], i, i + 1, i + 2);
                                    i += 3;
                                }
                            }
                        case TMeshPrimitiveType.TRIANGLE_STRIP:
                            {
                                nFaces = count - 2;
                                faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                                for (i in 0...nFaces) {
                                    //The ordering is to ensure that the triangles are all drawn with the same orientation
                                    if ((i + 1) % 2 == 0) {
                                        //For even n, vertices n + 1, n, and n + 2 define triangle n
                                        SetFace3(faces[i], i + 1, i, i + 2);
                                    }
                                    else {
                                        //For odd n, vertices n, n+1, and n+2 define triangle n
                                        SetFace3(faces[i], i, i + 1, i + 2);
                                    }
                                }
                            }
                        case TMeshPrimitiveType.TRIANGLE_FAN:
                            nFaces = count - 2;
                            faces = [for (i in 0...nFaces) new AiFace()];//Arrays.InitializeWithDefaultInstances<aiFace>(nFaces);
                            SetFace3(faces[0], 0, 1, 2);
                            for (i in 1 ... nFaces) {
                                SetFace3(faces[i], faces[0].indices[0], faces[i - 1].indices[2], i + 2);
                            }
                    }
                }

                if (faces != null) {
                    aim.faces = faces;
                    aim.numFaces = nFaces;
                    ///ai_assert(CheckValidFacesIndices(faces, (uint)nFaces, aim.mNumVertices));
                }

                if (prim.material != null) {
                    aim.materialIndex = prim.material.index;
                }
                else {
                    aim.materialIndex = mScene.numMaterials - 1;
                }

            }
        }

        meshOffsets.push(k);
        mScene.meshes = meshes;//(meshes, mScene.meshes, mScene.numMeshes);
        mScene.numMeshes = meshes.length;
    }

    public function ImportCameras(r:Asset) {
        if (r.cameras.length == 0) {
            return;
        }

        mScene.numCameras = r.cameras.length;
        mScene.cameras = [];//new aiCamera[r.cameras.Size()];

        for (i in 0...r.cameras.length) {
            var cam:Camera = r.cameras[i];

            var aicam:AiCamera = mScene.cameras[i] = new AiCamera();

            // cameras point in -Z by default, rest is specified in node transform
            aicam.lookAt = new AiVector3D(0.0, 0.0, -1.0 );

            switch (cam.type )
            {
                case CameraType.Perspective(aspectRatio, yFov):{
                    aicam.aspect = aspectRatio;
                    aicam.horizontalFOV = yFov * aicam.aspect;
                    aicam.clipPlaneFar = cam.zfar;
                    aicam.clipPlaneNear = cam.znear;
                }
                case CameraType.Orthographic(xmag, ymag):{
                    // assimp does not support orthographic cameras
                }
                default:{

                }
            }
        }
    }

    public function ImportNodes(r:Asset) {
        if (r.defaultScene == null) {
            return;
        }
        var rootNodes:Vector<Node> = r.defaultScene.nodes;

        // The root nodes
        var numRootNodes = rootNodes.length;
        if (numRootNodes == 1) { // a single root node: use it
            mScene.rootNode = ImportNode(mScene, r, meshOffsets, rootNodes[0]);
        }
        else if (numRootNodes > 1) { // more than one root node: create a fake root
            var root = new AiNode();
            root.name = "ROOT";
            root.children = [];//new AiNode[numRootNodes];
            for (i in 0...numRootNodes) {
                var node = ImportNode(mScene, r, meshOffsets, rootNodes[i]);
                node.parent = root;
                root.children[root.numChildren++] = node;
            }
            mScene.rootNode = root;
        }

        //if (!mScene->mRootNode) {
        //  mScene->mRootNode = new aiNode("EMPTY");
        //}
    }

    public function ImportAnimations(r:Asset) {
        if (r.defaultScene == null) {
            return;
        }

        mScene.numAnimations = r.animations.length;
        if (mScene.numAnimations == 0) {
            return;
        }

        mScene.animations = [];// new aiAnimation[mScene.mNumAnimations];
        for (i in 0... r.animations.length) {
            var anim:Animation = r.animations[i];

            var ai_anim:AiAnimation = new AiAnimation();
            ai_anim.name = anim.name;
            ai_anim.duration = 0;
            ai_anim.ticksPerSecond = 0;

            var samplers = GatherSamplers(anim);

            ai_anim.numChannels = Lambda.count(samplers);
            if (ai_anim.numChannels > 0) {
                ai_anim.channels = [];// new aiNodeAnim[ai_anim.mNumChannels];
                var j = 0;
                for (iter in samplers.keys()) {
                    ai_anim.channels[j] = CreateNodeAnim(r, r.nodes[iter], samplers.get(iter));
                    ++j;
                }
            }

            // Use the latest keyframe for the duration of the animation
            var maxDuration:Float = 0;
            for (j in 0... ai_anim.numChannels) {
                var chan = ai_anim.channels[j];
                if (chan.numPositionKeys > 0) {
                    var lastPosKey = chan.positionKeys[chan.numPositionKeys - 1];
                    if (lastPosKey.time > maxDuration) {
                        maxDuration = lastPosKey.time;
                    }


                }
                if (chan.numRotationKeys > 0) {
                    var lastRotKey = chan.rotationKeys[chan.numRotationKeys - 1];
                    if (lastRotKey.time > maxDuration) {
                        maxDuration = lastRotKey.time;
                    }

                }
                if (chan.numScalingKeys > 0) {
                    var lastScaleKey = chan.scalingKeys[chan.numScalingKeys - 1];
                    if (lastScaleKey.time > maxDuration) {
                        maxDuration = lastScaleKey.time;
                    }

                }
            }
            ai_anim.duration = maxDuration;
            ai_anim.ticksPerSecond = 1;//fps

            mScene.animations[i] = ai_anim;
        }
    }

    public function ImportEmbeddedTextures(r:Asset) {
        embeddedTexIdxs = [];//.resize(r.images.Size(), -1);

        var numEmbeddedTexs = 0;
        for (i in 0... r.images.length) {
            var img:Image = r.images[i];
            if (img.bufferView != null) {
                numEmbeddedTexs += 1;
            }
        }

        if (numEmbeddedTexs == 0) {
            return;
        }

        mScene.textures = [];//new aiTexture[numEmbeddedTexs];

        // Add the embedded textures
        for (i in 0 ... r.images.length) {
            var img:Image = r.images[i];
            if (img.bufferView == null) {
                continue;
            }

            var idx = mScene.numTextures++;
            embeddedTexIdxs[i] = idx;

            var tex:AiTexture = mScene.textures[idx] = new AiTexture();

            var length = img.bufferView.byteLength;
            var data = img.bufferView.data;

            tex.width = length;
            tex.height = 0;
            tex.pcData = (data);

            if (img.mimeType != null) {
                var ext:String = img.mimeType;
                ext = ext.substr(ext.indexOf('/') + 1) ;
                if (ext != null) {
                    if (ext == "jpeg") {
                        ext = "jpg";
                    }
                    tex.achFormatHint = ext;
                }
            }
        }
    }

    override public function internReadFile(file:String, ioStream:IOStream, pScene:AiScene, buffers:Array<IOStream>):Void {

        this.mScene = pScene;

        // read the asset file

        var asset:GLTF2 = GLTF2.parseAndLoad(ioStream.bytes.toString(), buffers.map(function(b:IOStream) return b.bytes));
        //
        // Copy the data out
        //
        ImportEmbeddedTextures(asset);
        trace("ImportEmbeddedTextures");
        ImportMaterials(asset);
        trace("ImportMaterials");
        ImportMeshes(asset);
        trace("ImportMeshes");
        ImportCameras(asset);
        trace("ImportCameras");
        ImportNodes(asset);
        trace("ImportNodes");
        ImportAnimations(asset);
        trace("ImportAnimations");

       // trace("pScene",pScene);
        if (pScene.numMeshes == 0) {
            //   pScene.flags |= AI_SCENE_FLAGS_INCOMPLETE;
        }
    }
}