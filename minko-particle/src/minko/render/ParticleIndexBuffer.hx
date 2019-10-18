package minko.render;
class ParticleIndexBuffer extends IndexBuffer {
    private var _padding:Array<Int>;

    public static function create(context:AbstractContext) {
        return new ParticleIndexBuffer(context);
    }


    // void
    // ParticleIndexBuffer::update(unsigned int nParticles)
    // {
    //     unsigned int size = nParticles * 6;

    //     _context->uploaderIndexBufferData(_id, 0, size, &data()[0]);

    //     if(size < data().size())
    //         _context->uploaderIndexBufferData(_id, size, data().size() - size, &_padding[0]);
    // }

    public function resize(nParticles:Int) {
        var isData = data;
        var oldSize = isData.length;
        var size = nParticles * 6;

        if (oldSize != size) {
            if (nParticles == 0) {
                dispose();
            }
            else {
                //   isData = [];//.Resize(size);
                //   _padding = [];//.Resize(size, 0);

                if (oldSize < size) {
                    var j = 0, k = 0;
                    for (i in 0...nParticles) {
                        isData[j++] = k;
                        isData[j++] = k + 2;
                        isData[j++] = k + 1;
                        isData[j++] = k + 1;
                        isData[j++] = k + 2;
                        isData[j++] = k + 3;

                        k += 4;
                    }
                }
                upload();
            }
        }
    }

    public function new(context) {
        super(context);
        this._padding = [];
    }
}
