package minko.render.pipeline;

import glm.Mat4;
import glm.Vec3;
import minko.render.AbstractContext;
import minko.render.light.LightSet;
import minko.render.pbr.PointShadow;
import minko.render.pbr.ShadowCascade;
import minko.render.pbr.SpotShadow;
import minko.render.target.RenderCapabilities;
import minko.render.target.RenderTarget;
import minko.render.target.RenderTargetPool;

class FrameContext {
    public var context:AbstractContext;
    public var width:Int;
    public var height:Int;
    public var frameId:Int;
    public var time:Float;
    public var queue:RenderQueue;
    public var lights:LightSet;
    public var targetPool:RenderTargetPool;
    public var capabilities:RenderCapabilities;
    public var viewMatrix:Mat4;
    public var projectionMatrix:Mat4;
    public var cameraPosition:Vec3;
    public var shadowMap:RenderTarget;
    public var lightViewProjection:Mat4;
    public var shadowCascades:Array<ShadowCascade>;
    public var shadowCascadeSplits:Array<Float>;
    public var spotShadow:SpotShadow;
    public var pointShadow:PointShadow;
    public var spotShadows:Array<SpotShadow>;
    public var pointShadows:Array<PointShadow>;
    public var aoMap:RenderTarget;
    public var shadowTexelSize:Float;
    public var shadowSoftness:Float;
    public var shadowLightSize:Float;
    public var data:Dynamic;

    public function new(context:AbstractContext, width:Int, height:Int, frameId:Int = 0, time:Float = 0.0) {
        this.context = context;
        this.width = width;
        this.height = height;
        this.frameId = frameId;
        this.time = time;
        this.queue = null;
        this.lights = null;
        this.targetPool = null;
        this.capabilities = null;
        this.viewMatrix = Mat4.identity(new Mat4());
        this.projectionMatrix = Mat4.identity(new Mat4());
        this.cameraPosition = new Vec3(0.0, 0.0, 0.0);
        this.shadowMap = null;
        this.lightViewProjection = Mat4.identity(new Mat4());
        this.shadowCascades = null;
        this.shadowCascadeSplits = null;
        this.spotShadow = null;
        this.pointShadow = null;
        this.spotShadows = [];
        this.pointShadows = [];
        this.aoMap = null;
        this.shadowTexelSize = 1.0 / 512.0;
        this.shadowSoftness = 0.0;
        this.shadowLightSize = 0.02;
        this.data = null;
    }
}
