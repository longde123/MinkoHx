package minko.file;
import Array;
import glm.Vec2;
import haxe.ds.StringMap;
import Lambda;
import minko.file.Options.GeometryFunction;
import minko.render.MipFilter;
import minko.render.TextureFilter;
import minko.render.TextureFormat;
import minko.serialize.Types.ImageFormat;
import minko.utils.MathUtil;
class EmbedMode {
    public var None:Int;
    public var Geometry:Int;
    public var Material:Int;
    public var Texture:Int;
    public var All:Int;
}

typedef NameFunction = String -> String;
typedef UriFunction = String -> String;


class TextureOptions {
    public var compressTexture:Bool;
    public var compressedTextureQualityFactor:Float;
    public var preserveMipMaps:Bool;
    public var generateMipMaps:Bool;
    public var useTextureSRGBSpace:Bool;
    public var upscaleTextureWhenProcessedForMipMapping:Bool;
    public var textureScale:Vec2;
    public var textureMaxSize:Vec2;
    public var textureFilter:TextureFilter;
    public var mipFilter:MipFilter;
}

class WriterOptions {
    public function new() {
    }

    private var _addBoundingBoxes:Bool;

    private var _embedMode:Int;

    private var _geometryNameFunction:NameFunction;
    private var _materialNameFunction:NameFunction;
    private var _textureNameFunction:NameFunction;

    private var _geometryUriFunction:UriFunction;
    private var _materialUriFunction:UriFunction;
    private var _textureUriFunction:UriFunction;

    private var _geometryFunction:GeometryFunction;
    private var _materialFunction:MaterialFunction;
    private var _textureFunction:TextureFunction;

    private var _imageFormat:ImageFormat;
    private var _textureFormats:Array<TextureFormat>;

    private var _textureOptions:StringMap< TextureOptions >;

    private var _writeAnimations:Bool;

    private var _nullAssetUuids:Array<String> ;

    public static function create() {
        var writerOptions = new WriterOptions();

        return writerOptions;
    }

    public static function createbyWriterOptions(other:WriterOptions) {
        var instance = WriterOptions.create();

        instance._addBoundingBoxes = other._addBoundingBoxes;
        instance._embedMode = other._embedMode;
        instance._geometryNameFunction = other._geometryNameFunction;
        instance._materialNameFunction = other._materialNameFunction;
        instance._textureNameFunction = other._textureNameFunction;
        instance._geometryUriFunction = other._geometryUriFunction;
        instance._materialUriFunction = other._materialUriFunction;
        instance._textureUriFunction = other._textureUriFunction;
        instance._geometryFunction = other._geometryFunction;
        instance._materialFunction = other._materialFunction;
        instance._textureFunction = other._textureFunction;
        instance._imageFormat = other._imageFormat;
        instance._textureFormats = other._textureFormats;
        instance._textureOptions = other._textureOptions;
        instance._writeAnimations = other._writeAnimations;
        instance._nullAssetUuids = other._nullAssetUuids;

        return instance;
    }
    public var addBoundingBoxes(get, set):Bool;

    function get_addBoundingBoxes() {
        return _addBoundingBoxes;
    }

    function set_addBoundingBoxes(value) {
        _addBoundingBoxes = value;

        return value;
    }
    public var embedMode( get, set):Int;

    function get_embedMode() {
        return _embedMode;
    }

    function set_embedMode(value) {
        _embedMode = value;

        return value;
    }

    public var geometryNameFunction(get, set):NameFunction;

    function get_geometryNameFunction() {
        return _geometryNameFunction;
    }

    function set_geometryNameFunction(func) {
        _geometryNameFunction = func;

        return func;
    }

    public var materialNameFunction(get, set):NameFunction;

    function get_materialNameFunction() {
        return _materialNameFunction;
    }

    function set_materialNameFunction(func) {
        _materialNameFunction = func;

        return func;
    }
    public var textureNameFunction(get, set):NameFunction;

    function get_textureNameFunction() {
        return _textureNameFunction;
    }

    function set_textureNameFunction(func) {
        _textureNameFunction = func;

        return func;
    }
    public var geometryUriFunction(get, set):UriFunction;

    function get_geometryUriFunction() {
        return _geometryUriFunction;
    }

    function set_geometryUriFunction(func) {
        _geometryUriFunction = func;

        return func;
    }
    public var materialUriFunction(get, set):UriFunction;

    function get_materialUriFunction() {
        return _materialUriFunction;
    }

    function set_materialUriFunction(func) {
        _materialUriFunction = func;

        return func;
    }
    public var textureUriFunction(get, set):UriFunction;

    function get_textureUriFunction() {
        return _textureUriFunction;
    }

    function set_textureUriFunction(func) {
        _textureUriFunction = func;

        return func;
    }
    public var geometryFunction(get, set):GeometryFunction;

    function get_geometryFunction() {
        return _geometryFunction;
    }

