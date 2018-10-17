package minko.geometry;
import glm.Mat4;
class Skin {
    private var _numBones:Int;
    private var _bones:Array<Bone>;
    private var _duration:Int; // in milliseconds
    private var _timeFactor:Float;
    private var _boneMatricesPerFrame:Array<Array<Mat4>> ;
    private var _maxNumVertexBones:Int;
    private var _numVertexBones:Array<Int>; // size = #vertices
    private var _vertexBones:Array<Int>; // size = #vertices * #bones
    private var _vertexBoneWeights:Array<Float>; // size = #vertices * #bones
    public static function create(numBones, duration, numFrames) {
        return new Skin(numBones, duration, numFrames);
    }

    public function clone() {
        var skin = new Skin().copyFrom(this);

        return skin;
    }

    public var numBones(get, null):Int;

    function get_numBones() {
        return _numBones;
    }
    public var maxNumVertexBones(get, null):Int;

    function get_maxNumVertexBones() {
        return _maxNumVertexBones;
    }
    public var bones(get, set):Array<Bone>;

    function get_bones() {
        return _bones;
    }

    function set_bones(v) {
        _bones = (v);
        return v;
    }

    public function getBone(boneId) {
        return _bones[boneId];
    }

    public function setBone(boneId, value) {
        _bones[boneId] = value;
    }

    public var duration(get, null):Int;

    function get_duration() {
        return _duration;
    }

    public function getFrameId(time) {
        var frameId = time * _timeFactor;

        return Math.floor(Math.min(frameId, numFrames - 1));
    }

    public var numFrames(get, null):Int;

    function get_numFrames() {
        return _boneMatricesPerFrame.length;
    }
    public var boneMatricesPerFrame(get, set):Array<Array<Mat4>>;

    public function set_boneMatricesPerFrame(v:Array<Array<Mat4>>) {
        _boneMatricesPerFrame = (v);
        return v;
    }

    public function get_boneMatricesPerFrame() {
        return _boneMatricesPerFrame;
    }


    public function getMatrices(frameId) {
        return _boneMatricesPerFrame[frameId];
    }

    public function setMatrix(frameId, boneId, value:Mat4) {
#if DEBUG_SKINNING
				Debug.Assert(frameId < numFrames() && boneId < numBones());
#end

        _boneMatricesPerFrame[frameId][boneId] = value;
    }

    public var numVertices(get, null):Int;

    function get_numVertices() {
        return _numVertexBones.length;
    }

    public function numVertexBones(vertexId) {
#if DEBUG_SKINNING
				Debug.Assert(vertexId < numVertices());
#end

        return _numVertexBones[vertexId];
    }

    public function vertexBoneData(vertexId, j, boneId, boneWeight) {
        var index = vertexArraysIndex(vertexId, j);

        boneId = _vertexBones[index];
        boneWeight = _vertexBoneWeights[index];
    }

    public function vertexBoneId(vertexId, j) {
        return _vertexBones[vertexArraysIndex(vertexId, j)];
    }

    public function vertexBoneWeight(vertexId, j) {
        return _vertexBoneWeights[vertexArraysIndex(vertexId, j)];
    }

    public function reorganizeByVertices() {
        _numVertexBones = null;
        _vertexBones = null;
        _vertexBoneWeights = null;

        var lastId = lastVertexId;
        var numVertices = lastId + 1;
        var numBones = _bones.length;

        _numVertexBones = [for (i in 0...numVertices) 0];
        _vertexBones = [for (i in 0...numVertices * numBones) 0];
        _vertexBoneWeights = [for (i in 0...numVertices * numBones) 0.0];

        for (boneId in 0...numBones) {
            var bone = _bones[boneId];

            var vertexIds = bone.vertexIds;
            var vertexWeights = bone.vertexWeights;

            for (i in 0...vertexIds.length) {
                if (vertexWeights[i] > 0.0) {
                    var vId = vertexIds[i];
#if DEBUG_SKINNING
							Debug.Assert(vId < numVertices);
#end

                    var j = _numVertexBones[vId];

                    ++_numVertexBones[vId];

                    var index = vertexArraysIndex(vId, j);

                    _vertexBones[index] = boneId;
                    _vertexBoneWeights[index] = vertexWeights[i];
                }
            }
        }

        _maxNumVertexBones = 0;
        for (vId in 0... numVertices) {
            _maxNumVertexBones = Math.floor(Math.max(_maxNumVertexBones, _numVertexBones[vId]));
        }

        return this;
    }

    public function disposeBones() {
        _bones = null;

        return this;
    }

    public function new(numBones = 0, duration = 0, numFrames = 0) {
        this._bones = [for (i in 0...numBones) null];
        this._numBones = numBones;
        this._duration = duration;
        this._timeFactor = duration > 0 ? numFrames / duration : 0.0 ;
        this._boneMatricesPerFrame = [for (i in 0...numFrames)[for (j in 0...numBones) Mat4.identity(new Mat4())] ];
        this._maxNumVertexBones = 0;
        this._numVertexBones = [];
        this._vertexBones = [];
        this._vertexBoneWeights = [];
    }

    public function copyFrom(skin:Skin) {
        this._bones = [];
        this._numBones = skin._numBones;
        this._duration = skin._duration;
        this._timeFactor = skin._timeFactor;
        this._boneMatricesPerFrame = (skin._boneMatricesPerFrame.concat([]));
        this._maxNumVertexBones = skin._maxNumVertexBones;
        this._numVertexBones = (skin._numVertexBones.concat([]));
        this._vertexBones = (skin._vertexBones.concat([]));
        this._vertexBoneWeights = (skin._vertexBoneWeights.concat([]));
        return this;
    }

    public var lastVertexId(get, null):Int;

    function get_lastVertexId() {
        var lastId = 0;
        for (boneId in 0... _bones.length) {
            var vertexId = _bones[boneId].vertexIds ;
            for (i in 0...vertexId.length) {
                lastId = Math.floor(Math.max(lastId, vertexId[i]));
            }
        }

        return lastId;
    }

    private function vertexArraysIndex(vertexId, j) {
#if DEBUG_SKINNING
				Debug.Assert(vertexId < numVertices() && j < numVertexBones(vertexId));
#end

        return j + _numBones * vertexId;
    }

}
