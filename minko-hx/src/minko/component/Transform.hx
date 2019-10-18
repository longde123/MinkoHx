package minko.component;
import minko.data.UnsafePointer;
import minko.data.UnsafePointer;
import glm.Mat4;
import haxe.ds.ObjectMap;
import minko.component.Transform.NodeTransformCacheEntry;
import minko.data.Provider;
import minko.data.Store;
import minko.render.AbstractTexture;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal3.SignalSlot3;
import minko.utils.MathUtil;
@:expose("minko.component.RootTransform")
class RootTransform extends AbstractComponent {
    public static function create() {
        return new RootTransform();
    }


    override public function dispose() {
        _nodeTransformCache = null;
        _nodeToId = null;
        for(_n in _nodeToPropertyChangedSlot.keys()){
            _nodeToPropertyChangedSlot.get(_n).dispose();
            _n.dispose();
        }

        _nodeToPropertyChangedSlot=null;
        for(_t in _targetSlots)
              _t.dispose();
        _targetSlots = null;
        if(_renderingBeginSlot!=null)_renderingBeginSlot.dispose();
        _renderingBeginSlot = null;
        _nodes=null;
        _toAdd=null;
        _toRemove=null;
        super.dispose();
    }

    public function setDirty(target:Node, d:Bool) {

        if (!_invalidLists)
            _nodeTransformCache[_nodeToId.get(target)]._dirty = true;

    }

    private var _nodeTransformCache:Array<NodeTransformCacheEntry>;
    private var _nodeToId:ObjectMap<Node, Int> ;
    private var _nodes:Array<Node> ;
    private var _invalidLists:Bool;

    private var _targetSlots:Array<SignalSlot3<Dynamic,Dynamic,Dynamic>> ;
    private var _renderingBeginSlot:SignalSlot3<SceneManager, Int, AbstractTexture>;
    private var _toAdd:Array<Node> ;
    private var _toRemove:Array<Node> ;
    private var _nodeToPropertyChangedSlot:ObjectMap<Node, SignalSlot3<Store, Provider, String>>;

    public function new() {
        super();
        this._nodeTransformCache = new Array<NodeTransformCacheEntry>();
        this._nodeToId = new ObjectMap<Node, Int> ();
        this._nodes = new Array<Node>() ;
        this._invalidLists = false;

        this._targetSlots = new Array<SignalSlot3<Dynamic,Dynamic,Dynamic>>() ;
        this._renderingBeginSlot = null;
        this._toAdd = new Array<Node>() ;
        this._toRemove = new Array<Node>() ;
        this._nodeToPropertyChangedSlot = new ObjectMap<Node, SignalSlot3<Store, Provider, String>>();
    }


    override public function clone(option:CloneOption) {

        return RootTransform.create();
    }

    override public function targetAdded(target:Node) {
        _targetSlots.push(target.added.connect(addedHandler));
        _targetSlots.push(target.removed.connect(removedHandler));
        _targetSlots.push(target.componentAdded.connect(componentAddedHandler));
        _targetSlots.push(target.componentRemoved.connect(componentRemovedHandler));

        var sceneManager:SceneManager = cast target.root.getComponent(SceneManager);

        if (sceneManager != null) {
            _renderingBeginSlot = sceneManager.renderingBegin.connect(renderingBeginHandler, 1000.0);
        }

        addedHandler(target, target.root, target.parent);
    }

    override public function targetRemoved(target:Node) {

    }

    public function componentAddedHandler(node:Node, target:Node, ctrl:AbstractComponent) {

        if (Std.is(ctrl, SceneManager)) {
            var sceneManager:SceneManager = cast(ctrl, SceneManager);
            _renderingBeginSlot = sceneManager.renderingBegin.connect(renderingBeginHandler, 1000.0);
        }
        else {
            if (Std.is(ctrl, Transform)) {

                var removeIt = Lambda.has(_toRemove, target);

                if (removeIt) {
                    _toRemove.remove(target);
                }
                else {
                    _toAdd.push(target);
                    _invalidLists = true;
                }
            }
        }
    }

