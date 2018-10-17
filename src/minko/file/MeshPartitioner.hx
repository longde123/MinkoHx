package minko.file;
import Array;
import glm.Vec3;
import haxe.ds.ObjectMap;
import minko.component.Surface;
import minko.data.HalfEdge;
import minko.geometry.Geometry;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
import minko.utils.VectorHelper;

class SurfaceIndexer {
    public var hash:Surface -> Int;
    public var equal:Surface -> Surface -> Bool;
}


class Options {
    private var instanceFieldsInitialized:Bool ;

    static private function initializeInstanceFields() {
        all = mergeSurfaces | createOneNodePerSurface | applyCrackFreePolicy;
    }

    private static var none = 0;

    private static var mergeSurfaces = 1 << 0;
    private static var createOneNodePerSurface = 1 << 1;
    private static var applyCrackFreePolicy = 1 << 2;

    private static var all = initializeInstanceFields();

    private var maxNumTrianglesPerNode:Int;
    private var maxNumIndicesPerNode:Int;

    private var maxNumSurfacesPerSurfaceBucket:Int;
    private var maxNumTrianglesPerSurfaceBucket:Int;

    private var flags:Int;

    private var partitionMaxSizeFunction:Options -> NodeSet -> Vec3;

    private var worldBoundsFunction:NodeSet -> Vec3 -> Vec3 -> Void;

    private var nodeFilterFunction:Node -> Bool;
    private var surfaceIndexer:SurfaceIndexer;

    private var validSurfacePredicate:Surface -> Bool;
    private var instanceSurfacePredicate:Surface -> Bool;

}


class OctreeNode {
    public function new(depth:Int, minBound:Vec3, maxBound:Vec3, parent:OctreeNode) {
        this.depth = depth;
        this.minBound = minBound;
        this.maxBound = maxBound;
        this.triangles = VectorHelper.nestedList(1, 1, 0);
        this.sharedTriangles = VectorHelper.nestedList(1, 1, 0);
        this.indices = VectorHelper.nestedList(1, 1, 0);
        this.sharedIndices = VectorHelper.nestedList(1, 1, 0);
        this.parent = parent;
        this.children = new Array<OctreeNode>();
    }

    public var depth:Int;
    public var minBound:Vec3;
    public var maxBound:Vec3;

    public var triangles:Array<Array<Int>>;
    public var sharedTriangles:Array<Array<Int>>;

    public var indices:Array<Array<Int>>;
    public var sharedIndices:Array<Array<Int>>;

    public var parent:OctreeNode;

    public var children:Array<OctreeNode>;
}
class SpatialIndex<T> {
    public function clear(){

    }

    public function get(v:Vec3):T {

    }

    public function size():Int {

    }
}

class PartitionInfo {
    public var root:Node;
    public var surfaces:Array<Surface> ;

    public var useRootSpace:Bool;
    public var isInstance:Bool;

    public var indices:Array<Int>;
    public var vertices:Array<Float>;

    public var minBound:Vec3;
    public var maxBound:Vec3;

    public var vertexSize:Int;
    public var positionAttributeOffset:Int;

    public var baseDepth:Int;

    public var halfEdges:Array<HalfEdge>;
    public var halfEdgeReferences:Array<HalfEdge>;

    public var protectedIndices:Array<Int>;

    public var mergedIndices:SpatialIndex<Array<Int>>;
    public var markedDiscontinousIndices:Array<Int>;

    public var rootPartitionNode:OctreeNode;

}


class MeshPartitioner extends AbstractWriterPreprocessor<Node> {
    private var _options:Options;
    private var _streamingOptions:StreamingOptions;

    private var _assetLibrary:AssetLibrary;

    private var _filteredNodes:NodeSet;

    private var _worldMinBound:Vec3;
    private var _worldMaxBound:Vec3;

    private var _processedInstances:ObjectMap<Geometry, Array<Geometry>>;

    private var _progressRate:Float;
    private var _statusChanged:Signal2<AbstractWriterPreprocessor<Node>, String>;


    public static function create(options:Options, streamingOptions:StreamingOptions) {
        var instance = (new MeshPartitioner());

        instance._options = options;
        instance._streamingOptions = streamingOptions;

        return instance;
    }

    public var progressRate(get, null):Float;

    function get_progressRate() {
        return _progressRate;
    }

    override function get_statusChanged() {
        return _statusChanged;
    }

    public function new() {
    }
}
