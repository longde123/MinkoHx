package minko.file;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import Lambda;
import minko.render.GlContext;
import minko.render.Texture;
import minko.render.TextureFormat;
import minko.render.TextureFormatInfo;
import minko.render.TextureType;
import minko.serialize.Types.ImageFormat;
import minko.Tuple.Tuple3;
using minko.utils.BytesTool;
typedef FormatParserFunction = String -> Options -> Bytes -> AssetLibrary -> Int -> Int -> TextureType -> Int -> Bool;

class TextureParser extends AbstractSerializerParser {

    private var _dataEmbed:Bool;

    public static function create() {
        var instance = (new TextureParser());

        return instance;
    }

    public var dataEmbed(null, set):Bool;

    function set_dataEmbed(value) {
        _dataEmbed = value;

        return value;
    }

    static private var _formatParserFunctions:IntMap<FormatParserFunction> = init_formatParserFunctions();

    static function init_formatParserFunctions() {
        var tmp = new IntMap<FormatParserFunction>();
        tmp.set(TextureFormat.RGB, parseRGBATexture) ;
        tmp.set(TextureFormat.RGBA, parseRGBATexture) ;
        tmp.set(TextureFormat.RGB_DXT1, parseCompressedTexture.bind(TextureFormat.RGB_DXT1));
        tmp.set(TextureFormat.RGBA_DXT1, parseCompressedTexture.bind(TextureFormat.RGBA_DXT1));
        tmp.set(TextureFormat.RGBA_DXT3, parseCompressedTexture.bind(TextureFormat.RGBA_DXT3));
        tmp.set(TextureFormat.RGBA_DXT5, parseCompressedTexture.bind(TextureFormat.RGBA_DXT5));
        tmp.set(TextureFormat.RGB_ETC1, parseCompressedTexture.bind(TextureFormat.RGB_ETC1));
        tmp.set(TextureFormat.RGB_PVRTC1_2BPP, parseCompressedTexture.bind(TextureFormat.RGB_PVRTC1_2BPP));
        tmp.set(TextureFormat.RGB_PVRTC1_4BPP, parseCompressedTexture.bind(TextureFormat.RGB_PVRTC1_4BPP));
        tmp.set(TextureFormat.RGBA_PVRTC1_2BPP, parseCompressedTexture.bind(TextureFormat.RGBA_PVRTC1_2BPP));
        tmp.set(TextureFormat.RGBA_PVRTC1_4BPP, parseCompressedTexture.bind(TextureFormat.RGBA_PVRTC1_4BPP));
        tmp.set(TextureFormat.RGB_ATITC, parseCompressedTexture.bind(TextureFormat.RGB_ATITC));
        tmp.set(TextureFormat.RGBA_ATITC, parseCompressedTexture.bind(TextureFormat.RGBA_ATITC));
    }

    public function new() {

        super();
        this._textureHeaderSize = 0;
        this._dataEmbed = false;
    }

