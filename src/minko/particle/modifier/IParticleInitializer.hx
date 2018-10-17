package minko.particle.modifier;
interface IParticleInitializer {
    function initialize(particle:ParticleData, time:Float):Void;
    function getNeededComponents():Int;
}
