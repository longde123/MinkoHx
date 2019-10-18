package minko.file;

import minko.material.BasicMaterial;
import haxe.ds.StringMap;
import minko.component.Skinning.SkinningMethod;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.Effect;
import minko.render.TextureFormat;
import minko.scene.Node;
@:expose("minko.file.FileStatus")
@:enum abstract FileStatus(Int) from Int to Int{
    var Pending = 0;
    var Aborted = 1;
}

typedef ParserHandler = Void -> AbstractParser;
typedef ProtocolHandler = Void -> AbstractProtocol;
typedef MaterialFunction = String -> Material -> Material;
typedef TextureFunction = String -> AbstractTexture -> AbstractTexture;
typedef GeometryFunction = String -> Geometry -> Geometry;
typedef ProtocolFunction = String -> ProtocolHandler;
typedef ParserFunction = String -> ParserHandler;
typedef UriFunction = String -> String;
typedef NodeFunction = Node -> Node;

typedef EffectFunction = Effect -> Effect;
typedef TextureFormatFunction = Array<TextureFormat> -> TextureFormat;//todo
typedef AttributeFunction = Node -> String -> String -> Void;
typedef PreventLoadingFunction = String -> Bool;

typedef FileStatusFunction = File -> Float -> FileStatus;
@:expose("minko.file.Options")
class Options {

    private var _context:AbstractContext;
    private var _assets:AssetLibrary;
    private var _includePaths:Array<String>;
    private var _platforms:Array<String>;
    private var _userFlags:Array<String>;

    private var _parsers:StringMap<ParserHandler>;
    private var _protocols:StringMap<ProtocolHandler>;

    private var _optimizeForRendering:Bool;
    private var _generateMipMaps:Bool;
    private var _parseMipMaps:Bool;
    private var _resizeSmoothly:Bool;
    private var _isCubeTexture:Bool;
    private var _isRectangleTexture:Bool;
    private var _generateSmoothNormals:Bool;
    private var _normalMaxSmoothingAngle:Float;
    private var _includeAnimation:Bool;
    private var _startAnimation:Bool;
    private var _loadAsynchronously:Bool;
    private var _disposeIndexBufferAfterLoading:Bool;
    private var _disposeVertexBufferAfterLoading:Bool;
    private var _disposeTextureAfterLoading:Bool;
    private var _storeDataIfNotParsed:Bool;
    private var _preserveMaterials:Bool;
    private var _trackAssetDescriptor:Bool;
    private var _skinningFramerate:Int;
    private var _skinningMethod:SkinningMethod;
    private var _effect:Effect;
    private var _material:Material;
    private var _textureFormats:Array<TextureFormat>;
    private var _materialFunction:MaterialFunction;
    private var _textureFunction:TextureFunction;
    private var _geometryFunction:GeometryFunction;
    private var _protocolFunction:ProtocolFunction;
    private var _parserFunction:ParserFunction;
    private var _uriFunction:UriFunction;
    private var _nodeFunction:NodeFunction;
    private var _effectFunction:EffectFunction;
    private var _textureFormatFunction:TextureFormatFunction;
    private var _attributeFunction:AttributeFunction;
    private var _fileStatusFunction:FileStatusFunction;
    private var _preventLoadingFunction:PreventLoadingFunction;
    private var _seekingOffset:Int;
    private var _seekedLength:Int;
    private var _fixMipMaps:Bool;
    private static var _defaultProtocols:StringMap<ProtocolHandler> = new StringMap<ProtocolHandler>();
    private static var _defaultMaterial:Material =BasicMaterial.create("defaultMaterial");
    public var fixMipMaps(get, set):Bool;

    function get_fixMipMaps() {
        return _fixMipMaps;
    }

    function set_fixMipMaps(p) {
        _fixMipMaps = p;
        return p;
    }
    public static function empty() {
        var instance = new Options();
        instance.initialize();
        return instance;
    }

    public static function create(context:AbstractContext) {
        var options:Options = empty();
        options._context = context;
        return options;
    }

    public function clone():Options {
        var copy:Options = new Options();
        copy.copyFrom(this) ;
        copy.initialize();
        return copy;
    }

