package minko.file;
import minko.file.AbstractStream.POPTextureLodHeader;
import minko.file.transcoder.CRNTranscoder;
import minko.file.transcoder.QTranscoder;
import minko.file.transcoder.PVRTranscoder;
import minko.file.AbstractStream.POPTextureHeader;
import minko.file.AbstractStream.POPTextureStream;
import minko.file.AbstractStream.POPTextureFormatHeader;
import minko.file.TextureWriter.FormatWriterFunction;
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
typedef StreamedFormatWriterFunction = AbstractTexture -> String -> WriterOptions  -> Array<Bytes> -> Bool;
class StreamedTextureWriter extends AbstractWriter  {

    //TextureFormat typedef FormatWriterFunction = AbstractTexture -> String -> WriterOptions -> TextureStream -> Bool
    private static var _formatWriterFunctions:IntMap<StreamedFormatWriterFunction> = init_formatWriterFunctions();

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

    override public function write(filename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Array<SerializedAsset>):Void {
    }

    override public function embedAll(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Array<SerializedAsset>):Bytes {
    }


    override public function embed(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency):AbstractStream {
        if (!writerOptions.generateMipMaps(_textureType)) {
            writerOptions.generateMipMapsValue(_textureType, true);
        }
        var blobStream:POPTextureStream=new POPTextureStream();
        var texture:AbstractTexture = _data;

        if (texture.type == TextureType.Texture2D && !writerOptions.useTextureSRGBSpace(_textureType)) {
            var texture2D:Texture = cast(texture);

            TextureWriter.gammaDecode(texture2D.data, texture2D.data, TextureWriter.defaultGamma);
        }

        ensureTextureSizeIsValid(texture, writerOptions, _textureType);

        var textureFormats = writerOptions.textureFormats ;

        var linkedAsset = _linkedAsset;
        var linkedAssetId = _linkedAssetId;


        for (textureFormat in textureFormats) {
            if (TextureFormatInfo.isCompressed(textureFormat) && !writerOptions.compressTexture(_textureType)) {
                continue;
            }

            var formatHeader = new POPTextureFormatHeader();

            formatHeader.textureFormat = textureFormat;
            var textureLodHeader= new POPTextureLodHeader();
            if (!_formatWriterFunctions.get(textureFormat)(_data, _textureType, writerOptions,  textureLodHeader.mipLevelDatas)) {
                // TODO
                // handle error
            }
            else {
                blobStream.formatHeaders.push(formatHeader);
                blobStream.lodDatas.push(textureLodHeader);
            }
        }

        var width = texture.width;
        var height = texture.height;
        var numFaces = (texture.type == TextureType.Texture2D ? 1 : 6);
        var numMipMaps = (writerOptions.generateMipMaps(_textureType) && texture.width == texture.height ? MathUtil.getp2(texture.width) + 1 : 0);

        var textureHeaderData = new POPTextureHeader();
        textureHeaderData.width=(width);
        textureHeaderData.height=(height);
        textureHeaderData.numFaces=(numFaces);
        textureHeaderData.numMipMaps=(numMipMaps);
        textureHeaderData.linkedAssetId=(linkedAssetId);

        blobStream.header=textureHeaderData;

        if (linkedAsset != null && linkedAsset.linkType == LinkedAsset.LinkType.Internal) {
//            linkedAsset.length = blobStream.length;
//            linkedAsset.data = blobStream.getBytes();
        }
        else {
//            result.writeOneBytes(blobStream.getBytes());
        }

        return blobStream;
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

    public function writeMipLevels(textureFormat:TextureFormat, textureWidth, textureHeight, _data:BytesOutput, mipLevels:Array<Bytes>) {
        var data=_data.getBytes();
        var numMipMaps = MathUtil.getp2(Math.floor(Math.max(textureWidth, textureHeight))) + 1;
        for (i in 0...numMipMaps) {
            var mipLevelWidth = Math.max(textureWidth >> i, 1);
            var mipLevelHeight = Math.max(textureHeight >> i, 1);
            var mipLevelDataSize = TextureFormatInfo.textureSize(textureFormat, mipLevelWidth, mipLevelHeight);
            //todo mipLevelDataSize
            var mipLevelData =  AbstractTexture.resizeData(textureWidth,textureHeight,data,mipLevelWidth, mipLevelHeight, true);
            mipLevels.push(mipLevelData);
        }

        return true;
    }

    public function writeRGBATexture(abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions,  mipLevels:Array<Bytes>) {
        var textureFormat = TextureFormat.RGBA;
        var imageFormat = writerOptions.imageFormat;
        var texture:Texture = cast(abstractTexture);
        mipLevels=texture.data;
        return true;
    }

    public function writePvrCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, mipLevels:Array<Bytes>) {
        var _out = new BytesOutput();

        if (!PVRTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        if (!writeMipLevels(textureFormat, abstractTexture.width, abstractTexture.height, _out, mipLevels)) {
            return false;
        }

        return true;
    }

    public function writeQCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, mipLevels:Array<Bytes>) {
        var _out = new BytesOutput();

        if (!QTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        if (!writeMipLevels(textureFormat, abstractTexture.width, abstractTexture.height, _out, mipLevels)) {
            return false;
        }

        return true;
    }

    public function writeCRNCompressedTexture(textureFormat:TextureFormat, abstractTexture:AbstractTexture, textureType:String, writerOptions:WriterOptions, mipLevels:Array<Bytes>) {
        var _out = new BytesOutput();

        if (!CRNTranscoder.transcode(abstractTexture, textureType, writerOptions, textureFormat, _out)) {
            return false;
        }

        if (!writeMipLevels(textureFormat, abstractTexture.width, abstractTexture.height, _out, mipLevels)) {
            return false;
        }

        return true;
    }

}
