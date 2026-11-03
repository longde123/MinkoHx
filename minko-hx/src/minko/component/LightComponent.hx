package minko.component;

import glm.Vec3;
import minko.CloneOption;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.scene.Node;

/**
 * Scene-graph wrapper around a render Light.
 *
 * The component does not register itself with a renderer; PBRRenderer collects
 * LightComponent instances from its scene each frame and calls
 * syncFromTransform() before building FrameContext.lights.
 */
@:expose("minko.component.LightComponent")
class LightComponent extends AbstractComponent {
    private var _light:Light;

    public function new(type:LightType) {
        super();
        _light = new Light(type);
    }

    public var light(get, null):Light;

    function get_light():Light {
        return _light;
    }

    public var type(get, null):LightType;

    function get_type():LightType {
        return _light.type;
    }

    public var color(get, set):Vec3;

    function get_color():Vec3 {
        return _light.color;
    }

    function set_color(value:Vec3):Vec3 {
        _light.color = value;
        return value;
    }

    public var intensity(get, set):Float;

    function get_intensity():Float {
        return _light.intensity;
    }

    function set_intensity(value:Float):Float {
        _light.intensity = value;
        return value;
    }

    public var range(get, set):Float;

    function get_range():Float {
        return _light.range;
    }

    function set_range(value:Float):Float {
        _light.range = value;
        return value;
    }

    public var innerCone(get, set):Float;

    function get_innerCone():Float {
        return _light.innerCone;
    }

    function set_innerCone(value:Float):Float {
        _light.innerCone = value;
        return value;
    }

    public var outerCone(get, set):Float;

    function get_outerCone():Float {
        return _light.outerCone;
    }

    function set_outerCone(value:Float):Float {
        _light.outerCone = value;
        return value;
    }

    public var castShadow(get, set):Bool;

    function get_castShadow():Bool {
        return _light.castShadow;
    }

    function set_castShadow(value:Bool):Bool {
        _light.castShadow = value;
        return value;
    }

    public function setColor(value:Vec3):LightComponent {
        _light.color = value;
        return this;
    }

    public function setIntensity(value:Float):LightComponent {
        _light.intensity = value;
        return this;
    }

    public function setRange(value:Float):LightComponent {
        _light.range = value;
        return this;
    }

    public function setCone(inner:Float, outer:Float):LightComponent {
        _light.innerCone = inner;
        _light.outerCone = outer;
        return this;
    }

    public function setCastShadow(value:Bool):LightComponent {
        _light.castShadow = value;
        return this;
    }

    /**
     * Copy the node Transform into the render light.
     *
     * Position comes from the model-to-world translation; direction is the
     * transform's -Z axis. Without a Transform the render light keeps its
     * current values.
     */
    public function syncFromTransform():Void {
        var node = target;
        if (node == null) {
            return;
        }
        var transform:Transform = cast(node.getComponent(Transform), Transform);
        if (transform == null) {
            return;
        }

        var world = transform.modelToWorldMatrix;
        if (world == null) {
            world = transform.matrix;
        }
        if (world == null) {
            return;
        }

        _light.position = new Vec3(world.r0c3, world.r1c3, world.r2c3);
        var direction = new Vec3(-world.r0c2, -world.r1c2, -world.r2c2);
        var length = Math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z);
        if (length > 0.0001) {
            _light.direction = new Vec3(direction.x / length, direction.y / length, direction.z / length);
        }
    }

    override public function clone(option:CloneOption):Dynamic {
        var copy = createByType(_light.type);
        copy.light.color = _light.color;
        copy.light.intensity = _light.intensity;
        copy.light.position = _light.position;
        copy.light.direction = _light.direction;
        copy.light.range = _light.range;
        copy.light.innerCone = _light.innerCone;
        copy.light.outerCone = _light.outerCone;
        copy.light.castShadow = _light.castShadow;
        return copy;
    }

    private static function createByType(type:LightType):LightComponent {
        switch (type) {
            case LightType.Directional:
                return new DirectionalLight();
            case LightType.Point:
                return new PointLight();
            case LightType.Spot:
                return new SpotLight();
        }
    }

    override public function dispose():Void {
        _light = null;
        super.dispose();
    }
}
