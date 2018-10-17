package minko.particle.shape;
class Point extends EmitterShape {
    public static function create() {
        var point = new Point();

        return point;
    }

    public function new() {
        super();
    }

    override public function initPosition(particle:ParticleData) {
        particle.x = 0;
        particle.y = 0;
        particle.z = 0;
    }
}
