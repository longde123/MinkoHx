package minko.component;

import glm.Mat4;
import glm.Vec3;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.light.Light;
import minko.render.light.LightSet;
import minko.render.pbr.GBufferFallbackRenderer;
import minko.render.pbr.GBufferRenderer;
import minko.render.pbr.DeferredLightingRenderer;
import minko.render.pbr.FullscreenEffect;
import minko.render.pbr.PBRForwardRenderer;
import minko.render.pbr.PBRShaderLibrary;
import minko.render.pbr.SSAORenderer;
import minko.render.pbr.ShadowRenderer;
import minko.render.pipeline.DeferredPBRPath;
import minko.render.pipeline.ForwardPBRPath;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.PipelineRenderer;
import minko.render.pipeline.PostProcessChain;
import minko.render.pipeline.RenderPipeline;
import minko.render.pipeline.RenderQueue;
import minko.render.target.RenderTarget;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal;
import minko.signal.Signal3.SignalSlot3;

/**
 * Scene-graph component that drives the new render pipeline with a default
 * PBR forward path.
 *
 * The component finds the SceneManager on its root, subscribes to the
 * SceneManager render signal (ordered by priority), and lazily creates:
 *
 *   PBRForwardRenderer -> ForwardPBRPath -> PipelineRenderer
 *
 * Camera/view/projection come from PipelineRenderer's SceneCollector. Lights,
 * post-processing and shadows are configured through this component's public
 * fields. It is the scene-graph entry point for the new pipeline.
 */
@:expose("minko.component.PBRRenderer")
class PBRRenderer extends AbstractComponent {
    private var _name:String;
    private var _enabled:Bool;
    private var _priority:Float;

    private var _sceneManager:SceneManager;
    private var _context:AbstractContext;
    private var _pipeline:PipelineRenderer;
    private var _forwardPath:ForwardPBRPath;
    private var _forwardRenderer:PBRForwardRenderer;
    private var _deferredPath:DeferredPBRPath;
    private var _gbufferRenderer:GBufferRenderer;
    private var _gbufferFallback:GBufferFallbackRenderer;
    private var _deferredLighting:DeferredLightingRenderer;
    private var _transparentCopier:FullscreenEffect;
    private var _useDeferred:Bool;

    private var _lights:LightSet;
    private var _manualLights:LightSet;
    private var _renderingBegin:Signal<PBRRenderer>;
    private var _renderingEnd:Signal<PBRRenderer>;

    private var _renderingSlot:SignalSlot3<SceneManager, Int, AbstractTexture>;
    private var _rootComponentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _rootComponentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _disposed:Bool;

    /** Optional, user-owned post-process chain. */
    public var postProcess:PostProcessChain;
    /** Optional, user-owned shadow renderer. */
    public var shadowRenderer:ShadowRenderer;
    public var lightViewProjection:Mat4;
    public var shadowMapSize:Int;
    public var shadowCascadeCount:Int;
    public var shadowSplitLambda:Float;
    public var shadowLightDirection:Vec3;
    public var shadowMaxDistance:Float;
    public var spotShadowSize:Int;
    public var pointShadowSize:Int;
    public var enableLocalShadows:Bool;
    /** Optional, user-owned deferred SSAO renderer. */
    public var ssaoRenderer:SSAORenderer;

    public static function create(priority:Float = 0.0, name:String = ""):PBRRenderer {
        return new PBRRenderer(priority, name);
    }

    public function new(priority:Float = 0.0, name:String = "") {
        super();
        _name = name;
        _enabled = true;
        _priority = priority;
        _sceneManager = null;
        _context = null;
        _pipeline = null;
        _forwardPath = null;
        _forwardRenderer = null;
        _deferredPath = null;
        _gbufferRenderer = null;
        _gbufferFallback = null;
        _deferredLighting = null;
        _transparentCopier = null;
        _useDeferred = false;
        _lights = new LightSet();
        _manualLights = new LightSet();
        _renderingBegin = new Signal<PBRRenderer>();
        _renderingEnd = new Signal<PBRRenderer>();
        _renderingSlot = null;
        _rootComponentAddedSlot = null;
        _rootComponentRemovedSlot = null;
        _disposed = false;
        postProcess = null;
        shadowRenderer = null;
        lightViewProjection = Mat4.identity(new Mat4());
        shadowMapSize = 512;
        shadowCascadeCount = 1;
        shadowSplitLambda = 0.5;
        shadowLightDirection = new Vec3(0.0, -1.0, 0.0);
        shadowMaxDistance = 100.0;
        spotShadowSize = 512;
        pointShadowSize = 512;
        enableLocalShadows = true;
        ssaoRenderer = null;
    }

