package minko.component;
import glm.Mat3;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import minko.geometry.Geometry;
import minko.geometry.Skin;
import minko.render.AbstractContext;
import minko.render.VertexAttribute;
import minko.render.VertexBuffer;
import minko.scene.Node;
import minko.utils.MathUtil;
@:expose("minko.component.SkinningMethod")
@:enum abstract SkinningMethod(Int) from Int to Int
{
    var SOFTWARE = 0;
    var HARDWARE = 1;
}
@:expose("minko.component.Skinning")
class Skinning extends AbstractAnimation {

    static public var PNAME_NUM_BONES = "numBones";
    static public var PNAME_BONE_MATRICES = "boneMatrices";
    static public var PNAME_BONE_NORMAL_MATRICES = "boneNormalMatrices";
    static public var ATTRNAME_BONE_IDS_A = "boneIdsA";
    static public var ATTRNAME_BONE_IDS_B = "boneIdsB";
    static public var ATTRNAME_BONE_WEIGHTS_A = "boneWeightsA";
    static public var ATTRNAME_BONE_WEIGHTS_B = "boneWeightsB";
    static public var MAX_NUM_BONES_PER_VERTEX = 8;

    static private var ATTRNAME_POSITION = "position";
    static private var ATTRNAME_NORMAL = "normal";


    private var _skin:Skin;
    private var _context:AbstractContext;
    private var _method:SkinningMethod;

    private var _skeletonRoot:Node;
    private var _moveTargetBelowRoot:Bool;

    private var _boneVertexBuffer:VertexBuffer ; // vertex buffer storing vertex attributes

    private var _targetGeometry:ObjectMap<Node, Geometry>;
    private var _targetInputPositions:ObjectMap<Node, Array<Float>>; // only for software skinning
    private var _targetInputNormals:ObjectMap<Node, Array<Float>>; // only for software skinning

    public static function create(skin, method, context, skeletonRoot, moveTargetBelowRoot = false, isLooping = true):Skinning {
        var ptr = new Skinning(skin, method, context, skeletonRoot, moveTargetBelowRoot, isLooping);

        ptr.initialize();

        return ptr;
    }

    override public function clone(option:CloneOption) {
        var skin:Skinning = create(null, null, null, null).copyFromSkinning(this, option);

        skin.initialize();

        return skin;
    }
    public var skin(get, null):Skin;

    function get_skin() {
        return _skin;
    }

    override public function initialize() {
        super.initialize();

        if (_skin == null) {
            throw ("skin");
        }

        if (_context == null) {
            throw ("context");
        }

        if (_method != SkinningMethod.SOFTWARE && _skin.maxNumVertexBones > MAX_NUM_BONES_PER_VERTEX) {
            var error_msg = "The maximum number of bones per vertex gets too high (" + _skin.maxNumVertexBones + ") to propose hardware skinning (max allowed = " + MAX_NUM_BONES_PER_VERTEX + ")" ;

            _method = SkinningMethod.SOFTWARE;
       }
       // _method = SkinningMethod.SOFTWARE;
        _boneVertexBuffer = _method == SkinningMethod.SOFTWARE ? null : createVertexBufferForBones();

        _maxTime = _skin.duration;

        setPlaybackWindow(0, _maxTime);
        seek(0);
    }

    override public function targetAdded(target:Node) {
        super.targetAdded(target);

        // FIXME: in certain circumstances (deserialization from minko studio)
        // it may be necessary to move the target directly below the skeleton root
        // for which the skinning matrices have been computed.

        if (_skeletonRoot == null || !_moveTargetBelowRoot)
            return;

        if (target.parent != null)
            target.parent.removeChild(target);

        _skeletonRoot.addChild(target);

        if (target.hasComponent(Transform)) {
            var transform:Transform = cast target.getComponent(Transform);
            transform.matrix = Mat4.identity(new Mat4());

        }

        if (target.hasComponent(MasterAnimation)) {
            var masterAnimation:MasterAnimation = cast target.getComponent(MasterAnimation);
            masterAnimation.initAnimations();
        }
    }

    public function copyFromSkinning(skinning:Skinning, option:CloneOption) {
        //: base(skinning, option)
        copyFrom(skinning, option);
        this._skin = new Skin();
        this._context = skinning._context;
        this._method = skinning._method;
        this._skeletonRoot = skinning._skeletonRoot;
        this._moveTargetBelowRoot = skinning._moveTargetBelowRoot;
        this._boneVertexBuffer = null;
        this._targetGeometry = new ObjectMap<Node, Geometry>();
        this._targetInputPositions = new ObjectMap<Node, Array<Float>>();
        this._targetInputNormals = new ObjectMap<Node, Array<Float>>();
        this._skin = skinning._skin.clone();

        var targetGeometry = skinning._targetGeometry;

        for (it in targetGeometry.keys()) {
            _targetGeometry.set(it, targetGeometry.get(it));
        }
        return this;
    }


