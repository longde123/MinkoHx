package minko.component;
import minko.scene.Node;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
class AbstractScript extends AbstractComponent {
    private var _enabled:Bool;
    private var _started:Bool;
    private var _time:Float;
    private var _deltaTime:Float;

    private var _targetAddedSlot:SignalSlot2<AbstractComponent, Node> ;
    private var _targetRemovedSlot:SignalSlot2<AbstractComponent, Node> ;
    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;
    private var _componentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _componentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _frameBeginSlot:SignalSlot3<SceneManager, Float, Float>;
    private var _frameEndSlot:SignalSlot3<SceneManager, Float, Float>;
    public var enabled(get, set):Bool;

    function get_enabled() {
        return _enabled;
    }

    function set_enabled(v) {
        if (v != _enabled) {
            _enabled = v;
            _started = !v;

            if (target != null) {
                setSceneManager(cast target.root.getComponent(SceneManager));
            }
        }
        return v;
    }

    public function new() {
        super();
        this._enabled = true;
        this._started = false;
        this._time = 0.0;
        this._deltaTime = 0.0;
        this._targetAddedSlot = null;
        this._targetRemovedSlot = null;
        this._addedSlot = null;
        this._removedSlot = null;
        this._componentAddedSlot = null;
        this._componentRemovedSlot = null;
        this._frameBeginSlot = null;
        this._frameEndSlot = null;
    }
    public var time(get, null):Float;

    function get_time() {
        return _time;
    }
    public var deltaTime(get, null):Float;

    function get_deltaTime() {
        return _deltaTime;
    }

    public function start(target:Node) {
        // nothing
    }

    public function update(target:Node) {
        // nothing
    }

    public function end(target:Node) {
        // nothing
    }

    public function stop(target:Node) {
        // nothing
    }
    public var ready(get, null):Bool;

    function get_ready() {
        return true;
    }
    public var priority(get, null):Float;

    function get_priority() {
        return 0.0;
    }

    override public function targetAdded(target:Node) {
        _componentAddedSlot = target.componentAdded.connect(componentAddedHandler);
        _componentRemovedSlot = target.componentRemoved.connect(componentRemovedHandler);
        _addedSlot = target.added.connect(addedOrRemovedHandler);
        _removedSlot = target.removed.connect(addedOrRemovedHandler);
        _started = false;
        if (target.root.hasComponent(SceneManager)) {
            setSceneManager(cast target.root.getComponent(SceneManager));
        }
    }

    public function addedOrRemovedHandler(node:Node, target:Node, parent:Node) {
        if (node.root != target.root) {
            return;
        }

        setSceneManager(cast target.root.getComponent(SceneManager));
    }

    override public function targetRemoved(target:Node) {
        _componentAddedSlot = null;
        _componentRemovedSlot = null;
        _frameBeginSlot = null;
        _frameEndSlot = null;
        if (_started) {
            _started = false;
            stop(target);
        }
    }

    public function componentAddedHandler(nod:Node, target:Node, component:AbstractComponent) {
        var sceneManager:SceneManager = cast(component, SceneManager);
        if (sceneManager != null) {
            setSceneManager(sceneManager);
        }
    }

    public function componentRemovedHandler(nod:Node, target:Node, component:AbstractComponent) {
        var sceneManager:SceneManager = cast(component, SceneManager);

        if (sceneManager != null) {
            setSceneManager(null);
        }
    }

    public function frameBeginHandler(sceneManager:SceneManager, time, deltaTime) {
        var target = this.target;

        _time = time;
        _deltaTime = deltaTime;

        if (!_started && ready && target != null) {
            _started = true;
            start(target);
        }

        if (_started) {
            update(target);
        }

        if (!_started) {
            stop(target);
        }
    }

    public function frameEndHandler(sceneManager:SceneManager, time, deltaTime) {
        if (_started) {
            end(target);
        }
    }

    function setSceneManager(sceneManager:SceneManager = null) {
        if (sceneManager != null && _enabled) {
            if (_frameBeginSlot == null) {
                _frameBeginSlot = sceneManager.frameBegin.connect(frameBeginHandler, priority);
                if (_frameEndSlot == null) {
                    _frameEndSlot = sceneManager.frameEnd.connect(frameEndHandler, priority);
                }
                else if (_frameBeginSlot != null) {
                    if (_started) {
                        _started = false;
                        stop(target);
                    }

                    _frameBeginSlot = null;
                    _frameEndSlot = null;
                }
            }


        }
    }
}