    public var pipeline(get, null):RenderPipeline;

    function get_pipeline() {
        return _pipeline != null ? _pipeline.pipeline : null;
    }

    public var renderer(get, null):PipelineRenderer;

    function get_renderer() {
        return _pipeline;
    }

    public var forwardPath(get, null):ForwardPBRPath;

    function get_forwardPath() {
        return _forwardPath;
    }

    public var forwardRenderer(get, null):PBRForwardRenderer;

    function get_forwardRenderer() {
        return _forwardRenderer;
    }

    public var deferredPath(get, null):DeferredPBRPath;

    function get_deferredPath() {
        return _deferredPath;
    }

    public var useDeferred(get, set):Bool;

    function get_useDeferred() {
        return _useDeferred;
    }

    function set_useDeferred(value:Bool) {
        if (value != _useDeferred) {
            _useDeferred = value;
            if (_pipeline != null) {
                _pipeline.pipeline.path = value ? _deferredPath : _forwardPath;
            }
        }
        return value;
    }

    public var lights(get, null):LightSet;

    function get_lights() {
        return _lights;
    }

    public var renderingBegin(get, null):Signal<PBRRenderer>;

    function get_renderingBegin() {
        return _renderingBegin;
    }

    public var renderingEnd(get, null):Signal<PBRRenderer>;

    function get_renderingEnd() {
        return _renderingEnd;
    }

    public var name(get, set):String;

    function get_name() {
        return _name;
    }

    function set_name(value:String) {
        _name = value;
        return value;
    }

    public var enabled(get, set):Bool;

    function get_enabled() {
        return _enabled;
    }

    function set_enabled(value:Bool) {
        _enabled = value;
        return value;
    }

    public var priority(get, set):Float;

    function get_priority() {
        return _priority;
    }

    function set_priority(value:Float) {
        if (value != _priority) {
            _priority = value;
            if (_sceneManager != null) {
                if (_renderingSlot != null) {
                    _renderingSlot.dispose();
                }
                _renderingSlot = _sceneManager.renderingEnd.connect(_renderFrame, _priority);
            }
        }
        return value;
    }

    public function addLight(light:Light):PBRRenderer {
        _manualLights.add(light);
        _lights.add(light);
        if (_pipeline != null) {
            _pipeline.pipeline.lights = _lights;
        }
        return this;
    }

    public function clearLights():Void {
        _manualLights.clear();
        _lights.clear();
        if (_pipeline != null) {
            _pipeline.pipeline.lights = _lights;
        }
    }

    private function _collectLights():Void {
        _lights.clear();
        for (light in _manualLights.lights) {
            _lights.add(light);
        }

        if (target == null) {
            return;
        }

        var nodes = NodeSet.createbyNode(target.root).descendants(true).where(function(node:Node) {
            return node.hasComponent(LightComponent);
        }).nodes;

        for (node in nodes) {
            var component:LightComponent = cast node.getComponent(LightComponent);
            if (component == null || component.light == null) {
                continue;
            }
            component.syncFromTransform();
            _lights.add(component.light);
        }
    }

    override public function targetAdded(target:Node):Void {
        if (_disposed) {
            return;
        }

        _clearRootSlots();

        if (target.root != null) {
            _rootComponentAddedSlot = target.root.componentAdded.connect(_rootComponentChanged);
            _rootComponentRemovedSlot = target.root.componentRemoved.connect(_rootComponentChanged);
        }

        findSceneManager();
    }

