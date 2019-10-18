package minko.render;
import minko.Uuid.Enable_uuid;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.io.Error;
import minko.component.Renderer.EffectVariables;
import minko.data.BindingMap;
import minko.data.Store;
typedef ProgramFunc = Program -> Void ;

@:expose("minko.render.Pass")
class Pass  extends Enable_uuid {

    private var _name:String;
    private var _isForward:Bool;
    private var _programTemplate:Program;
    private var _attributeBindings:BindingMap ;
    private var _uniformBindings:BindingMap ;
    private var _stateBindings:BindingMap ;
    private var _macroBindings:MacroBindingMap;
    private var _states:States;

    private var _signatureToProgram:ObjectMap<ProgramSignature, Program> ;
    private var _signature:StringMap<ProgramSignature>;
    private var _uniformFunctions:StringMap<ProgramFunc>;
    private var _attributeFunctions:StringMap<ProgramFunc>;
    private var _macroFunctions:StringMap<ProgramFunc>;



    public function dispose() {
        for (signatureAndProgram in _signatureToProgram.iterator()) {
            if (signatureAndProgram != null) {
                signatureAndProgram.dispose();
            }
        }
    }

    public static function create(name, isForward, program, attributeBindings, uniformBindings, stateBindings, macroBindings) {
        return new Pass(name, isForward, program, attributeBindings, uniformBindings, stateBindings, macroBindings);
    }

    public static function createbyPass(pass:Pass, deepCopy = false) {
        var p:Pass = create(pass._name, pass._isForward, deepCopy ? Program.createbyProgram(pass._programTemplate, deepCopy) : pass._programTemplate, pass._attributeBindings, pass._uniformBindings, pass._stateBindings, pass._macroBindings);

        for (signatureProgram in pass._signatureToProgram.keys()) {
            var programSignature:ProgramSignature = new ProgramSignature().copyFrom(signatureProgram);
            p._signatureToProgram.set(programSignature, pass._signatureToProgram.get(signatureProgram));
            p._signature.set(programSignature.key, programSignature);
        }

        p._uniformFunctions = pass._uniformFunctions;
        p._attributeFunctions = pass._attributeFunctions;
        p._macroFunctions = pass._macroFunctions;

        if (pass._programTemplate.isReady) {
            for (nameAndFunc in p._uniformFunctions.iterator()) {
                nameAndFunc(pass._programTemplate);
            }
            for (nameAndFunc in p._attributeFunctions.iterator()) {
                nameAndFunc(pass._programTemplate);
            }
            for (nameAndFunc in p._macroFunctions.iterator()) {
                nameAndFunc(pass._programTemplate);
            }
        }

        return p;
    }
    public var name(get, null):String;

    function get_name() {
        return _name;
    }

    public var isForward(get, null):Bool;

    function get_isForward() {
        return _isForward;
    }
    public var program(get, null):Program;

    function get_program() {
        return _programTemplate;
    }
    public var attributeBindings(get, null):BindingMap;

    function get_attributeBindings() {
        return _attributeBindings;
    }
    public var uniformBindings(get, null):BindingMap;

    function get_uniformBindings() {
        return _uniformBindings;
    }
    public var stateBindings(get, null):BindingMap;

    function get_stateBindings() {
        return _stateBindings;
    }
    public var macroBindings(get, null):MacroBindingMap;

    function get_macroBindings() {
        return _macroBindings;
    }
    public var states(get, null):States;

    function get_states() {
        return _states;
    }

    //todo
    public function setUniform(name:String, values:Array<Any>) {

        _uniformFunctions.set(name, function(program:Program) {
            setUniformOnProgram(program, name, values);
        });

        if (_programTemplate.isReady) {
            _programTemplate.setUniform(name, values);
        }
        for (signatureAndProgram in _signatureToProgram.iterator()) {
            signatureAndProgram.setUniform(name, values);
        }
    }

