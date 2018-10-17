package minko.material;
import glm.Vec4;
import minko.render.AbstractTexture;
import minko.render.TextureType;
import minko.utils.MathUtil;
class PhongMaterial extends BasicMaterial {
    static public function create(name = "PhongMaterial"):PhongMaterial {
        return new PhongMaterial(name) ;
    }

    static public function createbyPhongMaterial(source:PhongMaterial) {
        var pm:PhongMaterial = create(source.name);

        pm.data.copyFrom(source.data);

        return pm;
    }

    public var specularColor(get, set):Vec4;

    function set_specularColor(color) {
        data.set("specularColor", color);

        return color;
    }

    public function specularColorRGBA(color) {
        return specularColor = ( MathUtil.rgba(color));
    }

    function get_specularColor() {
        return data.get("specularColor");
    }
    public var shininess(get, set):Float;

    function set_shininess(value) {
        data.set("shininess", value);

        return value;
    }

    function get_shininess() {
        return data.get("shininess");
    }
    public var normalMap(get, set):AbstractTexture;

    function get_normalMap() {
        return data.hasProperty("normalMap") ? data.get("normalMap") : null;
    }

    function set_normalMap(value:AbstractTexture) {
        if (value.type == TextureType.CubeTexture)
            throw ("Only 2d normal maps are currently supported.");
        data.set("normalMap", value);
        //sampler
        return value;
    }
    public var specularMap(get, set):AbstractTexture;

    function get_specularMap() {
        return data.hasProperty("specularMap") ? data.get("specularMap") : null;
    }

    function set_specularMap(value:AbstractTexture) {
        if (value.type == TextureType.CubeTexture)
            throw ("Only 2d normal maps are currently supported.");
        data.set("specularMap", value);
        //sampler
        return value;
    }
    public var environmentAlpha(get, set):Float;

    function set_environmentAlpha(value) {
        data.set("environmentAlpha", value);

        return value;
    }

    function get_environmentAlpha() {
        return data.get("environmentAlpha");
    }
    public var environmentCubemap(get, null):AbstractTexture;

    function get_environmentCubemap() {
        return data.hasProperty("environmentCubemap") ? data.get("environmentCubemap") : null;
    }
    public var environmentMap(null, set):AbstractTexture;

    function set_environmentMap(value:AbstractTexture) {
        if (value.type == TextureType.Texture2D)
            data.set("environmentMap2d", value);
        else
            data.set("environmentCubemap", value);

        return value;
    }
    public var environmentMap2d(get, null):AbstractTexture;

    function get_environmentMap2d() {
        return data.hasProperty("environmentMap2d") ? data.get("environmentMap2d") : null;
    }

    public var alphaMap(get, null):AbstractTexture;

    function get_alphaMap() {
        return data.hasProperty("alphaMap") ? data.get("alphaMap") : null;
    }

    function set_alphaMap(value:AbstractTexture) {
        if (value.type == TextureType.CubeTexture)
            throw ("Only 2d transparency maps are currently supported.");

        data.set("alphaMap", value);

        return value;
    }

    public var alphaThreshold:Float;

    function set_alphaThreshold(value) {
        data.set("alphaThreshold", value);

        return value;
    }

    function get_alphaThreshold() {
        return data.get("alphaThreshold");
    }
    public var fresnelReflectance:Float;

    function get_fresnelReflectance() {
        return data.get("fresnelReflectance");
    }

    function set_fresnelReflectance(value) {
        data.set("fresnelReflectance", value);

        return value;
    }
    public var fresnelExponent:Float;

    function get_fresnelExponent() {
        return data.get("fresnelExponent");
    }

    function set_fresnelExponent(value) {
        data.set("fresnelExponent", value);

        return value;
    }

    public function new(name) {
        super(name);
    }
}