    public var context(get, set):AbstractContext;

    function get_context() {
        return _context;
    }

    function set_context(v) {
        _context = v;
        return v;
    }
    public var assetLibrary(get, set):AssetLibrary;

    function get_assetLibrary() {
        return _assets;
    }

    function set_assetLibrary(v) {
        _assets = v;
        return v;
    }
    public var includePaths(get, set):Array<String>;

    function set_includePaths(v) {
        _includePaths = v;
        return v;
    }

    function get_includePaths() {
        return _includePaths;
    }
    public var platforms(get, null):Array<String>;

    function get_platforms() {
        return _platforms;
    }
    public var userFlags(get, null):Array<String>;

    function get_userFlags() {
        return _userFlags;
    }
    public var optimizeForRendering(get, set):Bool;

    function get_optimizeForRendering() {
        return _optimizeForRendering;
    }

    function set_optimizeForRendering(value) {
        _optimizeForRendering = value;
        return value;
    }
    public var generateMipmaps(get, set):Bool;

    function get_generateMipmaps() {
        return _generateMipMaps;
    }

    function set_generateMipmaps(generateMipmaps) {
        _generateMipMaps = generateMipmaps;
        return generateMipmaps;
    }
    public var parseMipMaps(get, set):Bool;

    function get_parseMipMaps() {
        return _parseMipMaps;
    }

    function set_parseMipMaps(parseMipMaps) {
        _parseMipMaps = parseMipMaps;
        return parseMipMaps;
    }
    public var includeAnimation(get, set):Bool;

    function get_includeAnimation() {
        return _includeAnimation;
    }

    function set_includeAnimation(value) {
        _includeAnimation = value;
        return value;
    }
    public var startAnimation(get, set):Bool;

    function get_startAnimation() {
        return _startAnimation;
    }

    function set_startAnimation(value) {
        _startAnimation = value;
        return value;
    }
    public var loadAsynchronously(get, set):Bool;

    function get_loadAsynchronously() {
        return _loadAsynchronously;
    }

    function set_loadAsynchronously(value) {
        _loadAsynchronously = value;
        return value;
    }
    public var resizeSmoothly(get, set):Bool;

    function get_resizeSmoothly() {
        return _resizeSmoothly;
    }

    function set_resizeSmoothly(value) {
        _resizeSmoothly = value;
        return value;
    }
    public var isCubeTexture(get, set):Bool;

    function get_isCubeTexture() {
        return _isCubeTexture;
    }

    function set_isCubeTexture(value) {
        _isCubeTexture = value;

        return value;
    }

    public var isRectangleTexture(get, set):Bool;

    function get_isRectangleTexture() {
        return _isRectangleTexture;
    }

    function set_isRectangleTexture(value) {
        _isRectangleTexture = value;

        return value;
    }

    public var generateSmoothNormals(get, set):Bool;

    function get_generateSmoothNormals() {
        return _generateSmoothNormals;
    }

    function set_generateSmoothNormals(value) {
        _generateSmoothNormals = value;

        return value;
    }
    public var normalMaxSmoothingAngle(get, set):Float;

    function get_normalMaxSmoothingAngle() {
        return _normalMaxSmoothingAngle;
    }

    function set_normalMaxSmoothingAngle(value) {
        _normalMaxSmoothingAngle = value;

        return value;
    }
    public var disposeIndexBufferAfterLoading(get, set):Bool;

    function get_disposeIndexBufferAfterLoading() {
        return _disposeIndexBufferAfterLoading;
    }

    function set_disposeIndexBufferAfterLoading(value) {
        _disposeIndexBufferAfterLoading = value;

        return value;
    }
    public var disposeVertexBufferAfterLoading(get, set):Bool;

    function get_disposeVertexBufferAfterLoading() {
        return _disposeVertexBufferAfterLoading;
    }

    function set_disposeVertexBufferAfterLoading(value) {
        _disposeVertexBufferAfterLoading = value;

        return value;
    }
    public var disposeTextureAfterLoading(get, set):Bool;

    function get_disposeTextureAfterLoading() {
        return _disposeTextureAfterLoading;
    }

