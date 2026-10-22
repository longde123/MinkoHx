package minko.render;
import Array;
import StringBuf;
import Std;
import minko.Tuple;
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
    public var isEmpty(get,null):Bool;

    function get_isEmpty():Bool {
        return _macros.length == 0;
    }

    function get_key():String {
        var b = new StringBuf();
        b.add(_macros.length + ":");
        for (macroName in _macros) {
            b.add(macroName.length + ":" + macroName);
        }
        b.add("|" + _values.length + ":");
        for (value in _values) {
            var s = Std.string(value);
            b.add(s.length + ":" + s);
        }
        b.add("|" + _types.length + ":");
        for (type in _types) {
            b.add(Std.string(type) + ",");
        }
        b.add("|" + _mask.length + ":");
        for (defined in _mask) {
            b.add(defined ? "1" : "0");
        }
        return b.toString();
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

    public function bind(macroBindings:MacroBindingMap, variables:Array<Tuple<String, String>>, targetData:Store, rendererData:Store, rootData:Store) {
        this._mask = [for (i in 0..._maxNumMacros) false];
        _values = [];
        _macros = [];
        _types = [];

        var macroId = 0;
        for (provider in macroBindings.defaultValues.providers) {
            for (propertyNameAndValue in provider.keys()) {
                if (!macroBindings.bindings.exists(propertyNameAndValue)) {
                    if (macroId == _maxNumMacros) {
                        throw "ProgramSignature: more than " + _maxNumMacros + " default macros";
                    }

                    _macros.push(propertyNameAndValue);
                    var type:Null<MacroType> = macroBindings.types.get(propertyNameAndValue);
                    if (type == null) {
                        type = MacroType.UNSET;
                    }
                    _types.push(type);
                    if (type != MacroType.UNSET) {
                        _values.push(provider.get(propertyNameAndValue));
                    } else {
                        _values.push(MacroType.UNSET);
                    }
                    _mask[macroId] = true;
                    ++macroId;
                }
            }
        }

        for (macroNameAndBinding in macroBindings.bindings.keys()) {
            var macroName:String = macroNameAndBinding;
            var macroBinding:MacroBinding = macroBindings.bindings.get(macroNameAndBinding);
            var propertyName = Store.getActualPropertyName(variables, macroBinding.propertyName);

            var store:Store = targetData;
            if (macroBinding.source != Source.TARGET) {
                store = (macroBinding.source == Source.RENDERER ? rendererData : rootData);
            }

            var type:Null<MacroType> = macroBindings.types.get(macroName);
            if (type == null) {
                type = MacroType.UNSET;
            }

            var hasValue = store.hasProperty(propertyName);
            var valueStore = store;
            var valuePropertyName = propertyName;
            if (!hasValue && macroBindings.defaultValues.hasProperty(macroName)) {
                hasValue = true;
                valueStore = macroBindings.defaultValues;
                valuePropertyName = macroName;
            }
            else if (!hasValue && macroBindings.defaultValues.hasProperty(propertyName)) {
                hasValue = true;
                valueStore = macroBindings.defaultValues;
                valuePropertyName = propertyName;
            }

            if (hasValue) {
                // WARNING: we do not support more than 64 macro bindings
                if (macroId == _maxNumMacros) {
                    throw "ProgramSignature: more than " + _maxNumMacros + " macros";
                }
                _macros.push(macroName);
                _types.push(type);
                if (type != MacroType.UNSET) {
                    var value = getValueFromStore(valueStore, valuePropertyName, type);

                    if (type == MacroType.INT) {
                        value = Math.max(macroBinding.minValue, Math.min(macroBinding.maxValue, value));
                    }

                    _values.push(value);
                } else {
                    _values.push(MacroType.UNSET);
                }
                _mask[macroId] = true;
                ++macroId;
            }
        }
    }

    public function copyFrom(signature:ProgramSignature):ProgramSignature {
        this._mask = signature._mask.concat([]);
        this._values = signature._values.concat([]);
        this._types = signature._types.concat([]);
        this._macros = signature._macros.concat([]);
        return this;
    }

    public function updateProgram(program:Program) {
        for (macroIndex in 0..._maxNumMacros) {
            if (_mask[macroIndex] == true) {
                var type:Null<MacroType> = _types[macroIndex];
                if (type == null) {
                    type = MacroType.UNSET;
                }
                switch (type) {
                    case MacroType.UNSET:
                        program.define(_macros[macroIndex]);
                    default:
                        program.setDefine(_macros[macroIndex], formatMacroValue(type, _values[macroIndex]));
                }
            }
        }
    }

    static function formatMacroValue(type:MacroType, value:Any):String {
        switch (type) {
            case MacroType.FLOAT2:
                return formatVector(value, "vec2", 2);
            case MacroType.FLOAT3:
                return formatVector(value, "vec3", 3);
            case MacroType.FLOAT4:
                return formatVector(value, "vec4", 4);
            case MacroType.INT2:
                return formatVector(value, "ivec2", 2);
            case MacroType.INT3:
                return formatVector(value, "ivec3", 3);
            case MacroType.INT4:
                return formatVector(value, "ivec4", 4);
            case MacroType.BOOL2:
                return formatVector(value, "bvec2", 2);
            case MacroType.BOOL3:
                return formatVector(value, "bvec3", 3);
            case MacroType.BOOL4:
                return formatVector(value, "bvec4", 4);
            case MacroType.FLOAT9:
                return formatMatrix(value, "mat3", 3);
            case MacroType.FLOAT16:
                return formatMatrix(value, "mat4", 4);
            default:
                return Std.string(value);
        }
    }

    static function formatVector(value:Any, prefix:String, size:Int):String {
        var components = getComponents(value, size);
        if (components == null) {
            return Std.string(value);
        }
        return prefix + "(" + components.join(", ") + ")";
    }

    static function formatMatrix(value:Any, prefix:String, size:Int):String {
        if (Std.isOfType(value, Array)) {
            var array:Array<Any> = cast value;
            if (array.length >= size * size) {
                var components = [for (i in 0...(size * size)) Std.string(array[i])];
                return prefix + "(" + components.join(", ") + ")";
            }
        }
        else if (value != null) {
            var components = [];
            var complete = true;
            for (row in 0...size) {
                for (column in 0...size) {
                    var name = "r" + row + "c" + column;
                    if (!Reflect.hasField(value, name)) {
                        complete = false;
                        break;
                    }
                    components.push(Std.string(Reflect.field(value, name)));
                }
                if (!complete) {
                    break;
                }
            }
            if (complete) {
                return prefix + "(" + components.join(", ") + ")";
            }
        }
        return Std.string(value);
    }

    static function getComponents(value:Any, size:Int):Array<String> {
        if (Std.isOfType(value, Array)) {
            var array:Array<Any> = cast value;
            if (array.length >= size) {
                return [for (i in 0...size) Std.string(array[i])];
            }
            return null;
        }
        if (value == null) {
            return null;
        }
        var names = ["x", "y", "z", "w"];
        var components = [];
        for (i in 0...size) {
            if (!Reflect.hasField(value, names[i])) {
                return null;
            }
            components.push(Std.string(Reflect.field(value, names[i])));
        }
        return components;
    }

    public function getValueFromStore(store:Store, propertyName:String, type:MacroType):Any {
        switch (type) {
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
                throw "ProgramSignature: cannot read a value for an UNSET macro";
        }

        throw "ProgramSignature: unsupported macro type " + type;
    }

    public function dispose():Void {
    }
}
