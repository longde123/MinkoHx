package minko.render.pipeline;

import glm.Mat4;
import glm.Vec3;
import minko.render.AbstractContext;
import minko.render.light.LightSet;
import minko.render.pbr.FullscreenEffect;
import minko.render.pbr.PBRShaderLibrary;
import minko.render.target.RenderCapabilities;
import minko.render.target.RenderTargetPool;

class RenderPipeline {
    public var path:RenderPath;
    public var queue:RenderQueue;
    public var lights:LightSet;
    public var targetPool:RenderTargetPool;
    public var capabilities:RenderCapabilities;
    public var graph:RenderGraph;
    public var viewMatrix:Mat4;
    public var projectionMatrix:Mat4;
    public var cameraPosition:Vec3;

    private var _context:AbstractContext;
    private var _frameId:Int;
    private var _presenter:FullscreenEffect;
    private var _frame:FrameContext;

    public function new(context:AbstractContext, path:RenderPath) {
        this._context = context;
        this.path = path;
        this.queue = new RenderQueue();
        this.lights = new LightSet();
        this.targetPool = new RenderTargetPool(context);
        this.capabilities = RenderCapabilities.detect(context);
        this.graph = null;
        this.viewMatrix = Mat4.identity(new Mat4());
        this.projectionMatrix = Mat4.identity(new Mat4());
        this.cameraPosition = new Vec3(0.0, 0.0, 0.0);
        this._presenter = null;
        this._frameId = 0;
        this._frame = null;
    }

    public function render(width:Int, height:Int, time:Float = 0.0):Void {
        var frame = _frame;
        if (frame == null) {
            frame = new FrameContext(_context, width, height, _frameId, time);
            _frame = frame;
        }
        else {
            frame.context = _context;
            frame.width = width;
            frame.height = height;
            frame.frameId = _frameId;
            frame.time = time;
            frame.shadowMap = null;
            frame.lightViewProjection = null;
            frame.shadowCascades = null;
            frame.shadowCascadeSplits = null;
            frame.spotShadow = null;
            frame.pointShadow = null;
            frame.spotShadows = [];
            frame.pointShadows = [];
            frame.aoMap = null;
            frame.shadowTexelSize = 1.0 / 512.0;
            frame.shadowSoftness = 0.0;
            frame.shadowLightSize = 0.02;
            frame.data = null;
        }
        frame.queue = queue;
        frame.lights = lights;
        frame.targetPool = targetPool;
        frame.capabilities = capabilities;
        frame.viewMatrix = viewMatrix;
        frame.projectionMatrix = projectionMatrix;
        frame.cameraPosition = cameraPosition;

        graph = path.build(queue, frame);
        if (graph != null) {
            graph.execute(frame);

            var output = graph.output;
            if (output != null && output.target != null && output.target.color != null) {
                _context.configureViewport(0, 0, width, height);
                if (_context.supportsBlit) {
                    _context.blitRenderTarget(output.target.nativeTarget);
                }
                else {
                    if (_presenter == null) {
                        _presenter = new FullscreenEffect(_context, "Present", PBRShaderLibrary.presentFragment());
                    }
                    var color = output.target.color;
                    _presenter.render(null, function(effect:FullscreenEffect) {
                        effect.setTexture("uColorMap", color);
                    });
                }
            }

            graph.releaseTransients(targetPool);
        }

        _frameId++;
    }

    public function dispose():Void {
        if (_presenter != null) {
            _presenter.dispose();
            _presenter = null;
        }
        if (graph != null) {
            graph.dispose();
            graph = null;
        }
        if (path != null) {
            path.dispose();
            path = null;
        }
        if (targetPool != null) {
            targetPool.dispose();
            targetPool = null;
        }
        queue = null;
        lights = null;
        _frame = null;
        _context = null;
    }
}

