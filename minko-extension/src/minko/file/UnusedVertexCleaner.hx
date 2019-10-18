package minko.file;
import minko.utils.MathUtil;
import minko.component.Surface;
import minko.geometry.Geometry;
import minko.render.VertexBuffer;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
class UnusedVertexCleaner extends AbstractWriterPreprocessor {

    private var _statusChanged:Signal2<AbstractWriterPreprocessor, String>;

    override public function get_statusChanged() {
        return _statusChanged;
    }
    private var _progressRate:Float;
   // public var progressRate(get, null):Float;

    function get_progressRate() {
        return _progressRate;
    }


    public static function create() {
        var instance = (new UnusedVertexCleaner());

        return instance;
    }


    public function new() {

        super();
        this._statusChanged = new Signal2<AbstractWriterPreprocessor<Node>, String>();
        this._progressRate = 0.0;
    }

    override public function process(_node:Dynamic, assetLibrary:AssetLibrary) {
        var node:Node = cast _node;
        if (statusChanged && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "UnusedVertexCleaner: start");
        }

        var geometrySet = new Array<Geometry>();

        var surfaceNodeSet:NodeSet = NodeSet.create(node).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Surface);
        });

        for (surfaceNode in surfaceNodeSet.nodes()) {
            var surfaces:Array<Surface> = cast surfaceNode.getComponents(Surface);
            for (surface in surfaces) {
                geometrySet.insert(surface.geometry);
            }
        }

        if (geometrySet.length > 0) {
            var geometryIndex = 0;

            for (geometry in geometrySet) {
                _progressRate = geometryIndex / geometrySet.length;

                if (statusChanged != null && statusChanged.numCallbacks > 0) {
                    statusChanged.execute(this, "UnusedVertexCleaner: processing geometry with " + (geometry.numVertices) + " vertices");
                }

                processGeometry(geometry, assetLibrary);

                ++geometryIndex;
            }
        }

        _progressRate = 1.0;

        if (statusChanged != null && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "UnusedVertexCleaner: stop");
        }
    }

    public function processGeometry(geometry:Geometry, assetLibrary:AssetLibrary) {
        var numIndices = geometry.indices.numIndices;
        var numVertices = geometry.numVertices;

        if (numVertices == 0) {
            return;
        }

        var u32IndexData = geometry.indices.dataPointer;

        var vertexUseCount = [ for (i in 0...numVertices) 0];

        for (i in 0...numIndices) {
            var index = u32IndexData[i];

            ++vertexUseCount[index];
        }

        var indexMap = [ for (i in 0...numVertices) 0];//new List<uint>(numVertices);
        var currentNewIndex = 0 ;

        for (i in 0...numIndices) {
            var vertexUsed = vertexUseCount[i] > 0;

            if (vertexUsed) {
                indexMap[i] = currentNewIndex++;
            }
            else {
                indexMap[i] = currentNewIndex;
            }
        }

        var newNumVertices = currentNewIndex;

        for (i in 0...numIndices) {
            var index = u32IndexData[i];

            var newIndex = indexMap[index];


            u32IndexData[i] = newIndex;
        }

        var vertexBuffers = geometry.vertexBuffers();
        var newVertexBuffers = new Array<VertexBuffer>();


        for (vertexBuffer in vertexBuffers) {
            var vertexBufferData = vertexBuffer.data;
            var newVertexBufferData = [for (i in 0...newNumVertices * vertexBuffer.vertexSize) 0.0];

            for (vertexAttribute in vertexBuffer.attributes) {
                var currentNewIndex = 0;
                for (i in 0...numVertices) {
                    var vertexUsed = vertexUseCount[i] > 0;

                    if (!vertexUsed) {
                        continue;
                    }


                    MathUtil.std_copy(vertexBufferData,
                    i * vertexAttribute.vertexSize + vertexAttribute.offset,
                    i * vertexAttribute.vertexSize + vertexAttribute.offset + vertexAttribute.size,
                    newVertexBufferData,
                    currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset);

                    ++currentNewIndex;
                }
            }

            var newVertexBuffer = VertexBuffer.create(vertexBuffer.context, newVertexBufferData);

            for (attribute in vertexBuffer.attributes) {
                newVertexBuffer.addAttribute(attribute.name, attribute.size, attribute.offset);
            }

            newVertexBuffers.push(newVertexBuffer);
        }

        for (vertexBuffer in vertexBuffers) {
            geometry.removeVertexBuffer(vertexBuffer);
        }

        for (vertexBuffer in newVertexBuffers) {
            geometry.addVertexBuffer(vertexBuffer);
        }
    }

}
