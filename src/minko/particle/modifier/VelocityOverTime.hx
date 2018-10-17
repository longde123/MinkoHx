package minko.particle.modifier;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
class VelocityOverTime extends Modifier3 implements IParticleUpdater {
    public static function create(vx:Sampler, vy:Sampler, vz:Sampler) {
        var modifier = new VelocityOverTime(vx, vy, vz);

        return modifier;
    }

    public function new(vx, vy, vz) {
        super(vx, vy, vz);

    }

    public function update(particles:Array<ParticleData>, timeStep:Float):Void {
        for (particle in particles) {
            if (particle.alive) {
                var t = particle.lifetime > 0.0 ? particle.timeLived / particle.lifetime : 0.0;

                var dx = _x.value(t) * timeStep;
                var dy = _y.value(t) * timeStep;
                var dz = _z.value(t) * timeStep;

                particle.x += dx;
                particle.y += dy;
                particle.z += dz;
            }
        }
    }

    public function getNeededComponents() {
        return VertexComponentFlags.DEFAULT;
    }


}
