package minko.material;

import glm.Vec3;
import minko.render.AbstractTexture;

/**
 * Classic Blinn-Phong material data.
 *
 * This class only owns material parameters. Rendering is supplied by a
 * PipelineEffect or a future Phong render path.
 */
@:expose("minko.material.PhongMaterial")
class PhongMaterial extends Material {
    public static inline var DIFFUSE = "diffuse";
    public static inline var SPECULAR = "specular";
    public static inline var SHININESS = "shininess";
    public static inline var AMBIENT = "ambient";
    public static inline var EMISSIVE = "emissive";
    public static inline var DIFFUSE_MAP = "diffuseMap";
    public static inline var SPECULAR_MAP = "specularMap";
    public static inline var NORMAL_MAP = "normalMap";
    public static inline var ALPHA = "alpha";
    public static inline var DOUBLE_SIDED = "doubleSided";

    public static function create(name:String = "phong-material"):PhongMaterial {
        return new PhongMaterial(name);
    }

    public function new(name:String = "phong-material") {
        super(name);

        set(DIFFUSE, new Vec3(1.0, 1.0, 1.0));
        set(SPECULAR, new Vec3(0.2, 0.2, 0.2));
        set(SHININESS, 32.0);
        set(AMBIENT, new Vec3(0.1, 0.1, 0.1));
        set(EMISSIVE, new Vec3(0.0, 0.0, 0.0));
        set(ALPHA, 1.0);
        set(DOUBLE_SIDED, false);
    }

    public function setDiffuse(value:Vec3):PhongMaterial {
        set(DIFFUSE, value);
        return this;
    }

    public function setSpecular(value:Vec3):PhongMaterial {
        set(SPECULAR, value);
        return this;
    }

    public function setShininess(value:Float):PhongMaterial {
        set(SHININESS, value);
        return this;
    }

    public function setAmbient(value:Vec3):PhongMaterial {
        set(AMBIENT, value);
        return this;
    }

    public function setEmissive(value:Vec3):PhongMaterial {
        set(EMISSIVE, value);
        return this;
    }

    public function setDiffuseMap(value:AbstractTexture):PhongMaterial {
        set(DIFFUSE_MAP, value);
        return this;
    }

    public function setSpecularMap(value:AbstractTexture):PhongMaterial {
        set(SPECULAR_MAP, value);
        return this;
    }

    public function setNormalMap(value:AbstractTexture):PhongMaterial {
        set(NORMAL_MAP, value);
        return this;
    }

    public function setAlpha(value:Float):PhongMaterial {
        set(ALPHA, value);
        return this;
    }

    public function setDoubleSided(value:Bool):PhongMaterial {
        set(DOUBLE_SIDED, value);
        return this;
    }
}