    function set_disposeTextureAfterLoading(value) {
        _disposeTextureAfterLoading = value;

        return value;
    }

    public var storeDataIfNotParsed(get, set):Bool;

    function get_storeDataIfNotParsed() {
        return _storeDataIfNotParsed;
    }

    function set_storeDataIfNotParsed(value) {
        _storeDataIfNotParsed = value;

        return value;
    }
    public var preserveMaterials(get, set):Bool;

    function get_preserveMaterials() {
        return _preserveMaterials;
    }

    function set_preserveMaterials(value) {
        _preserveMaterials = value;

        return value;
    }
    public var trackAssetDescriptor(get, set):Bool;

    function get_trackAssetDescriptor() {
        return _trackAssetDescriptor;
    }

    function set_trackAssetDescriptor(value) {
        _trackAssetDescriptor = value;

        return value;
    }

    public var skinningFramerate(get, set):Int;

    function get_skinningFramerate() {
        return _skinningFramerate;
    }

    function set_skinningFramerate(value) {
        _skinningFramerate = value;

        return value;
    }

    public var skinningMethod(get, set):SkinningMethod;

    function get_skinningMethod() {
        return _skinningMethod;
    }

    function set_skinningMethod(value) {
        _skinningMethod = (value);

        return value;
    }

    public var effect(get, set):Effect;

    function get_effect() {
        return _effect;
    }

    function set_effect(effect) {
        _effect = effect;

        return effect;
    }
    public var material(get, set):Material;

    function get_material() {
        return _material;
    }

    function set_material(material) {
        _material = material;

        return material;
    }

    public function registerTextureFormat(textureFormat:TextureFormat) {
        _textureFormats.push(textureFormat);

        return this;
    }
    public var protocolFunction(get, set):ProtocolFunction;

    function get_protocolFunction() {
        return _protocolFunction != null ? _protocolFunction : defaultProtocolFunction;
    }

    function set_protocolFunction(func) {
        _protocolFunction = func;

        return func;
    }

    public var parserFunction(get, set):ParserFunction;

    function get_parserFunction() {
        return _parserFunction;
    }