    public function componentRemovedHandler(node:Node, target:Node, ctrl:AbstractComponent) {

        if (Std.is(ctrl, SceneManager)) {
            var sceneManager:SceneManager = cast(ctrl, SceneManager);
            _renderingBeginSlot = null;
        }
        else {
            if (Std.is(ctrl, Transform)) {
                var addIt = Lambda.has(_toAdd, target);
                if (addIt) {
                    _toAdd.remove(target);
                }
                else {
                    _toRemove.push(target);
                    _invalidLists = true;
                }
            }
        }
    }

    public function addedHandler(node:Node, target:Node, ancestor:Node) {
        if (node.root == this.target && node != target) {
            var otherRoot:RootTransform = cast target.getComponent(RootTransform);

            if (otherRoot != null) {
                _toAdd = _toAdd.concat(otherRoot._nodes.concat(otherRoot._toAdd));
                for (toRemove in _toRemove) {
                    _toAdd.remove(toRemove);
                }
                _invalidLists = true;

                target.removeComponent(otherRoot);
                otherRoot.dispose();
                otherRoot=null;
            }
        }
    }

    public function removedHandler(node:Node, target:Node, ancestor:Node) {
        _invalidLists = true;

        var withTransforms:NodeSet = NodeSet.createbyNode(target).descendants(true, false).where(function(n:Node) {
            return n.hasComponent(Transform);
        });
        _toRemove = withTransforms.nodes.concat(_toRemove) ;
    }

    public function updateTransformsList() {

        //dirty  tree  Trans list
        if (_toAdd.length == 0 && _toRemove.length == 0) {
            return;
        }

        for (toRemove in _toRemove) {
            _nodeToId.remove(toRemove);
            _nodeToPropertyChangedSlot.get(toRemove).dispose();
            _nodeToPropertyChangedSlot.remove(toRemove);
        }

        _nodes = new Array<Node>() ;

        for (nodeAndId in _nodeToId.keys()) {
            _nodes.push(nodeAndId);
        }

        for (node in _toAdd) {
            _nodes.push(node);
            _nodeToPropertyChangedSlot.set(node,
            node.data.getPropertyChanged("matrix").connect(function(store:Store, provider:Provider, propertyName:String) {
                _nodeTransformCache[_nodeToId.get(node)]._dirty = true;
            })
            );
        }

        _toAdd = new Array<Node>();
        _toRemove = new Array<Node>();

        for(n in _nodeTransformCache){
            n.clear();
        }
        _nodeTransformCache = [for (i in 0..._nodes.length) new NodeTransformCacheEntry()];

        for (node in _nodes) {
            var transform:Transform = cast node.getComponent(Transform);

            transform.dirty = true;
        }

        sortNodes();

        var nodeId = 0;
        var ancestor:Node = null;
        var ancestorId = -1;
        var firstSiblingId = -1;
        var numSiblings = 0;

        for (node in _nodes) {
            var previousAncestor = ancestor;

            ancestor = node.parent;

            while (ancestor != null && !ancestor.hasComponent(Transform)) {
                ancestor = ancestor.parent;
            }

            if (previousAncestor == null && ancestor == null) {
                numSiblings = 0;
            }
            else if (ancestor != previousAncestor) {
                if (previousAncestor == null) {
                    ancestorId = _nodeToId.get(ancestor);

                    firstSiblingId = nodeId;
                    ++numSiblings;
                }
                else {
                    var previousAncestorId = _nodeToId.get(previousAncestor);

                    var previousAncestorCacheEntry = _nodeTransformCache[previousAncestorId];

                    previousAncestorCacheEntry._firstChildId = firstSiblingId;
                    previousAncestorCacheEntry._numChildren = numSiblings;

                    firstSiblingId = nodeId;
                    numSiblings = ancestor != null ? 1 : 0;

                    previousAncestor = ancestor;

                    ancestorId = ancestor != null ? _nodeToId.get(ancestor) : -1;
                }
            }
            else {
                ++numSiblings;
            }

            _nodeToId.set(node, nodeId);

            var nodeCacheEntry = _nodeTransformCache[nodeId];

            nodeCacheEntry._node = node;

            nodeCacheEntry._parentId = ancestorId;

            nodeCacheEntry._matrix = node.data.getUnsafePointer("matrix");
            nodeCacheEntry._modelToWorldMatrix = node.data.getUnsafePointer("modelToWorldMatrix");
            nodeCacheEntry._provider = cast( node.getComponent(Transform), Transform).data;

            ++nodeId;
      }

        if (ancestor != null) {
            ancestorId = _nodeToId.get(ancestor);

            var ancestorCacheEntry = _nodeTransformCache[ancestorId];
            ancestorCacheEntry._firstChildId = firstSiblingId;
            ancestorCacheEntry._numChildren = numSiblings;
        }

        _invalidLists = false;
    }

