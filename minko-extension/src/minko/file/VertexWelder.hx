package minko.file;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import Lambda;
import minko.component.Surface;
import minko.file.MeshPartitioner.SpatialIndex;
import minko.geometry.Geometry;
import minko.render.VertexAttribute;
import minko.render.VertexBuffer;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
import minko.utils.MathUtil;
typedef NodePredicateFunction = Node -> Bool;
typedef VertexAttributePredicateFunction<T> = String -> T -> T -> Bool;


class VertexWelder extends AbstractWriterPreprocessor {


    private var _statusChanged:Signal2<AbstractWriterPreprocessor , String>;

    override public function get_statusChanged() {
        return _statusChanged;
    }
    private var _progressRate:Float;
   // public var progressRate(get, null):Float;

    function get_progressRate() {
        return _progressRate;
    }
    private var _nodePredicateFunction:NodePredicateFunction;

    private var _scalarAttributeWeldablePredicateFunction:VertexAttributePredicateFunction<Float>;
    private var _vec2AttributeWeldablePredicateFunction:VertexAttributePredicateFunction<Vec2> ;
    private var _vec3AttributeWeldablePredicateFunction:VertexAttributePredicateFunction<Vec3> ;
    private var _vec4AttributeWeldablePredicateFunction:VertexAttributePredicateFunction<Vec4> ;

    private var _weldedGeometrySet:Array<Geometry>;

    public static function create() {
        var instance = (new VertexWelder());

        return instance;
    }

    public var nodePredicateFunction(get, set):NodePredicateFunction;

    function get_nodePredicateFunction() {
        return _nodePredicateFunction;
    }

    function set_nodePredicateFunction(func) {
        _nodePredicateFunction = func;

        return func;
    }


    public var scalarAttributeWeldablePredicateFunction(get, set):VertexAttributePredicateFunction<Float>;
    public var vec2AttributeWeldablePredicateFunction(get, set):VertexAttributePredicateFunction<Vec2> ;
    public var vec3AttributeWeldablePredicateFunction(get, set):VertexAttributePredicateFunction<Vec3> ;
    public var vec4AttributeWeldablePredicateFunction(get, set):VertexAttributePredicateFunction<Vec4> ;


    function get_scalarAttributeWeldablePredicateFunction() {
        return _scalarAttributeWeldablePredicateFunction;
    }

    function set_scalarAttributeWeldablePredicateFunction(func) {
        _scalarAttributeWeldablePredicateFunction = func;

        return func;
    }

    function get_vec2AttributeWeldablePredicateFunction() {
        return _vec2AttributeWeldablePredicateFunction;
    }

    function set_vec2AttributeWeldablePredicateFunction(func) {
        _vec2AttributeWeldablePredicateFunction = func;

        return func;
    }

    function get_vec3AttributeWeldablePredicateFunction() {
        return _vec3AttributeWeldablePredicateFunction;
    }

    function set_vec3AttributeWeldablePredicateFunction(func) {
        _vec3AttributeWeldablePredicateFunction = func;

        return func;
    }

    function get_vec4AttributeWeldablePredicateFunction() {
        return _vec4AttributeWeldablePredicateFunction;
    }

    function set_vec4AttributeWeldablePredicateFunction(func) {
        _vec4AttributeWeldablePredicateFunction = func;

        return func;
    }

    static private function weldAttribute<T>(attribute:VertexAttribute, data:Array<Float>, indices:Array<Int>, makeVec:Float -> T) {
        var values = [];//new List<T>(indices.Count);

        for (i in 0...indices.length) {
            values[i] = makeVec(data,indices[i] * attribute.vertexSize + attribute.offset );
            //todo
        }

        var result = values[0];

        for (i in 1...values.length) {
            result += values[i];
        }

        result /= values.length;

        return result;
    }

    static private function canWeldAttribute<T>(attribute:VertexAttribute, data:Array<Float>, indices:Tuple<Int, Int>, makeVec:Float -> Int -> T, predicate:VertexAttributePredicateFunction<T>) {
        var lhsValue = makeVec(data, indices.first * attribute.vertexSize + attribute.offset);

        var rhsValue = makeVec(data, indices.second * attribute.vertexSize + attribute.offset);

        if (predicate != null && !predicate(attribute.name, lhsValue, rhsValue)) {
            return false;
        }

        return true;
    }

    public function new() {
        super();
        nodePredicateFunction = function(n) return true;
    }

