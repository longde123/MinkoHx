package minko.file;
import glm.Vec3;
import minko.component.BoundingBox;
import minko.component.Surface;
import minko.component.Transform;
import minko.scene.Layout;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
typedef SurfaceClusterPredicateFunction = NodeInfo -> Bool;
class NodeInfo {
    public var surfaces:Array<Surface>;

    public var numVertices:Int;
    public var numTriangles:Int;

    public var bounds:Tuple<Vec3, Vec3>;
    public var size:Vec3;
    public var xyArea:Float;
    public var xzArea:Float;
    public var yzArea:Float;
    public var volume:Float;
    public var vertexDensity:Float;
    public var triangleDensity:Float;

    public var worldVolumeRatio:Float;
    public var worldNumVerticesRatio:Float;
    public var worldNumTrianglesRatio:Float;
    public var worldSizeRatio:Vec3;
    public var worldXyAreaRatio:Float;
    public var worldXzAreaRatio:Float;
    public var worldYzAreaRatio:Float;

    public function name():Void {

        this.surfaces = [];
        this.numVertices = 0;
        this.numTriangles = 0;
        this.bounds = new Tuple<Vec3, Vec3>();
        this.size = new Vec3();
        this.xyArea = 0.0;
        this.xzArea = 0.0;
        this.yzArea = 0.0;
        this.volume = 0.0;
        this.vertexDensity = 0.0;
        this.triangleDensity = 0.0;
        this.worldVolumeRatio = 0.0;
        this.worldNumVerticesRatio = 0.0;
        this.worldNumTrianglesRatio = 0.0;
        this.worldSizeRatio = new Vec3();
        this.worldXyAreaRatio = 0.0;
        this.worldXzAreaRatio = 0.0;
        this.worldYzAreaRatio = 0.0;
    }

}

class SurfaceClusterEntry {
    public var layout:Layout;
    public var predicate:SurfaceClusterPredicateFunction;

    public function new(layout, predicate) {
        this.layout = layout;
        this.predicate = predicate;
    }
}

class SurfaceClusterBuilder extends AbstractWriterPreprocessor {

    private var _statusChanged:Signal2<AbstractWriterPreprocessor, String>;

    override public function get_statusChanged() {
        return _statusChanged;
    }
    private var _progressRate:Float;
   // public var progressRate(get, null):Float;

    function get_progressRate() {
        return _progressRate;
    }

    private var _surfaceClusters:Array<SurfaceClusterEntry>;
    private var _rootNodeInfo:NodeInfo;
    private var _surfaceNodeInfo:Array<NodeInfo>;

    public static function create() {
        var instance = (new SurfaceClusterBuilder());
        return instance;
    }


    public function new() {
        super();
        this._statusChanged = new Signal2<AbstractWriterPreprocessor<Node>, String>();
        this._progressRate = 0.0;
    }

    override public function process(_node:Dynamic, assetLibrary:AssetLibrary) {
        var node:Node=cast _node;
        if (statusChanged != null && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "SurfaceClusterBuilder: start");
        }

        if (_surfaceClusters.length > 0) {
            if (!node.hasComponent(Transform)) {
                node.addComponent(Transform.create());
            }
            var nodeTransform:Transform = node.getComponent(Transform);
            nodeTransform.updateModelToWorldMatrix();

            cacheNodeInfo(node, _rootNodeInfo, _surfaceNodeInfo);

            if (_surfaceNodeInfo.length > 0) {
                buildClusters();
            }
        }

        _progressRate = 1.0;

        if (statusChanged != null && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "SurfaceClusterBuilder: stop");
        }
    }

    public function cacheNodeInfo(root:Node, rootNodeInfo:NodeInfo, surfaceNodeInfo:Array<NodeInfo>) {
        var surfaces = new Array<Surface>();

        var surfaceNodes:NodeSet = NodeSet.create(root).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Surface);
        });

        surfaces.reserve(surfaceNodes.size());

        for (surfaceNode in surfaceNodes.nodes) {
            var __surfaces:Array<Surface> = cast surfaceNode.getComponents(Surface);
            for (surface in __surfaces) {
                surfaces.push(surface);
            }
        }

