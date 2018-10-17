package minko.file;
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
typedef FormatWriterFunction = AbstractTexture -> String -> WriterOptions -> Bytes -> Bool

class TextureWriter extends AbstractWriter<Texture> {


    static private var _formatWriterFunctions:IntMap<FormatWriterFunction> = init_formatWriterFunctions();

    static function init_formatWriterFunctions() {
        var tmp = new IntMap<FormatWriterFunction>();
        tmp.set(TextureFormat.RGB, writeRGBATexture);
        tmp.set(TextureFormat.RGBA, writeRGBATexture);
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

    override public function embed(assetLibrary:AssetLibrary, options:Options, dependency:Dependency, writerOptions:WriterOptions, embeddedHeaderData:BytesOutput) {
        var texture:AbstractTexture = cast _data;
        ensureTextureSizeIsValid(texture, writerOptions, _textureType);
        if (texture.type == TextureType.Texture2D && !writerOptions.useTextureSRGBSpace(_textureType)) {
            var texture2D:Texture = cast(texture);
            gammaDecode(texture2D.data, texture2D.data, defaultGamma);
        }

        var generateMipmaps = writerOptions.generateMipMaps(_textureType);
        var textureFormats = writerOptions.textureFormats;
        var headerStream = new BytesOutput();
        var formatStream = new BytesOutput();
        var blobStream = new BytesOutput();

        formatStream.writeInt32(textureFormats.length);

        for (textureFormat in textureFormats) {
            if (TextureFormatInfo.isCompressed(textureFormat) && !writerOptions.compressTexture(_textureType)) {
                continue;
            }
            var offset = blobStream.length;
            if (_formatWriterFunctions.get(textureFormat)(_data, _textureType, writerOptions, blobStream)) {
                var length = blobStream.length - offset;
                formatStream.writeInt32(textureFormat);
                formatStream.writeInt32(offset);
                formatStream.writeInt32(length);
            }
            else {
                // TODO
                // handle error

            }
        }
        var width = texture.width;
        var height = texture.height;
        var numFaces = (texture.type == TextureType.Texture2D ? 1 : 6);
        var numMipmaps = (generateMipmaps ? MathUtil.getp2(width) + 1 : 0);
        headerStream.writeInt32(width);
        headerStream.writeInt32(height);
        headerStream.writeInt8(numFaces);
        headerStream.writeInt8(numMipmaps);
        var result = new BytesOutput();
        result.writeBytes(headerStream);
        result.writeBytes(formatStream);
        result.writeBytes(blobStream);
        return result ;
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

    public function writeRGBATexture(abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput) {
        var imageFormat = writerOptions.imageFormat ;

        var texture:Texture = cast (abstractTexture);

        var textureData = new BytesOutput();

        switch (imageFormat)
        {
            case ImageFormat.PNG:
                {
                    var writer = PNGWriter.create();

                    writer.writeToStream(textureData, texture.data , texture.width, texture.height);

                    break;
                }
            default:
                return false;
        }

        blob.writeInt8(imageFormat);
        blob.writeBytes(textureData.getBytes());


        return true;
    }

    public function writePvrCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput) {
        var _out = new BytesOutput();

        if (!PVRTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out, {PVRTranscoder.Options.fastCompression})) {
            return false;
        }

        blob.writeBytes(_out);

        return true;
    }

    public function writeQCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput) {
        var _out = new BytesOutput();

        if (!QTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        blob.writeBytes(_out);

        return true;
    }

    public function writeCRNCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput) {
        var _out = new BytesOutput();


        if (!CRNTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        blob.writeBytes(_out);

        return true;
    }
}
