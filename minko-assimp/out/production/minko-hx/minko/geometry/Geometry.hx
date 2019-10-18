package minko.geometry;
import glm.GLM;
import glm.Vec2;
import glm.Vec3;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import minko.data.Provider;
import minko.math.Ray;
import minko.render.IndexBuffer;
import minko.render.VertexAttribute;
import minko.render.VertexBuffer;
import minko.signal.Signal2.SignalSlot2;
import minko.Uuid.Has_uuid;
@:expose("minko.geometry.Geometry")
class Geometry extends Has_uuid {
    private var _data:Provider;
    private var _vertexSize:Int;
    private var _numVertices:Int;
    private var _vertexBuffers:Array<VertexBuffer> ;
    private var _indexBuffer:IndexBuffer;

    private var _vbToVertexSizeChangedSlot:ObjectMap<VertexBuffer, SignalSlot2<VertexBuffer, Int>>;

    public function new(name:String) {
        super();
        this._data = Provider.create() ;
        this._vertexSize = 0;
        this._numVertices = 0;
        this._indexBuffer = null;
        this._vertexBuffers = [];
        _vbToVertexSizeChangedSlot = new ObjectMap<VertexBuffer, SignalSlot2<VertexBuffer, Int>>();
        _data.set("name", name);
        _data.set("uuid", _data.uuid);
    }

    public function dispose() {
        _data = null;
        _vertexBuffers = null;
        _indexBuffer = null;
    }
    public static function create():Geometry {
        return createbyName("");
    }
    public static function createbyName(name:String = "geometry"):Geometry {
        return new Geometry(name);
    }

    override function get_uuid() {
        return _data.uuid;
    }

    public function clone() {
        var geometry = new Geometry("").copyFrom(this) ;

        return geometry;
    }

    public var data(get, null):Provider;

    function get_data() {
        return _data;
    }

    public var vertexBuffers(get, null):Array<VertexBuffer>;

    function get_vertexBuffers() {
        return _vertexBuffers;
    }
    public var name(get, null):String;

    function get_name() {
        return _data.get("name");
    }

    public function vertexBuffer(vertexAttributeName:String):VertexBuffer {

        var vertexBufferIt:VertexBuffer = Lambda.find(_vertexBuffers, function(vb:VertexBuffer) {
            return vb.hasAttribute(vertexAttributeName);
        });

        if (vertexBufferIt == null) {
            return null;
        }

        return vertexBufferIt;
    }

    public function hasVertexBuffer(vertexBuffer:VertexBuffer) {
        return Lambda.has(_vertexBuffers, vertexBuffer);
    }

    public function hasVertexAttribute(vertexAttributeName:String) {
        return _data.hasProperty(vertexAttributeName);
    }
    public var indices(get, set):IndexBuffer;

    function set_indices(__indices:IndexBuffer) {
        _indexBuffer = __indices;

        if (__indices.isReady) {
            _data.set("indices", __indices.id);
            _data.set("firstIndex", 0);
            _data.set("numIndices", __indices.numIndices);
        }
        return __indices;
    }

    function get_indices() {
        return _indexBuffer;
    }

    public function addVertexBuffer(vertexBuffer:VertexBuffer) {
        if (hasVertexBuffer(vertexBuffer)) {
            throw ("vertexBuffer");
        }

        var bufVertexSize = vertexBuffer.vertexSize;
        var bufNumVertices = vertexBuffer.numVertices;

        for (attribute in vertexBuffer.attributes) {
            _data.set(attribute.name, attribute);
        }
        _vertexSize += bufVertexSize;
        _data.set("vertex.size", _vertexSize);

        if (_vertexBuffers.length > 0 && _numVertices != bufNumVertices) {
            throw ("inconsistent number of vertices between the geometry's vertex streams.");
        }
        else if (_vertexBuffers.length == 0) {
            _numVertices = bufNumVertices;
        }

        _vertexBuffers.push(vertexBuffer);

        _vbToVertexSizeChangedSlot.set(vertexBuffer, vertexBuffer.vertexSizeChanged.connect(vertexSizeChanged));

        computeCenterPosition();
    }

    public function removeVertexBuffer(vertexBufferIt:VertexBuffer) {
        if (!hasVertexBuffer(vertexBufferIt)) {
            throw ("vertexBuffer");
        }
        var vertexBuffer:VertexBuffer = vertexBufferIt;


        for (attribute in vertexBuffer.attributes) {
            _data.unset(attribute.name);
        }

        _vertexSize -= vertexBuffer.vertexSize;
        _data.set("vertex.size", _vertexSize);

        _vertexBuffers.remove(vertexBufferIt);

        if (_vertexBuffers.length == 0) {
            _numVertices = 0;
        }
        _vbToVertexSizeChangedSlot.get(vertexBuffer).dispose();
        _vbToVertexSizeChangedSlot.remove(vertexBuffer);
        vertexBuffer.dispose();
    }


