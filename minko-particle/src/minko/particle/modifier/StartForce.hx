package minko.particle.modifier;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
class StartForce extends Modifier3 implements IParticleInitializer {
    public static function create(fx:Sampler, fy:Sampler, fz:Sampler) {
        var modifier = new StartForce(fx, fy, fz);

        return modifier;
    }

    public function new(fx:Sampler, fy:Sampler, fz:Sampler) {
        super(fx, fy, fz);
    }

    public function initialize(particle:ParticleData, time:Float):Void {

        particle.startfx = _x.value();
        particle.startfy = _y.value();
        particle.startfz = _z.value();

        var tt = time * time;

        particle.x += particle.startfx * tt;
        particle.y += particle.startfy * tt;
        particle.z += particle.startfz * tt;
    }

    public function getNeededComponents() {
        return VertexComponentFlags.DEFAULT;
    }


}
