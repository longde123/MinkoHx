package minko.particle.shape;
class EmitterShape {

    public function initPositionAndDirection(particle:ParticleData) {
        initPosition(particle);
        initDirection(particle);
    }

    public function initPosition(particle:ParticleData) {

    }

    public function initDirection(particle:ParticleData) {
        particle.startvx = particle.x;
        particle.startvy = particle.y;
        particle.startvz = particle.z;
    }

    public function new() {
    }
}