    public function removeVertexBufferbyName(attributeName:String) {

        var vertexBufferIt:VertexBuffer = Lambda.find(_vertexBuffers, function(vb:VertexBuffer) {
            return vb.hasAttribute(attributeName);
        });

        if (vertexBufferIt == null) {
            throw ("attributeName = " + attributeName);
        }

        removeVertexBuffer(vertexBufferIt);
    }

    public var numVertices(get, null):Int;

    function get_numVertices() {
        return _numVertices;
    }

    public var vertexSize(get, set):Int;

    function get_vertexSize() {
        return _vertexSize;
    }

    public function computeNormals() {

        if (numVertices == 0) {
            return this;
        }
        var normalBuffer:VertexBuffer = vertexBuffer("normal");
        // if (normalBuffer)
        // throw std::logic_error("The geometry already stores precomputed normals.");

        var xyzBuffer:VertexBuffer = vertexBuffer("position");
        if (xyzBuffer == null) {
            throw ("Computation of normals requires positions.");
        }


        var uintIndices:Array<Int> = indices.dataPointer ;

        var numFaces = Math.floor(uintIndices.length / 3) ;

        var vertexIds = [0, 0, 0];
        var xyz = new Array<Vec3>();//3

        var xyzAttribute:VertexAttribute = xyzBuffer.attribute("position");
        var xyzSize = xyzAttribute.vertexSize; // xyzBuffer->vertexSize();
        var xyzOffset = xyzAttribute.offset;
        var xyzData:Array<Float> = xyzBuffer.data;

        var normalSize:Int;
        var normalOffset:Int;
        var normalsData:Array<Float>;

        if (normalBuffer != null) {
            normalsData = normalBuffer.data;
            var normalAttribute:VertexAttribute = normalBuffer.attribute("normal");
            normalSize = normalAttribute.vertexSize;
            normalOffset = normalAttribute.offset;
        }
        else {
            normalsData = [for (i in 0...3 * numVertices) 0.0];
            normalSize = 3;
            normalOffset = 0;
        }

        for (i in 0...numVertices) {
            var index = normalOffset + i * normalSize;

            normalsData[index] = 0.0;
            normalsData[index + 1] = 0.0;
            normalsData[index + 2] = 0.0;
        }
        var offset = 0;
        for (i in 0...numFaces) {

            for (k in 0... 3) {
                vertexIds[k] = uintIndices[offset++];
                var index = xyzOffset + vertexIds[k] * xyzSize;
                xyz[k] = new Vec3(xyzData[index], xyzData[index + 1], xyzData[index + 2]);
            }

            //math
            var faceNormal = Vec3.cross(xyz[0] - xyz[1], xyz[0] - xyz[2], new Vec3());


            for (k in 0... 3) {
                var index = normalOffset + normalSize * vertexIds[k];

                normalsData[index] += faceNormal.x;
                normalsData[index + 1] += faceNormal.y;
                normalsData[index + 2] += faceNormal.z;
            }
        }

        for (i in 0... numVertices) {
            var indexOffset = normalOffset + i * normalSize;

            var x = normalsData[indexOffset];
            var y = normalsData[indexOffset + 1];
            var z = normalsData[indexOffset + 2];
            var lengthSquared = x * x + y * y + z * z;
            //todo
            var invLength = lengthSquared > GLM.EPSILON ? 1.0 / Math.sqrt(lengthSquared) : 1.0;

            normalsData[indexOffset] *= invLength;
            normalsData[indexOffset + 1] *= invLength;
            normalsData[indexOffset + 2] *= invLength;
        }

        if (normalBuffer == null) {
            normalBuffer = VertexBuffer.createbyData(xyzBuffer.context, normalsData);
            normalBuffer.addAttribute("normal", normalSize, normalOffset);
            addVertexBuffer(normalBuffer);

            normalsData = null;
        }

        return this;
    }

