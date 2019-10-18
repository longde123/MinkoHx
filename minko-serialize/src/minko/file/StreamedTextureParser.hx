package minko.file;
import minko.render.GlContext;
import haxe.io.BytesOutput;
import minko.render.TextureFormatInfo;
import minko.file.AbstractStream.POPTextureFormatHeader;
import minko.file.AbstractStream.POPTextureHeader;
import glm.Vec2;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.render.AbstractTexture;
import minko.render.Texture;
import minko.render.TextureFormat;
import minko.render.TextureType;

class DataChunk {

    public var data:Bytes;
    public var offset:Int;
    public var size:Int;

    public function new(data, offset, size) {
        this.data = data;
        this.offset = offset;
        this.size = size;
    }
}
class StreamedTextureParser extends AbstractStreamedAssetParser {
    private var _texture:AbstractTexture;

    private var _textureType:TextureType;
    private var _textureFormat:TextureFormat;
    private var _textureWidth:Int;
    private var _textureHeight:Int;
    private var _textureNumFaces:Int;
    private var _textureNumMipmaps:Int;
    private var _mipLevelsInfo:Array<POPTextureFormatHeader> ;

    public static function create() {
        return new StreamedTextureParser();
    }


    public function new() {

        super();
        this._texture = null;
        this._textureType = TextureType.Texture2D;
        this._textureFormat = TextureFormat.RGBA;
        this._textureWidth = 0;
        this._textureHeight = 0;
        this._textureNumFaces = 0;
        this._textureNumMipmaps = 0;
        this._mipLevelsInfo = new Array<Tuple<Int, Int>>();
        assetExtension = (0x00000055);
    }

