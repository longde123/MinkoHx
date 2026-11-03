package minko.component;

import glm.Mat4;
import haxe.ds.ObjectMap;
import minko.component.Transform.NodeTransformCacheEntry;
import minko.render.AbstractTexture;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal3.SignalSlot3;

@:expose("minko.component.RootTransform")
class RootTransform extends AbstractComponent {
    public static function create() {
        return new RootTransform();
    }

    private var _nodeTransformCache:Array<NodeTransformCacheEntry>;
    private var _nodeToId:ObjectMap<Node, Int>;
    private var _nodes:Array<Node>;
    private var _invalidLists:Bool;

    private var _targetSlots:Array<SignalSlot3<Dynamic, Dynamic, Dynamic>>;
    private var _renderingBeginSlot:SignalSlot3<SceneManager, Int, AbstractTexture>;
    private var _toAdd:Array<Node>;
    private var _toRemove:Array<Node>;
    private var _nodeToMatrixChangedSlot:ObjectMap<Node, SignalSlot<Transform>>;

    public function new() {
        super();
        this._nodeTransformCache = new Array<NodeTransformCacheEntry>();
        this._nodeToId = new ObjectMap<Node, Int>();
        this._nodes = new Array<Node>();
        this._invalidLists = false;
        this._targetSlots = new Array<SignalSlot3<Dynamic, Dynamic, Dynamic>>();
        this._renderingBeginSlot = null;
        this._toAdd = new Array<Node>();
        this._toRemove = new Array<Node>();
        this._nodeToMatrixChangedSlot = new ObjectMap<Node, SignalSlot<Transform>>();
    }

    override public function dispose() {
        _nodeTransformCache = null;
        _nodeToId = null;
        for (node in _nodeToMatrixChangedSlot.keys()) {
            _nodeToMatrixChangedSlot.get(node).dispose();
        }
        _nodeToMatrixChangedSlot = null;
        for (slot in _targetSlots) {
            slot.dispose();
        }
        _targetSlots = null;
        if (_renderingBeginSlot != null) {
            _renderingBeginSlot.dispose();
        }
        _renderingBeginSlot = null;
        _nodes = null;
        _toAdd = null;
        _toRemove = null;
        super.dispose();
    }

    public function setDirty(target:Node, d:Bool) {
        if (!_invalidLists) {
            var id = _nodeToId.get(target);
            if (id != null) {
                _nodeTransformCache[id]._dirty = true;
            }
        }
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
        if (Std.isOfType(ctrl, SceneManager)) {
            var sceneManager:SceneManager = cast ctrl;
            _renderingBeginSlot = sceneManager.renderingBegin.connect(renderingBeginHandler, 1000.0);
        }
        else if (Std.isOfType(ctrl, Transform)) {
            if (Lambda.has(_toRemove, target)) {
                _toRemove.remove(target);
            }
            else {
                _toAdd.push(target);
                _invalidLists = true;
            }
        }
    }

    public function componentRemovedHandler(node:Node, target:Node, ctrl:AbstractComponent) {
        if (Std.isOfType(ctrl, SceneManager)) {
            _renderingBeginSlot = null;
        }
        else if (Std.isOfType(ctrl, Transform)) {
            if (Lambda.has(_toAdd, target)) {
                _toAdd.remove(target);
            }
            else {
                _toRemove.push(target);
                _invalidLists = true;
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
                otherRoot = null;
            }
        }
    }

    public function removedHandler(node:Node, target:Node, ancestor:Node) {
        _invalidLists = true;
        var withTransforms:NodeSet = NodeSet.createbyNode(target).descendants(true, false).where(function(n:Node) {
            return n.hasComponent(Transform);
        });
        _toRemove = withTransforms.nodes.concat(_toRemove);
    }

