package assimp.format.gltf2.types;
import assimp.format.gltf2.schema.GLTF.TMaterial;
import haxe.ds.Vector;
import assimp.format.gltf2.schema.GLTF.TGlTf;
class TextureInfo {
    public var texture:Texture;
    public var index:Int;
    public var texCoord:Int ;

    public function new():Void {

        texCoord = 0;
    }
}

class NormalTextureInfo extends TextureInfo {
    public var scale:Float;

    public function new():Void {
        super();
        scale = 1;
    }
}

class OcclusionTextureInfo extends TextureInfo {
    public var strength:Float;

    public function new():Void {
        super();
        strength = 1;
    }
}

class PbrMetallicRoughness {
    public var baseColorFactor:Array<Float>;//TVec3;
    public var baseColorTexture:TextureInfo;
    public var metallicRoughnessTexture:TextureInfo;
    public var metallicFactor:Float;
    public var roughnessFactor:Float;

    public function new() {
        baseColorTexture = new TextureInfo();
        metallicRoughnessTexture = new TextureInfo();
    }
}

class PbrSpecularGlossiness {
    public var diffuseFactor:Array<Float>;//TVec4;
    public var specularFactor:Array<Float>;//TVec3;
    public var glossinessFactor:Float;
    public var diffuseTexture:TextureInfo;
    public var specularGlossinessTexture:TextureInfo;

    public function new():Void {
        diffuseTexture = new TextureInfo();
        specularGlossinessTexture = new TextureInfo();
        SetDefaults();
    }

    function SetDefaults() {

    }
}
@:allow(assimp.format.gltf2.GLTF2)
class Material extends Ref {

    static public var defaultBaseColor:Array<Float> = [1, 1, 1, 1];
    static public var defaultEmissiveFactor:Array<Float> = [0, 0, 0];
    static public var defaultDiffuseFactor:Array<Float> = [1, 1, 1, 1];
    static public var defaultSpecularFactor:Array<Float> = [1, 1, 1];
    public var name:Null<String>;

    //PBR metallic roughness properties
    public var pbrMetallicRoughness:Null<PbrMetallicRoughness>;

    //other basic material properties
    public var normalTexture:NormalTextureInfo;
    public var occlusionTexture:OcclusionTextureInfo;
    public var emissiveTexture:TextureInfo;
    public var emissiveFactor:Array<Float>;//vec3;
    public var alphaMode:String;
    public var alphaCutoff:Float;
    public var doubleSided:Bool;

    //extension: KHR_materials_pbrSpecularGlossiness
    public var pbrSpecularGlossiness:Null<PbrSpecularGlossiness>;

    //extension: KHR_materials_unlit
    public var unlit:Bool;


    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Material> {
        var materials = new Vector< Material>(raw.materials.length);
        for (i in 0...raw.materials.length) {
            materials[i] = new Material();
            materials[i].index = i;
        }
        for (i in 0...raw.materials.length) {
            materials[i].load(gltf, raw.materials[i]);
        }
        return materials;
    }

    function load(gltf:GLTF2, material:TMaterial) {
        if (material.pbrMetallicRoughness != null) {


            this.pbrMetallicRoughness.baseColorFactor = material.pbrMetallicRoughness.baseColorFactor;

            if (material.pbrMetallicRoughness.baseColorTexture != null) {
                this.pbrMetallicRoughness.baseColorTexture.texture = gltf.textures[material.pbrMetallicRoughness.baseColorTexture.index];
                this.pbrMetallicRoughness.baseColorTexture.texCoord = material.pbrMetallicRoughness.baseColorTexture.texCoord;
            }

            if (material.pbrMetallicRoughness.metallicRoughnessTexture != null) {
                this.pbrMetallicRoughness.metallicRoughnessTexture.texture = gltf.textures[material.pbrMetallicRoughness.metallicRoughnessTexture.index];
                this.pbrMetallicRoughness.metallicRoughnessTexture.texCoord = material.pbrMetallicRoughness.metallicRoughnessTexture.texCoord;
            }


            this.pbrMetallicRoughness.metallicFactor = material.pbrMetallicRoughness.metallicFactor;
            this.pbrMetallicRoughness.roughnessFactor = material.pbrMetallicRoughness.roughnessFactor;
        }
        if (material.normalTexture != null) {
            this.normalTexture.texture = gltf.textures[material.normalTexture.index];
            this.normalTexture.texCoord = material.normalTexture.texCoord;
        }

        if (material.occlusionTexture != null) {
            this.occlusionTexture.texture = gltf.textures[material.occlusionTexture.index];
            this.occlusionTexture.texCoord = material.occlusionTexture.texCoord;
        }
        if (material.emissiveTexture != null) {
            this.emissiveTexture.texture = gltf.textures[material.emissiveTexture.index];
            this.emissiveTexture.texCoord = material.emissiveTexture.texCoord;
        }


        this.emissiveFactor = material.emissiveFactor;
        doubleSided = material.doubleSided;
        alphaCutoff = material.alphaCutoff;
        if (material.alphaMode != null)
            alphaMode = material.alphaMode;

//        if (Value* extensions = FindObject(material, "extensions")) {
//            if (r.extensionsUsed.KHR_materials_pbrSpecularGlossiness) {
//                if (Value* pbrSpecularGlossiness = FindObject(*extensions, "KHR_materials_pbrSpecularGlossiness")) {
//                    PbrSpecularGlossiness pbrSG;
//
//                    ReadMember(*pbrSpecularGlossiness, "diffuseFactor", pbrSG.diffuseFactor);
//                    ReadTextureProperty(r, *pbrSpecularGlossiness, "diffuseTexture", pbrSG.diffuseTexture);
//                    ReadTextureProperty(r, *pbrSpecularGlossiness, "specularGlossinessTexture", pbrSG.specularGlossinessTexture);
//                    ReadMember(*pbrSpecularGlossiness, "specularFactor", pbrSG.specularFactor);
//                    ReadMember(*pbrSpecularGlossiness, "glossinessFactor", pbrSG.glossinessFactor);
//
//                    this->pbrSpecularGlossiness = Nullable<PbrSpecularGlossiness>(pbrSG);
//                }
//            }
//
//            unlit = nullptr != FindObject(*extensions, "KHR_materials_unlit");


            if(material.extensions!=null){

            }

    }

    public function new():Void {
        super();
        normalTexture = new NormalTextureInfo();
        occlusionTexture = new OcclusionTextureInfo();
        emissiveTexture = new TextureInfo();
        SetDefaults();
    }

    function SetDefaults() {
        //pbr materials
        pbrMetallicRoughness = new PbrMetallicRoughness();
        pbrMetallicRoughness.baseColorFactor = defaultBaseColor.copy();
        pbrMetallicRoughness.metallicFactor = 1.0;
        pbrMetallicRoughness.roughnessFactor = 1.0;

        emissiveFactor = defaultEmissiveFactor.copy();
        alphaMode = "OPAQUE";
        alphaCutoff = 0.5;
        doubleSided = false;
        unlit = false;
    }

}
