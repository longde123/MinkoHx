package minko.particle.modifier;
import glm.Vec3;
import minko.particle.sampler.SamplerVec3;
import minko.particle.tools.VertexComponentFlags;
class StartColor extends ModifierVec31 implements IParticleInitializer {
    public static function create(x) {
        var ptr = new StartColor(x);

        return ptr;
    }

    public function new(color:SamplerVec3) {
        super(color) ;
    }

    public function initialize(particle:ParticleData, time:Float):Void {
        var initialize_c = new Vec3();
        _x.setValue(initialize_c);

        particle.r = initialize_c.x;
        particle.g = initialize_c.y;
        particle.b = initialize_c.z;
    }

    public function getNeededComponents() {
        return VertexComponentFlags.COLOR;
    }
}
