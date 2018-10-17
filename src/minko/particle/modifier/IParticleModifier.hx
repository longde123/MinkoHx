package minko.particle.modifier;
import minko.data.ParticlesProvider;
interface IParticleModifier {
    function getNeededComponents():Int;
    function setProperties(particle:ParticlesProvider):Void;
    function unsetProperties(particle:ParticlesProvider):Void;
}
