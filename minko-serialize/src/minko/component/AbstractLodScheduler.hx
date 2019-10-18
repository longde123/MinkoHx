package minko.component;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import minko.data.Provider;
import minko.data.Store;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
typedef ComponentSolverFunction = Node -> AbstractComponent;

class LodInfo {
    public var requiredLod:Int;
    public var priority:Float;

    public function new() {
        this.requiredLod = 0;
        this.priority = 0.0;
    }

    public function equals(other:LodInfo) {
        return requiredLod == other.requiredLod && priority == other.priority;
    }
}

class ResourceInfo {
    public var data:Provider;

    public var lodRequirementIsInvalid:Bool;

    public var lodInfo:LodInfo;

    public var propertyChangedSlot:SignalSlot2<Provider, String>;
    public var layoutChangedSlot:SignalSlot2<Node, Node>;

    public function new(data) {
        this.data = data;
        this.lodRequirementIsInvalid = true;
        this.lodInfo = new LodInfo();
        this.propertyChangedSlot = null;
        this.layoutChangedSlot = null;
    }

    public var uuid(get, null):String;

    function get_uuid() {
        return data.uuid;
    }
}

class AbstractLodScheduler extends AbstractComponent {


    static public var DEFAULT_LOD = 0;

    private var _masterLodScheduler:MasterLodScheduler;

    private var _resources:StringMap<ResourceInfo>;

    private var _sceneManagerFunction:ComponentSolverFunction;
    private var _rendererFunction:ComponentSolverFunction;
    private var _masterLodSchedulerFunction:ComponentSolverFunction;

    private var _nodeAddedSlot:SignalSlot3<Node, Node, Node>;
    private var _nodeRemovedSlot:SignalSlot3<Node, Node, Node>;

    private var _componentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _componentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;

    private var _frameBeginSlot:SignalSlot3<SceneManager, Float, Float>;

    private var _rootNodePropertyChangedSlot:SignalSlot3<Store, Provider, String>;
    private var _rendererNodePropertyChangedSlot:SignalSlot3<Store, Provider, String>;

    private var _nodeLayoutChangedSlots:ObjectMap<Node, SignalSlot2<Node, Node>>;
    private var _surfaceLayoutmaskChangedSlots:ObjectMap<Surface, SignalSlot<AbstractComponent>>;

    private var _addedSurfaces:Array<Surface>;
    private var _removedSurfaces:Array<Surface>;

    private var _enabled:Bool;

    private var _frameTime:Float;


    public var sceneManagerFunction(get, set):ComponentSolverFunction;

    function get_sceneManagerFunction() {
        return _sceneManagerFunction;
    }

    function set_sceneManagerFunction(value) {
        _sceneManagerFunction = value;

        return value;
    }

    public var rendererFunction(get, set):ComponentSolverFunction;

    function get_rendererFunction() {
        return _rendererFunction;
    }

    function set_rendererFunction(value) {
        _rendererFunction = value;

        return value;
    }
    public var masterLodSchedulerFunction(get, set):ComponentSolverFunction;

    function get_masterLodSchedulerFunction() {
        return _masterLodSchedulerFunction;
    }

    function set_masterLodSchedulerFunction(value) {
        _masterLodSchedulerFunction = value;

        return value;
    }

    public var enabled(get, set):Bool;

    function get_enabled() {
        return _enabled;
    }

    function set_enabled(value) {
        if (_enabled == value) {
            return value;
        }

        _enabled = value;

        if (_enabled) {
            invalidateLodRequirement();
        }

        return value;
    }
    public var masterLodScheduler(get, null):MasterLodScheduler;

    function get_masterLodScheduler() {
        return _masterLodScheduler;
    }


    function lodInfo(resource:ResourceInfo, time:Float) {
        return null;
    }

    public function new() {
        super();
        this._masterLodScheduler = new MasterLodScheduler();
        this._sceneManagerFunction = null;
        this._rendererFunction = null;
        this._masterLodSchedulerFunction = null;
        this._nodeAddedSlot = null;
        this._nodeRemovedSlot = null;
        this._componentAddedSlot = null;
        this._componentRemovedSlot = null;
        this._frameBeginSlot = null;
        this._enabled = true;
        this._frameTime = 0.0;
    }

