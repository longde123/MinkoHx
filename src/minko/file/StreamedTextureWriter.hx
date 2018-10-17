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
import minko.StreamingCommon;
import minko.utils.MathUtil;
using minko.utils.BytesTool;
typedef FormatWriterFunction = AbstractTexture -> String -> WriterOptions -> BytesOutput -> Array<Tuple<Int, Int>> -> Bool;
class StreamedTextureWriter extends AbstractWriter<AbstractTexture> {

    //TextureFormat
    private static var _formatWriterFunctions:IntMap<FormatWriterFunction> = init_formatWriterFunctions();

    private var _textureType:String;

    private var _linkedAsset:LinkedAsset;
    private var _linkedAssetId:Int;

    public static function create() {
        var instance = (new StreamedTextureWriter());

        return instance;
    }
    public var textureType(null, set):String;

    function set_textureType(value) {
        _textureType = value;
    }

    public function linkedAsset(linkedAsset:LinkedAsset, linkedAssetId:Int) {
        _linkedAsset = linkedAsset;

        _linkedAssetId = linkedAssetId;
    }

    private static function init_formatWriterFunctions() {
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
        tmp.set(TextureFormat.RGB_ATITC, writeQCompressedTexture.bind(extureFormat.RGB_ATITC));
        tmp.set(TextureFormat.RGBA_ATITC, writeQCompressedTexture.bind(TextureFormat.RGBA_ATITC));
    }

    public function new() {

        super();
        this._textureType = "";
        _magicNumber = 0x00000055 | StreamingCommon.MINKO_SCENE_MAGIC_NUMBER;
    }

    public function embed(assetLibrary:AssetLibrary, options:Options, dependency:Dependency, writerOptions:WriterOptions, embeddedHeaderData:BytesOutput) {
        if (!writerOptions.generateMipMaps(_textureType)) {
            writerOptions.generateMipMapsValue(_textureType, true);
        }

        var texture = _data;

        if (texture.type == TextureType.Texture2D && !writerOptions.useTextureSRGBSpace(_textureType)) {
            var texture2D:Texture = cast(texture);

            TextureWriter.gammaDecode(texture2D.data, texture2D.data, TextureWriter.defaultGamma);
        }

        ensureTextureSizeIsValid(texture, writerOptions, _textureType);

        var textureFormats = writerOptions.textureFormats ;

        var linkedAsset = _linkedAsset;
        var linkedAssetId = _linkedAssetId;

        var headerStream = new BytesOutput();
        var blobStream = new BytesOutput();

        var headerData = new BytesOutput();
//msgpack.type.tuple< uint, msgpack.type.tuple<int, int, byte, byte>, List<msgpack.type.tuple<int, List<msgpack.type.tuple<int, int>>>>>();

        var formatHeaders = new BytesOutput();
        //new List<msgpack.type.tuple<int, List<msgpack.type.tuple<int, int>>>>();

        for (textureFormat in textureFormats) {
            if (TextureFormatInfo.isCompressed(textureFormat) && !writerOptions.compressTexture(_textureType)) {
                continue;
            }

            var formatHeader = new Tuple<Int, Array<Tuple<Int, Int>>>();

            formatHeader.first = textureFormat;

            if (!_formatWriterFunctions.get(textureFormat)(_data, _textureType, writerOptions, blobStream, formatHeader.second)) {
                // TODO
                // handle error
            }
            else {
                formatHeaders.writeInt32(formatHeader.first);
                formatHeaders.writeInt32(formatHeader.second.length);
                for (i in 0...formatHeader.second.length) {
                    var f = formatHeader.second[i];
                    formatHeaders.writeInt32(f.first);
                    formatHeaders.writeInt32(f.second);
                }
            }
        }

        var width = texture.width;
        var height = texture.height;
        var numFaces = (texture.type == TextureType.Texture2D ? 1 : 6);
        var numMipMaps = (writerOptions.generateMipMaps(_textureType) && texture.width == texture.height ? MathUtil.getp2(texture.width) + 1 : 0);

        var textureHeaderData = new BytesOutput();
        textureHeaderData.writeInt32(width)
        textureHeaderData.writeInt32(height)
        textureHeaderData.writeInt32(numFaces)
        textureHeaderData.writeInt32(numMipMaps);

        headerData.writeInt32(linkedAssetId);
        headerData.writeOneBytes(textureHeaderData.getBytes());
        headerData.writeOneBytes(formatHeaders);

        headerStream.writeOneBytes(headerData.getBytes());


        var result:BytesOutput = new BytesOutput();

        embeddedHeaderData.writeOneBytes(headerStream);

        if (linkedAsset != null && linkedAsset.linkType == LinkedAsset.LinkType.Internal) {
            linkedAsset.length = blobStream.length;
            linkedAsset.data = blobStream.getBytes();
        }
        else {
            result.writeOneBytes(blobStream.getBytes());
        }

        return result;
    }

