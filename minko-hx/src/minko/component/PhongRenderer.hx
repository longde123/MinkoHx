package minko.component;

import glm.Mat4;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.light.Light;
import minko.render.light.LightSet;
import minko.render.phong.PhongForwardRenderer;
import minko.render.pbr.ShadowRenderer;
import minko.render.pipeline.ForwardPhongPath;
import minko.render.pipeline.PipelineRenderer;
import minko.render.pipeline.PostProcessChain;
import minko.render.pipeline.RenderPipeline;
import minko.render.target.RenderTarget;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal;
import minko.signal.Signal3.SignalSlot3;

/**
 * Scene-graph component that drives the forward Phong path through
 * SceneManager. It mirrors PBRRenderer's scene wiring without deferred or PBR
 * specific resources.
 */
@:expose("minko.component.PhongRenderer")
class PhongRenderer extends AbstractComponent {
    private var _name:String;
    private var _enabled:Bool;
    private var _priority:Float;

    private var _sceneManager:SceneManager;
    private var _context:AbstractContext;
    private var _pipeline:PipelineRenderer;
    private var _forwardPath:ForwardPhongPath;
    private var _forwardRenderer:PhongForwardRenderer;

    private var _lights:LightSet;
    private var _manualLights:LightSet;
    private var _renderingBegin:Signal<PhongRenderer>;
    private var _renderingEnd:Signal<PhongRenderer>;

    private var _renderingSlot:SignalSlot3<SceneManager, Int, AbstractTexture>;
    private var _rootComponentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _rootComponentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _disposed:Bool;

    public var postProcess:PostProcessChain;
    public var shadowRenderer:ShadowRenderer;
    public var lightViewProjection:Mat4;
    public var shadowMapSize:Int;
    public var spotShadowSize:Int;
    public var pointShadowSize:Int;
    public var enableLocalShadows:Bool;

    public static function create(priority:Float = 0.0, name:String = ""):PhongRenderer {
        return new PhongRenderer(priority, name);
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
        _lights = new LightSet();
        _manualLights = new LightSet();
        _renderingBegin = new Signal<PhongRenderer>();
        _renderingEnd = new Signal<PhongRenderer>();
        _renderingSlot = null;
        _rootComponentAddedSlot = null;
        _rootComponentRemovedSlot = null;
        _disposed = false;
        postProcess = null;
        shadowRenderer = null;
        lightViewProjection = Mat4.identity(new Mat4());
        shadowMapSize = 512;
        spotShadowSize = 512;
        pointShadowSize = 512;
        enableLocalShadows = true;
    }

    public var pipeline(get, null):RenderPipeline;

    function get_pipeline() {
        return _pipeline != null ? _pipeline.pipeline : null;
    }

    public var renderer(get, null):PipelineRenderer;

    function get_renderer() {
        return _pipeline;
    }

    public var forwardPath(get, null):ForwardPhongPath;

    function get_forwardPath() {
        return _forwardPath;
    }

    public var forwardRenderer(get, null):PhongForwardRenderer;

    function get_forwardRenderer() {
        return _forwardRenderer;
    }

    public var lights(get, null):LightSet;

    function get_lights() {
        return _lights;
    }

    public var renderingBegin(get, null):Signal<PhongRenderer>;

    function get_renderingBegin() {
        return _renderingBegin;
    }

    public var renderingEnd(get, null):Signal<PhongRenderer>;

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
        _priority = value;
        if (_sceneManager != null) {
            _disposeSceneManagerBinding();
            _renderingSlot = _sceneManager.renderingEnd.connect(_renderFrame, _priority);
        }
        return value;
    }

    public function addLight(light:Light):PhongRenderer {
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
            throw ("PhongRenderer cannot be in two separate scenes.");
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
            _forwardRenderer = new PhongForwardRenderer(context);
        }
        if (_forwardPath == null) {
            _forwardPath = new ForwardPhongPath(function(queue, frame, renderTarget) {
                _forwardRenderer.render(queue, frame, renderTarget);
            }, postProcess);
        }
        if (_pipeline == null) {
            _context = context;
            _pipeline = new PipelineRenderer(context, target.root, _forwardPath, _canvasWidth(), _canvasHeight());
            _pipeline.pipeline.lights = _lights;
        }

        _pipeline.root = target.root;
        _pipeline.width = _canvasWidth();
        _pipeline.height = _canvasHeight();
        _forwardPath.postProcess = postProcess;
        _forwardPath.shadowRenderer = shadowRenderer;
        _forwardPath.lightViewProjection = lightViewProjection;
        _forwardPath.shadowMapSize = shadowMapSize;
        _forwardPath.spotShadowSize = spotShadowSize;
        _forwardPath.pointShadowSize = pointShadowSize;
        _forwardPath.enableLocalShadows = enableLocalShadows;
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
        if (_forwardRenderer != null) {
            _forwardRenderer.dispose();
            _forwardRenderer = null;
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
