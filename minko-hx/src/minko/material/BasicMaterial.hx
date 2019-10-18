package minko.material;
import glm.Vec2;
import glm.Vec4;
import minko.render.AbstractTexture;
import minko.render.Blending.Destination;
import minko.render.Blending.Mode;
import minko.render.Blending.Source;
import minko.render.Blending;
import minko.render.CompareMode;
import minko.render.States;
import minko.render.StencilOperation;
import minko.render.TriangleCulling;
import minko.utils.MathUtil;
@:expose("minko.material.BasicMaterial")
class BasicMaterial extends Material {
    private var _defaultStates:States;

    public static function create(name = "BasicMaterial"):BasicMaterial {
        return new BasicMaterial(name);
    }

    public static function createbyBasicMaterial(source:BasicMaterial) {
        var pm:Material = create(source.name);

        pm.data.copyFrom(source.data);

        return pm;
    }

    public var diffuseColor(get, set):Vec4;

    function set_diffuseColor(value) {
        data.set("diffuseColor", value);

        return value;
    }

    public function diffuseColorRGBA(diffuseRGBA) {
        return diffuseColor = ( MathUtil.rgba(diffuseRGBA));
    }

    function get_diffuseColor() {
        return data.get("diffuseColor");
    }

    public var uvScale(get, set):Vec2;

    function set_uvScale(value) {
        data.set("uvScale", value);

        return value;
    }

    function get_uvScale() {
        return data.get("uvScale");
    }
    public var uvOffset(get, set):Vec2;

    function set_uvOffset(value) {
        data.set("uvOffset", value);

        return value;
    }

    function get_uvOffset() {
        return data.get("uvOffset");
    }

    public var diffuseMap(get, set):AbstractTexture;

    function get_diffuseMap() {
        return data.hasProperty("diffuseMap") ? data.get("diffuseMap") : null;
    }

    function set_diffuseMap(texture:AbstractTexture) {
#if  DEBUG
	assert(texture == nullptr || texture->type() == TextureType::Texture2D);
#end
        if (texture != null)
            data.set("diffuseMap", texture);
        else
            data.unset("diffuseMap");

        return texture;
    }

    public var fogColor(get, set):Vec4;

    function set_fogColor(value) {
        data.set("fogColor", value);

        return value;
    }

    public function fogColorRGBA(fogRGBA) {
        return fogColor = (MathUtil.rgba(fogRGBA));
    }

    function get_fogColor() {
        return data.get("fogColor");
    }
    public var fogStart(get, set):Float;

    function set_fogStart(value) {
        data.get("fogBounds").x = value;

        return value;
    }

    function get_fogStart() {
        return data.get("fogBounds").x;
    }
    public var fogEnd(get, set):Float;

    function set_fogEnd(value) {
        data.get("fogBounds").y = value;

        return value;
    }

    function get_fogEnd() {
        return data.get("fogBounds").y;
    }
    public var fogTechnique(get, set):FogTechnique;

    function set_fogTechnique(value) {
        data.set("fogTechnique", value);

        return value;
    }

    function get_fogTechnique() {
        return data.get("fogTechnique");
    }

    public function setBlendingMode(src:Source, dst:Destination) {
        data.set("blendingMode", src | dst);
        data.set(States.PROPERTY_BLENDING_SOURCE, src);
        data.set(States.PROPERTY_BLENDING_DESTINATION, dst);

        return (this);
    }
    public var blendingMode(null, set):Mode;

    function set_blendingMode(value) {
        var srcBlendingMode:Source = (value & 0x00ff);
        var dstBlendingMode:Destination = (value & 0xff00);

        data.set("blendingMode", value);
        data.set(States.PROPERTY_BLENDING_SOURCE, srcBlendingMode);
        data.set(States.PROPERTY_BLENDING_DESTINATION, dstBlendingMode);

        return value;
    }

    public var blendingSourceFactor(get, null):Source;

    function get_blendingSourceFactor() {
        return data.hasProperty("bleblendingModendMode") ? data.get("blendingMode") & 0x00ff : _defaultStates.blendingSourceFactor;
    }

    public var blendingDestinationFactor(get, null):Destination;

    function get_blendingDestinationFactor() {
        return data.hasProperty("blendingMode") ? data.get("blendingMode") & 0xff00 : _defaultStates.blendingDestinationFactor;
    }
    public var colorMask(get, set):Bool;

    function set_colorMask(value) {
        data.set(States.PROPERTY_COLOR_MASK, value);

        return value;
    }

    function get_colorMask() {
        return data.hasProperty(States.PROPERTY_COLOR_MASK) ? data.get(States.PROPERTY_COLOR_MASK) : _defaultStates.colorMask;
    }
    public var depthMask(get, set):Bool;

