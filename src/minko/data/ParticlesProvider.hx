package minko.data;
import glm.Vec2;
import glm.Vec4;
import minko.material.Material;
import minko.render.AbstractTexture;
import minko.utils.MathUtil;
class ParticlesProvider extends Material {
    public static function create():ParticlesProvider {
        var ptr = new ParticlesProvider();

        ptr.initialize();

        return ptr;
    }

    public var propertyNames(get,null):Iterator<String>;
    function get_propertyNames(){
        return _provider.values.keys();
    }
    public function new() {

        super("");
    }

    override public function initialize() {
        set("particles.timeStep", 0.0);

        diffuseColorRGBA(0xffffffff);
    }
    public var diffuseColor(get, set):Vec4;

    function get_diffuseColor() {


        return get("particles.diffuseColor");
    }

    function set_diffuseColor(color) {
        set("particles.diffuseColor", color);

        return color;
    }

    public function diffuseColorRGBA(diffuseRGBA) {
        return diffuseColor = ( MathUtil.rgba(diffuseRGBA));
    }

    public var diffuseMap(get, set):AbstractTexture;

    function get_diffuseMap() {
        return hasProperty("particles.spritesheet") ? get("particles.spritesheet") : null;
    }

    public function getbyValue(key:String,v:Any):Any {
        if(hasProperty(key)){
            return get(key);
        }
        set(key,v);
        return get(key);
    }
    function set_diffuseMap(texture:AbstractTexture) {
#if  DEBUG
	assert(texture == nullptr || texture->type() == TextureType::Texture2D);
#end
        if (texture != null)
            set("particles.spritesheet", texture);
        else
            unset("particles.spritesheet");

        return texture;
    }


    public function unsetDiffuseMap() {
        if (hasProperty("particles.spritesheet")) {
            unset("particles.spritesheet");
        }

        return (this);
    }

    public function spritesheetSize(numCols, numRows) {
        set("particles.spritesheetSize", new Vec2(numCols, numRows));

        return (this);
    }

    public function unsetSpritesheetSize() {
        if (hasProperty("particles.spritesheetSize")) {
            unset("particles.spritesheetSize");
            unset("particles.spritesheet");
        }

        return (this);
    }
    public var isInWorldSpace(get, set):Bool;

    function set_isInWorldSpace(value) {
        if (value) {
            set("particles.worldspace", true);
        }
        else if (hasProperty("particles.worldspace")) {
            unset("particles.worldspace");
        }

        return value;
    }

    function get_isInWorldSpace() {
        return hasProperty("particles.worldspace");
    }
}
