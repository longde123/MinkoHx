package minko.component;
import minko.render.Texture;
import minko.utils.MathUtil;
@:expose("minko.component.ImageBasedLight")
class ImageBasedLight extends AbstractLight {
    public static function create() :ImageBasedLight{
        var instance = new ImageBasedLight() ;

        instance.brightness = (1.0);

        return instance;
    }

    public var diffuse(get, set):Float;

    function get_diffuse() {
        return provider.get("diffuse");
    }

    function set_diffuse(value) {
        provider.set("diffuse", MathUtil.clamp(value, 0.0, 1.0));

        return value;
    }
    public var specular(get, set):Float;

    function get_specular() {
        return provider.get("specular");
    }

    function set_specular(value) {
        provider.set("specular", MathUtil.clamp(value, 0.0, 1.0));

        return value;
    }
    public var irradianceMap(get, set):Texture;

    function get_irradianceMap() {
        return provider.get("irradianceMap");
    }

    function set_irradianceMap(value) {
        provider.set("irradianceMap", value);

        return value;
    }
    public var radianceMap(get, set):Texture;

    function get_radianceMap() {
        return provider.get("radianceMap");
    }

    function set_radianceMap(value) {
        provider.set("radianceMap", value);

        return value;
    }
    public var brightness(get, set):Float;

    function get_brightness() {
        return provider.get("brightness");
    }

    function set_brightness(value) {
        provider.set("brightness", value);

        return value;
    }
    public var orientation(get, set):Float;

    function get_orientation() {
        return provider.get("orientation");
    }

    function set_orientation(value) {
        provider.set("orientation", value);

        return value;
    }

    public function new() {
        super("imageBasedLight");
    }
}
