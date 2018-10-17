package minko.particle.modifier;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
class StartSize extends Modifier1 implements IParticleInitializer {
    public static function create(x) {
        var ptr = new StartSize(x);

        return ptr;
    }

    public function initialize(particle:ParticleData, time:Float):Void {
        particle.size = _x.value();
    }

    public function new(size:Sampler) {
        super(size);
    }


    public function getNeededComponents() {
        return VertexComponentFlags.SIZE;
    }
}