    override public function targetRemoved(target:Node):Void {
        _disposeSceneManagerBinding();
        _disposePipeline();
        _clearRootSlots();
        _sceneManager = null;
    }

    private function _rootComponentChanged(node:Node, target:Node, component:AbstractComponent):Void {
        if (Std.isOfType(component, SceneManager)) {
            findSceneManager();
        }
    }

    public function findSceneManager():Void {
        if (target == null) {
            setSceneManager(null);
            return;
        }

        var roots:NodeSet = NodeSet.createbyNode(target).roots().where(function(node:Node) {
            return node.hasComponent(SceneManager);
        });

        if (roots.nodes.length > 1) {
            throw ("PBRRenderer cannot be in two separate scenes.");
        }
        else if (roots.nodes.length == 1) {
            setSceneManager(cast roots.nodes[0].getComponent(SceneManager));
        }
        else {
            setSceneManager(null);
        }
    }

    public function setSceneManager(sceneManager:SceneManager):Void {
        if (sceneManager == _sceneManager) {
            return;
        }

        _disposeSceneManagerBinding();
        _disposePipeline();

        _sceneManager = sceneManager;
        if (_sceneManager != null) {
            _renderingSlot = _sceneManager.renderingEnd.connect(_renderFrame, _priority);
        }
    }

    private function _renderFrame(sceneManager:SceneManager, frameId:Int, renderTarget:AbstractTexture):Void {
        if (!_enabled || _disposed) {
            return;
        }
        if (!_ensurePipeline()) {
            return;
        }

        _pipeline.time = _sceneManager.time;
        _collectLights();

        _renderingBegin.execute(this);
        _pipeline.render(0.0);
        _renderingEnd.execute(this);
    }

    private function _ensurePipeline():Bool {
        if (_sceneManager == null || target == null) {
            return false;
        }

        var context = _sceneManager.assets.context;
        if (context == null) {
            return false;
        }

        if (_pipeline != null && _context != context) {
            _disposePipeline();
        }

        if (_forwardRenderer == null) {
            _forwardRenderer = new PBRForwardRenderer(context);
        }
        if (_gbufferRenderer == null) {
            _gbufferRenderer = new GBufferRenderer(context);
        }
        if (_gbufferFallback == null) {
            _gbufferFallback = new GBufferFallbackRenderer(context);
        }
        if (_deferredLighting == null) {
            _deferredLighting = new DeferredLightingRenderer(context);
        }
        if (_forwardPath == null) {
            _forwardPath = new ForwardPBRPath(function(queue:RenderQueue, frame:FrameContext, renderTarget:RenderTarget) {
                _forwardRenderer.render(queue, frame, renderTarget);
            }, postProcess);
        }
        if (_deferredPath == null) {
            _deferredPath = new DeferredPBRPath(function(queue:RenderQueue, frame:FrameContext, gbuffer:minko.render.target.GBuffer) {
                if (frame.capabilities != null && frame.capabilities.supportsMRT) {
                    _gbufferRenderer.render(queue, frame, gbuffer);
                }
                else {
                    _gbufferFallback.render(queue, frame, gbuffer);
                }
            }, function(frame:FrameContext, gbuffer:minko.render.target.GBuffer, output:RenderTarget) {
                _deferredLighting.render(gbuffer, output, frame);
            }, function(queue:RenderQueue, frame:FrameContext, sceneColor:RenderTarget, output:RenderTarget) {
                if (_transparentCopier == null) {
                    _transparentCopier = new FullscreenEffect(context, "PBRRendererTransparentCopy", PBRShaderLibrary.presentFragment());
                }
                _transparentCopier.render(output, function(effect:FullscreenEffect) {
                    effect.setTexture("uColorMap", sceneColor.color);
                });
                output.bind(frame.context, false);
                _forwardRenderer.renderTransparent(queue, frame);
                output.unbind(frame.context);
            }, postProcess);
        }
        if (_pipeline == null) {
            _context = context;
            _pipeline = new PipelineRenderer(context, target.root, _useDeferred ? _deferredPath : _forwardPath, _canvasWidth(), _canvasHeight());
            _pipeline.pipeline.lights = _lights;
        }

        _pipeline.root = target.root;
        _pipeline.width = _canvasWidth();
        _pipeline.height = _canvasHeight();

        _forwardPath.postProcess = postProcess;
        _forwardPath.shadowRenderer = shadowRenderer;
        _forwardPath.lightViewProjection = lightViewProjection;
        _forwardPath.shadowMapSize = shadowMapSize;
        _forwardPath.shadowCascadeCount = shadowCascadeCount;
        _forwardPath.shadowSplitLambda = shadowSplitLambda;
        _forwardPath.shadowLightDirection = shadowLightDirection;
        _forwardPath.shadowMaxDistance = shadowMaxDistance;
        _forwardPath.spotShadowSize = spotShadowSize;
        _forwardPath.pointShadowSize = pointShadowSize;
        _forwardPath.enableLocalShadows = enableLocalShadows;

        _deferredPath.postProcess = postProcess;
        _deferredPath.shadowRenderer = shadowRenderer;
        _deferredPath.lightViewProjection = lightViewProjection;
        _deferredPath.shadowMapSize = shadowMapSize;
        _deferredPath.shadowCascadeCount = shadowCascadeCount;
        _deferredPath.shadowSplitLambda = shadowSplitLambda;
        _deferredPath.shadowLightDirection = shadowLightDirection;
        _deferredPath.shadowMaxDistance = shadowMaxDistance;
        _deferredPath.spotShadowSize = spotShadowSize;
        _deferredPath.pointShadowSize = pointShadowSize;
        _deferredPath.enableLocalShadows = enableLocalShadows;
        _deferredPath.ssaoRenderer = ssaoRenderer;

        if (_pipeline.pipeline.path != (_useDeferred ? _deferredPath : _forwardPath)) {
            _pipeline.pipeline.path = _useDeferred ? _deferredPath : _forwardPath;
        }

        return true;
    }

