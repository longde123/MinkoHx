package minko.render;
import haxe.ds.StringMap;
@:expose("minko.render.ShaderType")
@:enum abstract ShaderType(Int) from Int to Int
{
    var VERTEX_SHADER = 0;
    var FRAGMENT_SHADER = 1;
}
@:expose("minko.render.Shader")
class Shader extends AbstractResource {
    private var _type:ShaderType;
    private var _source:String;
    private var _definedMacros:StringMap<String>;

    public function new(context, type) {
        super(context);
        this._type = type;
        _definedMacros = new StringMap<String>();
    }

    public function clearDefinedMacros():Void {
        _definedMacros = new StringMap<String>();
    }

    public static function create(context:AbstractContext, type:ShaderType):Shader {
        return new Shader(context, type);
    }

    public static function createbySource(context:AbstractContext, type:ShaderType, source:String):Shader {
        var s:Shader = create(context, type);

        s._source = source;


        return s;
    }

    public static function createbyShader(shader:Shader):Shader {
        var s:Shader = create(shader.context, shader._type);

        s._source = shader._source;
        for (k in shader._definedMacros.keys())
            s._definedMacros.set(k, shader._definedMacros.get(k));

        return s;
    }

    public var type(get, null):ShaderType;

    function get_type() {
        return _type;
    }
    public var source(get, set):String;

    function get_source() {
        return _source;
    }

    function set_source(v) {
        _source = v;
        return v;
    }

    public function define(macroName) {
        if (!Lambda.has(_definedMacros, macroName)) {
            _definedMacros.set(macroName, null);
        }
    }

    public function setDefine(macroName, value) {
        if (!Lambda.has(_definedMacros, macroName)) {
            _definedMacros.set(macroName, value );
        }
    }


    public override function dispose() {
        if (_type == ShaderType.VERTEX_SHADER) {
            _context.deleteVertexShader(_id);
        }
        else if (_type == ShaderType.FRAGMENT_SHADER) {
            _context.deleteFragmentShader(_id);
        }

        _id = -1;
    }

    public override function upload() {
        if (_type == ShaderType.VERTEX_SHADER) {
            _id = _context.createVertexShader();
        } else {
            _id = _context.createFragmentShader();
        }
        inline function defineToString(macroName){
            var value:String= _definedMacros.get(macroName);
            if (value!=null) {

                return "#define " + macroName + " " +value+ "\n";
            }
            return "#define " + macroName + "\n";
        }
//#if MINKO_PLATFORM & (MINKO_PLATFORM_ANDROID | MINKO_PLATFORM_IOS | MINKO_PLATFORM_HTML5)
        var source = "#version 100\n  " ;
        for (s in _definedMacros.keys()) {
            source += defineToString(s);

        }
        source += _source;
//#else
        //       var source = "#version 120\n" + _source;
//#end

        /*
        if (_type == ShaderType.VERTEX_SHADER) {
            //{ success: success, output: output, log: log };
            var vsShader= untyped __js__('optimizeShader({0}, {1})',source,"vs");
            if(vsShader.success){
                source=vsShader.output;
            }else{
                trace(vsShader.log);
            }
        }else{
            var fsShader= untyped __js__('optimizeShader({0}, {1})',source,"fs");
            if(fsShader.success){
                source=fsShader.output;
            }else{
                trace(fsShader.log);
            }
        } */


        _context.setShaderSource(_id, source);
       // trace(source);

        _context.compileShader(_id);
    }


}
