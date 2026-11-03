package minko.render.pipeline;

import haxe.ds.StringMap;

/**
 * One stage of a PipelineEffect: shader sources, uniform bindings, state and
 * compile-time macros.
 *
 * A technique owns no GPU resource; PipelineEffectRenderer compiles and caches
 * the Program on first use. Macro definitions are applied when the program is
 * compiled (#define lines prepended to both shader sources).
 */
class PipelineTechnique {
    public var name:String;
    public var stage:EffectStage;
    public var vertexSource:String;
    public var fragmentSource:String;
    public var uniforms:Array<PipelineUniform>;
    public var state:PipelineState;
    public var macros:StringMap<String>;
    public var macroVersion:Int;

    public function new(stage:EffectStage, vertexSource:String, fragmentSource:String,
                        ?uniforms:Array<PipelineUniform>, ?state:PipelineState, ?name:String = "",
                        ?macros:StringMap<String>) {
        this.name = name;
        this.stage = stage;
        this.vertexSource = vertexSource;
        this.fragmentSource = fragmentSource;
        this.uniforms = uniforms == null ? [] : uniforms;
        this.state = state == null ? PipelineState.opaque() : state;
        this.macros = macros == null ? new StringMap<String>() : macros;
        this.macroVersion = 0;
    }

    /**
     * Adds a compile-time macro.
     *
     * An empty value produces a bare "#define NAME"; a non-empty value produces
     * "#define NAME value". Use a null value to suppress an inherited macro.
     */
    public function addMacro(name:String, value:String = ""):PipelineTechnique {
        macros.set(name, value);
        macroVersion++;
        return this;
    }
}
