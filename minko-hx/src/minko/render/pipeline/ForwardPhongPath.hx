package minko.render.pipeline;

import minko.render.target.RenderTarget;

/**
 * Forward Phong render path.
 *
 * Same graph/post/shadow structure as ForwardPBRPath, with a Phong-specific
 * path and pass name.
 */
class ForwardPhongPath extends ForwardPath {
    public function new(renderScene:RenderQueue -> FrameContext -> RenderTarget -> Void = null,
                        postProcess:PostProcessChain = null) {
        super(renderScene, postProcess, "forward-phong", "ForwardPhongPass");
    }
}
