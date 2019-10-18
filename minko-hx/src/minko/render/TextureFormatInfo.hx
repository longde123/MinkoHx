package minko.render;
import haxe.ds.IntMap;
@:expose("minko.render.Entry")
class Entry {
    public var _name:String;

    public var _isCompressed:Bool;

    public var _numBitsPerPixel:Int;

    public var _minimumSize:Int;

    public var _hasAlphaChannel:Bool;
    public var _hasSeparateAlphaChannel:Bool;

    public function new(name, isCompressed, numBitsPerPixel, minimumSize, hasAlphaChannel, hasSeparateAlphaChannel) {
        this._name = name;
        this._isCompressed = isCompressed;
        this._numBitsPerPixel = numBitsPerPixel;
        this._minimumSize = minimumSize;
        this._hasAlphaChannel = hasAlphaChannel;
        this._hasSeparateAlphaChannel = hasSeparateAlphaChannel;
    }
}
@:expose("minko.render.TextureFormatInfo")
class TextureFormatInfo {
    private static var _formats:IntMap< Entry> = initializeFormatsMap();

    public static function initializeFormatsMap() {
        var m:IntMap< Entry> = new IntMap< Entry>();
        m.set(TextureFormat.RGB, new Entry("RGB", false, 24, 3, false, false));
        m.set(TextureFormat.RGBA, new Entry("RGBA", false, 32, 4, true, false));

        m.set(TextureFormat.RGB_DXT1, new Entry("RGB_DXT1", true, 4, 8, false, false));
        m.set(TextureFormat.RGBA_DXT1, new Entry("RGBA_DXT1", true, 4, 8, true, false));
        m.set(TextureFormat.RGBA_DXT3, new Entry("RGBA_DXT3", true, 8, 16, true, false));
        m.set(TextureFormat.RGBA_DXT5, new Entry("RGBA_DXT5", true, 8, 16, true, false));

        m.set(TextureFormat.RGB_ETC1, new Entry("RGB_ETC1", true, 4, 8, false, false));
        m.set(TextureFormat.RGBA_ETC1, new Entry("RGBA_ETC1", true, 4, 8, true, true));

        m.set(TextureFormat.RGB_PVRTC1_2BPP, new Entry("RGB_PVRTC1_2BPP", true, 2, 32, false, false));
        m.set(TextureFormat.RGB_PVRTC1_4BPP, new Entry("RGB_PVRTC1_4BPP", true, 4, 32, false, false));
        m.set(TextureFormat.RGBA_PVRTC1_2BPP, new Entry("RGBA_PVRTC1_2BPP", true, 2, 32, true, false));
        m.set(TextureFormat.RGBA_PVRTC1_4BPP, new Entry("RGBA_PVRTC1_4BPP", true, 4, 32, true, false));

        m.set(TextureFormat.RGBA_PVRTC2_2BPP, new Entry("RGBA_PVRTC2_2BPP", true, 2, 32, true, false));
        m.set(TextureFormat.RGBA_PVRTC2_4BPP, new Entry("RGBA_PVRTC2_4BPP", true, 4, 32, true, false));

        m.set(TextureFormat.RGB_ATITC, new Entry("RGB_ATITC", true, 8, 16, false, false));
        m.set(TextureFormat.RGBA_ATITC, new Entry("RGBA_ATITC", true, 8, 16, true, false));
        return m;
    }

    public static function isSupported(format:TextureFormat) {
        //var availableFormats = WebGlContext.availableTextureFormats();

        // return availableFormats.exists(format)  ;
        return false;
    }

    public static function textureSize(format:TextureFormat, width, height) {
        return Math.floor(Math.max(minimumSize(format), numBitsPerPixel(format) / 8.0 * width * height));
    }

    public static function name(format:TextureFormat) {
        return _formats.get(format)._name;
    }

    public static function isCompressed(format:TextureFormat) {
        return _formats.get(format)._isCompressed;
    }

    public static function numBitsPerPixel(format:TextureFormat) {
        return _formats.get(format)._numBitsPerPixel;
    }

    public static function minimumSize(format:TextureFormat) {
        return _formats.get(format)._minimumSize;
    }

    public static function hasAlphaChannel(format:TextureFormat) {
        return _formats.get(format)._hasAlphaChannel;
    }

    public static function hasSeparateAlphaChannel(format:TextureFormat) {
        return _formats.get(format)._hasSeparateAlphaChannel;
    }
    public static var textureFormats(get, null):Array<TextureFormat>;

    public static function get_textureFormats() {
        var formats = [];

        for (textureFormat in _formats.keys()) {
            formats.push(textureFormat);
        }

        return formats;
    }
}