    public function computeTangentSpace(doNormals:Bool) {
        if (numVertices == 0) {
            return this;
        }
        var xyzBuffer:VertexBuffer = vertexBuffer("position");
        if (xyzBuffer == null) {
            throw ("Computation of tangent space requires positions.");
        }
        var uvBuffer:VertexBuffer = vertexBuffer("uv");
        if (uvBuffer == null) {
            throw ("Computation of tangent space requires uvs.");
        }
        if (doNormals) {
            computeNormals();
        }


        var uintIndices:Array<Int> = indices.dataPointer ;
        var numFaces = Math.floor(uintIndices.length / 3);

        var vertexIds = [0, 0, 0];
        var xyz = new Array<Vec3>();//3
        var uv = new Array<Vec2>();//3

        var xyzSize = xyzBuffer.vertexSize;
        var xyzOffset = xyzBuffer.attribute("position").offset;
        var xyzData:Array<Float> = xyzBuffer.data;

        var uvSize = uvBuffer.vertexSize;
        var uvOffset = uvBuffer.attribute("uv").offset;
        var uvData:Array<Float> = uvBuffer.data;

        var tangentsData:Array<Float> = [ for (i in 0...3 * numVertices) 0.0];
        var offset = 0;
        for (i in 0...numFaces) {
            for (k in 0...3) {
                vertexIds[k] = uintIndices[offset++];
                var index = xyzOffset + vertexIds[k] * xyzSize;
                xyz[k] = new Vec3(xyzData[index], xyzData[index + 1], xyzData[index + 2]);
                index = uvOffset + vertexIds[k] * uvSize;
                uv[k] = new Vec2(uvData[index], uvData[index + 1]);
            }

            //math
            var uv02:Vec2 = uv[0] - uv[2];
            var uv12:Vec2 = uv[1] - uv[2];
            var denom = uv02.x * uv12.y - uv12.x * uv02.y;
            var invDenom = Math.abs(denom) > GLM.EPSILON ? 1.0 / denom : 1.0;

            var faceTangent:Vec3 = ((xyz[0] - xyz[2]) * uv12.y - (xyz[1] - xyz[2]) * uv02.y) * invDenom;

            for (k in 0... 3) {
                var index = 3 * vertexIds[k];

                tangentsData[index] += faceTangent.x;
                tangentsData[index + 1] += faceTangent.y;
                tangentsData[index + 2] += faceTangent.z;
            }
        }
        var index = 0;
        for (i in 0... numVertices) {
            var x = tangentsData[index];
            var y = tangentsData[index + 1];
            var z = tangentsData[index + 2];
            var lengthSquared = x * x + y * y + z * z;
            //todo
            var invLength = lengthSquared > GLM.EPSILON ? 1.0 / Math.sqrt(lengthSquared) : 1.0;

            tangentsData[index] *= invLength;
            tangentsData[index + 1] *= invLength;
            tangentsData[index + 2] *= invLength;
            index += 3;
        }

        var tangentsBuffer:VertexBuffer = VertexBuffer.createbyData(xyzBuffer.context, tangentsData);
        tangentsBuffer.addAttribute("tangent", 3, 0);
        addVertexBuffer(tangentsBuffer);

        return this;
    }

    public function computeCenterPosition() {

        if (numVertices == 0) {
            return this;
        }
        var xyzBuffer:VertexBuffer = vertexBuffer("position");
        if (xyzBuffer == null) {
            return this;
        }

        var xyzAttr:VertexAttribute = xyzBuffer.attribute("position");
        var xyzOffset = xyzAttr.offset;
        var xyzSize = Math.floor(Math.max(0, Math.min(3, xyzAttr.size)));
        var xyzData:Array<Float> = xyzBuffer.data ;

        var minXYZ:Array<Float> = [Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY];
        var maxXYZ:Array<Float> = [Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY];

        var vertexIndex = xyzOffset;
        while (vertexIndex < xyzData.length) {
            for (k in 0... xyzSize) {
                var vk = xyzData[vertexIndex + k];

                minXYZ[k] = Math.min(minXYZ[k], vk);
                maxXYZ[k] = Math.max(maxXYZ[k], vk);
            }

            vertexIndex += xyzBuffer.vertexSize;
        }

        var minPosition = new Vec3(minXYZ[0], minXYZ[1], minXYZ[2]);
        var maxPosition = new Vec3(maxXYZ[0], maxXYZ[1], maxXYZ[2]);

        //math
        var centerPosition = (minPosition - maxPosition) * .5;

        _data.set("centerPosition", centerPosition);

        return this;
    }

    public function removeDuplicatedVertices() {
        var vertices = new Array<Array<Float>>();

        for (vb in _vertexBuffers) {
            vertices.push(vb.data);
        }

        removeDuplicateVertices(_indexBuffer.data, vertices, numVertices);
    }