    function set_geometryFunction(func) {
        _geometryFunction = func;

        return func;
    }
    public var materialFunction(get, set):MaterialFunction;

    function get_materialFunction() {
        return _materialFunction;
    }

    function set_materialFunction(func) {
        _materialFunction = func;

        return func;
    }
    public var textureFunction(get, set):TextureFunction;

    function get_textureFunction() {
        return _textureFunction;
    }

    function set_textureFunction(func) {
        _textureFunction = func;

        return func;
    }
    public var imageFormat(get, set):ImageFormat;

    function get_imageFormat() {
        return _imageFormat;
    }

    function set_imageFormat(value) {
        _imageFormat = value;

        return value;
    }
    public var textureFormats(get, null):Array<ImageFormat>;

    function get_textureFormats() {
        return _textureFormats;
    }

    public function registerTextureFormat(textureFormat) {
        _textureFormats.push(textureFormat);

        return this;
    }

    private function textureOptions(textureType):TextureOptions {
        var textureOptionsIt = _textureOptions.exists(textureType);

        if (textureOptionsIt != false) {
            return _textureOptions.get(textureType);
        }

        return _textureOptions.get("");
    }

    public function compressedTextureQualityFactor(textureType) {
        return textureOptions(textureType).compressedTextureQualityFactor;
    }

    function IsNullOrEmpty(s):Bool {
        return (s == null || s == "");

    }

    public function compressedTextureQualityFactorValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.compressedTextureQualityFactor = MathUtil.clamp(value, 0.0, 1.0);
            }
        }
        else {
            _textureOptions.get(textureType).compressedTextureQualityFactor = MathUtil.clamp(value, 0.0, 1.0);
        }

        return this;
    }


    public function compressTexture(textureType) {
        return textureOptions(textureType).compressTexture;
    }

    public function compressTextureValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.compressTexture = value;
            }
        }
        else {
            _textureOptions.get(textureType).compressTexture = value;
        }

        return this;
    }

    public function preserveMipMaps(textureType) {
        return textureOptions(textureType).preserveMipMaps;
    }

    public function preserveMipMapsValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.preserveMipMaps = value;
            }
        }
        else {
            _textureOptions.get(textureType).preserveMipMaps = value;
        }

        return this;
    }

    public function generateMipMaps(textureType) {
        return textureOptions(textureType).generateMipMaps;
    }

    public function generateMipMapsValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.generateMipMaps = value;
            }
        }
        else {
            _textureOptions.get(textureType).generateMipMaps = value;
        }

        return this;
    }

    public function useTextureSRGBSpace(textureType) {
        return textureOptions(textureType).useTextureSRGBSpace;
    }

    public function useTextureSRGBSpaceValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.useTextureSRGBSpace = value;
            }
        }
        else {
            _textureOptions.get(textureType).useTextureSRGBSpace = value;
        }

        return this;
    }

    public function upscaleTextureWhenProcessedForMipMapping(textureType) {
        return textureOptions(textureType).upscaleTextureWhenProcessedForMipMapping;
    }

    public function upscaleTextureWhenProcessedForMipMappingValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.upscaleTextureWhenProcessedForMipMapping = value;
            }
        }
        else {
            _textureOptions.get(textureType).upscaleTextureWhenProcessedForMipMapping = value;
        }

        return this;
    }

    public function textureMaxSize(textureType) {
        return textureOptions(textureType).textureMaxSize;
    }

    public function textureMaxSizeValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.textureMaxSize = value;
            }
        }
        else {
            _textureOptions.get(textureType).textureMaxSize = value;
        }

        return this;
    }

    public function textureScale(textureType) {
        return textureOptions(textureType).textureScale;
    }

    public function textureScaleValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.textureScale = value;
            }
        }
        else {
            _textureOptions.get(textureType).textureScale = value;
        }

        return this;
    }

    public function textureFilter(textureType) {
        return textureOptions(textureType).textureFilter;
    }

    public function textureFilterValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.textureFilter = value;
            }
        }
        else {
            _textureOptions.get(textureType).textureFilter = value;
        }

        return this;
    }

    public function mipFilter(textureType) {
        return textureOptions(textureType).mipFilter;
    }

    public function mipFilterValue(textureType, value) {
        if (IsNullOrEmpty(textureType)) {
            for (textureOption in _textureOptions) {
                textureOption.mipFilter = value;
            }
        }
        else {
            _textureOptions.get(textureType).mipFilter = value;
        }

        return this;
    }
    public var writeAnimations(get, set):Bool;

    function get_writeAnimations() {
        return _writeAnimations;
    }

    function set_writeAnimations(value) {
        _writeAnimations = value;

        return value;
    }
    public var nullAssetUuids(get, null):Array<String>;

    function get_nullAssetUuids() {
        return _nullAssetUuids;
    }

    public function assetIsNull(uuid) {
        return Lambda.has(_nullAssetUuids, uuid);
    }


}
