package minko.math;
import glm.Vec3;
import glm.Vec3;
import glm.GLM;
import glm.Vec3;
import glm.Mat4;
import haxe.ds.ObjectMap;
import minko.component.BoundingBox;
import minko.component.Surface;
import minko.component.Transform;
import minko.data.Provider;
import minko.data.Store;
import minko.file.AssetLibrary;
import minko.geometry.CubeGeometry;
import minko.material.BasicMaterial;
import minko.math.AbstractShape.BoundingBoxPlane;
import minko.math.AbstractShape.ShapePosition;
import minko.render.Blending.Mode;
import minko.render.Priority;
import minko.render.TriangleCulling;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal3;
import minko.utils.MathUtil;
@:expose("minko.math.NodeEntry")
class NodeEntry {

    public var node:Node;
    public var box:Box;

    public function new(node, box) {
        this.node = node;
        this.box = box;
    }


}
@:expose("minko.math.OctTree")
class OctTree {
    public static inline var _k = 2;
    private var _maxDepth:Int;
    private var _depth:Int;
    private var _splitted:Bool;
    private var _parent:OctTree;
    private var _root:OctTree;
    private var _children:Array<OctTree>; //x, y, z in {0, 1}, child index : x + y << 1 + z << 2
    private var _content:Array<NodeEntry>;
    private var _childrenContent:Array<Node>;
    private var _nodeToOctant:ObjectMap<Node, OctTree> ;
    private var _worldSize:Float;
    private var _center:Vec3;
    private var _nodeToTransformChangedSlot:ObjectMap<Node, SignalSlot3<Store, Provider, String>>;
    private var _octantBox:Box;
    private var _inside:Bool;
    private var _debugNode:Node;
    private var _frustumLastPlaneId:ShapePosition;
    private var _invalidNodes:Array<Node>;


    public function new(worldSize:Float, maxDepth:Int, center:Vec3, depth:Int) {
        this._maxDepth = maxDepth;
        this._depth = depth;
        this._splitted = false;
        this._worldSize = worldSize;
        this._center = center;
        this._frustumLastPlaneId = 0 ;
        var halfEdgeLength = edgeLength / 2.0 ;

        _octantBox = Box.createbyVector3( (_center+ halfEdgeLength),  (_center - halfEdgeLength));
        _nodeToTransformChangedSlot = new ObjectMap<Node, SignalSlot3<Store, Provider, String>>();


        _children = []; //x, y, z in {0, 1}, child index : x + y << 1 + z << 2
        _content = [];
        _childrenContent = [];
        _nodeToOctant = new ObjectMap<Node, OctTree>() ;
        _invalidNodes = [];
    }

    public static function create(worldSize, maxDepth, center, depth = 0) {
        var instance:OctTree = (new OctTree(worldSize, maxDepth, center, depth));

        instance._root = instance;

        return instance;
    }

    public function insert(node:Node) {
        if (_nodeToOctant.exists(node)) {
            return this;
        }

        if (!node.hasComponent(BoundingBox)) {
            return this;
        }

        var transform:Transform = cast node.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        var optimalDepth = Math.floor(Math.min(computeDepth(node), _maxDepth));
        var currentDepth = 0;

        return _root.doInsert(node, 0, optimalDepth);
    }

    public function remove(node:Node) {
        var root = _root;
        root._invalidNodes.remove(node);
        return root.doRemove(node);
    }

    public function computeDepth(node:Node) {
        var surface:Surface = cast node.getComponent(Surface);
        var size = computeSize(cast node.getComponent(BoundingBox));

        return Math.floor(Math.log(_worldSize / size) / Math.log(2));
    }

    public function generateVisual(assetLibrary:AssetLibrary, rootNode:Node = null) {
        if (rootNode == null) {
            rootNode = Node.create();
        }

        var node:Node = Node.create();

        if (_content.length > 0) {

            var matrix:Mat4 = GLM.translate(new Vec3(_center.x, _center.y, _center.z) ,  Mat4.identity(new Mat4())) *
            GLM.scale( new Vec3(edgeLength, edgeLength, edgeLength),  Mat4.identity(new Mat4()) );

            var material:BasicMaterial = BasicMaterial.create();

            material.diffuseColorRGBA(0x00FF0020);
            material.blendingMode = (Mode.ALPHA);
            material.triangleCulling = (TriangleCulling.NONE);
            material.priority = (Priority.TRANSPARENT);

            node.addComponent(Transform.createbyMatrix4(matrix))
            .addComponent(Surface.create(CubeGeometry.create(assetLibrary.context), material, assetLibrary.effect("effect/Basic.effect")));
            rootNode.addChild(node);
            _debugNode = node;
        }

        if (_splitted) {
            for (octant in _children) {
                octant.generateVisual(assetLibrary, rootNode);
            }
        }

        return node;
    }

