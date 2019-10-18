package minko.particle.modifier;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
class StartAngularVelocity extends Modifier1 implements IParticleInitializer {
    public static function create(w) {
        var ptr = new StartAngularVelocity(w);

        return ptr;
    }

    public function new(w:Sampler) {
        super(w) ;
    }

    public function initialize(particle:ParticleData, time:Float):Void {

        particle.startAngularVelocity = _x.value();
        particle.rotation += particle.startAngularVelocity * time;
    }

    public function getNeededComponents() {
        return VertexComponentFlags.ROTATION;
    }
}
