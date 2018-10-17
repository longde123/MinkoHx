package minko.particle.modifier;
import minko.data.ParticlesProvider;
import minko.particle.sampler.Sampler;
import minko.particle.tools.VertexComponentFlags;
import minko.render.AbstractTexture;
class StartSprite extends Modifier1 implements IParticleInitializer {
    private var _numCols:Int;
    private var _numRows:Int;
    private var _spritesheet:AbstractTexture;

    public static function create(spriteIndex:Sampler, numCols, numRows) {
        var ptr = new StartSprite(spriteIndex, numCols, numRows);

        return ptr;
    }


    public function new(spriteIndex:Sampler, numCols, numRows) {
        super(spriteIndex);
        this._numCols = numCols;
        this._numRows = numRows;

    }


    public function getNeededComponents() {
        return VertexComponentFlags.SPRITE_INDEX;
    }

    public function setProperties(provider:ParticlesProvider) {
        provider.spritesheetSize(_numRows, _numCols);
    }

    public function unsetProperties(provider:ParticlesProvider) {
        provider.unsetSpritesheetSize();
    }


    public function initialize(particle:ParticleData, time:Float):Void {
        particle.spriteIndex = _x.value();
    }
}
