package minko.render;
class ParticleVertexBuffer extends VertexBuffer {
    public static function create(context) {
        var vb = new ParticleVertexBuffer(context);

        vb.initialize();

        return vb;
    }

    public function initialize() {
        addAttribute("offset", 2, 0);
        addAttribute("position", 3, 2);
    }


    // void
    // ParticleVertexBuffer::update(unsigned int nParticles, unsigned int vertexSize)
    // {
    //     unsigned int size = nParticles * vertexSize * 4;

    //     _context->uploadVertexBufferData(_id, 0, size, &data()[0]);
    // }

    public function resize(nParticles, vertexSize) {
        var vertexData = data ;
        var oldSize = vertexData.length;
        var size = (nParticles * vertexSize) << 2;

        if (oldSize != size) {
            dispose();
        }

        //  vertexData = [];//.Resize(size);

        var ptr = vertexData;
        var idx = 0;
        for (i in 0...nParticles) {
            ptr[idx] = -0.5;
            ptr[idx + 1] = -0.5;
            idx += vertexSize;

            ptr[idx] = 0.5;
            ptr[idx + 1] = -0.5;
            idx += vertexSize;

            ptr[idx] = -0.5;
            ptr[idx + 1] = 0.5;
            idx += vertexSize;

            ptr[idx] = 0.5;
            ptr[idx + 1] = 0.5;
            idx += vertexSize;
        }

        upload();
    }

    public function resetAttributes() {
        /*
				attributes().resize(0);
				vertexSize(0);

				addAttribute("offset", 2, 0);
				addAttribute("position", 3, 2);
				*/
    }

    public function new(context) {
        super(context);
    }
}