    override public function addedHandler(node:Node, target:Node, parent:Node) {
        super.addedHandler(node, target, parent);

        if (_skin.duration == 0)
            return; // incorrect animation

        // FIXME
        if (node.getComponents(Surface).length > 1)
            throw "Warning: The skinning component is not intended to work on node with several surfaces. Attempts to apply skinning to first surface." ;

        if (node.hasComponent(Surface)) {
            var geometry:Geometry = cast(node.getComponent(Surface), Surface).geometry;

            if (geometry.hasVertexAttribute(ATTRNAME_POSITION)
            && geometry.vertexBuffer(ATTRNAME_POSITION).numVertices == _skin.numVertices
            && !geometry.hasVertexBuffer(_boneVertexBuffer)) {
                _targetGeometry.set(node, geometry);
                _targetInputPositions.set(node, geometry.vertexBuffer(ATTRNAME_POSITION).data);

                if (geometry.hasVertexAttribute(ATTRNAME_NORMAL)
                && geometry.vertexBuffer(ATTRNAME_NORMAL).numVertices == _skin.numVertices)
                    _targetInputNormals.set(node, geometry.vertexBuffer(ATTRNAME_NORMAL).data);

                if (_method != SkinningMethod.SOFTWARE) {
                    geometry.addVertexBuffer(_boneVertexBuffer);

                    geometry.data.set(PNAME_BONE_MATRICES, []);
                    geometry.data.set(PNAME_BONE_NORMAL_MATRICES, []);

                    geometry.data.set(PNAME_NUM_BONES, 0);
                }
            }
        }
    }

    override public function removedHandler(node:Node, target:Node, parent:Node) {
        super.removedHandler(node, target, parent);

        if (_targetGeometry.exists(target)) {
            var geometry = _targetGeometry.get(target);

            if (_method != SkinningMethod.SOFTWARE) {
                geometry.removeVertexBuffer(_boneVertexBuffer);
                geometry.data.unset(PNAME_BONE_MATRICES);
                geometry.data.unset(PNAME_BONE_NORMAL_MATRICES);
                geometry.data.unset(PNAME_NUM_BONES);
            }

            _targetGeometry.remove(target);
        }
        if (_targetInputPositions.exists(target))
            _targetInputPositions.remove(target);
        if (_targetInputNormals.exists(target))
            _targetInputNormals.remove(target);
    }

    override public function update() {
        var frameId = _skin.getFrameId(_currentTime);

        updateFrame(frameId, target);
    }

    public function updateFrame(frameId:Int, target:Node) {
        if (_targetGeometry.exists(target) == false)
            return;

        // assert(frameId < _skin->numFrames());

        var geometry:Geometry = _targetGeometry.get(target);
        var boneMatrices:Array<Mat4> = _skin.getMatrices(frameId);
        var boneNormalMatrices:Array<Mat4> = _skin.getNormalMatrices(frameId);
        if (_method == SkinningMethod.HARDWARE) {
            if (!geometry.data.hasProperty(PNAME_NUM_BONES) || geometry.data.get(PNAME_NUM_BONES) != _skin.numBones){
                geometry.data.set(PNAME_NUM_BONES, _skin.numBones);
            }
            geometry.data.set(PNAME_BONE_MATRICES, boneMatrices);
            geometry.data.set(PNAME_BONE_NORMAL_MATRICES, boneNormalMatrices);

        }
        else
            performSoftwareSkinningFrame(target, boneMatrices);
    }

    public function performSoftwareSkinningFrame(target:Node, boneMatrices:Array<Mat4>) {
#if  DEBUG_SKINNING
	assert(target && _targetGeometry.count(target) > 0 && _targetInputPositions.count(target) > 0);
#end
        //DEBUG_SKINNING

        var geometry = _targetGeometry.get(target);

        // transform positions
        var xyzBuffer:VertexBuffer = geometry.vertexBuffer(ATTRNAME_POSITION);
        var xyzAttr = xyzBuffer.attribute(ATTRNAME_POSITION);

        performSoftwareSkinning(xyzAttr, xyzBuffer, _targetInputPositions.get(target), boneMatrices, false);

        // transform normals
        if (geometry.hasVertexAttribute(ATTRNAME_NORMAL) && _targetInputNormals.exists(target)) {
            var normalBuffer:VertexBuffer = geometry.vertexBuffer(ATTRNAME_NORMAL);
            var normalAttr = normalBuffer.attribute(ATTRNAME_NORMAL);

            performSoftwareSkinning(normalAttr, normalBuffer, _targetInputNormals.get(target), boneMatrices, true);
        }
    }