    /*
    * function removeDuplicateVertices(vertices) {
    var positionLookup = [];
    var final = [];

    for( let i = 0; i < vertices.length-3; i += 3 ) {
        var index = vertices[i] + vertices[i + 1] + vertices[i + 2];

        if( positionLookup.indexOf( index ) == -1 ) {
            positionLookup.push( index );
            final.push(vertices[i])
            final.push(vertices[i+1])
            final.push(vertices[i+2])
        }
    }
    return final;
}*/
    public function removeDuplicateVertices(indices:Array<Int>, vertices:Array<Array<Float>>, numVertices:Int) {
        var newVertexCount = 0;
        var newLimit = 0;

        var hashToNewVertexId = new StringMap<Int>();
        var oldVertexIdToNewVertexId = new IntMap<Int>();

        for (oldVertexId in 0... numVertices) {
            var hash = "";
            for (vb in vertices) {
                var vertexSize = Math.floor(vb.length / numVertices);
                for (i in 0... vertexSize) {
                    hash += (vb[oldVertexId * vertexSize + i]) + " ";
                }
            }

            var newVertexId = 0;

            if (!hashToNewVertexId.exists(hash)) {
                newVertexId = newVertexCount++;
                hashToNewVertexId.set(hash, newVertexId);
                newLimit = 1 + newVertexId;

                if (newVertexId != oldVertexId) {
                    for (vb in vertices) {
                        var vertexSize = Math.floor(vb.length / numVertices);
                        // vb_copy(vb,oldVertexId * vertexSize, (oldVertexId + 1) * vertexSize, vb, newVertexId * vertexSize);
                        for (i in 0...vertexSize)
                            vb[newVertexId * vertexSize + i] = vb[oldVertexId * vertexSize + i];
                    }
                }
            }
            else {
                newVertexId = hashToNewVertexId.get(hash);
            }

            oldVertexIdToNewVertexId.set(oldVertexId, newVertexId);
        }

        for (vb in vertices) {
            var len = (newLimit * vb.length / numVertices);
            //重建长度
            while (vb.length > len) vb.pop();
        }

        for (i in 0...indices.length) {
            var index = indices[i];
            indices[i] = oldVertexIdToNewVertexId.get(index);
        }
    }


    public function getVertexAttribute(attributeName:String) :VertexAttribute{
        for (vertexBuffer in _vertexBuffers) {
            if (vertexBuffer.hasAttribute(attributeName)) {
                return vertexBuffer.attribute(attributeName);
            }
        }

        throw ("attributeName = " + attributeName);
    }

    public function castRay(ray:Ray, distance:Float, triangle:Int, hitXyz:Vec3 = null, hitUv:Vec2 = null, hitNormal:Vec3 = null) {
        var EPSILON = 0.00001 ;

        var hit = false;
        var indicesData:Array<Int> = _indexBuffer.data;
        var numIndices = indicesData.length;

        var xyzBuffer:VertexBuffer = vertexBuffer("position");
        var xyzData:Array<Float> = xyzBuffer.data ;
        var xyzPtr = xyzData ;
        var xyzVertexSize = xyzBuffer.vertexSize ;
        var xyzOffset = xyzBuffer.attribute("position").offset;

        var minDistance = Math.POSITIVE_INFINITY;
        var lambda = new Vec2();
        var triangleIndice = -3;

        var v0 = new Vec3();
        var v1 = new Vec3();
        var v2 = new Vec3();
        var edge1 = new Vec3();
        var edge2 = new Vec3();
        var pvec = new Vec3();
        var tvec = new Vec3();
        var qvec = new Vec3();

        var dot = 0.0;
        var invDot = 0.0;
        var u = 0.0;
        var v = 0.0;
        var t = 0.0;
        var i = 0;
        while (i < numIndices) {
            var index:Int = indicesData[i] * xyzVertexSize;
            v0 = new Vec3(xyzPtr[index], xyzPtr[index + 1], xyzPtr[index + 2] );
            index = indicesData[i + 1] * xyzVertexSize;
            v1 = new Vec3(xyzPtr[index], xyzPtr[index + 1], xyzPtr[index + 2] );
            index = indicesData[i + 2] * xyzVertexSize;
            v2 = new Vec3(xyzPtr[index], xyzPtr[index + 1], xyzPtr[index + 2] );

            //math
            edge1 = v1 - (v0) ;
            edge2 = v2 - (v0);

            pvec = Vec3.cross(ray.direction, edge2, new Vec3()) ;
            dot = Vec3.dot(edge1, pvec);

            if (dot > -EPSILON && dot < EPSILON) {
                continue;
            }

            invDot = 1.0 / dot;
            //math
            tvec = ray.origin - v0;
            u = Vec3.dot(tvec, pvec) * invDot;
            if (u < 0.0 || u > 1.0) {
                continue;
            }

            qvec = Vec3.cross(tvec, edge1, new Vec3());
            v = Vec3.dot(ray.direction, qvec) * invDot;
            if (v < 0.0 || u + v > 1.0) {
                continue;
            }

            t = Vec3.dot(qvec, edge2) * invDot;
            if (t < minDistance && t > 0) {
                minDistance = t;
                distance = t;
                triangle = i;
                hit = true;

                if (hitUv != null) {
                    lambda.x = u;
                    lambda.y = v;
                }

                if (hitXyz != null) {
                    hitXyz = new Vec3(ray.origin.x + minDistance * ray.direction.x,
                    ray.origin.y + minDistance * ray.direction.y,
                    ray.origin.z + minDistance * ray.direction.z);
                }
            }

            if (hitUv != null) {
                getHitUv(triangle, lambda, hitUv);
            }

            if (hitNormal != null) {
                getHitNormal(triangle, hitNormal);
            }
            i += 3;
        }

        return hit;
    }

