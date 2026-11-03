package minko.render.pbr;

import glm.Mat4;
import minko.render.target.RenderTarget;

class SpotShadow {
    public var target:RenderTarget;
    public var atlas:RenderTarget;
    public var cell:Int;
    public var lightViewProjection:Mat4;
    public var lightIndex:Int;

    public function new(target:RenderTarget = null, lightViewProjection:Mat4 = null, lightIndex:Int = -1) {
        this.target = target;
        this.atlas = null;
        this.cell = 0;
        this.lightViewProjection = lightViewProjection != null ? lightViewProjection : Mat4.identity(new Mat4());
        this.lightIndex = lightIndex;
    }
}
