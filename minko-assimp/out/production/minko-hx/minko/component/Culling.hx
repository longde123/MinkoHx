package minko.component;
import glm.Vec3;
import minko.data.Provider;
import minko.data.Store;
import minko.math.AbstractShape;
import minko.math.OctTree;
import minko.render.AbstractTexture;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Layout;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
@:expose("minko.component.Culling")
class Culling extends AbstractComponent {

    private var _octTree:OctTree;
    private var _worldSize:Float;
    private var _maxDepth:Int;
    private var _layout:Int;
    private var _bindProperty:String;
    private var _frustum:AbstractShape;
    private var _targetAddedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _targetRemovedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;
    private var _addedToSceneSlot:SignalSlot3<Node, Node, Node>;
    private var _layoutChangedSlot:SignalSlot2<Node, Node>;
    private var _viewMatrixChangedSlot:SignalSlot3<Store, Provider, String>;
    private var _updateNextFrame:Bool;
    private var _renderingBeginSlot:SignalSlot3<SceneManager, Int, AbstractTexture>;

    public function new(shape:AbstractShape, bindProperty:String, layout:Layout) {
        super();
        this._frustum = shape;
        this._bindProperty = bindProperty;
        this._worldSize = 50.0;
        this._maxDepth = 7;
        this._layout = layout;
    }

    public static function create(shape:AbstractShape, bindPropertyName:String, ?layout = BuiltinLayout.DEFAULT) {
        return new Culling(shape, bindPropertyName, layout);
    }

    public var worldSize(get, set):Float;

    function get_worldSize() {
        return _worldSize;
    }

    function set_worldSize(value) {
        _worldSize = value;

        return value;
    }

    public var maxDepth(get, set):Int;

    function get_maxDepth() {
        return _maxDepth;
    }

    function set_maxDepth(value) {
        _maxDepth = value;

        return value;
    }

    public var octTree(get, null):OctTree;

    function get_octTree() {
        return _octTree;
    }

    override public function targetAdded(target:Node) {
        if (target.getComponents(Culling).length > 1) {
            throw ("The same camera node cannot have more than one Culling.");
        }

        if (_octTree == null) {
            _octTree = OctTree.create(worldSize, maxDepth, new Vec3());
        }

        if (target.root.hasComponent(SceneManager)) {
            targetAddedToSceneHandler(null, target, null);
        }
        else {
            _addedToSceneSlot = target.added.connect(targetAddedToSceneHandler);
        }

        _viewMatrixChangedSlot = target.data.getPropertyChanged(_bindProperty).connect(function(d, p, n) {
            _updateNextFrame = true;
        });
    }

    override public function targetRemoved(target:Node) {
        _addedSlot = null;
        _removedSlot = null;
        _layoutChangedSlot = null;
        _renderingBeginSlot = null;
        _octTree = null;
        _addedToSceneSlot = null;
        _viewMatrixChangedSlot = null;
        _renderingBeginSlot = null;
    }


    private function addedHandler(node:Node, target:Node, ancestor:Node) {
        var nodeSet:NodeSet = NodeSet.createbyNode(target).descendants(true).where(function(descendant:Node) {
            return (descendant.layout & BuiltinLayout.IGNORE_CULLING) == 0 && descendant.hasComponent(Surface);
        });

        for (n in nodeSet.nodes) {
            _octTree.insert(n);
        }
    }

    private function removedHandler(node:Node, target:Node, ancestor:Node) {
        var nodeSet:NodeSet = NodeSet.createbyNode(target).descendants(true).where(function(descendant:Node) {
            return (descendant.layout & BuiltinLayout.IGNORE_CULLING) == 0 && descendant.hasComponent(Surface);
        });

        for (nodeToRemove in nodeSet.nodes) {
            _octTree.remove(nodeToRemove);
        }
    }

    private function layoutChangedHandler(node:Node, target:Node) {
        if ((target.layout & BuiltinLayout.IGNORE_CULLING) == 0) {
            _octTree.insert(target);
        }
        else {
            _octTree.remove(target);
        }
    }

    private function targetAddedToSceneHandler(node:Node, target:Node, ancestor:Node) {
        var sceneManager:SceneManager = cast target.root.getComponent(SceneManager);

        if (sceneManager != null) {
            _addedToSceneSlot = null;

            _layoutChangedSlot = target.root.layoutChanged.connect(layoutChangedHandler);
            _addedSlot = target.root.added.connect(addedHandler, -1.0);

            _removedSlot = target.root.removed.connect(removedHandler);

            _renderingBeginSlot = sceneManager.renderingBegin.connect(function(sm:SceneManager, fid:Int, rt:AbstractTexture) {
                if (_updateNextFrame) {
                    _frustum.updateFromMatrix(this.target.data.get(_bindProperty));
                    _octTree.testFrustum(_frustum,
                    function(node:Node) {
                        var layout = node.layout;
                        if ((layout & BuiltinLayout.HIDDEN) == 0) {
                            layout = layout | BuiltinLayout.DEFAULT;
                        }
                        layout = layout | BuiltinLayout.INSIDE_FRUSTUM;
                        node.layout = (layout);
                    },
                    function(node:Node) {
                        var layout = node.layout;
                        layout = layout & ~BuiltinLayout.DEFAULT;
                        layout = layout & ~BuiltinLayout.INSIDE_FRUSTUM;
                        node.layout = (layout);
                    }
                    );
                    _updateNextFrame = false;
                }
            }, -1.0);

            addedHandler(target.root, target.root, target.root);
        }
    }
}
