package minko.render;

import haxe.ds.StringMap;
import minko.data.Binding;
import minko.data.Provider;
import minko.file.EffectParser.Technique;
import minko.material.Material;
import minko.Uuid.Has_uuid;
typedef OnPassFunction = Pass -> Void;
typedef OnPassFunctionList = Array<OnPassFunction>;
@:expose("minko.render.Effect")
class Effect extends Has_uuid {
    private var _name:String;

    private var _techniques:StringMap<Array<Pass>>;
    private var _fallback:StringMap<String> ;
    private var _data:Provider;

    private var _uniformFunctions:OnPassFunctionList;
    private var _attributeFunctions:OnPassFunctionList;
    private var _macroFunctions:OnPassFunctionList;

    public static function create(name = "") {
        return new Effect(name);
    }

    public static function createbyTechnique(name, passes:Array<Pass>) {
        var effect:Effect = create(name);

        effect._techniques.set("default", passes);

        return effect;
    }

    override function get_uuid() {
        return _data.uuid;
    }

    public var name(get, null):String;

    function get_name() {
        return _name;
    }

    public var techniques(get, null):StringMap<Array<Pass>>;

    function get_techniques() {
        return _techniques;
    }
    public var data(get, null):Provider;

    function get_data() {
        return _data;
    }

    public function technique(techniqueName) {
        if (!hasTechnique(techniqueName)) {
            throw ("techniqueName = " + techniqueName);
        }

        return _techniques.get(techniqueName);
    }


    public function fallback(techniqueName) {
        var foundFallbackIt = _fallback.exists(techniqueName);

        if (foundFallbackIt == false) {
            throw ("techniqueName = " + techniqueName);
        }

        return _fallback.get(techniqueName);
    }

    public function hasTechnique(techniqueName) {
        return _techniques.exists(techniqueName) != false;
    }

    public function hasFallback(techniqueName) {
        return _fallback.exists(techniqueName) != false;
    }

    private static function setUniformOnPass(pass:Pass, name, values:Array<Any>) {
        pass.setUniform(name, values);
    }

    public function setUniform(name, values:Array<Any>) {
        _uniformFunctions.push(function(pass) {
            setUniformOnPass(pass, name, values);
        });

        for (technique in _techniques.iterator()) {
            for (pass in technique) {
                pass.setUniform(name, values);
            }
        }
    }

    public function setAttribute(name, attribute:VertexAttribute) {
        _attributeFunctions.push(function(pass) {
            setVertexAttributeOnPass(pass, name, attribute);
        });


        for (technique in _techniques.iterator()) {
            for (pass in technique) {
                pass.setAttribute(name, attribute);
            }
        }
    }

    public function define(macroName) {


        _macroFunctions.push(function(pass) {
            defineOnPass(pass, macroName);
        });


        for (technique in _techniques.iterator()) {
            for (pass in technique) {
                pass.define(macroName);
            }
        }
    }

    public function setDefine(macroName, macroValue:Any) {
        _macroFunctions.push(function(pass) {
            defineOnPassWithValue(pass, macroName, macroValue);
        });

        for (technique in _techniques.iterator()) {
            for (pass in technique) {
                pass.setDefine(macroName, macroValue);
            }
        }
    }

    public function addTechnique(name, passes:Technique) {
        if (hasTechnique(name))
            throw ("A technique named '" + name + "' already exists.");

        for (pass in passes) {
            for (func in _uniformFunctions)
                func(pass);
            for (func in _attributeFunctions)
                func(pass);
            for (func in _macroFunctions)
                func(pass);
        }
        _techniques.set(name, passes);
    }

    public function addTechniqueFallback(name, passes:Technique, fallback) {
        _fallback.set(name, fallback);

        addTechnique(name, passes);
    }

    public function removeTechnique(name) {
        if (!hasTechnique(name)) {
            throw ("The technique named '" + name + "' does not exist.");
        }

        _techniques.remove(name);
        _fallback.remove(name);
    }


    public function initializeMaterial(material:Material, technique = "default") {
        fillMaterial(material, technique);

        return material;
    }

    public function new(name = "") {
        super();
        this._data = Provider.create();
        this._name = name;

        this._techniques = new StringMap<Array<Pass>>();
        this._fallback = new StringMap<String>() ;

        this._uniformFunctions = new OnPassFunctionList();
        this._attributeFunctions = new OnPassFunctionList();
        this._macroFunctions = new OnPassFunctionList();
    }


    private static function setVertexAttributeOnPass(pass:Pass, name:String, attribute:VertexAttribute) {
        pass.setAttribute(name, attribute);
    }

    private static function defineOnPass(pass:Pass, macroName:String) {
        pass.define(macroName);
    }


    private static function defineOnPassWithValue(pass:Pass, macroName:String, macroValue:Any) {
        pass.setDefine(macroName, macroValue);
    }

    private function fillMaterial(material:Material, technique:String) {
        var passes:Array<Pass> = _techniques.get(technique);

        for (pass in passes) {
            // material properties are set using uniforms, thus we only read the default values
            // for uniforms
            var defaultValues = pass.uniformBindings.defaultValues.providers[0];
            for (nameAndBinding in pass.uniformBindings.bindings.keys()) {
                var uniformName = nameAndBinding;
                var nameAndBinding_second:Binding = pass.uniformBindings.bindings.get(nameAndBinding);
                if (defaultValues.hasProperty(uniformName)) {
                    var pos = nameAndBinding_second.propertyName.indexOf("material[@{materialUuid}].");

                    if (pos == 0) {
                        material.data.set(nameAndBinding_second.propertyName.substr(pos + 26), defaultValues.get(uniformName));
                    }
                }
            }
        }
    }

}
