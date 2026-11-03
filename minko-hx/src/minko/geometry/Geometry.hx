package minko.geometry;
import glm.GLM;
import glm.Vec2;
import glm.Vec3;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import glm.Mat4;
import minko.math.Ray;
import minko.render.IndexBuffer;
import minko.render.VertexAttribute;
import minko.render.VertexBuffer;
import minko.signal.Signal2.SignalSlot2;
import minko.Uuid.Enable_uuid;
@:expose("minko.geometry.Geometry")
class Geometry extends Enable_uuid {
    private var _name:String;
    private var _attributes:StringMap<VertexAttribute>;
    private var _vertexSize:Int;
    private var _numVertices:Int;
    private var _vertexBuffers:Array<VertexBuffer>;
    private var _indexBuffer:IndexBuffer;
    public var centerPosition:Vec3;
    public var numBones:Int;
    public var boneMatrices:Array<Mat4>;
    public var boneNormalMatrices:Array<Mat4>;
    /** Undeformed position snapshot used by software skinning. Owned by Skinning. */
    public var skinningInputPositions:Array<Float>;
    /** Undeformed normal snapshot used by software skinning. Owned by Skinning. */
    public var skinningInputNormals:Array<Float>;

    private var _vbToVertexSizeChangedSlot:ObjectMap<VertexBuffer, SignalSlot2<VertexBuffer, Int>>;

    public function new(name:String) {
        super();
        enable_uuid();
        this._name = name;
        this._attributes = new StringMap<VertexAttribute>();
        this._vertexSize = 0;
        this._numVertices = 0;
        this._indexBuffer = null;
        this._vertexBuffers = [];
        this.centerPosition = new Vec3();
        this.numBones = 0;
        this.boneMatrices = [];
        this.boneNormalMatrices = [];
        _vbToVertexSizeChangedSlot = new ObjectMap<VertexBuffer, SignalSlot2<VertexBuffer, Int>>();
    }

    public function dispose() {
        _attributes = null;
        _vertexBuffers = null;
        _indexBuffer = null;
        boneMatrices = null;
        boneNormalMatrices = null;
        skinningInputPositions = null;
        skinningInputNormals = null;
    }
    public static function create():Geometry {
        return createbyName("");
    }
    public static function createbyName(name:String = "geometry"):Geometry {
        return new Geometry(name);
    }

    public function clone() {
        var geometry = new Geometry("").copyFrom(this) ;
        return geometry;
    }

    public var vertexBuffers(get, null):Array<VertexBuffer>;

    function get_vertexBuffers() {
        return _vertexBuffers;
    }
    public var name(get, null):String;

    function get_name() {
        return _name;
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
        return _attributes.exists(vertexAttributeName);
    }
    public var indices(get, set):IndexBuffer;

