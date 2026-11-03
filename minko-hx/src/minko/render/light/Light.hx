package minko.render.light;

import glm.Vec3;

@:enum abstract LightType(Int) from Int to Int {
    var Directional = 0;
    var Point = 1;
    var Spot = 2;
}

class Light {
    public var type:LightType;
    public var color:Vec3;
    public var intensity:Float;
    public var position:Vec3;
    public var direction:Vec3;
    public var range:Float;
    public var innerCone:Float;
    public var outerCone:Float;
    public var castShadow:Bool;

    public function new(type:LightType) {
        this.type = type;
        this.color = new Vec3(1.0, 1.0, 1.0);
        this.intensity = 1.0;
        this.position = new Vec3(0.0, 0.0, 0.0);
        this.direction = new Vec3(0.0, 0.0, -1.0);
        this.range = 10.0;
        this.innerCone = 0.9;
        this.outerCone = 0.7;
        this.castShadow = false;
    }

    public static function directional():Light {
        return new Light(LightType.Directional);
    }

    public static function point():Light {
        return new Light(LightType.Point);
    }

    public static function spot():Light {
        return new Light(LightType.Spot);
    }
}
