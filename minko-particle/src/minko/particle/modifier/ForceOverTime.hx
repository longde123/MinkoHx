package minko.particle.modifier;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
class ForceOverTime extends Modifier3 implements IParticleUpdater {
    public static function create(fx, fy, fz) {
        var ptr = new ForceOverTime(fx, fy, fz);

        return ptr;
    }


    public function new(fx:Sampler, fy:Sampler, fz:Sampler) {

        super(fx, fy, fz);

    }


    public function update(particles:Array<ParticleData>, timeStep:Float):Void {
        var sqTime = timeStep * timeStep;

        for (particle in particles) {
            if (particle.alive) {
                var t = particle.lifetime > 0.0 ? particle.timeLived / particle.lifetime : 0.0;

                particle.x += _x.value(t) * sqTime;
                particle.y += _y.value(t) * sqTime;
                particle.z += _z.value(t) * sqTime;
            }
        }
    }

    public function getNeededComponents() {
        return VertexComponentFlags.DEFAULT;
    }
}