    function set_parserFunction(func) {
        _parserFunction = func;

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
    public var geometryFunction(get, set):GeometryFunction;

    function get_geometryFunction() {
        return _geometryFunction;
    }

    function set_geometryFunction(func) {
        _geometryFunction = func;

        return func;
    }
    public var uriFunction(get, set):UriFunction;

    function get_uriFunction() {
        return _uriFunction;
    }

    function set_uriFunction(func) {
        _uriFunction = func;

        return func;
    }
    public var nodeFunction(get, set):NodeFunction;

    function get_nodeFunction() {
        return _nodeFunction;
    }

    function set_nodeFunction(func) {
        _nodeFunction = func;

        return func;
    }
    public var effectFunction(get, set):EffectFunction;

    function get_effectFunction() {
        return _effectFunction;
    }

    function set_effectFunction(func) {
        _effectFunction = func;

        return func;
    }
    public var textureFormatFunction(get, set):TextureFormatFunction;

    function get_textureFormatFunction() {
        return _textureFormatFunction;
    }

    function set_textureFormatFunction(func) {
        _textureFormatFunction = func;

        return func;
    }
    public var attributeFunction(get, set):AttributeFunction;

    function get_attributeFunction() {
        return _attributeFunction;
    }

    function set_attributeFunction(func) {
        _attributeFunction = func;

        return func;
    }
    public var fileStatusFunction(get, set):FileStatusFunction;

    function get_fileStatusFunction() {
        return _fileStatusFunction;
    }

    function set_fileStatusFunction(func) {
        _fileStatusFunction = func;

        return func;
    }
    public var preventLoadingFunction(get, set):PreventLoadingFunction;

    function get_preventLoadingFunction() {
        return _preventLoadingFunction;
    }

    function set_preventLoadingFunction(func) {
        _preventLoadingFunction = func;

        return func;
    }
    public var seekingOffset(get, set):Int;

    function get_seekingOffset() {
        return _seekingOffset;
    }

    function set_seekingOffset(value) {
        _seekingOffset = value;

        return value;
    }

    public var seekedLength(get, set):Int;

    function get_seekedLength() {
        return _seekedLength;
    }

    function set_seekedLength(value) {
        _seekedLength = value;

        return value;
    }


    public function registerParser(extension:String, cls:ParserHandler) {
        var ext = extension.toLowerCase();

        _parsers.set(ext, cls) ;

        return this;
    }

    public function getParser(extension) {
        if (_parserFunction != null) {
            return _parserFunction(extension);
        }

        return _parsers.exists(extension) == false ? null : _parsers.get(extension);
    }


    public static function registerDefaultProtocol(protocol:String, cls:ProtocolHandler) {
        var prefix = protocol.toLowerCase();

        _defaultProtocols.set(prefix, cls) ;
    }

    public function registerProtocol(cls:ProtocolHandler, protocol:String) {
        var prefix = protocol.toLowerCase();

        _protocols.set(prefix, cls) ;

        return this;
    }

    public function getProtocol(protocol) {
        var p:ProtocolHandler = _protocols.exists(protocol) == false ? null : _protocols.get(protocol) ;

        if (p != null) {
            //   p.options = p.options.clone();

            return p;
        }

        var defaultProtocol = _defaultProtocols.exists(protocol) == false ? null : _defaultProtocols.get(protocol) ;

        return defaultProtocol;
    }

    static public function includePaths_clear() {

//   auto binaryDir = File::getBinaryDirectory();
        var binaryDir = "";
        var __includePaths = [];

        __includePaths.push("asset/effect");
        #if defined(DEBUG) && !defined(EMSCRIPTEN)
             __includePaths.push(binaryDir + "/../../../asset");
        #end
        return __includePaths;
    }

    public function new() {

        this._parsers = new StringMap<ParserHandler>();
        this._protocols = new StringMap<ProtocolHandler>();
        this._context = null;
        this._includePaths = [];

        this._platforms = [];
        this._userFlags = [];
        this._optimizeForRendering = true;
        this._generateMipMaps = false;//todo
        this._fixMipMaps=false;
        this._parseMipMaps = false;
        this._resizeSmoothly = false;
        this._isCubeTexture = false;
        this._isRectangleTexture = false;
        this._generateSmoothNormals = false;
        this._normalMaxSmoothingAngle = 80.0 ;
        this._includeAnimation = true;
        this._startAnimation = true;
        this._loadAsynchronously = true;
        this._disposeIndexBufferAfterLoading = false;
        this._disposeVertexBufferAfterLoading = false;
        this._disposeTextureAfterLoading = false;
        this._storeDataIfNotParsed = true;
        this._preserveMaterials = true;
        this._trackAssetDescriptor = false;
        this._skinningFramerate = 30;
        this._skinningMethod = SkinningMethod.HARDWARE;
        this._material = null;
        this._effect = null;
        this._seekingOffset = 0;
        this._seekedLength = 0;
        this._materialFunction = null;
        this._textureFunction = null;
        this._geometryFunction = null;
        this._protocolFunction = null;
        this._parserFunction = null;
        this._uriFunction = null;
        this._nodeFunction = null;
        this._effectFunction = null;
        this._textureFormatFunction = null;
        this._attributeFunction = null;
        this._fileStatusFunction = null;
        this._preventLoadingFunction = null;
        var binaryDir = File.getBinaryDirectory();

        includePaths.push(binaryDir + "/asset");
        includePaths.push(".");

        #if DEBUG && !EMSCRIPTEN
				 includePaths.push(binaryDir + "/../../../asset");
			 #end

        initializePlatforms();
        initializeUserFlags();
    }

    public function copyFrom(copy:Options) {
        this._context = copy._context;
        this._assets = copy._assets;
        this._includePaths = (copy._includePaths.concat([]));
        this._platforms = (copy._platforms.concat([]));
        this._userFlags = (copy._userFlags.concat([]));
        this._optimizeForRendering = copy._optimizeForRendering;
        this._parsers = (copy._parsers);
        this._protocols = (copy._protocols);
        this._generateMipMaps = copy._generateMipMaps;
        this._fixMipMaps= copy._fixMipMaps;
        this._parseMipMaps = copy._parseMipMaps;
        this._resizeSmoothly = copy._resizeSmoothly;
        this._isCubeTexture = copy._isCubeTexture;
        this._isRectangleTexture = copy._isRectangleTexture;
        this._generateSmoothNormals = copy._generateSmoothNormals;
        this._normalMaxSmoothingAngle = copy._normalMaxSmoothingAngle;
        this._includeAnimation = copy._includeAnimation;
        this._startAnimation = copy._startAnimation;
        this._disposeIndexBufferAfterLoading = copy._disposeIndexBufferAfterLoading;
        this._disposeVertexBufferAfterLoading = copy._disposeVertexBufferAfterLoading;
        this._disposeTextureAfterLoading = copy._disposeTextureAfterLoading;
        this._storeDataIfNotParsed = copy._storeDataIfNotParsed;
        this._preserveMaterials = copy._preserveMaterials;
        this._trackAssetDescriptor = copy._trackAssetDescriptor;
        this._skinningFramerate = copy._skinningFramerate;
        this._skinningMethod = copy._skinningMethod;
        this._effect = copy._effect;
        this._textureFormats = copy._textureFormats;
        this._material = copy._material;
        this._materialFunction = copy._materialFunction;
        this._textureFunction = copy._textureFunction;
        this._geometryFunction = copy._geometryFunction;
        this._protocolFunction = copy._protocolFunction;
        this._parserFunction = copy._parserFunction;
        this._uriFunction = copy._uriFunction;
        this._nodeFunction = copy._nodeFunction;
        this._effectFunction = copy._effectFunction;
        this._textureFormatFunction = copy._textureFormatFunction;
        this._attributeFunction = copy._attributeFunction;
        this._fileStatusFunction = copy._fileStatusFunction;
        this._preventLoadingFunction = copy._preventLoadingFunction;
        this._loadAsynchronously = copy._loadAsynchronously;
        this._seekingOffset = copy._seekingOffset;
        this._seekedLength = copy._seekedLength;
        return this;
    }

    public function initialize() {

        resetNotInheritedValues();
        initializeDefaultFunctions();

        if (!_parsers.exists("effect")) {
            registerParser("effect", function() return new EffectParser());
        }

        if (!_defaultProtocols.exists("file")) {
            registerDefaultProtocol("file", function() return new FileProtocol());
        }
    }

    private function initializePlatforms() {
#if MINKO_PLATFORM & MINKO_PLATFORM_WINDOWS
				_platforms.AddLast("windows");
#elif MINKO_PLATFORM & MINKO_PLATFORM_OSX
				_platforms.AddLast("osx");
#elif MINKO_PLATFORM & MINKO_PLATFORM_LINUX
				_platforms.AddLast("linux");
#elif MINKO_PLATFORM & MINKO_PLATFORM_IOS
				_platforms.AddLast("ios");
#elif MINKO_PLATFORM & MINKO_PLATFORM_ANDROID
				_platforms.AddLast("android");
#elif MINKO_PLATFORM & MINKO_PLATFORM_HTML5
				_platforms.AddLast("html5");
				if (testUserAgentPlatform("Windows"))
				{
					_platforms.AddLast("windows");
				}
				if (testUserAgentPlatform("Macintosh"))
				{
					_platforms.AddLast("osx");
					if (testUserAgentPlatform("Safari"))
					{
						_platforms.AddLast("safari");
					}
				}
				if (testUserAgentPlatform("Linux"))
				{
					_platforms.AddLast("linux");
				}
				if (testUserAgentPlatform("iPad"))
				{
					_platforms.AddLast("ios");
				}
				if (testUserAgentPlatform("iPhone"))
				{
					_platforms.AddLast("ios");
				}
				if (testUserAgentPlatform("iPod"))
				{
					_platforms.AddLast("ios");
				}
				if (testUserAgentPlatform("Android"))
				{
					_platforms.AddLast("android");
				}
				if (testUserAgentPlatform("Firefox"))
				{
					_platforms.AddLast("firefox");
				}
				if (testUserAgentPlatform("Chrome"))
				{
					_platforms.AddLast("chrome");
				}
				if (testUserAgentPlatform("Opera"))
				{
					_platforms.AddLast("opera");
				}
				if (testUserAgentPlatform("MSIE") || testUserAgentPlatform("Trident"))
				{
					_platforms.AddLast("msie");
				}
#end
    }

    private function initializeUserFlags() {
    }

    private function initializeDefaultFunctions() {
        var options = this;

        if (_materialFunction == null) {
            _materialFunction = function(UnnamedParameter1, material) {
                return material;
            };
        }

        if (_textureFunction == null) {
            _textureFunction = function(UnnamedParameter1, texture) {
                return texture;
            };
        }

        if (_geometryFunction == null) {
            _geometryFunction = function(UnnamedParameter1, geom) {
                return geom;
            };
        }

        if (_uriFunction == null) {
            _uriFunction = function(uri) {
                return uri;
            };
        }

        if (_nodeFunction == null) {
            _nodeFunction = function(node) {
                return node;
            };
        }

        if (_effectFunction == null) {
            _effectFunction = function(effect) {
                return effect;
            };
        }


        _textureFormatFunction = function(availableTextureFormats:Array<TextureFormat>) {
            var defaultTextureFormats:Array<TextureFormat> = [TextureFormat.RGBA_PVRTC2_2BPP,
            TextureFormat.RGBA_PVRTC2_4BPP,
            TextureFormat.RGBA_PVRTC1_2BPP,
            TextureFormat.RGBA_PVRTC1_4BPP,
            TextureFormat.RGB_PVRTC1_2BPP,
            TextureFormat.RGB_PVRTC1_4BPP,
            TextureFormat.RGBA_DXT5,
            TextureFormat.RGBA_DXT3,
            TextureFormat.RGBA_ATITC,
            TextureFormat.RGB_ATITC,
            TextureFormat.RGBA_ETC1,
            TextureFormat.RGB_ETC1,
            TextureFormat.RGBA_DXT1,
            TextureFormat.RGB_DXT1,
            TextureFormat.RGBA,
            TextureFormat.RGB];

            var textureFormats:Array<TextureFormat> = options._textureFormats.length == 0 ? defaultTextureFormats : options._textureFormats;

            var textureFormatIt = Lambda.find(textureFormats, function(textureFormat) {
                return Lambda.has(availableTextureFormats, textureFormat);
            });

            if (textureFormatIt != null) {
                return textureFormatIt;
            }

            if (Lambda.has(textureFormats, TextureFormat.RGB) && Lambda.has(availableTextureFormats, TextureFormat.RGBA)) {
                return TextureFormat.RGBA;
            }

            if (Lambda.has(textureFormats, TextureFormat.RGBA) && Lambda.has(availableTextureFormats, TextureFormat.RGB)) {
                return TextureFormat.RGB;
            }

            var errorMessage = "No desired texture format available";
            throw (errorMessage);
        };

        if (_material == null) {
            _material = _defaultMaterial;
        }

        if (_attributeFunction == null) {
            _attributeFunction = function(node, key, value) {
            };
        }

        _parserFunction = null;

        if (_preventLoadingFunction == null) {
            _preventLoadingFunction = function(filename) {
                return false;
            };
        }
    }

    private function resetNotInheritedValues() {
        seekingOffset = (0);
        seekedLength = (0);
    }

    private function defaultProtocolFunction(filename:String) {
        var protocol = "";
        var index = 0;
        for (i in 0...filename.length) {
            if (i < filename.length - 2 && filename.charAt(i) == ':' && filename.charAt(i + 1) == '/' && filename.charAt(i + 2) == '/') {
                break;
            }
            protocol += filename.charAt(i);
            index = i;
        }
        if (index != filename.length) {
            var loader = getProtocol(protocol);

            if (loader != null) {
                return loader;
            }
        }
        return getProtocol("file");
    }

#if MINKO_PLATFORM & MINKO_PLATFORM_HTML5
			private bool testUserAgentPlatform(string platform)
			{
				string script = "navigator.userAgent.indexOf(\"" + platform + "\") < 0 ? 0 : 1";

				return emscripten_run_script_int(script) == 1;
			}
#end


}
