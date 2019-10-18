package minko.file;
import minko.file.AbstractStream.TextureBlobStream;
import minko.file.AbstractStream.TextureStream;
import minko.file.transcoder.PVRTranscoder;
import minko.file.transcoder.QTranscoder;
import minko.file.transcoder.CRNTranscoder;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import minko.render.AbstractTexture;
import minko.render.Texture;
import minko.render.TextureFilter;
import minko.render.TextureFormat;
import minko.render.TextureFormatInfo;
import minko.render.TextureType;
import minko.serialize.Types.ImageFormat;
import minko.StreamingCommon;
import minko.utils.MathUtil;
typedef FormatWriterFunction = AbstractTexture -> String -> WriterOptions -> TextureStream -> Bool

class TextureWriter extends AbstractWriter {


    static private var _formatWriterFunctions:IntMap<FormatWriterFunction> = init_formatWriterFunctions();

    static function init_formatWriterFunctions() {
        var tmp = new IntMap<FormatWriterFunction>();
        tmp.set(TextureFormat.RGB, writeRGBTexture.bind(TextureFormat.RGB));

        tmp.set(TextureFormat.RGBA, writeRGBATexture.bind(TextureFormat.RGBA));

        tmp.set(TextureFormat.RGB_DXT1, writeCRNCompressedTexture.bind(TextureFormat.RGB_DXT1));

        tmp.set(TextureFormat.RGBA_DXT1, writeCRNCompressedTexture.bind(TextureFormat.RGBA_DXT1));
        tmp.set(TextureFormat.RGBA_DXT3, writeCRNCompressedTexture.bind(TextureFormat.RGBA_DXT3));
        tmp.set(TextureFormat.RGBA_DXT5, writeCRNCompressedTexture.bind(TextureFormat.RGBA_DXT5));

        tmp.set(TextureFormat.RGB_ETC1, writePvrCompressedTexture.bind(TextureFormat.RGB_ETC1));

        tmp.set(TextureFormat.RGB_PVRTC1_2BPP, writePvrCompressedTexture.bind(TextureFormat.RGB_PVRTC1_2BPP));
        tmp.set(TextureFormat.RGB_PVRTC1_4BPP, writePvrCompressedTexture.bind(TextureFormat.RGB_PVRTC1_4BPP));

        tmp.set(TextureFormat.RGBA_PVRTC1_2BPP, writePvrCompressedTexture.bind(TextureFormat.RGBA_PVRTC1_2BPP));
        tmp.set(TextureFormat.RGBA_PVRTC1_4BPP, writePvrCompressedTexture.bind(TextureFormat.RGBA_PVRTC1_4BPP));
        tmp.set(TextureFormat.RGBA_PVRTC2_2BPP, writePvrCompressedTexture.bind(TextureFormat.RGBA_PVRTC2_2BPP));
        tmp.set(TextureFormat.RGBA_PVRTC2_4BPP, writePvrCompressedTexture.bind(TextureFormat.RGBA_PVRTC2_4BPP));

        tmp.set(TextureFormat.RGB_ATITC, writeQCompressedTexture.bind(TextureFormat.RGB_ATITC));

        tmp.set(TextureFormat.RGBA_ATITC, writeQCompressedTexture.bind(TextureFormat.RGBA_ATITC));
        return tmp;
    }

    static private var _defaultGamma = 2.2 ;


    private var _textureType:String;

    public static function create() {
        return new TextureWriter();
    }
    public var defaultGamma(get, null):Float;

    function get_defaultGamma() {
        return _defaultGamma;
    }
    public var textureType(null, set):String;

    function set_textureType(v) {
        _textureType = v;
        return v;
    }


    public function new() {

        super();
        this._textureType = "";
        _magicNumber = 0x00000054 | StreamingCommon.MINKO_SCENE_MAGIC_NUMBER;
    }

