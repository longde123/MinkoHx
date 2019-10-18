package minko.render;
@:expose("minko.render.InputType")
@:enum abstract InputType(Int) from Int to Int
{
    var unknown = 0;
    var int1 = 1;
    var int2 = 2;
    var int3 = 3;
    var int4 = 4;
    var bool1 = 5;
    var bool2 = 6;
    var bool3 = 7;
    var bool4 = 8;
    var float1 = 9;
    var float2 = 10;
    var float3 = 11;
    var float4 = 12;
    var float9 = 13;
    var float16 = 14;
    var sampler2d = 15;
    var samplerCube = 16;
}
@:expose("minko.render.AbstractInput")

@:expose("minko.render.UniformInput")
class UniformInput{
    public var type:InputType;
    public var size:Int;
    public var name:String;
    public var location:Int;

    public function new(name, location, size, type) {
        this.name = name;
        this.location = location;
        this.size = size;
        this.type = (type);
    }
}
@:expose("minko.render.AttributeInput")
class AttributeInput  {
    public var name:String;
    public var location:Int;

    public function new(name, location) {
        this.name = name;
        this.location = location;
    }
}
@:expose("minko.render.ProgramInputs")
class ProgramInputs {

    private var _uniforms:Array<UniformInput>;
    private var _attributes:Array<AttributeInput>;

    public static function typeToString(type:InputType) {
        switch (type)
        {
            case InputType.unknown:
                return "unknown";
            case InputType.int1:
                return "int1";
            case InputType.int2:
                return "int2";
            case InputType.int3:
                return "int3";
            case InputType.int4:
                return "int4";
            case InputType.bool1:
                return "bool1";
            case InputType.bool2:
                return "bool2";
            case InputType.bool3:
                return "bool3";
            case InputType.bool4:
                return "bool4";
            case InputType.float1:
                return "float1";
            case InputType.float2:
                return "float2";
            case InputType.float3:
                return "float3";
            case InputType.float4:
                return "float4";
            case InputType.float9:
                return "float9";
            case InputType.float16:
                return "float16";
            case InputType.sampler2d:
                return "sampler2d";
            case InputType.samplerCube:
                return "samplerCube";
            default:
                throw ("type");
        }
    }

    public var uniforms(get, null):Array<UniformInput>;
    public var attributes(get, null):Array<AttributeInput>;

    function get_uniforms() {
        return _uniforms;
    }

    function get_attributes() {
        return _attributes;
    }

    public function new() {
        this._uniforms = [];
        this._attributes = [];
    }

    public function copyFrom(inputs:ProgramInputs) {
        this._uniforms = inputs._uniforms.concat([]);
        this._attributes = inputs._attributes.concat([]);
        return this;
    }


    public function setProgramInputs(uniforms:Array<UniformInput>, attributes:Array<AttributeInput>) {
        this._uniforms = uniforms.concat([]);
        this._attributes = attributes.concat([]);
    }


}