    override public function process(_node:Dynamic, assetLibrary:AssetLibrary) {
        var node:Node=cast _node;
        if (statusChanged && statusChanged .numCallbacks > 0)
            statusChanged .execute(this, "VertexWelder: start");

        var surfaceNodes:NodeSet = NodeSet.create(node).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Surface) && (!nodePredicateFunction() || nodePredicateFunction()(descendant));
        });

        for (surfaceNode in surfaceNodes.nodes()) {
            var surfaces:Array<Surface> = surfaceNode.getComponents(Surface);
            for (surface in surfaces) {
                if (acceptsSurface(surface))
                    weldSurfaceGeometry(surface);
            }
        }
        _progressRate = 1.0 ;
        if (statusChanged != null && statusChanged.numCallbacks > 0)
            statusChanged.execute(this, "VertexWelder: stop");
    }

    public function acceptsSurface(surface:Surface) {
        var geometry = surface.geometry;

        if (Lambda.has(_weldedGeometrySet, geometry)) {
            return false;
        }

        var data = geometry.data;

        if (!data.hasProperty("position")) {
            return false;
        }

        for (vertexBuffer in geometry.vertexBuffers) {
            for (vertexAttribute in vertexBuffer.attributes) {
                if (vertexAttribute.size == 0 || vertexAttribute.size > 4) {
                    return false;
                }
            }
        }

        return true;
    }

    public function weldSurfaceGeometry(surface:Surface) {
        var geometry = surface.geometry ;
        var spatialIndex:SpatialIndex<Array<Int>> = new SpatialIndex<Array<Int>>();
        buildSpatialIndex(geometry, spatialIndex);
        var expectedNumVertices = spatialIndex.size();
        if (expectedNumVertices == geometry.numVertices) {
            _weldedGeometrySet.insert(geometry);
            return;
        }

        var weldedIndices = new Array<Int>();
        var indices = new Array<Int>();
        var indexDataPointer:Array<Int> = null;
        indexDataPointer = geometry.indices.dataPointer;
        var indexData = indexDataPointer;

        indices = indexData.copy();//assign(indexData.begin(), indexData.end());


        var positionVertexBuffer:VertexBuffer = geometry.vertexBuffer("position");
        var positionAttribute = positionVertexBuffer.attribute("position");
        var positionData:Array<Float> = positionVertexBuffer.data;
        var vertexBufferToWeldedVertices:Array<Tuple<VertexBuffer, Array<Float>>> = new Array<Tuple<VertexBuffer, Array<Float>>>();

        var currentNewIndex = 0;
        var indexMap = [for (i in 0...geometry.numVertices) -1];

        for (i in 0... positionVertexBuffer.numVertices) {
            var index = i;

            if (Lambda.has(weldedIndices, index)) {
                continue;
            }
            var position_index = index * positionVertexBuffer.vertexSize + positionAttribute.offset;
            var position = MathUtil.make_vec3(positionData,position_index );

            var indicesToWeld = spatialIndex.get(position);

            var canWeldVertices = this.canWeldVertices(geometry, indicesToWeld);

            if (!canWeldVertices) {
                for (indexToWeld in indicesToWeld) {
                    if (Lambda.has(weldedIndices, indexToWeld)) {
                        continue;
                    }

                    for (vertexBuffer in geometry.vertexBuffers) {
                        var weldedVerticesPtr:Array<Float> = null;
                        var iterator:Tuple<VertexBuffer, Array<Float>> = Lambda.find(vertexBufferToWeldedVertices, function(pair:Tuple<VertexBuffer, Array<Float>>) {
                            return pair.first == vertexBuffer;
                        });

                        if (iterator == null) {
                            iterator = new Tuple<VertexBuffer, Array<Float>>(vertexBuffer, []);
                            vertexBufferToWeldedVertices.push(iterator);
                            weldedVerticesPtr = iterator.second;
                        }
                        else {
                            weldedVerticesPtr = iterator.second;
                        }

                        var weldedVertices:Array<Float> = weldedVerticesPtr.copy();

                        //todo;
                        //weldedVertices.resize(weldedVertices.length + vertexBuffer.vertexSize, 0.0);

                        var vertexBufferData = vertexBuffer.data;

                        for (vertexAttribute in vertexBuffer.attributes) {
                            if (vertexAttribute.size == 1) {
                                var result = vertexBufferData[indexToWeld * vertexBuffer.vertexSize + vertexAttribute.offset];

                                weldedVertices[currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset] = result;
                            }
                            else if (vertexAttribute.size == 2) {
                                var result = MathUtil.std_copy(vertexBufferData,
                                (indexToWeld * vertexBuffer.vertexSize + vertexAttribute.offset),
                                (indexToWeld * vertexBuffer.vertexSize + vertexAttribute.offset) + vertexAttribute.size,
                                weldedVertices,
                                currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset);
                            }
                            else if (vertexAttribute.size == 3) {
                                var result = MathUtil.std_copy(vertexBufferData,
                                (indexToWeld * vertexBuffer.vertexSize + vertexAttribute.offset),
                                (indexToWeld * vertexBuffer.vertexSize + vertexAttribute.offset) + vertexAttribute.size,
                                weldedVertices,
                                currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset);
                            }
                            else if (vertexAttribute.size == 4) {
                                var result = MathUtil.std_copy(vertexBufferData,
                                (indexToWeld * vertexBuffer.vertexSize + vertexAttribute.offset),
                                (indexToWeld * vertexBuffer.vertexSize + vertexAttribute.offset) + vertexAttribute.size,
                                weldedVertices,
                                currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset);
                            }
                        }
                    }

                    indexMap[indexToWeld] = currentNewIndex;

                    ++currentNewIndex;

                    weldedIndices.insert(indexToWeld);
                }

                continue;
            }

            for (vertexBuffer in geometry.vertexBuffers) {
                var weldedVerticesPtr:Array<Float> = null;

                var iterator:Tuple<VertexBuffer, Array<Float>> = Lambda.find(vertexBufferToWeldedVertices, function(pair:Tuple<VertexBuffer, Array<Float>>) {
                    return pair.first == vertexBuffer;
                });

                if (iterator == null) {
                    iterator = new Tuple<VertexBuffer, Array<Float>>(vertexBuffer, []);
                    vertexBufferToWeldedVertices.push(iterator);
                    weldedVerticesPtr = iterator.second;
                }
                else {
                    weldedVerticesPtr = iterator.second;
                }

                var weldedVertices:Array<Float> = weldedVerticesPtr.copy();

                //weldedVertices.resize(weldedVertices.size() + vertexBuffer.vertexSize(), 0.0f);
                //todo
                var vertexBufferData = vertexBuffer.data ;

                for (vertexAttribute in vertexBuffer.attributes) {
                    if (vertexAttribute.size == 1) {
                        var result = weldAttribute(vertexAttribute, vertexBufferData, indicesToWeld, function(data:Float, index:Int) {
                            return data;
                        });

                        weldedVertices[currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset] = result;
                    }
                    else if (vertexAttribute.size == 2) {
                        var resultVec2:Vec2 = weldAttribute(vertexAttribute, vertexBufferData, indicesToWeld, MathUtil.make_vec2);
                        var result = resultVec2.toFloatArray();
                        MathUtil.std_copy(result,
                        0,
                        vertexAttribute.size,
                        weldedVertices,
                        currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset);
                    }
                    else if (vertexAttribute.size == 3) {
                        var resultVec3:Vec3 = position;
                        if (vertexAttribute != positionAttribute) {
                            var resultVec3:Vec3 = weldAttribute(vertexAttribute, vertexBufferData, indicesToWeld, MathUtil.make_vec3);

                        }

                        if (vertexAttribute.name == "normal" || vertexAttribute.name == "tangent") {
                            resultVec3 = Vec3.normalize(resultVec3);
                        }

                        var result = resultVec3.toFloatArray();

                        MathUtil.std_copy(result,
                        0,
                        vertexAttribute.size,
                        weldedVertices,
                        currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset);
                    }
                    else if (vertexAttribute.size == 4) {
                        var resultVec4:Vec4 = weldAttribute(vertexAttribute, vertexBufferData, indicesToWeld, MathUtil.make_vec4);
                        var result = resultVec4.toFloatArray();
                        MathUtil.std_copy(result,
                        0,
                        vertexAttribute.size,
                        weldedVertices,
                        currentNewIndex * vertexAttribute.vertexSize + vertexAttribute.offset);
                    }
                }
            }

            for (weldedIndex in indicesToWeld) {
                weldedIndices.insert(weldedIndex);

                indexMap[weldedIndex] = currentNewIndex;
            }

            ++currentNewIndex;
        }

        for (i in 0...indices.length) {
            var newIndex = indexMap[indices[i]];

            if (newIndex == -1) {
                break;
            }


            indexDataPointer[i] = newIndex;

        }

        var newVertexBuffers = new Array<VertexBuffer>();

        for (vertexBufferToWeldedVerticesPair in vertexBufferToWeldedVertices) {
            var vertexBuffer = vertexBufferToWeldedVerticesPair.first;
            var data = vertexBufferToWeldedVerticesPair.second;

            var newVertexBuffer = render.VertexBuffer.create(vertexBuffer.context, data);

            for (attribute in vertexBuffer.attributes) {
                newVertexBuffer.addAttribute(attribute.name, attribute.size, attribute.offset);
            }

            geometry.removeVertexBuffer(vertexBuffer);

            newVertexBuffers.push(newVertexBuffer);
        }

        for (vertexBuffer in newVertexBuffers) {
            geometry.addVertexBuffer(vertexBuffer);
        }

        _weldedGeometrySet.insert(geometry);
    }

    public function buildSpatialIndex(geometry:Geometry, index:SpatialIndex<Array<Int>>) {
        var positionVertexBuffer = geometry.vertexBuffer("position");
        var positionAttribute = positionVertexBuffer.attribute("position");

        var data = positionVertexBuffer.data;

        for (i in 0...positionVertexBuffer.numVertices) {
            var position = MathUtil.make_vec3(data, (i * positionVertexBuffer.vertexSize + positionAttribute.offset));

            index.get(position).push(i);
        }
    }

    function next_permutation(permutation:Array<Any>) {
        var length = permutation.length;
        var result = [permutation.slice()];
        var c = [for (i in 0...length)0];
        var i = 1, k, p;

        while (i < length) {
            if (c[i] < i) {
                k = i % 2 && c[i];
                p = permutation[i];
                permutation[i] = permutation[k];
                permutation[k] = p;
                ++c[i];
                i = 1;
                result.push(permutation.slice());
            } else {
                c[i] = 0;
                ++i;
            }
        }
        return result;
    }

    public function canWeldVertices(geometry:Geometry, indices:Array<Int>) {
        if (indices.length <= 1 || indices.length > 8) {
            return false;
        }

        var permutations = [for (i in 0...indices.length - 2) true];//new List<bool>(indices.Count);

        var pairs = new Array<Tuple<Int, Int>>();

        var currentPairSize = 0;
        for (p in next_permutation(permutations)) {
            for (i in 0... indices.length) {
                if (permutations[i]) {
                    if (currentPairSize == 0) {
                        var p = new Tuple<Int, Int>(0, 0);
                        pairs.push(p);
                        p.first = indices[i];
                        ++currentPairSize;
                    }
                    else {
                        pairs[pairs.length - 1].second = indices[i];
                        ++currentPairSize;
                        break;
                    }
                }
            }

            if (currentPairSize >= 2) {
                currentPairSize = 0 ;

                continue;
            }

        }

        for (vertexBuffer in geometry.vertexBuffers) {
            for (vertexAttribute in vertexBuffer.attributes) {
                if (vertexAttribute.name == "position") {
                    continue;
                }

                for (pair in pairs) {
                    if (vertexAttribute.size == 1) {
                        if (!canWeldAttribute(vertexAttribute, vertexBuffer.data, pair, function(data, index) {
                            return data;
                        }, _scalarAttributeWeldablePredicateFunction)) {
                            return false;
                        }
                    }
                    else if (vertexAttribute.size == 2) {
                        if (!canWeldAttribute(vertexAttribute, vertexBuffer.data, pair, MathUtil.make_vec2, _vec2AttributeWeldablePredicateFunction)) {
                            return false;
                        }
                    }
                    else if (vertexAttribute.size == 3) {
                        if (!canWeldAttribute(vertexAttribute, vertexBuffer.data, pair, MathUtil.make_vec3, _vec3AttributeWeldablePredicateFunction)) {
                            return false;
                        }
                    }
                    else if (vertexAttribute.size == 4) {
                        if (!canWeldAttribute(vertexAttribute, vertexBuffer.data, pair, MathUtil.make_vec4, _vec4AttributeWeldablePredicateFunction)) {
                            return false;
                        }
                    }
                }
            }
        }

        return true;
    }
}