    override public function useDescriptor(filename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        return false;
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {

        _texture = createTexture(assetLibrary, filename, _textureType);

        if (_texture == null) {
            trace("failed to create texture from " + filename);
            _error.execute(this, ("StreamedTextureParsingError" + "streamed texture parsing error"));
            return;
        }

        if (deferParsing) {
            var textureReference = _dependency.getTextureReference(dependencyId);
            textureReference.texture = _texture;
            for (materialData in textureReference.dependentMaterialDataSet) {
                materialData.set(textureReference.textureType, textureReference.texture);
            }

            streamingOptions.masterLodScheduler.doDeferredTextureReady(this.data, textureReference.dependentMaterialDataSet, textureReference.textureType, textureReference.texture);
        }
    }

    public function createTexture(assetLibrary:AssetLibrary, filename:String, textureType:TextureType):AbstractTexture {
        switch (textureType)
        {
            case TextureType.Texture2D:
                {
                    var width = _textureWidth;
                    var height = _textureHeight;

                    var texture2d:Texture = Texture.create(assetLibrary.context, width, height, true, false, false, _textureFormat, filename);

                    _texture = texture2d;

                    texture2d.upload();

                    if (streamingOptions.streamedTextureFunction) {
                        texture2d = cast(streamingOptions.streamedTextureFunction(filename, texture2d));
                    }

                    assetLibrary.texture(filename, texture2d);

                    data.set("size", new Vec2(width, height));

                    data.set("maxAvailableLod", 0);
                    data.set("maxLod", maxLod);

                }
            case TextureType.CubeTexture:

                return null;
        }

        return _texture;
    }


    override public function headerParsed(data:Bytes, options:Options, linkedAssetId:Int):Void {
        //ref
        var header:POPTextureHeader = null;

        linkedAssetId = header.linkedAssetId;

        _textureWidth = header.width;
        _textureHeight = header.height;
        _textureNumFaces = header.numFaces;
        _textureNumMipmaps = header.numMipMaps;
        _textureType = _textureNumFaces == 1 ? TextureType.Texture2D : TextureType.CubeTexture;
        var formatHeaders:Array<POPTextureFormatHeader> = [];

        var availableTextureFormats = new Array<TextureFormat>();

        for (formatHeader in formatHeaders) {
            availableTextureFormats.push(formatHeader.textureFormat);
        }

        _textureFormat = matchingTextureFormat(options, availableTextureFormats);


        var formatHeader = formatHeaders.filter(function(entry:POPTextureFormatHeader) {
            return entry.textureFormat == _textureFormat;
        });

        _mipLevelsInfo = formatHeader;


    }

    public function extractLodData(format:TextureFormat, filename:String, options:Options, assetLibrary:AssetLibrary, lodData:DataChunk, extractedLodData:BytesOutput):Void {
        if (TextureFormatInfo.isCompressed(format)) {
            return false;
        }
        switch (format)
        {
            case TextureFormat.RGB:
            case TextureFormat.RGBA:
                {
                    var localAssetLibrary = AssetLibrary.create(assetLibrary.context());
                    var parser = PNGParser.create();
                    var parserOptions = options.clone().disposeTextureAfterLoading(false);

                    var p:BytesInput = new BytesInput(lodData.data);
                    var tmp:Bytes = Bytes.alloc(lodData.size);
                    p.readFullBytes(tmp, lodData.offset, lodData.size);

                    parser.parse(filename, filename, parserOptions, tmp, localAssetLibrary);
                    var mipLevelTexture = localAssetLibrary.texture(filename);
                    extractedLodData.writeFullBytes(mipLevelTexture.data, 0, mipLevelTexture.data.length) ;
                    mipLevelTexture.dispose();
                    break;
                }
            default:
                return false;
        }

        return true;
    }

    override public function lodParsed(previousLod:Int, currentLod:Int, data:Bytes, options:Options) {
        var dataOffset = 0 ;
        for (lod in (previousLod + 1)... currentLod) {
            var mipLevel = lodToMipLevel(lod);
            var mipLevelInfo = _mipLevelsInfo[mipLevel];
            var mipLevelDataSize = mipLevelInfo.blobSize;
            dataOffset += mipLevelDataSize;
            var mipLevelData = data;
            var extractedLodData:BytesOutput = new BytesOutput();
            if (extractLodData(_textureFormat, "", options, options.assetLibrary, new DataChunk(mipLevelData, dataOffset, mipLevelDataSize), extractedLodData)) {
                mipLevelData = extractedLodData.getBytes()
                mipLevelDataSize = mipLevelData.length;
            }

            switch (_textureType)
            {
                case TextureType.Texture2D:
                    {
                        var texture2d:Texture = cast(_texture);

                        texture2d.uploadMipLevel(mipLevel, (mipLevelData));
                        if (mipLevel == 0) {
                            var storeTextureData = !options.disposeTextureAfterLoading ;
                            if (storeTextureData) {
                                texture2d.data[lod] = (mipLevelData);
                            }
                        }
                        break;
                    }
                case TextureType.CubeTexture:

                    break;
            }
        }
        this.data.set("maxAvailableLod", currentLod);
    }

    public function matchingTextureFormat(options:Options, availableTextureFormats:Array<TextureFormat>) {
        var contextAvailableTextureFormats = GlContext.availableTextureFormats;
        var filteredAvailableTextureFormats = [];
        for (textureFormat in contextAvailableTextureFormats) {
            if (availableTextureFormats.indexOf(textureFormat) != 0) {
                filteredAvailableTextureFormats.push(textureFormat);

            }
        }
        return options.textureFormatFunction(filteredAvailableTextureFormats);
    }

    public function complete(currentLod) {
        return lodToMipLevel(currentLod) == 0;
    }

    override public function completed() {
    }

    public function lodToMipLevel(lod) {
        return (_textureNumMipmaps - 1) - lod;
    }

    override public function lodRangeFetchingBound(currentLod:Int, requiredLod:Int, lodRangeMinSize:Int, lodRangeMaxSize:Int, lodRangeRequestMinSize:Int, lodRangeRequestMaxSize:Int)
    :minko.Tuple.Tuple4<Int, Int, Int, Int> {


        if (streamingOptions.streamedTextureLodRangeFetchingBoundFunction) {
            return streamingOptions.streamedTextureLodRangeFetchingBoundFunction(currentLod, requiredLod, lodRangeMinSize, lodRangeMaxSize, lodRangeRequestMinSize, lodRangeRequestMaxSize);
        }
        else {
            lodRangeMinSize = StreamingOptions.MAX_LOD_RANGE;
        }

        return new minko.Tuple.Tuple4<Int, Int, Int, Int>(lodRangeMinSize, lodRangeMaxSize, lodRangeRequestMinSize, lodRangeRequestMaxSize);
    }

    override public function lodRangeRequestByteRange(lowerLod:Int, upperLod:Int, offset:Int, size:Int)
    :minko.Tuple<Int, Int> {

        var nextLodLowerBoundInfo = _mipLevelsInfo[lodToMipLevel(lowerLod)];
        var nextLodUpperBoundInfo = _mipLevelsInfo[lodToMipLevel(upperLod)];

        offset = (nextLodUpperBoundInfo.blobOffset);
        size = nextLodLowerBoundInfo.blobOffset + nextLodLowerBoundInfo.blobSize - offset;
        return new minko.Tuple<Int, Int>(offset, size);
    }

    override public function lodLowerBound(lod) {
        return lod;
    }

    public function maxLod() {
        return _textureNumMipmaps - 1;
    }
    //todo
}
