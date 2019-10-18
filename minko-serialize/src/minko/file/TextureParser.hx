package minko.file;
import minko.file.AbstractStream;
import minko.file.AbstractStream.TextureStream;
import minko.file.AbstractStream.TextureBlobStream;
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
        tmp.set(TextureFormat.RGB, parseRGBTexture.bind(TextureFormat.RGB)) ;
        tmp.set(TextureFormat.RGBA, parseRGBATexture.bind(TextureFormat.RGBA)) ;
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
        this._dataEmbed = false;
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        if (!_dataEmbed) {
            var textureFileOptions = options.clone();
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

            });

            loader.queue(filename).load();
        }
        else {


        }

        complete.execute(this);
    }


    override public function parseStream(filename, resolvedFilename, options:Options, _data:AbstractStream, assetLibrary:AssetLibrary) {
        var data:TextureStream = cast _data;
        var textureWidth = data.width;
        var textureHeight = data.height;
        var textureType = data.numFaces == 1 ? TextureType.Texture2D : TextureType.CubeTexture;
        var textureNumMipmaps = data.numMipmaps;
        for (t in data.blobs) {
            if (!_formatParserFunctions.get(t.textureFormat)(filename, options, t.textureData, assetLibrary, textureWidth, textureHeight, textureType, textureNumMipmaps)) {
                _error.execute(this, ("TextureParsingError" + "Failed to parse texture " + filename));
            }
        }
        complete.execute(this);
    }

    public function parseRGBTexture(format, fileName, options:Options, data:TextureBlobStream, assetLibrary:AssetLibrary, width, height, type:TextureType, numMipmaps) {

        var parser:AbstractParser = JPEGParser.create();

        parser.parse(fileName, fileName, options, data.textureData, assetLibrary);

        return true;
    }

    public function parseRGBATexture(format, fileName, options:Options, data:TextureBlobStream, assetLibrary:AssetLibrary, width, height, type:TextureType, numMipmaps) {

        var parser:AbstractParser = PNGParser.create();

        parser.parse(fileName, fileName, options, data.textureData, assetLibrary);

        return true;
    }

    public function parseCompressedTexture(format, fileName, options:Options, data:TextureBlobStream, assetLibrary:AssetLibrary, width, height, type:TextureType, numMipmaps) {
        var textureData:Bytes = data.textureData;

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
