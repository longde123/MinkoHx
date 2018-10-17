package minko.file;
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
    private var _mipLevelsInfo:Array<Tuple<Int, Int>> ;

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

    public function useDescriptor(filename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        return false;
    }

    public function parsed(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        _texture = createTexture(assetLibrary, filename, _textureType);

        if (_texture == null) {
            trace("failed to create texture from " + filename);

            _error.execute(this, ("StreamedTextureParsingError" + "streamed texture parsing error"));

            return;
        }

        if (deferParsing()) {
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
                    data.set("maxLod", maxLod());

                }
            case TextureType.CubeTexture:

                return null;
        }

        return _texture;
    }

    public function headerParsed(data:BytesInput, options:Options, linkedAssetId:Int) {
        //ref
        var header = msgpack.type.tuple < uint, msgpack.type.tuple < int, int, byte, byte>, List<msgpack.type.tuple<int, List<msgpack.type.tuple<int, int>>>>>();

        unpack(header, data, data.Count, 0u);

        linkedAssetId = header.get<0>();

        _textureWidth = header.get<1>().get<0>();
        _textureHeight = header.get<1>().get<1>();
        _textureNumFaces = header.get<1>().get<2>();
        _textureNumMipmaps = header.get<1>().get<3>();
        _textureType = _textureNumFaces == 1 ? TextureType.Texture2D : TextureType.CubeTexture;

        var availableTextureFormats = new LinkedList<TextureFormat>();

        foreach (var formatHeader in header.get<2>())
        {
        availableTextureFormats.push_back((TextureFormat)(formatHeader.get<0>()));
        }

        _textureFormat = matchingTextureFormat(options, availableTextureFormats);

            //C++ TO C# CONVERTER CRACKED BY X-CRACKER 2017 TODO TASK: Only lambda expressions having all locals passed by reference can be converted to C#:
            //ORIGINAL LINE: const auto formatHeader = *std::find_if(header.get<2>().begin(), header.get<2>().end(), [this](const msgpack::type::tuple<int, ClassicVector<msgpack::type::tuple<int, int>>>& entry)->bool
        var formatHeader = * std::find_if(header.get<2>().begin(), header.get<2>().end(), (msgpack.type.tuple<int, List<msgpack.type.tuple<int, int>>> entry) =>
        {
        return entry.get<0>() == (int)_textureFormat;
        });

        foreach (var mipLevel in formatHeader.get<1>())
        {
        _mipLevelsInfo.push_back(System.Tuple.Create(mipLevel.get<0>(), mipLevel.get<1>()));
        }
    }

    public function lodParsed(int previousLod, int currentLod, List<byte> data, Options.Ptr options) {
        var dataOffset = 0u;

        for (var lod = previousLod + 1; lod <= currentLod; ++lod)
        {
        var mipLevel = lodToMipLevel(lod);

        auto mipLevelInfo = _mipLevelsInfo.at(mipLevel);

        var mipLevelDataSize = std::get<1>(mipLevelInfo);
        dataOffset += mipLevelDataSize;

        var mipLevelData = data.data() + data.Count - dataOffset;

        var extractedLodData = new List<byte>();

        if (extractLodData(_textureFormat, "", options, options.assetLibrary(), DataChunk(mipLevelData, 0u, mipLevelDataSize), extractedLodData))
        {
        mipLevelData = extractedLodData.data();
        mipLevelDataSize = extractedLodData.size();
        }

        switch (_textureType)
        {
        case TextureType.Texture2D:
        {
        var texture2d = std::static_pointer_cast<Texture>(_texture);

            //C++ TO C# CONVERTER CRACKED BY X-CRACKER 2017 TODO TASK: There is no equivalent to 'const_cast' in C#:
        texture2d.uploadMipLevel(mipLevel, const_cast<byte>(mipLevelData));

        if (mipLevel == 0)
        {
        var storeTextureData = !options.disposeTextureAfterLoading();

        if (storeTextureData)
        {
            //C++ TO C# CONVERTER CRACKED BY X-CRACKER 2017 TODO TASK: There is no equivalent to 'const_cast' in C#:
        texture2d.data(const_cast<byte>(mipLevelData));
        }
        }

        break;
        }
        case TextureType.CubeTexture:

        break;
        }
        }

        this.data().set("maxAvailableLod", currentLod);
    }

    public function matchingTextureFormat(Options options, LinkedList<render.TextureFormat> availableTextureFormats) {
        var contextAvailableTextureFormats = OpenGLES2Context.availableTextureFormats();

        var availableTextureFormatMatches = std::unordered_multiset < TextureFormat, Hash<TextureFormat>>(contextAvailableTextureFormats.size());

        for ( textureFormatToContextFormat in contextAvailableTextureFormats)
        {
        availableTextureFormatMatches.insert(textureFormatToContextFormat.first);
        }

        for ( textureFormat in availableTextureFormats)
        {
        availableTextureFormatMatches.insert(textureFormat);
        }

        var filteredAvailableTextureFormats = new HashSet<TextureFormat, Hash<TextureFormat>>(availableTextureFormatMatches.size());

        for ( textureFormat in availableTextureFormatMatches)
        {
        if (availableTextureFormatMatches.count(textureFormat) == 2)
        {
        filteredAvailableTextureFormats.insert(textureFormat);
        }
        }

        return options.textureFormatFunction()(filteredAvailableTextureFormats);
    }

    public function complete(currentLod) {
        return lodToMipLevel(currentLod) == 0;
    }

    public function completed() {
    }

    public function lodToMipLevel(lod) {
        return (_textureNumMipmaps - 1) - lod;
    }

    public function extractLodData(TextureFormat format, string filename, Options options, AssetLibrary assetLibrary, DataChunk lodData, ref List<byte> extractedLodData) {
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

                    parser.parse(filename, filename, parserOptions, new List<byte>(lodData.data + lodData.offset, lodData.data + lodData.size), localAssetLibrary);

                    var mipLevelTexture = localAssetLibrary.texture(filename);

                    extractedLodData = mipLevelTexture.data();

                    mipLevelTexture.dispose();

                    break;
                }
            default:
                return false;
        }

        return true;
    }

    public function lodRangeFetchingBound(int currentLod, int requiredLod, ref int lodRangeMinSize, ref int lodRangeMaxSize, ref int lodRangeRequestMinSize, ref int lodRangeRequestMaxSize) {
        if (streamingOptions().streamedTextureLodRangeFetchingBoundFunction()) {
            streamingOptions().streamedTextureLodRangeFetchingBoundFunction()(currentLod, requiredLod, lodRangeMinSize, lodRangeMaxSize, lodRangeRequestMinSize, lodRangeRequestMaxSize);
        }
        else {
            lodRangeMinSize = StreamingOptions.MAX_LOD_RANGE;
        }
    }

    public function lodRangeRequestByteRange(int lowerLod, int upperLod, ref int offset, ref int size) {
        //ref
        auto nextLodLowerBoundInfo = _mipLevelsInfo.at(lodToMipLevel(lowerLod));
        auto nextLodUpperBoundInfo = _mipLevelsInfo.at(lodToMipLevel(upperLod));

        offset = std::get<0>(nextLodUpperBoundInfo);
        size = std::get<0>(nextLodLowerBoundInfo) + std::get<1>(nextLodLowerBoundInfo) - offset;
    }

    public function lodLowerBound(lod) {
        return lod;
    }

    public function maxLod() {
        return _textureNumMipmaps - 1;
    }

}
