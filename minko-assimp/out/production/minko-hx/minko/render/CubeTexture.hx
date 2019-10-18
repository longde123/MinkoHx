package minko.render;
import haxe.io.Bytes;
import minko.utils.MathUtil;
@:expose("minko.render.Face")
@:enum abstract Face(Int) from Int to Int {
    var POSITIVE_X = 0;
    var NEGATIVE_X = 1;
    var POSITIVE_Y = 2;
    var NEGATIVE_Y = 3;
    var POSITIVE_Z = 4;
    var NEGATIVE_Z = 5;
}
@:expose("minko.render.CubeTexture")
class CubeTexture extends AbstractTexture {
    private var _data:Array<Bytes> ; // pixel RGBA data indexed by face index
    private var _faceWidth:Int; // power of two
    private var _faceHeight:Int; // power of two


    public static function create(context:AbstractContext, width:Int, height:Int, ? mipMapping = false, ?optimizeForRenderToTexture = false, ?resizeSmoothly = true, ?format = TextureFormat.RGBA, ?filename = "") {

        return new CubeTexture(context, width, height, format, mipMapping, optimizeForRenderToTexture, resizeSmoothly, filename);
    }

    public function new(context:AbstractContext, width:Int, height:Int, format = TextureFormat.RGBA, mipMapping = false, optimizeForRenderToTexture = false, resizeSmoothly = true, filename = "") {
        super(
            TextureType.CubeTexture,
            context,
            width,
            height,
            format,
            mipMapping,
            optimizeForRenderToTexture,
            resizeSmoothly,
            filename
        );
        _data = [];//(6))
        // keep only the GPU relevant size of each face
        _widthGPU = Math.floor(Math.min(MathUtil.clp2(width), MAX_SIZE));
        _heightGPU = Math.floor(Math.min(MathUtil.clp2(height), MAX_SIZE));
    }

    public function setData(data:Bytes, face:Face, widthGPU = -1, heightGPU = -1) {
//Debug.Assert(math.GlobalMembers.isp2(_widthGPU) && math.GlobalMembers.isp2(_heightGPU));

        _data[ face] = AbstractTexture.resizeData(_width, _height, data, _widthGPU, _heightGPU, _resizeSmoothly);
    }

    public override function resize(width, height, resizeSmoothly) {
//Debug.Assert(math.GlobalMembers.isp2(width) && math.GlobalMembers.isp2(height));

        var previousWidth = this.width;
        var previousHeight = this.height;

        for (faceId in 0... 6) {
            var previousData = _data[faceId];

            _data[faceId] = AbstractTexture.resizeData(previousWidth, previousHeight, previousData, width, height, resizeSmoothly);
        }

        _width = width << 2;
        _widthGPU = width;

        _height = height * 3;
        _heightGPU = height;
    }

    public function uploadMipLevel(level, data, face) {
        var width = (_widthGPU >> level);
        var height = (_heightGPU >> level);

        _context.uploadCubeTextureData(_id, face, width, height, level, data);
    }

    public override function upload() {
        if (_id == -1) {
            id = _context.createTexture(_type, _widthGPU, _heightGPU, _mipMapping, _optimizeForRenderToTexture);
        }

        var numFacePixels = _widthGPU * _heightGPU;
        if (numFacePixels == 0) {
            return;
        }

        for (faceId in 0...6) {
            var faceData:Bytes = _data[faceId];

//Debug.Assert(faceData.Count == (numFacePixels << 2));

            var face:Face = faceId;

            _context.uploadCubeTextureData(_id, face, _widthGPU, _heightGPU, 0, faceData);
        }

        //if (_mipMapping)
        //      _context.generateMipmaps(_id);
    }

    public override function dispose() {
        if (_id != -1) {
            _context.deleteTexture(_id);
            id = -1;
        }

        disposeData();
    }

    public override function disposeData() {
        for (face in _data) {
        }
        _data = null;
    }


}
