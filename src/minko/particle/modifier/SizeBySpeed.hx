package minko.particle.modifier;
import glm.Vec4;
import minko.data.ParticlesProvider;
import minko.particle.sampler.LinearlyInterpolatedValue;
import minko.particle.tools.VertexComponentFlags;
class SizeBySpeed extends Modifier1 implements IParticleUpdater {

    private static var PROPERTY_NAME = "particles.sizeBySpeed";

    public static function create(sampler:LinearlyInterpolatedValue) {
        var ptr = new SizeBySpeed(sampler);

        return ptr;
    }

    public function new(size:LinearlyInterpolatedValue) {
        super(size);
        if (_x == null) {
            throw ("size");
        }
    }


    public function getNeededComponents() {
        return VertexComponentFlags.OLD_POSITION;
    }

    public function setProperties(provider:ParticlesProvider) {
        if (provider == null) {
            return;
        }

        var linearSampler:LinearlyInterpolatedValue = cast(_x);
//Debug.Assert(linearSampler);

        provider.set(PROPERTY_NAME, new Vec4(linearSampler.startTime, linearSampler.startValue, linearSampler.endTime, linearSampler.endValue));
    }

    public function unsetProperties(provider:ParticlesProvider) {
        if (provider != null && provider.hasProperty(PROPERTY_NAME)) {
            provider.unset(PROPERTY_NAME);
        }
    }

    public function update(NamelessParameter1:Array<ParticleData>, timeStep:Float):Void {
    }
}