    public function updateTransformsList() {
        if (_toAdd.length == 0 && _toRemove.length == 0) {
            return;
        }

        for (toRemove in _toRemove) {
            var slot = _nodeToMatrixChangedSlot.get(toRemove);
            if (slot != null) {
                slot.dispose();
                _nodeToMatrixChangedSlot.remove(toRemove);
            }
            _nodeToId.remove(toRemove);
        }

        _nodes = new Array<Node>();
        for (nodeAndId in _nodeToId.keys()) {
            _nodes.push(nodeAndId);
        }

        for (node in _toAdd) {
            _nodes.push(node);
            var transform:Transform = cast node.getComponent(Transform);
            if (transform != null) {
                _nodeToMatrixChangedSlot.set(node, transform.matrixChanged.connect(function(_) {
                    var id = _nodeToId.get(node);
                    if (id != null) {
                        _nodeTransformCache[id]._dirty = true;
                    }
                }));
            }
        }

        _toAdd = new Array<Node>();
        _toRemove = new Array<Node>();

        for (cacheEntry in _nodeTransformCache) {
            cacheEntry.clear();
        }
        _nodeTransformCache = [for (i in 0..._nodes.length) new NodeTransformCacheEntry()];

        for (node in _nodes) {
            var transform:Transform = cast node.getComponent(Transform);
            if (transform != null) {
                transform.dirty = true;
            }
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
            nodeCacheEntry._transform = cast node.getComponent(Transform);
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
        if (_nodes.length == 0) {
            return;
        }

        var sortedNodeSet:NodeSet = NodeSet.createbyNode(_nodes[0].root).descendants(true, false).where(function(descendant:Node) {
            var transform:Transform = cast descendant.getComponent(Transform);
            return transform != null && transform.dirty;
        });

        _nodes = sortedNodeSet.nodes.concat([]);
    }

    public function updateTransforms() {
        var modelToWorldMatrix:Mat4 = null;
        var nodeId = 0;

        for (node in _nodes) {
            var nodeCacheEntry = _nodeTransformCache[nodeId];

            if (nodeCacheEntry._dirty) {
                var transform = nodeCacheEntry._transform;
                var parentId = nodeCacheEntry._parentId;

                if (parentId < 0) {
                    modelToWorldMatrix = transform.matrix;
                }
                else {
                    var parentCacheEntry = _nodeTransformCache[parentId];
                    modelToWorldMatrix = parentCacheEntry._transform.modelToWorldMatrix * transform.matrix;
                }

                if (!transform.modelToWorldMatrix.equals(modelToWorldMatrix)) {
                    transform.setModelToWorldMatrix(modelToWorldMatrix);

                    var numChildren = nodeCacheEntry._numChildren;
                    if (numChildren > 0) {
                        var firstChildId = nodeCacheEntry._firstChildId;
                        var lastChildId = firstChildId + numChildren;
                        for (childId in firstChildId...lastChildId) {
                            _nodeTransformCache[childId]._dirty = true;
                        }
                    }
                }

                nodeCacheEntry._dirty = false;
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
    public var _transform:Transform;
    public var _parentId:Int;
    public var _firstChildId:Int;
    public var _numChildren:Int;
    public var _dirty:Bool;

    public function new() {
        this._node = null;
        this._transform = null;
        this._parentId = -1;
        this._firstChildId = -1;
        this._numChildren = 0;
        this._dirty = true;
    }

    public function clear():Void {
        this._node = null;
        this._transform = null;
        this._parentId = -1;
        this._firstChildId = -1;
        this._numChildren = 0;
        this._dirty = true;
    }
}

@:expose("minko.component.Transform")
class Transform extends AbstractComponent {
    private var _matrix:Mat4;
    private var _modelToWorld:Mat4;
    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;
    private var _dirty:Bool;
    private var _matrixChanged:Signal<Transform>;
    private var _modelToWorldChanged:Signal<Transform>;

    public static function create():Transform {
        var ctrl:Transform = new Transform();
        ctrl.matrix = Mat4.identity(new Mat4());
        return ctrl;
    }

    override public function dispose() {
        super.dispose();
        if (_addedSlot != null) _addedSlot.dispose();
        _addedSlot = null;
        if (_removedSlot != null) _removedSlot.dispose();
        _removedSlot = null;
        _matrix = null;
        _modelToWorld = null;
        if (_matrixChanged != null) _matrixChanged.dispose();
        if (_modelToWorldChanged != null) _modelToWorldChanged.dispose();
        _matrixChanged = null;
        _modelToWorldChanged = null;
    }

    public static function createbyMatrix4(transform:Mat4) {
        var ctrl:Transform = create();
        ctrl.matrix = transform;
        return ctrl;
    }

    override public function clone(option:CloneOption) {
        return Transform.createbyMatrix4(this.matrix);
    }

    public var matrixChanged(get, null):Signal<Transform>;

    function get_matrixChanged() {
        return _matrixChanged;
    }

    public var modelToWorldMatrixChanged(get, null):Signal<Transform>;

    function get_modelToWorldMatrixChanged() {
        return _modelToWorldChanged;
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
        return _matrix;
    }

    function set_matrix(value:Mat4) {
        _matrix = value;
        _dirty = true;
        _matrixChanged.execute(this);

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
        return _modelToWorld;
    }

    public function setModelToWorldMatrix(value:Mat4):Void {
        if (!_modelToWorld.equals(value)) {
            _modelToWorld = value;
            _modelToWorldChanged.execute(this);
        }
    }

    public function updateModelToWorldMatrix() {
        var rt:RootTransform = cast target.root.getComponent(RootTransform);
        if (rt != null) {
            rt.forceUpdate(target, true);
        }
    }

    override public function targetAdded(target:Node) {
        if (target.getComponents(Transform).length > 1) {
            throw ("A node cannot have more than one Transform.");
        }
        _addedSlot = target.added.connect(addedOrRemovedHandler);
        addedOrRemovedHandler(null, target, target.parent);
    }

    public function addedOrRemovedHandler(node:Node, target:Node, parent:Node) {
        if (!target.root.hasComponent(RootTransform)) {
            target.root.addComponent(RootTransform.create());
        }
    }

    override public function targetRemoved(target:Node) {
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
        this._matrix = Mat4.identity(new Mat4());
        this._modelToWorld = Mat4.identity(new Mat4());
        this._dirty = false;
        this._matrixChanged = new Signal<Transform>();
        this._modelToWorldChanged = new Signal<Transform>();
    }
}
