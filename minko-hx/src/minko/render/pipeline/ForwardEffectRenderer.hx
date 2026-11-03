package minko.render.pipeline;

import minko.render.AbstractContext;
import minko.render.target.RenderTarget;

/**
 * Draws RenderItems using their PipelineEffect only.
 * This is the non-PBR forward renderer: it never falls back to PBR shaders or
 * PBR material data. Items without an effect are skipped unless a defaultEffect
 * is provided. The caller (ForwardPath) owns render target binding, clearing
 * and post-processing.
 */
class ForwardEffectRenderer {
    public var defaultEffect:PipelineEffect;

    private var _effects:PipelineEffectRenderer;

    public function new(context:AbstractContext, ?defaultEffect:PipelineEffect) {
        this.defaultEffect = defaultEffect;
        this._effects = new PipelineEffectRenderer(context);
    }

    /**
     * Draws into the currently bound target. `target` is accepted for the
     * ForwardSceneDraw signature and is not rebound here.
     */
    public function render(queue:RenderQueue, frame:FrameContext, target:RenderTarget):Void {
        if (queue == null) {
            return;
        }

        drawQueue(queue.opaque, EffectStage.Forward, frame);
        drawQueue(queue.alphaTest, EffectStage.Forward, frame);
        drawQueue(queue.transparent, EffectStage.Transparent, frame);
    }

    private function drawQueue(items:Array<RenderItem>, stage:EffectStage, frame:FrameContext):Void {
        for (item in items) {
            var effect = item.pipelineEffect != null ? item.pipelineEffect : defaultEffect;
            if (effect == null) {
                continue;
            }
            _effects.draw(item, effect, stage, frame);
        }
    }

    public function dispose():Void {
        if (_effects != null) {
            _effects.dispose();
            _effects = null;
        }
        defaultEffect = null;
    }
}
