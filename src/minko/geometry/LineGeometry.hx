package minko.geometry;
import glm.Vec3;
import minko.render.AbstractContext;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
class LineGeometry extends Geometry {
    public static inline var MAX_NUM_LINES = 16000;
    public static inline var ATTRNAME_START_POS = "startPosition";
    public static inline var ATTRNAME_STOP_POS = "stopPosition";
    public static inline var ATTRNAME_WEIGHTS = "weights";

    private var _currentX:Float;
    private var _currentY:Float;
    private var _currentZ:Float;
    private var _numLines:Int;

    private var _vertexBuffer:VertexBuffer;
    private var __indexBuffer:IndexBuffer;

    public static function create(context:AbstractContext) {
        var ptr = new LineGeometry();

        ptr.initialize(context);

        return ptr;
    }

    public var currentXYZ(get, null):Vec3;

    function get_currentXYZ() {
        return new Vec3(_currentX, _currentY, _currentZ);
    }

    public var numLines(get, null):Int;

    function get_numLines() {
        return _numLines;
    }

    public function moveTo(x, y, z):LineGeometry {
        _currentX = x;
        _currentY = y;
        _currentZ = z;

        return (this);
    }

    public function moveToVector3(xyz:Vec3):LineGeometry {
        return moveTo(xyz.x, xyz.y, xyz.z);
    }

    public function lineTo(x, y, z, numSegments = 1):LineGeometry {
        if (numSegments == 0) {
            return moveTo(x, y, z);
        }

        var vertexSize = _vertexBuffer.vertexSize;
        var oldVertexDataSize = _vertexBuffer.data.length;
        var oldIndexDataSize = __indexBuffer.data.length;

        var vertexData:Array<Float> = [];//(oldVertexDataSize + 4 * numSegments * vertexSize);
        var indexData:Array<Int> = [];//(oldIndexDataSize + 6 * numSegments);

        if (oldVertexDataSize > 0) {
            vertexData = _vertexBuffer.data.concat([]);// sizeof(float) * oldVertexDataSize);
        }

        if (oldIndexDataSize > 0) {
            indexData = __indexBuffer.data.concat([]);// sizeof(ushort) * oldIndexDataSize);
        }

        _vertexBuffer.dispose();
        __indexBuffer.dispose();

        var invNumSegments = 1.0 / numSegments;
        var stepX = (x - _currentX) * invNumSegments;
        var stepY = (y - _currentY) * invNumSegments;
        var stepZ = (z - _currentZ) * invNumSegments;
        var vid = oldVertexDataSize;
        var iid = oldIndexDataSize;

        for (segmentId in 0... numSegments) {
            if (_numLines >= MAX_NUM_LINES) {
                throw ("Maximal number of segments (" + (_numLines) + ") for line geometry reached.");
            }

            var nextX = _currentX + stepX;
            var nextY = _currentY + stepY;
            var nextZ = _currentZ + stepZ;

            for (k in 0... 4) {
                var wStart = k < 2 ? 1.0 : 0.0;
                var wStop = k < 2 ? 0.0 : 1.0;
                var lineSpread = 0 < k && k < 3 ? 1.0 : -1.0;

                // start position
                vertexData[vid++] = _currentX;
                vertexData[vid++] = _currentY;
                vertexData[vid++] = _currentZ;

                // stop position
                vertexData[vid++] = nextX;
                vertexData[vid++] = nextY;
                vertexData[vid++] = nextZ;

                // weights attribute
                vertexData[vid++] = wStart;
                vertexData[vid++] = wStop;
                vertexData[vid++] = lineSpread;
            }

            var iOffset = (_numLines << 2);
            indexData[iid++] = iOffset;
            indexData[iid++] = iOffset + 2;
            indexData[iid++] = iOffset + 1;

            indexData[iid++] = iOffset;
            indexData[iid++] = iOffset + 3;
            indexData[iid++] = iOffset + 2;

            _currentX = nextX;
            _currentY = nextY;
            _currentZ = nextZ;
            ++_numLines;
        }

#if DEBUG
				Debug.Assert(vid == vertexData.Count);
				Debug.Assert(iid == indexData.Count);
#end

        _vertexBuffer.data = vertexData;
        __indexBuffer.data = indexData;

        return (this);
    }

    public function lineToVector3(xyz:Vec3, numSegments = 1):LineGeometry {
        return lineTo(xyz.x, xyz.y, xyz.z, numSegments);
    }

    override public function upload() {
        __indexBuffer.upload();
        _vertexBuffer.upload();

        addVertexBuffer(_vertexBuffer);
        indices = (__indexBuffer);

        computeCenterPosition();
    }

    public function new() {
        super("line");
        this._currentX = 0.0;
        this._currentY = 0.0;
        this._currentZ = 0.0;
        this._numLines = 0;
        this._vertexBuffer = null;
        this.__indexBuffer = null;
    }

    function initialize(context:AbstractContext) {
        if (context == null)
            throw ("context");

        _vertexBuffer = VertexBuffer.create(context);
        __indexBuffer = IndexBuffer.create(context);

        _vertexBuffer.addAttribute(ATTRNAME_START_POS, 3, 0);
        _vertexBuffer.addAttribute(ATTRNAME_STOP_POS, 3, 3);
        _vertexBuffer.addAttribute(ATTRNAME_WEIGHTS, 3, 6);

    }
}
