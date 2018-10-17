package minko.particle.modifier;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
class StartVelocity extends Modifier3 implements IParticleInitializer {
    public static function create(vx:Sampler, vy:Sampler, vz:Sampler) {
        var modifier = new StartVelocity(vx, vy, vz);

        return modifier;
    }

    public function new(vx, vy, vz) {
        super(vx, vy, vz);
    }


    public function getNeededComponents() {
        return VertexComponentFlags.DEFAULT;
    }

    public function initialize(particle:ParticleData, time:Float):Void {
        particle.startvx += _x.value();
        particle.startvy += _y.value();
        particle.startvz += _z.value();

        particle.x += particle.startvx * time;
        particle.y += particle.startvy * time;
        particle.z += particle.startvz * time;
    }

}
