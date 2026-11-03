package minko.render.pipeline;

/**
 * Render stage a PipelineTechnique is written for.
 *
 * A PipelineEffect holds at most one technique per stage. The stage is carried
 * by the technique itself, so effects do not need technique names or a legacy
 * Pass list.
 */
@:expose("minko.render.pipeline.EffectStage")
enum abstract EffectStage(Int) from Int to Int {
    var Forward = 0;
    var Transparent = 1;
    var GBuffer = 2;
    var Shadow = 3;
    var GBufferAlbedo = 4;
    var GBufferNormal = 5;
    var GBufferEmissive = 6;
}
