package minko.data;
import glm.Mat4;
import glm.Vec4;
import glm.Vec2;
import glm.Vec3;
class UnsafePointerArrayBuffer<R>{
    public var applyFunc:Dynamic->Array<R>;
    public var arrayBuffer:Array<R>;//ArrayBuffer
    public function new():Void {
        
    }
    public function applyDone(value:Dynamic){
        arrayBuffer=applyFunc(value);
    }
    static public function vecInts1(dataValue:Int) {
        return [dataValue];
    }

    static public function vecInts2(dataValue:Vec2) {
        return  dataValue.toFloatArray().map(function(v) return Math.floor(v));
    }

    static public function vecInts3(dataValue:Vec3) {
        return  dataValue.toFloatArray().map(function(v) return Math.floor(v));
    }

    static public function vecInts4(dataValue:Vec4) {
        return dataValue.toFloatArray().map(function(v) return Math.floor(v));
    }

    static public function vecFloats1(dataValue:Float) {
        return [dataValue];
    }

    static public function vecFloats2(dataValue:Vec2) {
        return  dataValue.toFloatArray();
    }

    static public function vecFloats3(dataValue:Vec3) {
        return dataValue.toFloatArray();
    }

    static public function vecFloats4(dataValue:Vec4) {
        return dataValue.toFloatArray();
    }

    static public function matFloats(dataValue:Mat4) {
        return dataValue.toFloatArray();
    }


    static public function vecsInts1(dataValue:Array<Int>) {
        return dataValue;
    }

    static public function vecsInts2(dataValue:Array<Vec2>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecInts2(d));
        }
        return tmp;
    }

    static public function vecsInts3(dataValue:Array<Vec3>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecInts3(d));
        }
        return tmp;
    }

    static public function vecsInts4(dataValue:Array<Vec4>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecInts4(d));
        }
        return tmp;
    }

    static public function vecsFloats1(dataValue:Array<Float>) {
        return dataValue;
    }

    static public function vecsFloats2(dataValue:Array<Vec2>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecFloats2(d));
        }
        return tmp;
    }

    static public function vecsFloats3(dataValue:Array<Vec3>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecFloats3(d));
        }
        return tmp;
    }

    static public function vecsFloats4(dataValue:Array<Vec4>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(vecFloats4(d));
        }
        return tmp;
    }

    static public function matsFloats(dataValue:Array<Mat4>) {
        var tmp = [];
        for (d in dataValue) {
            tmp = tmp.concat(matFloats(d));
        }
        return tmp;
    }
}
class UnsafePointer<T> {
    public var value(get,set):T;
    var v:T;
    public function arrayBuffer() :Dynamic {
        return buffer.arrayBuffer;
    }

    public var buffer:Null<UnsafePointerArrayBuffer<Dynamic>>;

    function set_value(v){
        this.v=v;
        if(buffer!=null){
            buffer.applyDone(v);
        }
        return this.v;
    }
    function get_value(){
       return this.v ;
    }
    public function new(d:T):Void {
        v=d;
    }
}