    private function _canvasWidth():Int {
        var width = _sceneManager != null && _sceneManager.canvas != null ? _sceneManager.canvas.width : 1;
        return width > 0 ? width : 1;
    }

    private function _canvasHeight():Int {
        var height = _sceneManager != null && _sceneManager.canvas != null ? _sceneManager.canvas.height : 1;
        return height > 0 ? height : 1;
    }

    private function _disposeSceneManagerBinding():Void {
        if (_renderingSlot != null) {
            _renderingSlot.dispose();
            _renderingSlot = null;
        }
    }

    private function _clearRootSlots():Void {
        if (_rootComponentAddedSlot != null) {
            _rootComponentAddedSlot.dispose();
            _rootComponentAddedSlot = null;
        }
        if (_rootComponentRemovedSlot != null) {
            _rootComponentRemovedSlot.dispose();
            _rootComponentRemovedSlot = null;
        }
    }

    private function _disposePipeline():Void {
        if (_pipeline != null) {
            _pipeline.pipeline.path = null;
            _pipeline.dispose();
            _pipeline = null;
        }
        if (_forwardPath != null) {
            _forwardPath.dispose();
            _forwardPath = null;
        }
        if (_deferredPath != null) {
            _deferredPath.dispose();
            _deferredPath = null;
        }
        if (_forwardRenderer != null) {
            _forwardRenderer.dispose();
            _forwardRenderer = null;
        }
        if (_gbufferRenderer != null) {
            _gbufferRenderer.dispose();
            _gbufferRenderer = null;
        }
        if (_gbufferFallback != null) {
            _gbufferFallback.dispose();
            _gbufferFallback = null;
        }
        if (_deferredLighting != null) {
            _deferredLighting.dispose();
            _deferredLighting = null;
        }
        if (_transparentCopier != null) {
            _transparentCopier.dispose();
            _transparentCopier = null;
        }
        _context = null;
    }

    override public function dispose():Void {
        if (_disposed) {
            return;
        }
        _disposed = true;

        _disposeSceneManagerBinding();
        _disposePipeline();
        _clearRootSlots();
        _sceneManager = null;
        _lights = null;
        _manualLights = null;
        postProcess = null;
        shadowRenderer = null;

        super.dispose();
    }
}