    private function performSoftwareSkinning(attr:VertexAttribute, vertexBuffer:VertexBuffer, inputData:Array<Float>, boneMatrices:Array<Mat4>, doDeltaTransform:Bool) {
#if DEBUG_SKINNING
				Debug.Assert(vertexBuffer != null && vertexBuffer.data().size() == inputData.Count);
				Debug.Assert(attr != null && std::get<1>(*attr) == 3);
				Debug.Assert(boneMatrices.Count == (_skin.numBones() << 4));
#end

        var vertexSize = vertexBuffer.vertexSize;
        var outputData:Array<Float> = vertexBuffer.data;
        var numVertices = Math.floor(outputData.length / vertexSize);

#if DEBUG_SKINNING
				Debug.Assert(numVertices == _skin.numVertices());
#end

        var index:Int = attr.offset;
        for (vId in 0 ...numVertices) {
            var v1:Vec4 = new Vec4(inputData[index], inputData[index + 1], inputData[index + 2], 1.0);
            var v2:Vec4 = new Vec4(0.0);

            var numVertexBones:Int = _skin.numVertexBones(vId);
            for (j in 0...numVertexBones) {
                var boneId = 0;
                var boneWeight = 0.0;

                var t:minko.Tuple<Int,Float>=_skin.vertexBoneData(vId, j, boneId, boneWeight);
                boneId=t.first;
                boneWeight=t.second;

                var boneMatrix:Mat4 = (boneMatrices[boneId]);

                //math
             //   if (!doDeltaTransform) {
                //  v2 += boneWeight * (boneMatrix * v1);
                    v2 = (boneMatrix * v1)*boneWeight;
//                }
//                else {
                   // v2 += math::vec4(boneWeight * (math::mat3(boneMatrix)) * math::vec3(v1), 0.f);
               // }
            }

            outputData[index] = v2.x;
            outputData[index + 1] = v2.y;
            outputData[index + 2] = v2.z;

            index += vertexSize;
        }

        vertexBuffer.upload();
    }

    private function createVertexBufferForBones() {
        var vertexSize = 16; // [bId0 bId1 bId2 bId3] [bId4 bId5 bId6 bId7] [bWgt0 bWgt1 bWgt2 bWgt3] [bWgt4 bWgt5 bWgt6 bWgt7]

//Debug.Assert(_skin.maxNumVertexBones() <= MAX_NUM_BONES_PER_VERTEX);

        var numVertices = _skin.numVertices;
        var vertexData:Array<Float> = [for (i in 0...numVertices * vertexSize) 0.0];

        var index = 0;
        for (vId in 0... numVertices) {
            var numVertexBones = _skin.numVertexBones(vId);

            var j = 0;
            while (j < numVertexBones && j < (vertexSize >> 2)) {
                vertexData[index + j] = _skin.vertexBoneId(vId, j);
                ++j;
            }
            index += (vertexSize >> 1);

            j = 0;
            while (j < numVertexBones && j < (vertexSize >> 2)) {
                vertexData[index + j] = _skin.vertexBoneWeight(vId, j);
                ++j;
            }
            index += (vertexSize >> 1);
        }

#if DEBUG_SKINNING
				Debug.Assert(index == vertexData.Count);
#end

        var vertexBuffer:VertexBuffer = VertexBuffer.createbyData(_context, vertexData);

        vertexBuffer.addAttribute(ATTRNAME_BONE_IDS_A, 4, 0);
        vertexBuffer.addAttribute(ATTRNAME_BONE_IDS_B, 4, 4);
        vertexBuffer.addAttribute(ATTRNAME_BONE_WEIGHTS_A, 4, 8);
        vertexBuffer.addAttribute(ATTRNAME_BONE_WEIGHTS_B, 4, 12);

        return vertexBuffer;
    }

    override public function rebindDependencies(componentsMap:ObjectMap<AbstractComponent, AbstractComponent>, nodeMap:ObjectMap<Node, Node>, option:Int) {

        _skeletonRoot = nodeMap.get(_skeletonRoot);
        var oldSurface:Surface = null;
        for (node in _targetGeometry.keys()) {
            oldSurface = cast node.getComponent(Surface);
            break;
        }
        var oldGeometry:Geometry = oldSurface.geometry;

        var componentsMapSurface:Surface = cast(componentsMap.get(oldSurface), Surface);
        componentsMapSurface.geometry = oldGeometry.clone();
    }

    public function new(skin:Skin,
                        method:SkinningMethod,
                        context:AbstractContext,
                        skeletonRoot:Node,
                        moveTargetBelowRoot:Bool,
                        isLooping:Bool) {
        super(isLooping);
        _skin = (skin);
        _context = (context);
        _method = method;
        _skeletonRoot = (skeletonRoot);
        _moveTargetBelowRoot = (moveTargetBelowRoot);
        _boneVertexBuffer = (null);
        _targetGeometry = new ObjectMap<Node, Geometry>();
        _targetInputPositions = new ObjectMap<Node, Array<Float>>();
        _targetInputNormals = new ObjectMap<Node, Array<Float>>();

    }
}
