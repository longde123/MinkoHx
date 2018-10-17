package minko.math;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.math.AbstractShape.PlanePosition;
class Frustum extends AbstractShape {
    public function new() {
        super();
        _points = [];
        _planes = [for (i in 0...6) new Vec4()];
        _blfResult = [for (i in 0...6) false];
        _blbResult = [for (i in 0...6) false];
        _brfResult = [for (i in 0...6) false];
        _brbResult = [for (i in 0...6) false];
        _tlfResult = [for (i in 0...6) false];
        _tlbResult = [for (i in 0...6) false];
        _trfResult = [for (i in 0...6) false];
        _trbResult = [for (i in 0...6) false];
    }
    private var _points:Array<Vec3>;
    private var _planes:Array<Vec4>;

    private var _blfResult:Array<Bool>;
    private var _blbResult:Array<Bool>;
    private var _brfResult:Array<Bool>;
    private var _brbResult:Array<Bool>;
    private var _tlfResult:Array<Bool>;
    private var _tlbResult:Array<Bool>;
    private var _trfResult:Array<Bool>;
    private var _trbResult:Array<Bool>;


    public static function create() {
        return new Frustum();
    }

    override public function castRay(ray:Ray, distance) {
        return false;
    }

    inline function getRawData(matrix:Mat4):Array<Float> {
        var out = matrix.toFloatArray();
        return out;
    }

    override public function updateFromMatrix(matrix:Mat4) {
        var data:Array<Float> = getRawData(matrix.transpose());

        _planes[PlanePosition.LEFT] = new Vec4(
        data[12] + data[0],
        data[13] + data[1],
        data[14] + data[2],
        data[15] + data[3]
        );
        _planes[PlanePosition.LEFT].normalize();
        _planes[PlanePosition.RIGHT] = new Vec4(
        data[12] - data[0],
        data[13] - data[1],
        data[14] - data[2],
        data[15] - data[3]
        );
        _planes[PlanePosition.RIGHT].normalize();
        _planes[PlanePosition.BOTTOM] = new Vec4(
        data[12] + data[4],
        data[13] + data[5],
        data[14] + data[6],
        data[15] + data[7]
        );
        _planes[PlanePosition.BOTTOM].normalize();
        _planes[PlanePosition.TOP] = new Vec4(
        data[12] - data[4],
        data[13] - data[5],
        data[14] - data[6],
        data[15] - data[7]
        );
        _planes[PlanePosition.TOP].normalize();
        _planes[PlanePosition.NEAR] = new Vec4(
        data[8],
        data[9],
        data[10],
        data[11]
        );
        _planes[PlanePosition.NEAR].normalize();
        _planes[PlanePosition.FAR] = new Vec4(
        data[12] - data[8],
        data[13] - data[9],
        data[14] - data[10],
        data[15] - data[11]
        );
        _planes[PlanePosition.FAR].normalize();
    }

    override public function testBoundingBox(box:Box) {
        return testBoundingBoxandPlane(box, 0).first;
    }

    override public function testBoundingBoxandPlane(box:Box, basePlaneId):AbstractShape.BoundingBoxPlane {
        var result = 0;

        // bottom left front
        var xblf = box.bottomLeft.x;
        var yblf = box.bottomLeft.y;
        var zblf = box.bottomLeft.z;

        // top right back
        var xtrb = box.topRight.x;
        var ytrb = box.topRight.y;
        var ztrb = box.topRight.z;

        // bottom right front
        var xbrf = xtrb;
        var ybrf = yblf;
        var zbrf = zblf;

        // bottom left back
        var xblb = xblf;
        var yblb = yblf;
        var zblb = ztrb;

        // bottom right back
        var xbrb = xtrb;
        var ybrb = yblf;
        var zbrb = ztrb;

        // top left back
        var xtlb = xblf;
        var ytlb = ytrb;
        var ztlb = ztrb;

        // top left front
        var xtlf = xtlb;
        var ytlf = ytrb;
        var ztlf = zblf;

        // top right front
        var xtrf = xbrf;
        var ytrf = ytrb;
        var ztrf = zblf;

        for (i in 0..._planes.length) {
            var planeId = (basePlaneId + i) % _planes.length;

            var pa = _planes[planeId].x;
            var pb = _planes[planeId].y;
            var pc = _planes[planeId].z;
            var pd = _planes[planeId].w;

            _blfResult[planeId] = pa * xblf + pb * yblf + pc * zblf + pd < 0.0;
            _brfResult[planeId] = pa * xbrf + pb * ybrf + pc * zbrf + pd < 0.0;
            _blbResult[planeId] = pa * xblb + pb * yblb + pc * zblb + pd < 0.0;
            _brbResult[planeId] = pa * xbrb + pb * ybrb + pc * zbrb + pd < 0.0;

            _tlfResult[planeId] = pa * xtlf + pb * ytlf + pc * ztlf + pd < 0.0;
            _trfResult[planeId] = pa * xtrf + pb * ytrf + pc * ztrf + pd < 0.0;
            _tlbResult[planeId] = pa * xtlb + pb * ytlb + pc * ztlb + pd < 0.0;
            _trbResult[planeId] = pa * xtrb + pb * ytrb + pc * ztrb + pd < 0.0;

            if (_blfResult[planeId] &&
            _brfResult[planeId] &&
            _blbResult[planeId] &&
            _brbResult[planeId] &&
            _tlfResult[planeId] &&
            _trfResult[planeId] &&
            _tlbResult[planeId] &&
            _trbResult[planeId]) {

                return new AbstractShape.BoundingBoxPlane(planeId, planeId);
            }
        }

        if (((_blfResult[PlanePosition.LEFT] && _trbResult[PlanePosition.RIGHT]) ||
        (_blfResult[PlanePosition.RIGHT] && _trbResult[PlanePosition.LEFT])) &&
        ((_blfResult[PlanePosition.TOP] && _trbResult[PlanePosition.BOTTOM]) ||
        (_blfResult[PlanePosition.BOTTOM] && _trbResult[PlanePosition.TOP])) &&
        ((_blfResult[PlanePosition.NEAR] && _trbResult[PlanePosition.FAR]) ||
        (_blfResult[PlanePosition.FAR] && _trbResult[PlanePosition.NEAR])))
            return new AbstractShape.BoundingBoxPlane(AbstractShape.ShapePosition.AROUND, 0);


        return return new AbstractShape.BoundingBoxPlane(AbstractShape.ShapePosition.INSIDE, 0);
    }
}