    function set_indices(__indices:IndexBuffer) {
        _indexBuffer = __indices;
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
            _attributes.set(attribute.name, attribute);
        }
        _vertexSize += bufVertexSize;

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
            _attributes.remove(attribute.name);
        }

        _vertexSize -= vertexBuffer.vertexSize;

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

        var normalBuffer:VertexBuffer = vertexBuffer("normal");
        var normalSize = 0;
        var normalOffset = 0;
        var normalData:Array<Float> = null;
        if (normalBuffer != null) {
            normalSize = normalBuffer.vertexSize;
            normalOffset = normalBuffer.attribute("normal").offset;
            normalData = normalBuffer.data;
        }

        var tangentsData:Array<Float> = [ for (i in 0...4 * numVertices) 0.0];
        var bitangentsData:Array<Float> = [ for (i in 0...3 * numVertices) 0.0];
        var offset = 0;
        for (i in 0...numFaces) {
            for (k in 0...3) {
                vertexIds[k] = uintIndices[offset++];
                var index = xyzOffset + vertexIds[k] * xyzSize;
                xyz[k] = new Vec3(xyzData[index], xyzData[index + 1], xyzData[index + 2]);
                index = uvOffset + vertexIds[k] * uvSize;
                uv[k] = new Vec2(uvData[index], uvData[index + 1]);
            }

            var edge1 = xyz[1] - xyz[0];
            var edge2 = xyz[2] - xyz[0];
            var deltaUV1 = uv[1] - uv[0];
            var deltaUV2 = uv[2] - uv[0];
            var denominator = deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y;
            var invDenom = Math.abs(denominator) > GLM.EPSILON ? 1.0 / denominator : 1.0;

            var faceTangent:Vec3 = (edge1 * deltaUV2.y - edge2 * deltaUV1.y) * invDenom;
            var faceBitangent:Vec3 = (edge2 * deltaUV1.x - edge1 * deltaUV2.x) * invDenom;

            for (k in 0...3) {
                var tangentIndex = 3 * vertexIds[k];
                tangentsData[tangentIndex] += faceTangent.x;
                tangentsData[tangentIndex + 1] += faceTangent.y;
                tangentsData[tangentIndex + 2] += faceTangent.z;
                bitangentsData[tangentIndex] += faceBitangent.x;
                bitangentsData[tangentIndex + 1] += faceBitangent.y;
                bitangentsData[tangentIndex + 2] += faceBitangent.z;
            }
        }

        for (i in 0...numVertices) {
            var tangentIndex = 3 * i;
            var x = tangentsData[tangentIndex];
            var y = tangentsData[tangentIndex + 1];
            var z = tangentsData[tangentIndex + 2];

            var nx = 0.0;
            var ny = 1.0;
            var nz = 0.0;
            if (normalData != null) {
                var normalIndex = normalOffset + i * normalSize;
                nx = normalData[normalIndex];
                ny = normalData[normalIndex + 1];
                nz = normalData[normalIndex + 2];
                var normalLength = Math.sqrt(nx * nx + ny * ny + nz * nz);
                if (normalLength > GLM.EPSILON) {
                    nx /= normalLength;
                    ny /= normalLength;
                    nz /= normalLength;
                }
            }

            var dotTN = x * nx + y * ny + z * nz;
            x -= nx * dotTN;
            y -= ny * dotTN;
            z -= nz * dotTN;

            var lengthSquared = x * x + y * y + z * z;
            if (lengthSquared <= GLM.EPSILON) {
                // Pick any axis orthogonal to the normal.
                if (Math.abs(ny) < 0.99) {
                    x = nz;
                    y = 0.0;
                    z = -nx;
                }
                else {
                    x = 0.0;
                    y = -nz;
                    z = ny;
                }
                lengthSquared = x * x + y * y + z * z;
            }
            var invLength = lengthSquared > GLM.EPSILON ? 1.0 / Math.sqrt(lengthSquared) : 1.0;
            x *= invLength;
            y *= invLength;
            z *= invLength;

            var bx = bitangentsData[tangentIndex];
            var by = bitangentsData[tangentIndex + 1];
            var bz = bitangentsData[tangentIndex + 2];
            var cx = ny * z - nz * y;
            var cy = nz * x - nx * z;
            var cz = nx * y - ny * x;
            var handedness = (cx * bx + cy * by + cz * bz) < 0.0 ? -1.0 : 1.0;

            var outputIndex = 4 * i;
            tangentsData[outputIndex] = x;
            tangentsData[outputIndex + 1] = y;
            tangentsData[outputIndex + 2] = z;
            tangentsData[outputIndex + 3] = handedness;
        }

        var tangentsBuffer:VertexBuffer = VertexBuffer.createbyData(xyzBuffer.context, tangentsData);
        tangentsBuffer.addAttribute("tangent", 4, 0);
        addVertexBuffer(tangentsBuffer);

        return this;
    }

    /**
     * Generates a vec4 tangent buffer (xyz + handedness). Idempotent.
     */
    public function computeTangents() {
        if (hasVertexAttribute("tangent")) {
            return this;
        }
        return computeTangentSpace(true);
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

        this.centerPosition = (minPosition + maxPosition) * .5;

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

    public function intersectRay(ray:Ray):Null<minko.math.RayHit> {
        if (_indexBuffer == null || !hasVertexAttribute("position")) {
            return null;
        }

        var indicesData = _indexBuffer.data;
        var xyzBuffer = vertexBuffer("position");
        var xyzData = xyzBuffer.data;
        var xyzVertexSize = xyzBuffer.vertexSize;
        var xyzOffset = xyzBuffer.attribute("position").offset;
        var minDistance = Math.POSITIVE_INFINITY;
        var hitTriangle = -1;
        var hitU = 0.0;
        var hitV = 0.0;
        var i = 0;

        while (i + 2 < indicesData.length) {
            var i0 = indicesData[i];
            var i1 = indicesData[i + 1];
            var i2 = indicesData[i + 2];
            i += 3;
            if (i0 < 0 || i1 < 0 || i2 < 0 || i0 >= xyzBuffer.numVertices || i1 >= xyzBuffer.numVertices || i2 >= xyzBuffer.numVertices) {
                continue;
            }

            var index0 = i0 * xyzVertexSize + xyzOffset;
            var index1 = i1 * xyzVertexSize + xyzOffset;
            var index2 = i2 * xyzVertexSize + xyzOffset;
            var v0 = new Vec3(xyzData[index0], xyzData[index0 + 1], xyzData[index0 + 2]);
            var v1 = new Vec3(xyzData[index1], xyzData[index1 + 1], xyzData[index1 + 2]);
            var v2 = new Vec3(xyzData[index2], xyzData[index2 + 1], xyzData[index2 + 2]);
            var edge1 = v1 - v0;
            var edge2 = v2 - v0;
            var pvec = Vec3.cross(ray.direction, edge2, new Vec3());
            var determinant = Vec3.dot(edge1, pvec);
            if (determinant <= 0.00001) {
                continue;
            }

            var invDeterminant = 1.0 / determinant;
            var tvec = ray.origin - v0;
            var u = Vec3.dot(tvec, pvec) * invDeterminant;
            if (u < 0.0 || u > 1.0) {
                continue;
            }

            var qvec = Vec3.cross(tvec, edge1, new Vec3());
            var v = Vec3.dot(ray.direction, qvec) * invDeterminant;
            if (v < 0.0 || u + v > 1.0) {
                continue;
            }

            var distance = Vec3.dot(qvec, edge2) * invDeterminant;
            if (distance > 0.0 && distance < minDistance) {
                minDistance = distance;
                hitTriangle = i - 3;
                hitU = u;
                hitV = v;
            }
        }

        if (hitTriangle < 0) {
            return null;
        }

        var position = new Vec3(
            ray.origin.x + minDistance * ray.direction.x,
            ray.origin.y + minDistance * ray.direction.y,
            ray.origin.z + minDistance * ray.direction.z
        );
        var w = 1.0 - hitU - hitV;
        var uv:Vec2 = null;
        var normal:Vec3 = null;
        var uvBuffer = vertexBuffer("uv");
        if (uvBuffer != null) {
            var uvData = uvBuffer.data;
            var uvSize = uvBuffer.vertexSize;
            var uvOffset = uvBuffer.attribute("uv").offset;
            var uv0 = indicesData[hitTriangle] * uvSize + uvOffset;
            var uv1 = indicesData[hitTriangle + 1] * uvSize + uvOffset;
            var uv2 = indicesData[hitTriangle + 2] * uvSize + uvOffset;
            uv = new Vec2(
                w * uvData[uv0] + hitU * uvData[uv1] + hitV * uvData[uv2],
                w * uvData[uv0 + 1] + hitU * uvData[uv1 + 1] + hitV * uvData[uv2 + 1]
            );
        }

        var normalBuffer = vertexBuffer("normal");
        if (normalBuffer != null) {
            var normalData = normalBuffer.data;
            var normalSize = normalBuffer.vertexSize;
            var normalOffset = normalBuffer.attribute("normal").offset;
            var n0 = indicesData[hitTriangle] * normalSize + normalOffset;
            var n1 = indicesData[hitTriangle + 1] * normalSize + normalOffset;
            var n2 = indicesData[hitTriangle + 2] * normalSize + normalOffset;
            normal = new Vec3(
                w * normalData[n0] + hitU * normalData[n1] + hitV * normalData[n2],
                w * normalData[n0 + 1] + hitU * normalData[n1 + 1] + hitV * normalData[n2 + 1],
                w * normalData[n0 + 2] + hitU * normalData[n1 + 2] + hitV * normalData[n2 + 2]
            );
            if (normal.length() > 1e-12) {
                normal = Vec3.normalize(normal, new Vec3());
            }
        }

        return new minko.math.RayHit(minDistance, hitTriangle, position, uv, normal);
    }

    public function castRay(ray:Ray, distance:Float, triangle:Int, hitXyz:Vec3 = null, hitUv:Vec2 = null, hitNormal:Vec3 = null) {
        var hit = intersectRay(ray);
        if (hit == null) {
            return false;
        }
        if (hitXyz != null) {
            hitXyz.x = hit.position.x;
            hitXyz.y = hit.position.y;
            hitXyz.z = hit.position.z;
        }
        if (hitUv != null && hit.uv != null) {
            hitUv.x = hit.uv.x;
            hitUv.y = hit.uv.y;
        }
        if (hitNormal != null && hit.normal != null) {
            hitNormal.x = hit.normal.x;
            hitNormal.y = hit.normal.y;
            hitNormal.z = hit.normal.z;
        }
        return true;
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
        this._name = geometry._name;
        this._attributes = new StringMap<VertexAttribute>();
        for (key in geometry._attributes.keys()) {
            this._attributes.set(key, geometry._attributes.get(key));
        }
        this._vertexSize = geometry._vertexSize;
        this._numVertices = geometry._numVertices;
        this._vertexBuffers = geometry._vertexBuffers.concat([]);
        this._indexBuffer = geometry._indexBuffer;
        this.centerPosition = geometry.centerPosition;
        this.numBones = geometry.numBones;
        this.boneMatrices = geometry.boneMatrices;
        this.boneNormalMatrices = geometry.boneNormalMatrices;
        // Snapshots are read-only inputs; sharing the reference is safe.
        this.skinningInputPositions = geometry.skinningInputPositions;
        this.skinningInputNormals = geometry.skinningInputNormals;
        return this;
    }


    function set_vertexSize(value) {
        _vertexSize = value;
        return value;
    }

    public function vertexSizeChanged(vertexBuffer:VertexBuffer, offset:Int) {
        _vertexSize += offset;
    }

}
