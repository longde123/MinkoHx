package minko.animation;
import glm.Mat4;
import minko.data.Store;
@:expose
class TimelineLookup {
    public var timetable:Int;
    public var mat4:Mat4;

    public function new() {

    }

    public static function interpolate(thisMat:Mat4, toMat:Mat4, percent:Float):Mat4 {

        var m:Mat4 = new Mat4();
        m.r0c0 = thisMat.r0c0 + (toMat.r0c0 - thisMat.r0c0) * percent;
        m.r0c1 = thisMat.r0c1 + (toMat.r0c1 - thisMat.r0c1) * percent;
        m.r0c2 = thisMat.r0c2 + (toMat.r0c2 - thisMat.r0c2) * percent;
        m.r0c3 = thisMat.r0c3 + (toMat.r0c3 - thisMat.r0c3) * percent;

        m.r1c0 = thisMat.r1c0 + (toMat.r1c0 - thisMat.r1c0) * percent;
        m.r1c1 = thisMat.r1c1 + (toMat.r1c1 - thisMat.r1c1) * percent;
        m.r1c2 = thisMat.r1c2 + (toMat.r1c2 - thisMat.r1c2) * percent;
        m.r1c3 = thisMat.r1c3 + (toMat.r1c3 - thisMat.r1c3) * percent;

        m.r2c0 = thisMat.r2c0 + (toMat.r2c0 - thisMat.r2c0) * percent;
        m.r2c1 = thisMat.r2c1 + (toMat.r2c1 - thisMat.r2c1) * percent;
        m.r2c2 = thisMat.r2c2 + (toMat.r2c2 - thisMat.r2c2) * percent;
        m.r2c3 = thisMat.r2c3 + (toMat.r2c3 - thisMat.r2c3) * percent;


        m.r3c0 = thisMat.r3c0 + (toMat.r3c0 - thisMat.r3c0) * percent;
        m.r3c1 = thisMat.r3c1 + (toMat.r3c1 - thisMat.r3c1) * percent;
        m.r3c2 = thisMat.r3c2 + (toMat.r3c2 - thisMat.r3c2) * percent;
        m.r3c3 = thisMat.r3c3 + (toMat.r3c3 - thisMat.r3c3) * percent;


        return m;

    }

    static public function getTimeInRange(time:Int, duration:Int) {
        var t =
        if (duration > 0) {
            if (time >= 0) {
                time % duration;
            } else {
                ((time % duration) + duration) % duration;
            }
        } else {
            0;
        }


        //assert(t < duration);

        return t;
    }

    static public function getIndexForTime(time:Int, timetable:Array<TimelineLookup>) {
        var numKeys = timetable.length;
        if (numKeys == 0)
            return 0;

        var id = 0;
        var lowerId = 0;
        var upperId = numKeys;

        while (upperId - lowerId > 1) {
            id = (lowerId + upperId) >> 1;
            if (timetable[id].timetable > time)
                upperId = id;
            else
                lowerId = id;
        }

        // assert(lowerId < numKeys);

        return lowerId;
    }
}
@:expose
class Matrix4x4Timeline extends AbstractTimeline {

    private var _matrices:Array<TimelineLookup>;
    private var _interpolate:Bool;

    public function new(propertyName:String, duration:Int, ?timetable:Array<Int>, ?matrices:Array<Mat4>, ?interpolate:Bool = false) {
        super(propertyName, duration);
        this._matrices = new Array<TimelineLookup>();
        this._interpolate = interpolate;
        initializeMatrixTimetable(timetable, matrices);
    }

    public static  function create(propertyName:String, duration:Int, ?timetable:Array<Int>, ?matrices:Array<Mat4>, ?interpolate:Bool = false) {
        var ptr = new Matrix4x4Timeline(propertyName, duration, timetable, matrices, interpolate);

        return ptr;
    }

    public static function createbyMatrix4x4Timeline(matrix:Matrix4x4Timeline) {
        var ptr = new Matrix4x4Timeline(matrix._propertyName, matrix._duration);

        ptr._matrices = new Array<TimelineLookup>();
        ptr._interpolate = matrix._interpolate;
        for (keyId in 0... matrix._matrices.length) {
            ptr._matrices[keyId] = matrix._matrices[keyId];
        }


        return ptr;
    }

    override public function clone() {
        return Matrix4x4Timeline.createbyMatrix4x4Timeline(this);
    }

    public var matrices(get, null):Array<TimelineLookup>;

    function get_matrices() {
        return _matrices;
    }
    public var interpolate(get, null):Bool;

    function get_interpolate() {
        return _interpolate;
    }

    override public function update(time:Int, data:Store, ?skipPropertyNameFormatting:Bool = true) {
        if (_isLocked || _duration == 0 || _matrices.length == 0) {
            return;
        }

        if (_interpolate) {
            data.set(_propertyName, interpolateTime(time));
        }
        else {
            var t = TimelineLookup.getTimeInRange(time, _duration + 1);
            var keyId = TimelineLookup.getIndexForTime(t, _matrices);

            data.set(_propertyName, _matrices[keyId].mat4);
        }
    }


    public function interpolateTime(time:Int) {
        var t = TimelineLookup.getTimeInRange(time, _duration + 1);
        var keyId = TimelineLookup.getIndexForTime(t, _matrices);

        // all matrices are sorted in order of increasing time
        if (t < _matrices[0].timetable || t >= _matrices[_matrices.length - 1].timetable) {
            return _matrices[keyId].mat4;
        }

#if DEBUG
				Debug.Assert(keyId + 1 < (int)_matrices.Count);
#end

        var current = _matrices[keyId];
        var next = _matrices[keyId + 1];
        var ratio = current.timetable < next.timetable ? (t - current.timetable) / (next.timetable - current.timetable) : 0.0 ;

        return TimelineLookup.interpolate(current.mat4, next.mat4, ratio);
    }


    private function initializeMatrixTimetable(timetable:Array<Int>, matrices:Array<Mat4>) {
        if (timetable.length == 0) {
            throw ("timetable");
        }
        if (matrices.length == 0) {
            throw ("matrices");
        }
        if (timetable.length != matrices.length) {
            throw ("The number of keys must match in both the 'timetable' and 'matrices' parameters.");
        }

        var numKeys = timetable.length;

        _matrices = [for (i in 0...numKeys)new TimelineLookup()];

        for (keyId in 0...numKeys) {
            _matrices[keyId].timetable = timetable[keyId];
            _matrices[keyId].mat4 = matrices[keyId];
        }
        _matrices.sort(function(a:TimelineLookup, b:TimelineLookup) {
            return a.timetable - b.timetable;
        });
    }

    override public function dispose():Void {
    }

}