    public function setAttribute(name:String, attribute:VertexAttribute) {
        _attributeFunctions.set(name, function(program:Program) {
            setVertexAttributeOnProgram(program, name, attribute);
        });

        if (_programTemplate.isReady) {
            _programTemplate.setAttributebyName(name, attribute);
        }
        for (signatureAndProgram in _signatureToProgram) {
            signatureAndProgram.setAttributebyName(name, attribute);
        }
    }

    public function define(macroName:String) {
        _macroFunctions.set(macroName, function(program:Program) {
            defineOnProgram(program, macroName);
        });

        _programTemplate.define(macroName);
    }


    public function setDefine(macroName:String, macroValue:Any) {

        _macroFunctions.set(macroName, function(program:Program) {
            defineOnProgramWithValue(program, macroName, macroValue);
        });
        _programTemplate.setDefine(macroName, macroValue);
    }

    private static function setUniformOnProgram(program:Program, name:String, values:Array<Any>) {
        program.setUniform(name, values);
    }

    private static function setVertexAttributeOnProgram(program:Program, name:String, attribute:VertexAttribute) {
        program.setAttributebyName(name, attribute);
    }

    private static function defineOnProgram(program:Program, macroName:String) {
        program.define(macroName);
    }


    private static function defineOnProgramWithValue<T>(program:Program, macroName:String, value:T) {
        //todo
        //  program.setDefine(macroName, value);
    }

    public function new(name, isForward, program:Program, attributeBindings:BindingMap, uniformBindings:BindingMap, stateBindings:BindingMap, macroBindings:MacroBindingMap) {
        this._name = name;
        this._isForward = isForward;
        this._programTemplate = program;
        this._attributeBindings = BindingMapBase.copyFrom(new BindingMap(), attributeBindings);
        this._uniformBindings = BindingMapBase.copyFrom(new BindingMap(), uniformBindings);
        this._stateBindings = BindingMapBase.copyFrom(new BindingMap(), stateBindings);
        this._macroBindings = MacroBindingMap.copyFrom2(new MacroBindingMap(), macroBindings);
        //todo
        this._states = States.createbyProvider(_stateBindings.defaultValues.providers[0]) ;
        this._signatureToProgram = new ObjectMap<ProgramSignature, Program>();
        this._uniformFunctions = new StringMap<ProgramFunc>();
        this._attributeFunctions = new StringMap<ProgramFunc>();
        this._macroFunctions = new StringMap<ProgramFunc>();
        this._signature = new StringMap<ProgramSignature>();
        super();
        enable_uuid();
    }

    public function selectProgram(vars:EffectVariables, targetData:Store, rendererData:Store, rootData:Store):Tuple<Program, ProgramSignature> {
        var program:Program = null;
        var signature:ProgramSignature = new ProgramSignature();


        if (Lambda.count(_macroBindings.bindings) == 0) {
            program = _programTemplate;
        }
        else {

            //todo  get value hask


            signature.bind(_macroBindings, vars, targetData, rendererData, rootData);
            var signatureKey =signature.key;

            var foundProgramIt =    _signature.exists(signatureKey);
            if (foundProgramIt) {
                signature.dispose();
                signature = _signature.get(signatureKey);
                program = _signatureToProgram.get(signature);
                return new Tuple<Program, ProgramSignature>(program, signature);

            }
            else {
                _signature.set(signatureKey, signature);
                program = Program.createbyProgram(_programTemplate, true);
                _signatureToProgram.set(signature, program);
                signature.updateProgram(program);

            }

        }
        return new Tuple<Program, ProgramSignature>(finalizeProgram(program), signature);

    }

    public function finalizeProgram(program:Program) {
        if (!program.vertexShader.isReady) {
            program.vertexShader.upload();
        }
        if (!program.fragmentShader.isReady) {
            program.fragmentShader.upload();
        }
        if (!program.isReady) {
            try {
                program.upload();
            } catch (e:Error) {
                throw e;

            }


            for (nameAndFunc in _uniformFunctions.iterator()) {
                nameAndFunc(program);
            }
            for (nameAndFunc in _attributeFunctions.iterator()) {
                nameAndFunc(program);
            }
            for (nameAndFunc in _macroFunctions.iterator()) {
                nameAndFunc(program);
            }
        }

        return program;
    }

}
