package minko.component;
import haxe.ds.ObjectMap;
import minko.data.Provider;
import minko.file.StreamingOptions;
import minko.geometry.Geometry;
import minko.render.AbstractTexture;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal5;
class MasterLodScheduler extends AbstractComponent {

    private var _geometryToDataMap:ObjectMap<Geometry, Provider>;
    private var _textureToDataMap:ObjectMap<AbstractTexture, Provider>;
    private var _deferredTextureDataSet:Array<Provider>;

    private var _deferredTextureRegistered:Signal2<MasterLodScheduler, Provider>;
    private var _deferredTextureReady:Signal5<MasterLodScheduler, Provider, Array<Provider>, String, AbstractTexture>;
    private var _streamingOptions:StreamingOptions;

    private var _nodeAddedSlot:SignalSlot3<Node, Node, Node>;
    private var _nodeRemovedSlot:SignalSlot3<Node, Node, Node>;

    private var _componentAddedSlot:SignalSlot3<Node, Node, AbstractComponent>;
    private var _componentRemovedSlot:SignalSlot3<Node, Node, AbstractComponent>;

    private var _lodSchedulers:Array<AbstractLodScheduler>;

    public static function create() {
        var instance = new MasterLodScheduler();

        instance.initialize();

        return instance;
    }
    public var streamingOptions(get, null):StreamingOptions;

    function get_streamingOptions() {
        return _streamingOptions;
    }
    public var deferredTextureRegistered(get, null):Signal2<MasterLodScheduler, Provider>;

    function get_deferredTextureRegistered() {
        return _deferredTextureRegistered;
    }
    public var deferredTextureReady(get, null):Signal5<MasterLodScheduler, Provider, Array<Provider>, String, AbstractTexture>;

    function get_deferredTextureReady() {
        return _deferredTextureReady;
    }
    public var deferredTextureDataSet(get, null):Array<Provider>;

    function get_deferredTextureDataSet() {
        return _deferredTextureDataSet;
    }

    public function new() {
        super();
        this._geometryToDataMap = new ObjectMap<Geometry, Provider>();
        this._textureToDataMap = new ObjectMap<AbstractTexture, Provider>();
        this._deferredTextureDataSet = new Array<Provider>();
        this._deferredTextureRegistered = new Signal2<MasterLodScheduler, Provider>();
        this._deferredTextureReady = new Signal5<MasterLodScheduler, Provider, Array<Provider>, String, AbstractTexture>();
    }

    public function invalidateLodRequirement() {
        for (lodScheduler in _lodSchedulers) {
            lodScheduler.invalidateLodRequirement();
        }
    }

    public function forceUpdate() {
        for (lodScheduler in _lodSchedulers) {
            lodScheduler.forceUpdate();
        }
    }
    public var enabled(null, set):Bool;

    function set_enabled(_enabled) {
        for (lodScheduler in _lodSchedulers) {
            lodScheduler.enabled = (_enabled);
        }
        return _enabled;
    }

    public function registerGeometry(geometry:Geometry, data:Provider) {
        _geometryToDataMap.set(geometry, data);

        return (this);
    }

    public function unregisterGeometry(geometry:Geometry) {
        _geometryToDataMap.remove(geometry);
    }

    public function geometryData(geometry:Geometry) {
        var dataIt = _geometryToDataMap.exists(geometry);

        return dataIt ? _geometryToDataMap.get(geometry) : null;
    }

    public function registerTexture(texture:AbstractTexture, data:Provider) {
        _textureToDataMap.set(texture, data);

        return (this);
    }

    public function registerDeferredTexture(data:Provider) {
        _deferredTextureDataSet.remove(data);

        deferredTextureRegistered.execute((this), data);

        return (this);
    }

    public function doDeferredTextureReady(data:Provider, materialDataSet:Array<Provider>, textureType:String, texture:AbstractTexture) {
        deferredTextureReady.execute((this), data, materialDataSet, textureType, texture);

        return (this);
    }

    public function unregisterTexture(texture:AbstractTexture) {
        _textureToDataMap.remove(texture);
    }

    public function textureData(texture:AbstractTexture) {
        var dataIt = _textureToDataMap.exists(texture);

        return dataIt ? _textureToDataMap.get(texture) : null;
    }

    override function set_layoutMask(value) {
        super.set_layoutMask(value);

        for (lodScheduler in _lodSchedulers) {
            lodScheduler.layoutMask = (value);
        }
    }

    override public function targetAdded(target:Node) {
        super.targetAdded(target);
        _nodeAddedSlot = target.added.connect(function(target:Node, node:Node, parent:Node) {
            var lodSchedulerNodes:NodeSet = NodeSet.createbyNode(node).descendants(true).where(function(descendant:Node) {
                return descendant.hasComponent(AbstractLodScheduler);
            });

            for (lodSchedulerNode in lodSchedulerNodes.nodes) {
                for (lodScheduler in lodSchedulerNode.getComponents(AbstractLodScheduler)) {
                    addLodScheduler(cast lodScheduler);
                }
            }
        });


        _nodeRemovedSlot = target.removed.connect(function(target:Node, node:Node, parent:Node) {
            var lodSchedulerNodes:NodeSet = NodeSet.createbyNode(node).descendants(true).where(function(descendant:Node) {
                return descendant.hasComponent(AbstractLodScheduler);
            });

            for (lodSchedulerNode in lodSchedulerNodes.nodes) {
                for (lodScheduler in lodSchedulerNode.getComponents(AbstractLodScheduler)) {
                    removeLodScheduler(cast lodScheduler);
                }
            }
        });
        _componentAddedSlot = target.componentAdded.connect(function(node:Node, target:Node, component:AbstractComponent) {
            var lodScheduler:AbstractLodScheduler = cast(component);

            if (lodScheduler!=null) {
                addLodScheduler(cast lodScheduler);
            }
        });

        _componentRemovedSlot = target.componentRemoved.connect(function(node:Node, target:Node, component:AbstractComponent) {
            var lodScheduler:AbstractLodScheduler = cast(component);

            if (lodScheduler!=null) {
                removeLodScheduler(cast lodScheduler);
            }
        });
    }

    override public function targetRemoved(target:Node) {
        super.targetRemoved(target);

        _nodeAddedSlot = null;
        _nodeRemovedSlot = null;

        _componentAddedSlot = null;
        _componentRemovedSlot = null;
    }

    public function initialize() {
        _streamingOptions = StreamingOptions.create();

        _streamingOptions.masterLodScheduler = (this);
    }

    public function addLodScheduler(lodScheduler:AbstractLodScheduler) {
        lodScheduler.layoutMask = layoutMask;

        _lodSchedulers.push(lodScheduler);
    }

    public function removeLodScheduler(lodScheduler:AbstractLodScheduler) {
        _lodSchedulers.remove(lodScheduler);
    }

}
