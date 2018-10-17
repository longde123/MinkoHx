package minko.render;
import haxe.io.Bytes;
class RectangleTexture extends AbstractTexture {
    private var _data:Bytes ;

    public static function create(context:AbstractContext, width, height, format:TextureFormat, filename = "") {

        return new RectangleTexture(context, width, height, format, filename);
    }

    public function new(context:AbstractContext, width:Int, height:Int, format:TextureFormat, filename = "") {

        super(TextureType.Texture2D, context, width, height, format, false, false, false, filename);

    }
    public var data(get, null):Bytes;

    function get_data() {
        return _data;
    }

    public function setData(data:Bytes, widthGPU = -1, heightGPU = -1) {
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

        var size = _width * _height * 4;

        _data = Bytes.alloc(size);

        if (_format == TextureFormat.RGBA) {
            _data.blit(0, data, 0, size);
        }
        else if (_format == TextureFormat.RGB) {
            var i = 0, j = 0;
            while (j < size) {
                _data.set(j, data.get(i));
                _data.set(j + 1, data.get(i + 1));
                _data.set(j + 2, data.get(i + 2));
                _data.set(j + 3, 255);
                i += 3;
                j += 4;
            }
        }
    }

    public override function resize(width, height, resizeSmoothly) {
        var previousWidth = this.width;
        var previousHeight = this.height;

        var previousData = _data;

        _data = resizeData(previousWidth, previousHeight, previousData, width, height, resizeSmoothly);

        _width = width;
        _widthGPU = width;

        _height = height;
        _heightGPU = height;
    }

    public override function dispose() {
        if (_id != -1) {
            _context.deleteTexture(_id);
            _id = -1;
        }

        disposeData();
    }

    public override function disposeData() {
        _data = null;
    }

    public override function upload() {
        if (_id == -1) {
            _id = _context.createRectangleTexture(_type, _widthGPU, _heightGPU);
        }

        if (_data.length > 0) {
            _context.uploadTexture2dData(_id, _widthGPU, _heightGPU, 0, _data);
        }
    }

}
