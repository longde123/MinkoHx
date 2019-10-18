package minko.geometry;
import minko.render.AbstractContext;
import minko.render.ParticleIndexBuffer;
import minko.render.ParticleVertexBuffer;
class ParticlesGeometry extends Geometry {

    private var _particleVertices:ParticleVertexBuffer;
    private var _particleIndices:ParticleIndexBuffer;

    public static function create(context) {
        var geom = new ParticlesGeometry();

        geom.initialize(context);

        return geom;
    }

    public var particleVertices(get, null):ParticleVertexBuffer;

    function get_particleVertices() {
        return _particleVertices;
    }

    public function initialize(context:AbstractContext) {
        _particleVertices = ParticleVertexBuffer.create(context);
        _particleIndices = ParticleIndexBuffer.create(context);

        addVertexBuffer(_particleVertices);
        indices = (_particleIndices);
    }

    public function initStreams(maxParticles) {
        if (maxParticles == 0) {
            return;
        }

        _particleVertices.resize(maxParticles, vertexSize);
        _particleIndices.resize(maxParticles);
    }

    public function new() {
        super("ParticlesGeometry");
    }
}

















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