    public function gammaEncode(src:Bytes, dst:Bytes, gamma:Float) {
        dst = Bytes.alloc(src.length);

        for (i in 0...src.length) {
            dst[i] = (Math.pow(src[i] / 255.0, 1.0 / gamma) * 255.0);
        }
    }

    public function gammaDecode(src:Bytes, dst:Bytes, gamma:Float) {
        dst = Bytes.alloc(src.length);

        for (i in 0...src.length) {
            dst[i] = (Math.pow(src[i] / 255.0, gamma) * 255.0 );
        }
    }

    override public function embed(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency):AbstractStream {
        var stream:TextureStream = new TextureStream();
        var texture:AbstractTexture = cast _data;
        ensureTextureSizeIsValid(texture, writerOptions, _textureType);
        if (texture.type == TextureType.Texture2D && !writerOptions.useTextureSRGBSpace(_textureType)) {
            var texture2D:Texture = cast(texture);
            gammaDecode(texture2D.data, texture2D.data, defaultGamma);
        }

        var generateMipmaps = writerOptions.generateMipMaps(_textureType);
        var width:Int = texture.width;
        var height:Int = texture.height;
        var numFaces:Int = (texture.type == TextureType.Texture2D ? 1 : 6);
        var numMipmaps:Int = (generateMipmaps ? MathUtil.getp2(width) + 1 : 0);
        stream.width = width;
        stream.height = height;
        stream.numFaces = numFaces;
        stream.numMipmaps = numMipmaps;
        var textureFormats = writerOptions.textureFormats;
        for (textureFormat in textureFormats) {
            if (TextureFormatInfo.isCompressed(textureFormat) && !writerOptions.compressTexture(_textureType)) {
                continue;
            }
            var blobStream:TextureBlobStream = new TextureBlobStream();
            blobStream.textureFormat = (textureFormat);
            if (_formatWriterFunctions.get(textureFormat)(_data, _textureType, writerOptions, blobStream)) {
                stream.blobs.push(blobStream);
            }
            else {
                // TODO
                // handle error

            }
        }
        return stream ;
    }

    public function ensureTextureSizeIsValid(texture:AbstractTexture, writerOptions:WriterOptions, textureType:String) {
        var width = texture.width;
        var height = texture.height;

        var newWidth = width;
        var newHeight = height;

        if (writerOptions.generateMipMaps(_textureType) && newWidth != newHeight) {
            newWidth = newHeight = writerOptions.upscaleTextureWhenProcessedForMipMapping(_textureType) ? Math.max(newWidth, newHeight) : Math.min(newWidth, newHeight);
        }

        newWidth = (newWidth * writerOptions.textureScale(_textureType).x);
        newHeight = (newHeight * writerOptions.textureScale(_textureType).y);

        newWidth = Math.min(newWidth, writerOptions.textureMaxSize(_textureType).x);
        newHeight = Math.min(newHeight, writerOptions.textureMaxSize(_textureType).y);

        if (width != newWidth || height != newHeight) {
            texture.resize(newWidth, newHeight, writerOptions.textureFilter(textureType) == TextureFilter.LINEAR);
        }
    }

    public function writeRGBATexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:TextureBlobStream) {
        var _out = new BytesOutput();
        if (!PNGWriter.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }
        blob.textureData = (_out.getBytes());

        return true;
    }

    public function writeRGBTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:TextureBlobStream) {
        var _out = new BytesOutput();
        if (!JPGWriter.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }
        blob.textureData = (_out.getBytes());

        return true;
    }

    public function writePvrCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:TextureBlobStream) {
        var _out = new BytesOutput();
        if (!PVRTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }
        blob.textureData = (_out.getBytes());

        return true;
    }

    public function writeQCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:TextureBlobStream) {
        var _out = new BytesOutput();

        if (!QTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        blob.textureData = (_out.getBytes());

        return true;
    }

    public function writeCRNCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:TextureBlobStream) {
        var _out = new BytesOutput();


        if (!CRNTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }
        blob.textureData = (_out.getBytes());

        return true;
    }
}