    public function upload() {
        for (vb in _vertexBuffers) {
            vb.upload();
        }

        _indexBuffer.upload();
    }

    public function disposeIndexBufferData() {
        _indexBuffer.disposeData();
    }

    public function disposeVertexBufferData() {
        for (vertexBuffer in _vertexBuffers) {
            vertexBuffer.disposeData();
        }
    }

//ORIGINAL LINE: bool equals(Geometry *geom) const;

//			bool equals(Geometry geom);


    public function copyFrom(geometry:Geometry) {
        this._data = Provider.createbyProvider(geometry._data);
        this._vertexSize = geometry._vertexSize;
        this._numVertices = geometry._numVertices;
        this._vertexBuffers = geometry._vertexBuffers.concat([]);
        this._indexBuffer = geometry._indexBuffer;
        return this;
    }


    function set_vertexSize(value) {
        _vertexSize = value;
        return value;
    }

    public function vertexSizeChanged(vertexBuffer:VertexBuffer, offset:Int) {
        _vertexSize += offset;
    }

    private function getHitUv(triangle:Int, lambda:Vec2, hitUv:Vec2) {
        var uvBuffer:VertexBuffer = vertexBuffer("uv");
        var uvData = uvBuffer.data;
        var uvPtr = uvData[0];
        var uvVertexSize = uvBuffer.vertexSize;
        var uvOffset = uvBuffer.attribute("uv").offset;
        var indicesData = _indexBuffer.data ;

        var u0 = uvData[indicesData[triangle] * uvVertexSize + uvOffset];
        var v0 = uvData[indicesData[triangle] * uvVertexSize + uvOffset + 1];

        var u1 = uvData[indicesData[triangle + 1] * uvVertexSize + uvOffset];
        var v1 = uvData[indicesData[triangle + 1] * uvVertexSize + uvOffset + 1];

        var u2 = uvData[indicesData[triangle + 2] * uvVertexSize + uvOffset];
        var v2 = uvData[indicesData[triangle + 2] * uvVertexSize + uvOffset + 1];

        var z = 1.0 - lambda.x - lambda.y;

        hitUv = new Vec2(z * u0 + lambda.x * u1 + lambda.y * u2, z * v0 + lambda.x * v1 + lambda.y * v2);
    }

    private function getHitNormal(triangle:Int, hitNormal:Vec3) {
        var normalBuffer:VertexBuffer = vertexBuffer("normal");
        var normalData:Array<Float> = normalBuffer.data;

        var normalVertexSize = normalBuffer.vertexSize;
        var normalOffset = normalBuffer.attribute("normal").offset;
        var indicesData = _indexBuffer.data;

        var index:Int = indicesData[triangle] * normalVertexSize + normalOffset;
        var v0 = new Vec3(normalData[index], normalData[index + 1], normalData[index + 2]);
        index = indicesData[triangle + 1] * normalVertexSize + normalOffset;
        var v1 = new Vec3(normalData[index], normalData[index + 1], normalData[index + 2]);
        index = indicesData[triangle + 2] * normalVertexSize + normalOffset;
        var v2 = new Vec3(normalData[index], normalData[index + 1], normalData[index + 2]);

        //math

        var edge1 = Vec3.normalize(v1 - v0, new Vec3());
        var edge2 = Vec3.normalize(v2 - v0, new Vec3());

        hitNormal = Vec3.cross(edge2, edge1, new Vec3());
    }

}