    public function ensureTextureSizeIsValid(texture:AbstractTexture, writerOptions:WriterOptions, textureType:String) {
        var width = texture.width;
        var height = texture.height;

        var newWidth = width;
        var newHeight = height;

        if (newWidth != newHeight) {
            newWidth = newHeight = writerOptions.upscaleTextureWhenProcessedForMipMapping(_textureType) ? Math.max(newWidth, newHeight) : Math.min(newWidth, newHeight);
        }

        newWidth = (newWidth * writerOptions.textureScale(_textureType).x);
        newHeight = (newHeight * writerOptions.textureScale(_textureType).y);

        newWidth = Math.floor(Math.min(newWidth, writerOptions.textureMaxSize(_textureType).x));
        newHeight = Math.floor(Math.min(newHeight, writerOptions.textureMaxSize(_textureType).y));

        if (width != newWidth || height != newHeight) {
            texture.resize(newWidth, newHeight, writerOptions.textureFilter(textureType) == TextureFilter.LINEAR);
        }
    }

    public function writeMipLevels(textureFormat:TextureFormat, textureWidth, textureHeight, data:BytesOutput, mipLevels:Array<Tuple<Int, Int>>, blob:BytesOutput) {
        var numMipMaps = MathUtil.getp2(Math.floor(Math.max(textureWidth, textureHeight))) + 1;

        //todo
        //mipLevels.Resize(numMipMaps);

        var dataOffset = 0;
        var serializedDataOffset = blob.length;

        for (i in 0...numMipMaps) {
            var previousBlobSize = blob.length;

            var mipLevelWidth = Math.max(textureWidth >> i, 1);
            var mipLevelHeight = Math.max(textureHeight >> i, 1);

            var mipLevelDataSize = TextureFormatInfo.textureSize(textureFormat, mipLevelWidth, mipLevelHeight);

            var mipLevelData = Bytes.alloc(mipLevelDataSize);
            data.writeFullBytes(mipLevelData, dataOffset, mipLevelDataSize);
            blob.writeOneBytes(mipLevelData);

            var mipLevelSerializedDataSize = blob.length - previousBlobSize;

            mipLevels[i].first = serializedDataOffset;
            mipLevels[i].second = mipLevelSerializedDataSize;

            dataOffset += mipLevelDataSize;
            serializedDataOffset += mipLevelSerializedDataSize;
        }

        return true;
    }

    public function writeRGBATexture(abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput, mipLevels:Array<Tuple<Int, Int>>) {
        var textureFormat = TextureFormat.RGBA;

        var imageFormat = writerOptions.imageFormat;

        var texture:Texture = cast(abstractTexture);

        var baseWidth = texture.width;
        var baseHeight = texture.height;

        var mipLevelTemplate = Texture.create(texture.context, baseWidth, baseHeight, false, false, true);

        mipLevelTemplate.data = (texture.data);

        var numMipLevels = MathUtil.getp2(baseWidth) + 1;
        //todo
        //mipLevels.Resize(numMipLevels);

        var serializedDataOffset = blob.length;

        for (i in 0... numMipLevels) {
            var previousBlobSize = blob.length;

            var mipLevelWidth = Math.max(baseWidth >> i, 1);
            var mipLevelHeight = Math.max(baseHeight >> i, 1);

            mipLevelTemplate.resize(mipLevelWidth, mipLevelHeight, true);

            var mipLevelData = new BytesOutput();

            var writer = PNGWriter.create();

            writer.writeToStream(mipLevelData, mipLevelTemplate.data, mipLevelWidth, mipLevelHeight);

            blob.writeOneBytes(mipLevelData.getBytes());

            var mipLevelSerializedDataSize = blob.length - previousBlobSize;

            mipLevels[i].first = serializedDataOffset;
            mipLevels[i].second = mipLevelSerializedDataSize;

            serializedDataOffset += mipLevelSerializedDataSize;
        }

        return true;
    }

    public function writePvrCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput, mipLevels:Array<Tuple<Int, Int>>) {
        var _out = new BytesOutput();

        if (!PVRTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out, PVRTranscoder.Options.fastCompression)) {
            return false;
        }

        if (!writeMipLevels(textureFormat, abstractTexture.width, abstractTexture.height, _out, mipLevels, blob)) {
            return false;
        }

        return true;
    }

    public function writeQCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput, mipLevels:Array<Tuple<Int, Int>>) {
        var _out = new BytesOutput();

        if (!QTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        if (!writeMipLevels(textureFormat, abstractTexture.width(), abstractTexture.height(), _out, mipLevels, blob)) {
            return false;
        }

        return true;
    }

    public function writeCRNCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, blob:BytesOutput, mipLevels:Array<Tuple<Int, Int>>) {
        var _out = new BytesOutput();

        if (!CRNTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        if (!writeMipLevels(textureFormat, abstractTexture.width(), abstractTexture.height(), _out, mipLevels, blob)) {
            return false;
        }

        return true;
    }

}