//surfaceNodeInfo.Capacity = surfaces.size();

        for (surface in surfaces) {
            surfaceNodeInfo.push(new NodeInfo());

            var nodeInfo = surfaceNodeInfo[surfaceNodeInfo.length - 1];

            var target = surface.target;
            var geometry = surface.geometry;

            if (!target.hasComponent(BoundingBox)) {
                target.addComponent(BoundingBox.create());
            }
            var boundingBox:BoundingBox = target.getComponent(BoundingBox);
            var box = boundingBox.box;

            nodeInfo.surfaces.push(surface);

            nodeInfo.numVertices = geometry.numVertices;
            nodeInfo.numTriangles = geometry.indices.numIndices / 3;

            nodeInfo.bounds = new Tuple<Vec3, Vec3>(box.bottomLeft, box.topRight);
            nodeInfo.size = nodeInfo.bounds.second - nodeInfo.bounds.first;
            nodeInfo.size = new Vec3(Math.max(nodeInfo.size.x, 1e-6), Math.max(nodeInfo.size.y, 1e-6), Math.max(nodeInfo.size.z, 1e-6));
            nodeInfo.xyArea = nodeInfo.size.x * nodeInfo.size.y;
            nodeInfo.xzArea = nodeInfo.size.x * nodeInfo.size.z;
            nodeInfo.yzArea = nodeInfo.size.y * nodeInfo.size.z;
            nodeInfo.volume = nodeInfo.size.x * nodeInfo.size.y * nodeInfo.size.z;
            nodeInfo.vertexDensity = nodeInfo.numVertices / nodeInfo.volume;
            nodeInfo.triangleDensity = nodeInfo.numTriangles / nodeInfo.volume;

            rootNodeInfo.surfaces.push(surface);

            rootNodeInfo.numVertices += nodeInfo.numVertices;
            rootNodeInfo.numTriangles += nodeInfo.numTriangles;

            rootNodeInfo.bounds = new Tuple<Vec3, Vec3>(new Vec3(Math.min(nodeInfo.bounds.first.x, rootNodeInfo.bounds.first.x), Math.min(nodeInfo.bounds.first.y, rootNodeInfo.bounds.first.y), Math.min(nodeInfo.bounds.first.z, rootNodeInfo.bounds.first.z)),
            new Vec3(Math.max(nodeInfo.bounds.second.x, rootNodeInfo.bounds.second.x), Math.max(nodeInfo.bounds.second.y, rootNodeInfo.bounds.second.y), Math.max(nodeInfo.bounds.second.z, rootNodeInfo.bounds.second.z)));
        }

        rootNodeInfo.size = rootNodeInfo.bounds.second - rootNodeInfo.bounds.first;
        rootNodeInfo.xyArea = rootNodeInfo.size.x * rootNodeInfo.size.y;
        rootNodeInfo.xzArea = rootNodeInfo.size.x * rootNodeInfo.size.z;
        rootNodeInfo.yzArea = rootNodeInfo.size.y * rootNodeInfo.size.z;
        rootNodeInfo.volume = rootNodeInfo.size.x * rootNodeInfo.size.y * rootNodeInfo.size.z;
        rootNodeInfo.vertexDensity = rootNodeInfo.numVertices / rootNodeInfo.volume;
        rootNodeInfo.triangleDensity = rootNodeInfo.numTriangles / rootNodeInfo.volume;

        for (nodeInfo in surfaceNodeInfo) {
            nodeInfo.worldVolumeRatio = nodeInfo.volume / rootNodeInfo.volume;
            nodeInfo.worldNumVerticesRatio = nodeInfo.numVertices / rootNodeInfo.numVertices;
            nodeInfo.worldNumTrianglesRatio = nodeInfo.numTriangles / rootNodeInfo.numTriangles;
            nodeInfo.worldSizeRatio = nodeInfo.size / rootNodeInfo.size;
            nodeInfo.worldXyAreaRatio = nodeInfo.xyArea / rootNodeInfo.xyArea;
            nodeInfo.worldXzAreaRatio = nodeInfo.xzArea / rootNodeInfo.xzArea;
            nodeInfo.worldYzAreaRatio = nodeInfo.yzArea / rootNodeInfo.yzArea;
        }
    }

    public function registerSurfaceCluster(layout:Layout, predicate:SurfaceClusterPredicateFunction) {
        _surfaceClusters.push(new SurfaceClusterEntry(layout, predicate));

        return (this);
    }

    public function buildClusters() {
        for (nodeInfo in _surfaceNodeInfo) {
            for (surfaceClusterEntry in _surfaceClusters) {
                if (clusterAccepts(surfaceClusterEntry, nodeInfo)) {
                    addToCluster(surfaceClusterEntry, nodeInfo);

                    break;
                }
            }
        }
    }

    public function clusterAccepts(surfaceClusterEntry:SurfaceClusterEntry, nodeInfo:NodeInfo) {
        return surfaceClusterEntry.predicate(nodeInfo);
    }

    public function addToCluster(surfaceClusterEntry:SurfaceClusterEntry, nodeInfo:NodeInfo) {
        if (nodeInfo.surfaces.length == 0) {
            return;
        }

        var target = nodeInfo.surfaces[0].target;

        target.layout = (target.layout | surfaceClusterEntry.layout);
    }


}