    function set_depthMask(value) {
        data.set(States.PROPERTY_DEPTH_MASK, value);

        return value;
    }

    function get_depthMask() {
        return data.hasProperty(States.PROPERTY_DEPTH_MASK) ? data.get(States.PROPERTY_DEPTH_MASK) : _defaultStates.depthMask;
    }
    public var depthFunction(get, set):CompareMode;

    function set_depthFunction(value) {
        data.set(States.PROPERTY_DEPTH_FUNCTION, value);

        return value;
    }

    function get_depthFunction() {
        return data.hasProperty(States.PROPERTY_DEPTH_FUNCTION) ? data.get(States.PROPERTY_DEPTH_FUNCTION) : _defaultStates.depthFunction;
    }


    public var triangleCulling(get, set):TriangleCulling;

    function set_triangleCulling(value) {
        data.set(States.PROPERTY_TRIANGLE_CULLING, value);

        return value;
    }

    function get_triangleCulling() {
        return data.hasProperty(States.PROPERTY_TRIANGLE_CULLING) ? data.get(States.PROPERTY_TRIANGLE_CULLING) : _defaultStates.triangleCulling;
    }
    public var stencilFunction(get, set):CompareMode;

    function set_stencilFunction(value) {
        data.set(States.PROPERTY_STENCIL_FUNCTION, value);

        return value;
    }

    function get_stencilFunction() {
        return data.hasProperty(States.PROPERTY_STENCIL_FUNCTION) ? data.get(States.PROPERTY_STENCIL_FUNCTION) : _defaultStates.stencilFunction;
    }
    public var stencilReference(get, set):Int;

    function set_stencilReference(value) {
        data.set(States.PROPERTY_STENCIL_REFERENCE, value);
        return value;
    }

    function get_stencilReference() {
        return data.hasProperty(States.PROPERTY_STENCIL_REFERENCE) ? data.get(States.PROPERTY_STENCIL_REFERENCE) : _defaultStates.stencilReference;
    }


    public var stencilMask(get, set):Int;

    function set_stencilMask(value) {
        data.set(States.PROPERTY_STENCIL_MASK, value);

        return value;
    }

    function get_stencilMask() {
        return data.hasProperty(States.PROPERTY_STENCIL_MASK) ? data.get(States.PROPERTY_STENCIL_MASK) : _defaultStates.stencilMask;
    }
    public var stencilFailOperation(get, set):StencilOperation;

    function set_stencilFailOperation(value) {
        data.set(States.PROPERTY_STENCIL_FAIL_OPERATION, value);

        return value;
    }

    function get_stencilFailOperation() {
        return data.hasProperty(States.PROPERTY_STENCIL_FAIL_OPERATION) ? data.get(States.PROPERTY_STENCIL_FAIL_OPERATION) : _defaultStates.stencilFailOperation;
    }
    public var stencilZFailOperation(get, set):StencilOperation;

    function set_stencilZFailOperation(value) {
        data.set(States.PROPERTY_STENCIL_ZFAIL_OPERATION, value);
        return value;
    }

    function get_stencilZFailOperation() {
        return data.hasProperty(States.PROPERTY_STENCIL_ZFAIL_OPERATION) ? data.get(States.PROPERTY_STENCIL_ZFAIL_OPERATION) : _defaultStates.stencilZFailOperation;
    }
    public var stencilZPassOperation(get, set):StencilOperation;

    function set_stencilZPassOperation(value) {
        data.set(States.PROPERTY_STENCIL_ZPASS_OPERATION, value);
        return value;
    }

    function get_stencilZPassOperation() {
        return data.hasProperty(States.PROPERTY_STENCIL_ZPASS_OPERATION) ? data.get(States.PROPERTY_STENCIL_ZPASS_OPERATION) : _defaultStates.stencilZPassOperation;
    }


    public var priority(get, set):Float;

    function set_priority(value) {
        data.set(States.PROPERTY_PRIORITY, value);
        return value;
    }

    function get_priority() {
        return data.hasProperty(States.PROPERTY_PRIORITY) ? data.get(States.PROPERTY_PRIORITY) : _defaultStates.priority;
    }

    public var zSorted(get, set):Bool;

    function set_zSorted(value) {
        data.set(States.PROPERTY_ZSORTED, value);
        return value;
    }

    function get_zSorted() {
        return data.hasProperty(States.PROPERTY_ZSORTED) ? data.get(States.PROPERTY_ZSORTED) : _defaultStates.zSorted;
    }


    public function new(name) {
        super(name);
    }
}
