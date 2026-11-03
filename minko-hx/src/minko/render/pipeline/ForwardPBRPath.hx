package minko.render.pipeline;

import minko.render.target.RenderTarget;

typedef ForwardSceneDraw = RenderQueue -> FrameContext -> RenderTarget -> Void;

/**
 * Forward PBR render path.
 *
 * Kept as a compatibility specialization of ForwardPath: same graph, same
 * fields, with the historical "forward-pbr" path name and "ForwardPBRPass"
 * pass name.
 */
class ForwardPBRPath extends ForwardPath {
    public function new(renderScene:ForwardSceneDraw = null, postProcess:PostProcessChain = null) {
        super(renderScene, postProcess, "forward-pbr", "ForwardPBRPass");
    }
}