    public function sortNodes() {

        var sortedNodeSet:NodeSet = NodeSet.createbyNode(_nodes[0].root).descendants(true, false).where(function(descendant:Node) {
            var transform:Transform = cast descendant.getComponent(Transform);

            return transform != null && transform.dirty;
        });

        //_nodes.assign(sortedNodeSet.nodes().begin(), sortedNodeSet.nodes().end());
        _nodes = sortedNodeSet.nodes.concat([]);
    }

    public function updateTransforms() {
        var modelToWorldMatrix:Mat4 = null;
        var nodeId = 0;
        var propertyName = "modelToWorldMatrix";

        for (node in _nodes) {
            var nodeCacheEntry = _nodeTransformCache[nodeId];

            if (nodeCacheEntry._dirty) {
                var parentId = nodeCacheEntry._parentId;

                if (parentId < 0) {
                    modelToWorldMatrix = nodeCacheEntry._matrix.value;
                }
                else {
                    var parentCacheEntry = _nodeTransformCache[parentId];
                    //math
                    modelToWorldMatrix = parentCacheEntry._modelToWorldMatrix.value * (nodeCacheEntry._matrix.value);
                }

                // Because we use an unsafe pointer that gives us a direct access to the
                // data provider internal value for "modelToWorldMatrix", we have to trigger
                // the "property changed" signal manually.
                // This technique completely bypasses the storeproperty name resolving
                // mechanism and is a lot faster.
                //todo fix !=
                if (!nodeCacheEntry._modelToWorldMatrix.value.equals(modelToWorldMatrix)) {
                    var nodeData:Store = node.data;
                    var provider = nodeCacheEntry._provider;

                    // manually update the data provider internal mat4 object
                   nodeCacheEntry._modelToWorldMatrix.value= modelToWorldMatrix;

                    // execute the "property changed" signal(s) manually
                    nodeData.propertyChanged.execute(nodeData, provider, propertyName);
                    if (nodeData.hasPropertyChangedSignal("modelToWorldMatrix")) {
                        nodeData.getPropertyChanged("modelToWorldMatrix").execute(nodeData, provider, propertyName);
                    }

                    var numChildren = nodeCacheEntry._numChildren;

                    if (numChildren > 0) {
                        var firstChildId = nodeCacheEntry._firstChildId;
                        var lastChildId = firstChildId + numChildren;

                        for (childId in firstChildId... lastChildId) {
                            var childCacheEntry = _nodeTransformCache[childId];
                            childCacheEntry._dirty = true;
                        }
                    }
                }

                nodeCacheEntry._dirty = false;

                var transform:Transform = cast node.getComponent(Transform);

                transform.dirty = false;
            }

            ++nodeId;
        }
    }

    public function forceUpdate(node:Node, updateTransformLists:Bool) {
        if (_invalidLists || updateTransformLists) {
            updateTransformsList();
        }

        updateTransforms();
    }

    public function renderingBeginHandler(sceneManager:SceneManager, frameId:Int, abstractTexture:AbstractTexture) {
        if (_invalidLists) {
            updateTransformsList();
        }

        updateTransforms();
    }
}
@:expose("minko.component.NodeTransformCacheEntry")
class NodeTransformCacheEntry {
    public var _node:Node;
    public var _matrix:UnsafePointer<Mat4>;
    public var _modelToWorldMatrix:UnsafePointer<Mat4>;

    public var _parentId:Int;
    public var _firstChildId:Int;
    public var _numChildren:Int;

    public var _dirty:Bool;
    public var _provider:Provider;

