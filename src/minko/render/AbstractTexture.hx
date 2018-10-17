package minko.render;
import haxe.io.Bytes;
import minko.utils.MathUtil;
class AbstractTexture extends AbstractResource {
    public var MAX_SIZE = 4096;

    private var _type:TextureType;
    private var _sampler:TextureSampler;
    private var _format:TextureFormat;
    private var _width:Int;
    private var _height:Int;
    private var _widthGPU:Int; // always power of 2
    private var _heightGPU:Int; // always power of 2
    private var _mipMapping:Bool;
    private var _resizeSmoothly:Bool;
    private var _optimizeForRenderToTexture:Bool;
    private var _filename:String;
    public var sampler(get, null):TextureSampler;

    function get_sampler() {
        return _sampler;
    }

    override function set_id(v) {
        _id = v;
        _sampler.id = v;
        return _id;
    }
    public var type(get, null):TextureType;

    function get_type() {
        return _type;
    }

    public var format(get, null):TextureFormat;

    function get_format() {
        return _format;
    }

    public var width(get, null):Int;

    function get_width() {
        return _widthGPU;
    }

    public var height(get, null):Int;

    function get_height() {
        return _heightGPU;
    }

    public var originalWidth(get, null):Int;

    function get_originalWidth() {
        return _width;
    }

    public var originalHeight(get, null):Int;

    function get_originalHeight() {
        return _height;
    }
    public var mipMapping(get, null):Bool;

    function get_mipMapping() {
        return _mipMapping;
    }

    public function activateMipMapping() {
        if (_mipMapping) {
            return;
        }

        _mipMapping = true;

        _context.activateMipMapping(_id);
    }

    public var optimizeForRenderToTexture(get, null):Bool;

    function get_optimizeForRenderToTexture() {
        return _optimizeForRenderToTexture;
    }

    public function resize(width, height, resizeSmoothly) {

    }

    public function disposeData() {

    }


    /*static*/
    public function resizeData(width, height, data:Bytes, newWidth, newHeight, resizeSmoothly) {
//newData.Clear();
        var newData:Bytes = null;
        if (newWidth == 0 || newHeight == 0) {
            return data;
        }

        if (newWidth == width && newHeight == height) {
            newData = Bytes.alloc(width * height * 4);
            newData.blit(0, data, 0, width * height * 4);
            return data;
        }

        var size = newWidth * newHeight * 4;
        var xFactor = (width - 1.0) / (newWidth - 1.0);
        var yFactor = (height - 1.0) / (newHeight - 1.0);

        newData = Bytes.alloc(size);

        var idx = 0;
        var y = 0.0;
        for (q in 0...newHeight) {
            var j = Math.floor(y);
            var dy = y - j;

            if (j >= height) {
                j = height - 1;
            }

            var x = 0.0 ;
            for (p in 0...newWidth) {
                var i = Math.floor(x);

                if (i >= width) {
                    i = width - 1;
                }

                var ijTL = (i + width * j) << 2;

                if (resizeSmoothly) {
                    // bilinear interpolation

                    var dx = x - i;
                    var dxy = dx * dy;

                    var ijTR = i < width - 1 ? ijTL + 4 : ijTL;
                    var ijBL = j < height - 1 ? ijTL + (width << 2) : ijTL;
                    var ijBR = (i < width - 1) && (j < height - 1) ? ijTL + ((width + 1) << 2) : ijTL;

                    var wTL = 1.0 - dx - dy + dxy;
                    var wTR = dx - dxy;
                    var wBL = dy - dxy;
                    var wBR = dxy;

                    for (k in 0...4) {
                        var color = wTL * data.get(ijTL + k) + wTR * data.get(ijTR + k) + wBL * data.get(ijBL + k) + wBR * data.get(ijBR + k);

                        newData.set(idx + k, Math.floor(color));
                    }
                }
                else {
                    // nearest pixel color

                    for (k in 0... 4) {
                        newData.set(idx + k, data.get(ijTL + k));
                    }
                }

                idx += 4;
                x += xFactor;
            }
            y += yFactor;
        }
        return newData;
#if DEBUG_TEXTURE
				Debug.Assert(newData.Count == newWidth * newHeight * sizeof(int));
#end
    }

    public function new(type:TextureType, context:AbstractContext, width:Int, height:Int,
                        format:TextureFormat, mipMapping:Bool, optimizeForRenderToTexture:Bool, resizeSmoothly:Bool, filename:String) {
        super(context);
        this._sampler = new minko.render.TextureSampler(uuid, _id);
        this._type = (type);
        this._format = (format);
        this._width = width;
        this._height = height;
        this._widthGPU = Math.floor(Math.min(MathUtil.clp2(width), MAX_SIZE));
        this._heightGPU = Math.floor(Math.min(MathUtil.clp2(height), MAX_SIZE));
        this._mipMapping = mipMapping;
        this._resizeSmoothly = resizeSmoothly;
        this._optimizeForRenderToTexture = optimizeForRenderToTexture;
        this._filename = filename;
    }


    public function getMipmapWidth(level) {
//Debug.Assert(math.GlobalMembers.isp2(_widthGPU));

        var p = MathUtil.getp2(_widthGPU);
        return 1 << (p - level);
        // return uint(powf(2.0f, (log2f(_widthGPU) - level)))
    }

    public function getMipmapHeight(level) {
//Debug.Assert(math.GlobalMembers.isp2(_heightGPU));

        var p = MathUtil.getp2(_heightGPU);

        return 1 << (p - level);
    }

}
