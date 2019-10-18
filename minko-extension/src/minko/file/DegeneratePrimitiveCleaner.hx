package minko.file;
import minko.utils.MathUtil;
import glm.Vec3;
import Lambda;
import minko.component.Surface;
import minko.file.MeshPartitioner.SpatialIndex;
import minko.geometry.Geometry;
import minko.render.IndexBuffer;
import minko.render.VertexAttribute;
import minko.render.VertexBuffer;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
import minko.utils.VectorHelper;

class DegeneratePrimitiveCleanerOptions {
    public var useMinPrecision:Bool;
    public var vertexMinPrecision:Float;

    public function copyFrom(v:DegeneratePrimitiveCleanerOptions):Void {

    }
}
class DegeneratePrimitiveCleaner extends AbstractWriterPreprocessor {


    private var _statusChanged:Signal2<AbstractWriterPreprocessor, String>;

    override public function get_statusChanged() {
        return _statusChanged;
    }
    private var _progressRate:Float;

    private var _options:DegeneratePrimitiveCleanerOptions;

    private var _spatialIndex:SpatialIndex<Int>;


    public static function create() {
        var instance = (new DegeneratePrimitiveCleaner());

        return instance;
    }
    public var options(null, set):DegeneratePrimitiveCleanerOptions;

    function set_options(v) {
        _options.copyFrom(options);

        return v;
    }

    // public var progressRate(get, null):Float;

    function get_progressRate() {
        return _progressRate;
    }

    public function new() {

        super();
        this._statusChanged = new Signal2<AbstractWriterPreprocessor<Node>, String>();
        this._progressRate = 0.0;
        this._options = defaultOptions();
    }

    public function defaultOptions() {
        var options = new DegeneratePrimitiveCleanerOptions();

        options.useMinPrecision = true;
        options.vertexMinPrecision = 1e-3;

        return options;
    }

    override public function process(node:Dynamic, assetLibrary:AssetLibrary) {
        if (statusChanged != null && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "DegeneratePrimitiveCleaner: start");
        }

        var geometrySet = new Array<Geometry>();
        var surfaceNodeSet:NodeSet = NodeSet.create(node).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Surface);
        });
        for (surfaceNode in surfaceNodeSet.nodes) {
            var surfaces:Array<Surface> = cast surfaceNode.getComponents(Surface);
            for (surface in surfaces) {
                geometrySet.push(surface.geometry);
            }
        }

        if (geometrySet.length > 0) {
            _spatialIndex = new SpatialIndex<Int>(_options.vertexMinPrecision);

            var geometryIndex = 0;
            for (geometry in geometrySet) {
                _progressRate = geometryIndex / geometrySet.length;
                if (statusChanged != null && statusChanged.numCallbacks > 0) {
                    statusChanged.execute(this, "DegeneratePrimitiveCleaner: processing geometry with index size " + (geometry.indices.numIndices));
                }
                processGeometry(geometry, assetLibrary);
                ++geometryIndex;
            }
        }

        _progressRate = 1.0;

        if (statusChanged && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "DegeneratePrimitiveCleaner: stop");
        }
    }

    public function processGeometry(geometry:Geometry, assetLibrary:AssetLibrary) {
        var primitiveSize = 3 ;

        var indices = geometry.indices;
        var numIndices = indices.numIndices;
        var numPrimitives = numIndices / primitiveSize;
        var u32Indices = indices.dataPointer;
        var degeneratePrimitives = new Array();

        for (i in 0...numIndices / primitiveSize) {
            var primitive = VectorHelper.initializedList(primitiveSize, 0);

            for (j in 0... primitiveSize) {
                var index = u32Indices[i * primitiveSize + j];
                primitive[j] = index;
            }

            var degeneratePrimitive = false;

            // find degenerate primitive by index

            for (j in 0... primitiveSize - 1) {
                for (k in 0 ... primitiveSize) {
                    if (j == k) {
                        continue;
                    }
                    if (primitive[j] != primitive[k]) {
                        continue;
                    }
                    degeneratePrimitive = true;
                    break;
                }
                if (degeneratePrimitive) {
                    break;
                }
            }

            if (!degeneratePrimitive && _options.useMinPrecision) {
                // find degenerate primitive by precision
                _spatialIndex.clear();
                var positionVertexBuffer:VertexBuffer = geometry.vertexBuffer("position");
                var positionVertexBufferData = positionVertexBuffer.data;
                var positionVertexAttribute:VertexAttribute = positionVertexBuffer.attribute("position");
                for (j in 0... primitiveSize) {
                    var p_index = primitive[j] * positionVertexAttribute.vertexSize + positionVertexAttribute.offset;
                    var position = MathUtil.make_vec3(positionVertexBufferData, p_index)
                    _spatialIndex.get(position) ++;
                }
                if (_spatialIndex.size() < 3) {
                    degeneratePrimitive = true;
                }
            }
            if (!degeneratePrimitive) {
                continue;
            }

            degeneratePrimitives.push(i);
        }

        var numDegeneratePrimitives = degeneratePrimitives.length;

        if (numDegeneratePrimitives == 0) {
            return;
        }

        if (statusChanged != null && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "DegeneratePrimitiveCleaner: removing " + (numDegeneratePrimitives) + " degenerate primitives");
        }

        var newNumIndices = numIndices - numDegeneratePrimitives * primitiveSize;
        var newIndexBuffer = new IndexBuffer();

        if (newNumIndices <= Math.POSITIVE_INFINITY) {
            newIndexBuffer = createIndexBuffer(indices, primitiveSize, numPrimitives, degeneratePrimitives, assetLibrary);
        }
        else {
            newIndexBuffer = createIndexBuffer(indices, primitiveSize, numPrimitives, degeneratePrimitives, assetLibrary);
        }

        geometry.indices = (newIndexBuffer);
    }

    public function createIndexBuffer(indexBuffer:IndexBuffer, primitiveSize:Int, numPrimitives:Int, degeneratePrimitives:Array<Int>, assetLibrary:AssetLibrary) {
        var numIndices = indexBuffer.numIndices;
        var numDegeneratePrimitives = degeneratePrimitives.length;
        var u32Indices = indexBuffer.dataPointer();
        var newNumIndices = numIndices - numDegeneratePrimitives * primitiveSize;
        var newIndices = [];//new Array<T>(newNumIndices, 0u);
        var primitiveOffset = 0;
        for (i in 0...numPrimitives) {
            if (Lambda.has(degeneratePrimitives, i)) {
                continue;
            }
            for (j in 0...primitiveSize) {
                newIndices[primitiveOffset * primitiveSize + j] = u32Indices[i * primitiveSize + j];
            }
            ++primitiveOffset;
        }
        return IndexBuffer.create(assetLibrary.context, newIndices);
    }
}
