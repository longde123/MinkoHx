package minko.particle.modifier;
import glm.Vec4;
import minko.data.ParticlesProvider;
import minko.particle.modifier.ModifierVec31;
import minko.particle.sampler.LinearlyInterpolatedValueVec3;
import minko.particle.tools.VertexComponentFlags;
class ColorOverTime extends ModifierVec31 implements IParticleUpdater {
    private static var PROPERTY_NAMES = [
        "particles.colorOverTimeStart",
        "particles.colorOverTimeEnd" ];

    public static function create(sampler:LinearlyInterpolatedValueVec3) {

        var ptr = new ColorOverTime(sampler);

        return ptr;
    }

    public function new(color:LinearlyInterpolatedValueVec3) {
        super(color);
        if (_x == null) {
            throw ("color");
        }
    }


    public function getNeededComponents() {
        return VertexComponentFlags.TIME;
    }

    public function setProperties(provider:ParticlesProvider) {
        if (provider == null) {
            return;
        }

        var linearSampler:LinearlyInterpolatedValueVec3 = cast(_x);
//Debug.Assert(linearSampler);

        provider.set(PROPERTY_NAMES[0], new Vec4(linearSampler.startValue.x, linearSampler.startValue.y, linearSampler.startValue.z, linearSampler.startTime));
        provider.set(PROPERTY_NAMES[1], new Vec4(linearSampler.endValue.x, linearSampler.endValue.y, linearSampler.endValue.z, linearSampler.endTime));
    }

    public function unsetProperties(provider:ParticlesProvider) {
        if (provider != null && provider.hasProperty(PROPERTY_NAMES[0])) {
            provider.unset(PROPERTY_NAMES[0]);
            provider.unset(PROPERTY_NAMES[1]);
        }
    }

    public function update(NamelessParameter1:Array<ParticleData>, timeStep:Float):Void {
    }

}
