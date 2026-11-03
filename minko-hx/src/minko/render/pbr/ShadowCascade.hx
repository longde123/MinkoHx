package minko.render.pbr;

import glm.Mat4;
import minko.render.target.RenderTarget;

/**
 * One cascade of a directional CSM shadow set.
 *
 * `split` is the view-space far distance of the slice. The first cascade is
 * also exposed through FrameContext.shadowMap for single-map consumers.
 */
class ShadowCascade {
    public var target:RenderTarget;
    public var lightViewProjection:Mat4;
    public var split:Float;

    public function new(target:RenderTarget = null, lightViewProjection:Mat4 = null, split:Float = 0.0) {
        this.target = target;
        this.lightViewProjection = lightViewProjection != null ? lightViewProjection : Mat4.identity(new Mat4());
        this.split = split;
    }
}