    override public function parse(filename, resolvedFilename, options:Options, _data:Bytes, assetLibrary:AssetLibrary) {
        var data:BytesInput = new BytesInput(_data);
        readHeader(filename, data, 0x00000054);


        var textureHeader = new BytesInput(data.readOneBytes());
        var formatBytes = new BytesInput(data.readOneBytes());
        var blobs = new BytesInput(data.readOneBytes());

        var textureWidth = textureHeader.readInt32();
        var textureHeight = textureHeader.readInt32();
        var textureType = textureHeader.readInt8() == 1 ? TextureType.Texture2D : TextureType.CubeTexture;
        var textureNumMipmaps = textureHeader.readInt8();


        var contextAvailableTextureFormats = GlContext.availableTextureFormats();
        var availableTextureFormats:IntMap<Int> = new IntMap<Int>();

        for (entry in contextAvailableTextureFormats) {
            trace("platform-supported texture format: " << TextureFormatInfo.name(entry));
            availableTextureFormats.set(entry, 1);
        }
        var formats:Array<Tuple3<Int, Int, Int>> = [];
        var len = formatBytes.readInt32();
        for (i in 0...len) {
            var img = new Tuple3<Int, Int, Int>(formatBytes.readInt32(), formatBytes.readInt32(), formatBytes.readInt32());
            formats.push(img);
        }
        for (entry in formats) {
            trace("embedded texture format: " << TextureFormatInfo.name(entry.first));
            if (availableTextureFormats.exists(entry.first)) {
                availableTextureFormats.set(entry, 2);
            }
        }

        var filteredAvailableTextureFormats = [];

        for (textureFormat in availableTextureFormats) {
            if (availableTextureFormats.get(textureFormat) == 2) {
                filteredAvailableTextureFormats.push(textureFormat);
            }
        }

        var desiredFormat = options.textureFormatFunction(filteredAvailableTextureFormats);

        var desiredFormatInfo:Tuple3<Int, Int, Int> = Lambda.find(formats, function(entry:Tuple3<Int, Int, Int>) {
            return entry.first == desiredFormat;
        });

        var offset = desiredFormatInfo.second;
        var length = desiredFormatInfo.thiree;

        if (!_dataEmbed) {
            var textureFileOptions = options.clone();
            textureFileOptions.seekingOffset = (offset);
            textureFileOptions.seekedLength = (length);
            textureFileOptions.loadAsynchronously = (false);
            textureFileOptions.storeDataIfNotParsed = (false);
            textureFileOptions.parserFunction = (function(extension) {
                return null;
            });

            var loader = Loader.create();

            loader.options = (textureFileOptions);

            var errorSlot = loader.error.connect(function(UnnamedParameter1, error) {
                _error.execute(this, ("TextureLoadingError" + "Failed to load texture " + filename));
            });

            var completeSlot = loader.complete.connect(function(loaderThis:Loader) {
                var textureData = loaderThis.files.get(filename).data;

                if (!_formatParserFunctions.get(desiredFormat)(filename, textureFileOptions, textureData, assetLibrary, textureWidth, textureHeight, textureType, textureNumMipmaps)) {
                    _error.execute(this, ("TextureParsingError" + "Failed to parse texture " + filename));
                }
            });

            loader.queue(filename).load();
        }
        else {

            var textureData = blobs;

            if (!_formatParserFunctions.get(desiredFormat)(filename, options, textureData, assetLibrary, textureWidth, textureHeight, textureType, textureNumMipmaps)) {
                _error.execute(this, ("TextureParsingError" + "Failed to parse texture " + filename));
            }
        }

        complete.execute(this);
    }

    public function parseRGBATexture(fileName, options:Options, data:BytesInput, assetLibrary:AssetLibrary, width, height, type:TextureType, numMipmaps) {
        var imageFormat = data.readInt8();
        var deserializedTexture = new BytesInput(data.readOneBytes());
        var parser:AbstractParser = null;

        switch (imageFormat)
        {
            case ImageFormat.PNG:
                parser = PNGParser.create();
                break;

            default:
                return false;
        }

        parser.parse(fileName, fileName, options, deserializedTexture, assetLibrary);

        return true;
    }

    public function parseCompressedTexture(format, fileName, options:Options, data:BytesInput, assetLibrary:AssetLibrary, width, height, type:TextureType, numMipmaps) {
        var textureData:Bytes = data.readOneBytes();

        var hasMipmaps = options.generateMipmaps && numMipmaps > 0;

        switch (type)
        {
            case TextureType.Texture2D:
                {
                    var texture = Texture.create(options.context, width, height, hasMipmaps, false, false, format, fileName);

                    var storeTextureData = !options.disposeTextureAfterLoading;

                    if (storeTextureData) {
                        texture.data = textureData;
                    }

                    texture.upload();

                    if (!storeTextureData) {
                        texture.uploadMipLevel(0, textureData);
                    }

                    if (hasMipmaps) {
                        var mipLevelSize = TextureFormatInfo.textureSize(format, width, height);
                        var mipLevelStart = 0;
                        var mipLevelOffset = mipLevelSize;
                        for (i in 1... numMipmaps) {
                            var mipLevelWidth = width >> i;
                            var mipLevelHeight = height >> i;

                            texture.uploadMipLevel(i, textureData.blit(mipLevelStart, mipLevelSize));
                            mipLevelStart = mipLevelOffset;
                            mipLevelSize = TextureFormatInfo.textureSize(format, mipLevelWidth, mipLevelHeight);
                            mipLevelOffset += mipLevelSize;
                        }
                    }

                    assetLibrary.setTexture(fileName, texture);

                    if (options.disposeTextureAfterLoading) {
                        texture.disposeData();
                    }

                    break;
                }
            case TextureType.CubeTexture:

                // TODO fixme

                return false;

            default:
                break;
        }

        return true;
    }

}
