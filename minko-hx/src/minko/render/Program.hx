package minko.render;
import minko.render.ProgramInputs.UniformInput;

@:expose("minko.render.Program")
class Program extends AbstractResource {
    private var _name:String;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _inputs:ProgramInputs;

    private var _setUniforms:Array<String>;
    private var _setTextures:Array<String>;
    private var _setAttributes:Array<String>;
    private var _definedMacros:Array<String>;

    public function new(_name, context) {
        super(context);
        this._name = _name;
        this._inputs = new ProgramInputs();

        this._setUniforms = new Array<String>();
        this._setTextures = new Array<String>();
        this._setAttributes = new Array<String>();
        this._definedMacros = new Array<String>();
    }

    public function clearDefinedMacros():Void {
        _definedMacros = [];
        _vertexShader.clearDefinedMacros();
        _fragmentShader.clearDefinedMacros();

    }

    public static function create(name, context):Program {
        return new Program(name, context);
    }

    public static function createbyProgram(program:Program, deepCopy = false) {
        var p:Program = create(program._name, program._context);

        p._vertexShader = deepCopy ? Shader.createbyShader(program._vertexShader) : program._vertexShader;
        p._fragmentShader = deepCopy ? Shader.createbyShader(program._fragmentShader) : program._fragmentShader;
        p._inputs =    new ProgramInputs();
        p._setTextures = [];
        p._setAttributes = [];

        return p;
    }

    public static function createbyShader(name, context, vertexShader, fragmentShader):Program {
        var p:Program = create(name, context);

        p._vertexShader = vertexShader;
        p._fragmentShader = fragmentShader;

        return p;
    }
    public var name(get, null):String;

    function get_name() {
        return _name;
    }

    public var vertexShader(get, null):Shader;

    function get_vertexShader() {
        return _vertexShader;
    }

    public var fragmentShader(get, null):Shader;

    function get_fragmentShader() {
        return _fragmentShader;
    }

    public var setTextureNames(get, null):Array<String>;

    function get_setTextureNames() {
        return _setTextures;
    }

    public var setAttributeNames(get, null):Array<String>;

    function get_setAttributeNames() {
        return _setAttributes;
    }

    public var setUniformNames(get, null):Array<String>;

    function get_setUniformNames() {
        return _setUniforms;
    }

    public var definedMacroNames(get, null):Array<String>;

    function get_definedMacroNames() {
        return _definedMacros;
    }

    public var inputs(get, null):ProgramInputs;

    function get_inputs() {
        return _inputs;
    }

    public override function upload() {
        _id = context.createProgram();
        _context.attachShader(_id, _vertexShader.id);
        _context.attachShader(_id, _fragmentShader.id);
        _context.linkProgram(_id);

        _inputs.copyFrom(_context.getProgramInputs(_id));
    }

    public override function dispose() {
        if (_id != -1) {
            _context.deleteProgram(_id);
            _id = -1;
        }

        _vertexShader = null;
        _fragmentShader = null;
    }

    public function setUniform(name, v:Array<Any>) {
        //todo
        //type, size
        //return setUniform<T, 1>(name, 1, &v);
    }

    inline function setUniformFloat(size, name, count, v) {

        var it:UniformInput = Lambda.find(_inputs.uniforms, function(u:UniformInput) {
            return u.name == name;
        });

        if (it != null) {
            var oldProgram = _context.currentProgram ;

            _context.setProgram(_id);

            switch(size){
                case 1 :
                    _context.setUniformFloat(it.location, count, v);
                case 2 :
                    _context.setUniformFloat2(it.location, count, v);
                case 3 :
                    _context.setUniformFloat3(it.location, count, v);
                case 4 :
                    _context.setUniformFloat4(it.location, count, v);
                case 16:
                    _context.setUniformMatrix4x4(it.location, count, v);
            }
            _context.setProgram(oldProgram);

            _setUniforms.push(name);
        }

        return this;
    }

    inline function setUniformInt(size, name, count, v) {

        var it:UniformInput = Lambda.find(_inputs.uniforms, function(u:UniformInput) {
            return u.name == name;
        });

        if (it != null) {
            var oldProgram = _context.currentProgram ;

            _context.setProgram(_id);

            switch(size){
                case 1 :
                    _context.setUniformInt(it.location, count, v);
                case 2 :
                    _context.setUniformInt2(it.location, count, v);
                case 3 :
                    _context.setUniformInt3(it.location, count, v);
                case 4 :
                    _context.setUniformInt4(it.location, count, v);
            }
            _context.setProgram(oldProgram);

            _setUniforms.push(name);
        }

        return this;
    }


    public function setUniformFloat1(name, v) {
        return setUniformFloat(1, name, 1, v);
    }


    public function setUniformFloat2(name, value) {
        return setUniformFloat(2, name, 1, value);
    }


    public function setUniformFloat3(name, value) {
        return setUniformFloat(3, name, 1, value);
    }


    public function setUniformFloat4(name, value) {
        return setUniformFloat(4, name, 1, value);
    }

    public function setUniformMatrix4x4(name, value) {
        return setUniformFloat(16, name, 1, value);
    }

    public function setUniformInt1(name, v) {
        return setUniformInt(1, name, 1, v);
    }


    public function setUniformInt2(name, value) {
        return setUniformInt(2, name, 1, value);
    }


    public function setUniformInt3(name, value) {
        return setUniformInt(3, name, 1, value);
    }


    public function setUniformInt4(name, value) {
        return setUniformInt(4, name, 1, value);
    }

    public function setUniformAbstractTexture(name:String, texture:AbstractTexture) {

        var it:UniformInput = Lambda.find(_inputs.uniforms, function(u:UniformInput) {
            return u.name == name;
        });

        if (it != null) {
            var oldProgram = _context.currentProgram ;

            _context.setTextureAt(_setTextures.length, texture.id, it.location);
            _context.setProgram(oldProgram);

            _setTextures.push(name);
            _setUniforms.push(name);
        }

        return this;
    }


    public function define(macroName) {
        _vertexShader.define(macroName);
        _fragmentShader.define(macroName);
        _definedMacros.push(macroName);

        return this;
    }


    public function setDefine(macroName, value) {
        _vertexShader.setDefine(macroName, value);
        _fragmentShader.setDefine(macroName, value);
        _definedMacros.push(macroName);

        return this;
    }

    public function setAttributebyName(name:String, attribute:VertexAttribute) {
        return setAttribute(name, attribute, name);
    }

    public function setAttribute(name:String, attribute:VertexAttribute, attributeName:String) {

        var it:ProgramInputs.AttributeInput = Lambda.find(_inputs.attributes, function(a:ProgramInputs.AttributeInput) {
            return a.name == name;
        });

        if (it != null) {
            var oldProgram = _context.currentProgram ;

            _context.setVertexBufferAt(it.location, attribute.resourceId, attribute.size, attribute.vertexSize, attribute.offset);
            _context.setProgram(oldProgram);

            _setAttributes.push(name);
        }

        return this;
    }


}
