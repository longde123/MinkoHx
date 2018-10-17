package minko.particle.modifier;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
class StartRotation extends Modifier1 implements IParticleInitializer {

    public static function create(x) {
        var ptr = new StartRotation(x);

        return ptr;
    }

    public function new(angle:Sampler) {
        super(angle);
    }

    public function initialize(particle:ParticleData, time:Float) {
        particle.rotation = _x.value();
    }

    public function getNeededComponents() {
        return VertexComponentFlags.ROTATION;
    }
}
