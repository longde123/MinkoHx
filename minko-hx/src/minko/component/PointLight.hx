package minko.component;

import glm.Vec3;
import minko.render.light.Light.LightType;

@:expose("minko.component.PointLight")
class PointLight extends LightComponent {
    public static function create(color:Vec3 = null, intensity:Float = 1.0, range:Float = 10.0):PointLight {
        var light = new PointLight();
        if (color != null) {
            light.setColor(color);
        }
        light.setIntensity(intensity);
        light.setRange(range);
        return light;
    }

    public function new() {
        super(LightType.Point);
    }
}
