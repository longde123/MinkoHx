package minko.render;
import Array;
import haxe.io.Bytes;
import minko.utils.MathUtil;
@:expose("minko.render.Texture")
class Texture extends AbstractTexture {
    private var _data:Array<Bytes>;

    public static function create(context:AbstractContext, width, height, mipMapping = false, optimizeForRenderToTexture = false, resizeSmoothly = true, format = TextureFormat.RGBA, filename = ""):Texture {

        return new Texture(context, width, height, mipMapping, optimizeForRenderToTexture, resizeSmoothly, format, filename);
    }
    public var data(get, null):Array<Bytes>;

    function get_data() {
        return _data;
    }

    public function setData(data:Bytes, widthGPU, heightGPU) {
        if (widthGPU >= 0) {
            if (widthGPU > MAX_SIZE) {
                throw ("widthGPU");
            }

            _width = widthGPU;
            _widthGPU = widthGPU;
        }
        if (heightGPU >= 0) {
            if (heightGPU > MAX_SIZE) {
                throw ("heightGPU");
            }

            _height = heightGPU;
            _heightGPU = heightGPU;
        }

        // Debug.Assert(math.isp2(_widthGPU) && math.isp2(_heightGPU));

        if (!TextureFormatInfo.isCompressed(_format)) {
            var size = _width * _height * 4;

            var rgba = Bytes.alloc(size);

            if (_format == TextureFormat.RGBA) {
                rgba.blit(0, data, 0, size);
            }
            else if (_format == TextureFormat.RGB) {
                _format = TextureFormat.RGBA;
                var i = 0, j = 0;
                while (j < size) {
                    rgba.set(j, data.get(i));
                    rgba.set(j + 1, data.get(i + 1));
                    rgba.set(j + 2, data.get(i + 2));
                    rgba.set(j + 3, 255);
                    i += 3;
                    j += 4;
                }
            }

            rgba = AbstractTexture.resizeData(_width, _height, rgba, _widthGPU, _heightGPU, _resizeSmoothly);
            _data.push(rgba);
        }
        else {
            var size = TextureFormatInfo.textureSize(_format, _width, _height);
            var rgb = Bytes.alloc(size);
            rgb.blit(0, data, 0, size);
            _data.push(rgb);
        }
    }

    override public function resize(width, height, resizeSmoothly) {
//Debug.Assert(math.isp2(width) && math.isp2(height));

        var previousWidth = this.width;
        var previousHeight = this.height;

        var previousNumMipMaps = data.length > TextureFormatInfo.textureSize(_format, previousWidth, previousHeight) ? MathUtil.getp2(previousWidth) + 1 : 1;

        var numMipMaps = previousNumMipMaps > 1 ? MathUtil.getp2(width) + 1 : 1;


        var newData = [];

        for (i in 0... numMipMaps) {
            var mipMapData:Bytes =data[i];
            var mipMapPreviousWidth = Math.floor(Math.max(previousWidth >> i, 1));
            var mipMapPreviousHeight = Math.floor(Math.max(previousHeight >> i, 1));
            var mipMapWidth = width >> i;
            var mipMapHeight = height >> i;
            var newMipMapData:Bytes = AbstractTexture.resizeData(mipMapPreviousWidth, mipMapPreviousHeight, mipMapData, mipMapWidth, mipMapHeight, resizeSmoothly);
            newData.push(newMipMapData);
        }

        _data = newData;

        _width = width;
        _widthGPU = width;

        _height = height;
        _heightGPU = height;
    }


    public override function dispose() {
        if (_id != -1) {
            _context.deleteTexture(_id);
            id = -1;
        }

        disposeData();
    }

    public override function disposeData() {
        _data = null;
    }

    public override function upload() {
        if (_id == -1) {
            if (TextureFormatInfo.isCompressed((_format))) {
                id = _context.createCompressedTexture(_type, (_format), _widthGPU, _heightGPU, _mipMapping);
            }
            else {
                id = _context.createTexture(_type, _widthGPU, _heightGPU, _mipMapping, _optimizeForRenderToTexture);
            }
        }

        if (_data.length > 0) {
            if (TextureFormatInfo.isCompressed((_format))) {
                _context.uploadCompressedTexture2dData(_id, (_format), _widthGPU, _heightGPU, _data.length, 0, _data[0]);
            }
            else {
                _context.uploadTexture2dData(_id, _widthGPU, _heightGPU, 0, _data[0]);

                if (_mipMapping) {
                    _context.generateMipmaps(_id);
                }
            }
        }
    }

    public function uploadMipLevel(level, data:Bytes ) {
        var width = (_widthGPU >> level);
        var height = (_heightGPU >> level);

        if (TextureFormatInfo.isCompressed((_format))) {
            var size = TextureFormatInfo.textureSize((_format), width, height);

            _context.uploadCompressedTexture2dData(_id, (_format), width, height, size, level, data);
        }
        else {
            _context.uploadTexture2dData(_id, width, height, level, data);
        }
    }

    public function new(context:AbstractContext, width, height, mipMapping = false, optimizeForRenderToTexture = false, resizeSmoothly = true, format = TextureFormat.RGBA, filename = "") {
        super(TextureType.Texture2D, context, width, height, format, mipMapping, optimizeForRenderToTexture, resizeSmoothly, filename);
        this._data = [];

    }
}
