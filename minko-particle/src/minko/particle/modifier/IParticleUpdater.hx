package minko.particle.modifier;
interface IParticleUpdater {
    function update(particles:Array<ParticleData>, timeStep:Float):Void;
    function getNeededComponents():Int;
}
