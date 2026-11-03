package minko.component;

import glm.Vec3;
import minko.render.light.Light.LightType;

@:expose("minko.component.DirectionalLight")
class DirectionalLight extends LightComponent {
    public static function create(color:Vec3 = null, intensity:Float = 1.0):DirectionalLight {
        var light = new DirectionalLight();
        if (color != null) {
            light.setColor(color);
        }
        light.setIntensity(intensity);
        return light;
    }

    public function new() {
        super(LightType.Directional);
    }
}
