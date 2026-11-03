package minko.component;

import glm.Vec3;
import minko.render.light.Light.LightType;

@:expose("minko.component.SpotLight")
class SpotLight extends LightComponent {
    public static function create(color:Vec3 = null, intensity:Float = 1.0, range:Float = 10.0,
                                  innerCone:Float = 0.9, outerCone:Float = 0.7):SpotLight {
        var light = new SpotLight();
        if (color != null) {
            light.setColor(color);
        }
        light.setIntensity(intensity);
        light.setRange(range);
        light.setCone(innerCone, outerCone);
        return light;
    }

    public function new() {
        super(LightType.Spot);
    }
}
