package minko.render;
import Array;
import minko.component.Renderer.EffectVariables;
import minko.data.Binding;
import minko.data.BindingMap.MacroBinding;
import minko.data.BindingMap.MacroBindingMap;
import minko.data.BindingMap.MacroType;
import minko.data.Store;
typedef MaskType = Array<Bool>;//64
@:expose("minko.render.ProgramSignature")
class ProgramSignature {
    public static inline var _maxNumMacros = 8 * 8;
    public var key(get,null):String;

    function get_key(){
        return  _macros.toString()+ _values.toString()+_types.toString()+_mask.toString();
    }
    private var _mask:MaskType;
    private var _values:Array<Any>;
    private var _types:Array<MacroType>;
    private var _macros:Array<String>;

    public function new() {
        this._mask = new MaskType();
        this._values = new Array<Any>();
        this._types = new Array<MacroType>();
        this._macros = new Array<String>();
    }

    public function bind(macroBindings:MacroBindingMap, variables:EffectVariables, targetData:Store, rendererData:Store, rootData:Store) {
        this._mask = [for (i in 0..._maxNumMacros) false];
        _values = [];//.reserve(_maxNumMacros);
        _macros = [];//.reserve(_maxNumMacros);
        _types = [];


        var macroId = 0;
        for (provider in macroBindings.defaultValues.providers) {
            for (propertyNameAndValue in provider.keys()) {
                if(!macroBindings.bindings.exists(propertyNameAndValue)){


                    _macros.push(propertyNameAndValue);
                    var type:MacroType = macroBindings.types.get(propertyNameAndValue);
                    _types.push(type);
                    if (type != MacroType.UNSET) {
                        _values.push(provider.get(propertyNameAndValue));
                    }else{
                        _values.push(MacroType.UNSET);
                    }
                    _mask[macroId] =true;
                    ++macroId;
                }
            }
        }

        for (macroNameAndBinding in macroBindings.bindings.keys()) {
            var macroName:String = macroNameAndBinding;

            var macroBinding:MacroBinding = macroBindings.bindings.get(macroNameAndBinding);
            if( macroName =="RADIANCE_MAP_MAX_LOD"){
                trace("radianceMap.maxAvailableLod");
            }
            var propertyName = Store.getActualPropertyName(variables, macroBinding.propertyName);
            var store:Store = targetData;
            if (macroBinding.source != Source.TARGET) {
                store = (macroBinding.source == Source.RENDERER ? rendererData : rootData);
            }
            var macroIsDefined = store.hasProperty(propertyName);
          //  var hasDefaultValue = macroBindings.defaultValues.hasProperty(propertyName);

            if (macroIsDefined){//} || hasDefaultValue) {
                var type:MacroType = macroBindings.types.get(macroName);

                // WARNING: we do not support more than 64 macro bindings
                if (macroId == _maxNumMacros) {
                    throw "";
                }
                _macros.push(macroName);
                _types.push(type);
                if (type != MacroType.UNSET) {
                    // update program signature
                    var value = getValueFromStore(macroIsDefined ? store : macroBindings.defaultValues, propertyName, type);

                    if (type == MacroType.INT) {
                        value = Math.max(macroBinding.minValue, Math.min(macroBinding.maxValue, value));
                    }

                    _values.push(value);
                }else{
                    _values.push(MacroType.UNSET);
                }
                _mask[macroId] = true;
                ++macroId;
            }
        }

    }

    public function copyFrom(signature:ProgramSignature):ProgramSignature {
        this._mask = signature._mask.concat([]);
        this._values = signature._values;
        this.key = signature.key;
        return this;
    }

    public function updateProgram(program:Program) {


        for (macroIndex in 0..._maxNumMacros) {
                if( _mask[macroIndex])
                switch (_types[macroIndex])
                {
                    case MacroType.UNSET:
                        program.define(_macros[macroIndex]);
                    case MacroType.BOOL:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.BOOL2:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.BOOL3:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.BOOL4:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.INT:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.INT2:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.INT3:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.INT4:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.FLOAT:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.FLOAT2:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.FLOAT3:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.FLOAT4:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.FLOAT9:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                    case MacroType.FLOAT16:
                        program.setDefine(_macros[macroIndex], (_values[macroIndex]));
                }
        }
    }

    public function getValueFromStore(store:Store, propertyName:String, type:MacroType) {
        switch (type)
        {
            case MacroType.BOOL:
                return store.get(propertyName);
            case MacroType.BOOL2:
                return store.get(propertyName);
            case MacroType.BOOL3:
                return store.get(propertyName);
            case MacroType.BOOL4:
                return store.get(propertyName);
            case MacroType.INT:
                return store.get(propertyName);
            case MacroType.INT2:
                return store.get(propertyName);
            case MacroType.INT3:
                return store.get(propertyName);
            case MacroType.INT4:
                return store.get(propertyName);
            case MacroType.FLOAT:
                return store.get(propertyName);
            case MacroType.FLOAT2:
                return store.get(propertyName);
            case MacroType.FLOAT3:
                return store.get(propertyName);
            case MacroType.FLOAT4:
                return store.get(propertyName);
            case MacroType.FLOAT9:
                return store.get(propertyName);
            case MacroType.FLOAT16:
                return store.get(propertyName);
            case MacroType.UNSET:
                throw "";
        }

        throw "";
    }

    public function dispose():Void {
        
    }
}