    public function new() {
        this._node = null;
        this._matrix = null;
        this._modelToWorldMatrix = null;
        this._parentId = -1;
        this._firstChildId = -1;
        this._numChildren = 0;
        this._dirty = true;
        this._provider = null;
    }

    public function clear():Void {
        this._node = null;
        this._matrix = null;
        this._modelToWorldMatrix = null;
        this._parentId = -1;
        this._firstChildId = -1;
        this._numChildren = 0;
        this._dirty = true;
        this._provider = null;
    }
}
@:expose("minko.component.Transform")
class Transform extends AbstractComponent {

    private var _matrix:UnsafePointer<Mat4>;
    private var _modelToWorld:UnsafePointer<Mat4>;
    private var _data:Provider;
    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;
    private var _dirty:Bool;

    public static function create():Transform {
        var ctrl:Transform = new Transform();

        ctrl.matrix = Mat4.identity(new Mat4());

        return ctrl;
    }

    override public function dispose() {
        super.dispose();
        if(_addedSlot !=null)_addedSlot.dispose();
        _addedSlot=null;
        if(_removedSlot!=null)_removedSlot.dispose();
        _removedSlot=null;
        _modelToWorld=null;
        _matrix=null;
        if(_data!=null) _data.dispose();
        _data=null;
    }


    public static function createbyMatrix4(transform:Mat4) {
        var ctrl:Transform = create();

        ctrl.matrix = transform;

        return ctrl;
    }

    override public function clone(option:CloneOption) {
        return Transform.createbyMatrix4(this.matrix.toFloatArray());
    }
    public var data(get, null):Provider;

    function get_data() {
        return _data;
    }
    public var dirty(get, set):Bool;

    function get_dirty() {
        return _dirty;
    }

    function set_dirty(v) {
        _dirty = v;
        return v;
    }

    public var matrix(get, set):Mat4;

    function get_matrix() {
        return _matrix.value;
    }

    function set_matrix(value:Mat4) {
      //  if (! value.equals( _matrix.value)) {
            //todo       this._data.set("matrix", _matrix)
          _matrix.value= value;
       // }
        if (target != null) {
            var rootTransform:RootTransform = cast target.root.getComponent(RootTransform);
            if (rootTransform != null) {
                rootTransform.setDirty(target, true);
            }
        }
        return value;
    }

    public var modelToWorldMatrix(get, null):Mat4;

    function get_modelToWorldMatrix() {
        return _modelToWorldMatrix(false);
    }

    public function _modelToWorldMatrix(forceUpdate) {
        if (forceUpdate) {
            updateModelToWorldMatrix();
        }

        return _modelToWorld.value;
    }

    public function updateModelToWorldMatrix() {
        var rt:RootTransform = cast target.root.getComponent(RootTransform);
        rt.forceUpdate(target, true);
    }

    override public function targetAdded(target:Node) {
        if (target.getComponents(Transform).length > 1) {
            throw ("A node cannot have more than one Transform.");
        }
        target.data.addProvider(_data);
        _addedSlot = target.added.connect(addedOrRemovedHandler);
        //_removedSlot = target->removed()->connect(callback);

        addedOrRemovedHandler(null, target, target.parent);
    }

    public function addedOrRemovedHandler(node:Node, target:Node, parent:Node) {
        if (!target.root.hasComponent(RootTransform)) {
            target.root.addComponent(RootTransform.create());
        }
    }

    override public function targetRemoved(target:Node) {
        target.data.removeProvider(_data);
        if (_addedSlot != null) {
            _addedSlot.dispose();
        }
        _addedSlot = null;
        if (_removedSlot != null) {
            _removedSlot.dispose();
        }

        _removedSlot = null;
    }

    public function new() {
        super();
        //	_worldToModel(1.),

        this._data = Provider.create();
        this._dirty = false;
        this._data
        .set("matrix", Mat4.identity(new Mat4()))
        .set("modelToWorldMatrix", Mat4.identity(new Mat4()));

        this._matrix = cast this._data.getUnsafePointer("matrix") ;
        this._modelToWorld = cast this._data.getUnsafePointer("modelToWorldMatrix") ;
    }

}