    public function defaultSceneManagerFunction(node:Node):AbstractComponent {
        return node.root.getComponent(SceneManager);
    }

    public function defaultRendererFunction(node:Node):AbstractComponent {
        var rendererNodes:NodeSet = NodeSet.createbyNode(node.root).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Renderer);
        });

        return rendererNodes.nodes.length == 0 ? null : rendererNodes.nodes[0].getComponent(Renderer);
    }

    public function defaultMasterLodSchedulerFunction(node:Node):AbstractComponent {
        return node.root.getComponent(MasterLodScheduler);
    }

    override public function targetAdded(target:Node) {
        _nodeAddedSlot = target.added.connect(nodeAddedHandler);

        _nodeRemovedSlot = target.removed.connect(nodeRemovedHandler);

        _componentAddedSlot = target.componentAdded.connect(componentAddedHandler);

        _componentRemovedSlot = target.componentRemoved.connect(componentRemovedHandler);

        _sceneManagerFunction = defaultSceneManagerFunction(target);

        _rendererFunction = defaultRendererFunction(target);

        _masterLodSchedulerFunction = defaultMasterLodSchedulerFunction(target);

        nodeAddedHandler(target, target);
    }

    override public function targetRemoved(target:Node) {
        _nodeAddedSlot = null;
        _nodeRemovedSlot = null;
    }

    public function registerResource(data:Provider):ResourceInfo {
        var uuid = data.uuid;
        _resources.set(uuid, new ResourceInfo(data));
        var insertedResource = _resources.get(uuid);


        insertedResource.propertyChangedSlot = insertedResource.data.propertyChanged.connect(
            function(provider:Provider, propertyName:String) {
                if (propertyName == "maxAvailableLod") {
                    var resource = _resources.get(provider.uuid);

                    maxAvailableLodChanged(resource, provider.get(propertyName));
                }
            });

        return insertedResource;
    }

    public function unregisterResource(uuid) {
        _resources.remove(uuid);
    }

    function _invalidateLodRequirement(resource:ResourceInfo) {
        resource.lodRequirementIsInvalid = true;
    }

    public function invalidateLodRequirement() {
        for (resource in _resources) {
            _invalidateLodRequirement(resource);
        }
    }

    public function forceUpdate() {
        invalidateLodRequirement();

        updated(_frameTime);
    }

    override function set_layoutMask(value) {
        super.set_layoutMask(value);

        for (surface in _surfaceLayoutmaskChangedSlots.keys()) {

            surfaceLayoutMaskInvalidated(surface);
        }
    }

    public function surfaceAdded(surface:Surface) {
    }

    public function surfaceRemoved(surface:Surface) {
    }

    public function viewPropertyChanged(worldToScreenMatrix:Mat4, viewMatrix:Mat4, eyePosition:Vec3, fov:Float, aspectRatio:Float, zNear:Float, zFar:Float) {
    }

    public function viewportChanged(viewport:Vec4) {
    }

    public function collectSurfaces() {
        while (_removedSurfaces.length > 0) {
            var surface = _removedSurfaces.pop();

            surfaceRemoved(surface);
        }

        if (_masterLodScheduler != null) {
            while (_addedSurfaces.length > 0) {
                var surface = _addedSurfaces.pop();

                surfaceAdded(surface);
            }
        }
    }

    public function sceneManagerSet(sceneManager:SceneManager) {
        if (sceneManager == null) {
            if(_frameBeginSlot)
                _frameBeginSlot.dispose()
            _frameBeginSlot = null;
            if(_rootNodePropertyChangedSlot)
                _rootNodePropertyChangedSlot.dispose();
            _rootNodePropertyChangedSlot = null;
        }
        else {
            _frameBeginSlot = sceneManager.frameBegin.connect(frameBeginHandler);

            var rootData = sceneManager.target.data;

            if (rootData.hasProperty("viewport")) {
                viewportChanged(rootData.get("viewport"));
            }

            _rootNodePropertyChangedSlot = sceneManager.target.data.propertyChanged.connect(rootNodePropertyChangedHandler);
        }
    }

    public function rendererSet(renderer:Renderer):Void {
        if (renderer == null) {
            if(_rendererNodePropertyChangedSlot)
                _rendererNodePropertyChangedSlot.dispose();
            _rendererNodePropertyChangedSlot = null;
        }
        else {
            var rendererData = renderer.target.data;

            if (rendererData.hasProperty("worldToScreenMatrix")) {
                var providers = rendererData.providers;

                var providerIt = Lambda.find(function(pro:Provider) {
                    return pro.hasProperty("worldToScreenMatrix");
                });

                rendererNodePropertyChangedHandler(rendererData, providerIt, "worldToScreenMatrix");
            }

            _rendererNodePropertyChangedSlot = renderer.target.data.propertyChanged.connect(rendererNodePropertyChangedHandler);
        }
    }

    public function masterLodSchedulerSet(masterLodScheduler:MasterLodScheduler) {
        if (_masterLodScheduler != masterLodScheduler) {
            _masterLodScheduler = masterLodScheduler;
        }
    }

    public function nodeAddedHandler(target:Node, node:Node) {
        var sceneManager = sceneManagerFunction(node);
        sceneManagerSet(sceneManager == null ? null : cast(sceneManager));

        var renderer = rendererFunction(node);
        rendererSet(renderer == null ? null : cast(renderer));

        var masterLodScheduler = masterLodSchedulerFunction(node);
        masterLodSchedulerSet(masterLodScheduler == null ? null : cast(masterLodScheduler));

        _nodeLayoutChangedSlots.set(node, node.layoutChanged.connect(function(target:Node, node:Node) {
            for (surface in node.getComponents(Surface)) {
                surfaceLayoutMaskInvalidated(surface);
            }
        }));

        var meshNodes:NodeSet = NodeSet.createbyNode(node).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Surface);
        });

        for (meshNode in meshNodes.nodes) {
            for (surface in meshNode.getComponents(Surface)) {
                watchSurface(surface);

                addPendingSurface(surface);
            }
        }
    }

    public function nodeRemovedHandler(target:Node, node:Node) {
        var sceneManager = sceneManagerFunction(node);
        sceneManagerSet(sceneManager == null ? null : cast(sceneManager));

        var renderer = rendererFunction(node);
        rendererSet(renderer == null ? null : cast(renderer));

        var masterLodScheduler = masterLodSchedulerFunction(node);
        masterLodSchedulerSet(masterLodScheduler == null ? null : cast(masterLodScheduler));

        _nodeLayoutChangedSlots.remove(node);

        for (surface in node.getComponents(Surface)) {
            unwatchSurface(surface);

            removePendingSurface(surface);
        }
    }

    public function componentAddedHandler(target:Node, component:AbstractComponent) {
        var sceneManager = cast(component, SceneManager);

        if (sceneManager != null) {
            sceneManagerSet(sceneManagerFunction(target));
        }

        var renderer = cast(component, Renderer);

        if (renderer != null) {
            rendererSet(rendererFunction(target));
        }

        var masterLodScheduler = cast(component, MasterLodScheduler);

        if (masterLodScheduler != null) {
            masterLodSchedulerSet(masterLodSchedulerFunction(target));
        }

        var surface = cast(component, Surface);

        if (surface != null) {
            watchSurface(surface);

            if (checkSurfaceLayout(surface)) {
                addPendingSurface(surface);
            }
        }
    }

    public function componentRemovedHandler(target:Node, component:AbstractComponent) {
        var sceneManager = cast(component, SceneManager);

        if (sceneManager != null) {
            sceneManagerSet(sceneManagerFunction(null));
        }

        var renderer = cast(component, Renderer);

        if (renderer != null) {
            rendererSet(rendererFunction(null));
        }

        var masterLodScheduler = cast(component, MasterLodScheduler);

        if (masterLodScheduler != null) {
            masterLodSchedulerSet(masterLodSchedulerFunction(null));
        }

        var surface = cast(component, Surface);

        if (surface != null) {
            unwatchSurface(surface);

            removePendingSurface(surface);
        }
    }

    public function frameBeginHandler(sceneManager:SceneManager, time:Float, deltaTime:Float) {
        _frameTime = time;

        if (!enabled) {
            return;
        }

        updated(time);
    }

    public function updated(time:Float) {
        collectSurfaces();

        for (uuidToResourcePair in _resources) {
            var resource = uuidToResourcePair;

            if (!resource.lodRequirementIsInvalid) {
                continue;
            }

            resource.lodRequirementIsInvalid = false;

            var lodInfo = this.lodInfo(resource, time);

            if (!resource.lodInfo.equals(lodInfo)) {
                var previousLodInfo = resource.lodInfo;

                resource.lodInfo = lodInfo;

                lodInfoChanged(resource, previousLodInfo, lodInfo);
            }
        }
    }

    public function rootNodePropertyChangedHandler(store:Store, provider:Provider, propertyName:String) {
        if (propertyName == "viewport") {
            viewportChanged(provider.get(propertyName));
        }
    }

    public function rendererNodePropertyChangedHandler(store:Store, provider:Provider, propertyName:String) {
        if (propertyName == "worldToScreenMatrix") {
            viewPropertyChanged(provider.get("worldToScreenMatrix"), provider.get("viewMatrix"), provider.get("eyePosition"), provider.get("fov"), provider.get("aspectRatio"), provider.get("zNear"), provider.get("zFar"));
        }
    }

    public function maxAvailableLodChanged(resource:ResourceInfo, maxAvailableLod:Int) {
    }

    public function lodInfoChanged(resource:ResourceInfo, previousLodInfo:LodInfo, lodInfo:LodInfo) {
        if (previousLodInfo.requiredLod != lodInfo.requiredLod) {
            resource.data.set("requiredLod", lodInfo.requiredLod);
        }

        if (previousLodInfo.priority != lodInfo.priority) {
            resource.data.set("priority", lodInfo.priority);
        }
    }

    public function checkSurfaceLayout(surface:Surface) {
        var surfaceLayout = surface.target.layout & surface.layoutMask;

        if ((surfaceLayout & BuiltinLayout.HIDDEN) != 0) {
            return false;
        }

        return (AbstractComponent.layoutMask & surfaceLayout) != 0;
    }

    public function surfaceLayoutMaskInvalidated(surface:Surface) {
        if (checkSurfaceLayout(surface)) {
            addPendingSurface(surface);
        }
        else {
            removePendingSurface(surface);
        }
    }

    public function watchSurface(surface:Surface) {
        _surfaceLayoutmaskChangedSlots.set(surface, surface.layoutMaskChanged.connect(function(UnnamedParameter1) {
            surfaceLayoutMaskInvalidated(surface);
        }));
    }

    public function unwatchSurface(surface:Surface) {
        _surfaceLayoutmaskChangedSlots.remove(surface);
    }

    public function addPendingSurface(surface:Surface) {

        var addedSurfaceIt = Lambda.has(_addedSurfaces, surface);
        var removedSurfaceIt = Lambda.has(_removedSurfaces, surface);

        if (removedSurfaceIt) {
            _removedSurfaces.remove(surface);
        }

        if (addedSurfaceIt == false) {
            _addedSurfaces.push(surface);
        }
    }

    public function removePendingSurface(surface:Surface) {
        var addedSurfaceIt = Lambda.has(_addedSurfaces, surface);
        var removedSurfaceIt = Lambda.has(_removedSurfaces, surface);

        if (addedSurfaceIt) {
            _addedSurfaces.remove(addedSurfaceIt);
        }

        if (removedSurfaceIt == false) {
            _removedSurfaces.push(surface);
        }
    }
}
