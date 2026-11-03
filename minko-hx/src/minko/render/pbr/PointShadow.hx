package minko.render.pbr;

import glm.Mat4;
import glm.Vec3;
import minko.render.AbstractTexture;
import minko.render.target.RenderTarget;

class PointShadow {
    public var matrices:Array<Mat4>;
    /** 4x3 2D atlas fallback. */
    public var atlas:RenderTarget;
    /** Hardware cube map holding linear distance / range per texel. */
    public var cube:AbstractTexture;
    public var faceSize:Int;
    public var baseCell:Int;
    public var lightIndex:Int;
    public var position:Vec3;
    public var range:Float;

    public function new(matrices:Array<Mat4> = null, lightIndex:Int = -1) {
        this.matrices = matrices != null ? matrices : [];
        this.atlas = null;
        this.cube = null;
        this.faceSize = 512;
        this.baseCell = 0;
        this.lightIndex = lightIndex;
        this.position = new Vec3();
        this.range = 10.0;
    }
}