    public function testFrustum(frustum:AbstractShape, insideFrustumCallback:Node -> Void, outsideFustumCallback:Node -> Void) {
        if (_invalidNodes.length > 0) {
            //todo
            for (node in _invalidNodes) {
                remove(node);
                insert(node);
            }
            _invalidNodes = new Array<Node>();
        }

        var frustumPtr:AbstractShape = (frustum);

        if (frustumPtr != null) {
            var result:BoundingBoxPlane = frustumPtr.testBoundingBoxandPlane(_octantBox, _frustumLastPlaneId);

            var shapePosition = result.first;
            _frustumLastPlaneId = cast result.second;

            if (shapePosition == ShapePosition.AROUND || shapePosition == ShapePosition.INSIDE) {
                if (_splitted) {
                    for (octantChild in _children) {
                        octantChild.testFrustum(frustum, insideFrustumCallback, outsideFustumCallback);
                    }
                }

                for (nodeEntry in _content) {
                    var node = nodeEntry.node;
                    var nodeBox = nodeEntry.box;

                    var nodeResult:BoundingBoxPlane = frustumPtr.testBoundingBoxandPlane(nodeBox, _frustumLastPlaneId);

                    if (nodeResult.first == ShapePosition.AROUND || nodeResult.first == ShapePosition.INSIDE) {
                        insideFrustumCallback(node);
                    }
                    else {
                        outsideFustumCallback(node);
                    }
                }
            }
            else {
                for (node in _childrenContent) {
                    outsideFustumCallback(node);
                }
            }
        }
    }

    public function addToContent(node:Node) {
        _nodeToOctant.set(node, this);

        addToChildContent(node);

        _content.push(new NodeEntry(node, cast(node.getComponent(BoundingBox), BoundingBox).box));

        _nodeToTransformChangedSlot.set(node, node.data.getPropertyChanged("modelToWorldMatrix").connect(
            function(store:Store, provider:Provider, propertyName:String) {
                nodeModelToWorldChanged(node);
            }
        ));
    }

    public function removeFromContent(node:Node) {
        var contentNodeIt:NodeEntry = Lambda.find(_content, function(nodeEntry:NodeEntry) return nodeEntry.node == node);

        if (contentNodeIt == null)
            return false;

        _content.remove(contentNodeIt);
        _nodeToTransformChangedSlot.remove(node);

        return true;
    }

    public function addToChildContent(node:Node) {
        _childrenContent.push(node);

        if (_parent == null)
            return;

        var parent = _parent ;

        parent._nodeToOctant.set(node, this);
        parent.addToChildContent(node);
    }

    public function intersects(node:Node) {
        var nodeBox:Box = cast(node.getComponent(BoundingBox), BoundingBox).box;
        var nodeMinBound = nodeBox.bottomLeft;
        var nodeMaxBound = nodeBox.topRight;
        var minBound = _octantBox.bottomLeft;
        var maxBound = _octantBox.topRight;
        if (nodeMinBound.x >= maxBound.x ||
        nodeMaxBound.x < minBound.x)
            return false;

        if (nodeMinBound.y >= maxBound.y ||
        nodeMaxBound.y < minBound.y)
            return false;

        if (nodeMinBound.z >= maxBound.z ||
        nodeMaxBound.z < minBound.z)
            return false;

        return true;
    }


    public function findNodeOctant(node:Node) {
    }

    public function nodeModelToWorldChanged(node:Node) {
        invalidateNode(node);
    }

    public function invalidateNode(node:Node) {
        _root._invalidNodes.push(node);
    }

    public function childOctantsIntersection(node:Node, octants:Array<OctTree>) {

        var nodeBox:Box = cast(node.getComponent(BoundingBox), BoundingBox).box;

        var nodeMinBound = nodeBox.bottomLeft;
        var nodeMaxBound = nodeBox.topRight;

        for (childOctant in _children) {
            if (!childOctant.intersects(node))
                continue;

            octants.push(childOctant);
        }

        return octants.length > 0;
    }

    public function doInsert(node:Node, currentDepth, optimalDepth) {
        if (!_splitted)
            split();

        var octants:Array<OctTree> = new Array<OctTree>();

        if (!childOctantsIntersection(node, octants)) {
            addToContent(node);

            return this;
        }

        var childOctantsConflict = octants.length > 1;

        var octant:OctTree = childOctantsConflict
        ? this
        : octants[0];

        if (childOctantsConflict || currentDepth == optimalDepth) {
            octant.addToContent(node);

            return this;
        }

        return octant.doInsert(node, currentDepth + 1, optimalDepth);
    }

    public function doRemove(node:Node) {
        var octantIt = _nodeToOctant.exists(node);

        if (octantIt == false)
            return this;

        var octant = _nodeToOctant.get(node);

        _childrenContent.remove(node);
        _nodeToOctant.remove(node);

        if (removeFromContent(node) || octant == this)
            return this;

        return octant.doRemove(node);
    }

    private function split() {
        this._children = [for (i in 0...8) null];//.Resize(8);

        var halfEdgeLength = edgeLength / 2.0 ;

        for (x in 0... 2) {
            for (y in 0...2) {
                for (z in 0...2) {
                    var index = x + (y << 1) + (z << 2);

                    var child:OctTree = OctTree.create(_worldSize,
                    _maxDepth,
                    new Vec3(_center.x + (x == 0 ? -halfEdgeLength / 2.0 : halfEdgeLength / 2.0),
                    _center.y + (y == 0 ? -halfEdgeLength / 2.0 : halfEdgeLength / 2.0),
                    _center.z + (z == 0 ? -halfEdgeLength / 2.0 : halfEdgeLength / 2.0)),
                    _depth + 1);
                    _children[index] = child;

                    child._parent = this;
                    child._root = _root;
                }
            }
        }
        _splitted = true;
    }

    private function computeSize(boundingBox:BoundingBox) {
        return Math.max(boundingBox.box.width, Math.max(boundingBox.box.height, boundingBox.box.depth));
    }

    public var edgeLength(get, null):Float;

    function get_edgeLength() {
        return (_worldSize / Math.pow(2.0, _depth));
    }

}
