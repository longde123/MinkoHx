package minko.material;

import glm.Vec3;
import glm.Vec4;
import minko.material.Material;
import minko.render.AbstractTexture;

/**
 * PBR material data. The actual shader is selected by RenderPath; this class
 * only defines the material contract consumed by the PBR render paths.
 */
@:expose("minko.material.PBRMaterial")
class PBRMaterial extends Material {
    public static inline var BASE_COLOR = "baseColor";
    public static inline var BASE_COLOR_MAP = "baseColorMap";
    public static inline var METALLIC = "metallic";
    public static inline var ROUGHNESS = "roughness";
    public static inline var EMISSIVE = "emissive";
    public static inline var NORMAL_SCALE = "normalScale";
    public static inline var OCCLUSION = "occlusion";
    public static inline var ALPHA_MODE = "alphaMode";
    public static inline var DOUBLE_SIDED = "doubleSided";

    public static function create(name:String = "pbr-material"):PBRMaterial {
        return new PBRMaterial(name);
    }

    public function new(name:String = "pbr-material") {
        super(name);

        set(BASE_COLOR, new Vec4(1.0, 1.0, 1.0, 1.0));
        set(METALLIC, 0.0);
        set(ROUGHNESS, 0.5);
        set(EMISSIVE, new Vec3(0.0, 0.0, 0.0));
        set(NORMAL_SCALE, 1.0);
        set(OCCLUSION, 1.0);
        set(ALPHA_MODE, 0);
        set(DOUBLE_SIDED, false);
    }

    public function setBaseColor(value:Vec4):PBRMaterial {
        set(BASE_COLOR, value);
        return this;
    }

    public function setBaseColorMap(value:AbstractTexture):PBRMaterial {
        set(BASE_COLOR_MAP, value);
        return this;
    }

    public function setMetallic(value:Float):PBRMaterial {
        set(METALLIC, value);
        return this;
    }

    public function setRoughness(value:Float):PBRMaterial {
        set(ROUGHNESS, value);
        return this;
    }

    public function setEmissive(value:Vec3):PBRMaterial {
        set(EMISSIVE, value);
        return this;
    }
}
