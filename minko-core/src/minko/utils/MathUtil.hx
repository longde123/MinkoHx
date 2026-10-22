package minko.utils;
import glm.Mat3;
import glm.Mat4;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import minko.math.Random;
class MathUtil {
    inline public static var pi = 3.14159265;
    inline public static var half_pi = 1.57079637;


    inline public static function lerp(from:Float, to:Float, t:Float) {
        return from + (to - from) * clamp(t, 0, 1);
    }
    inline public static function fract(  x:Float)
    {
        return x - Math.floor(x);
    }

    inline public static function std_copy(s:Array<Float>, begin, size, d:Array<Float>, index) {
        var g = 0;
        for (k in begin...size) {
            d[index + g] = s[k];
            g++;
        }
    }

    public static function make_vec2(a:Array<Float>, b :Int) {
        return new Vec2(a[b],a[b+1]);
    }
    public static function make_vec3(a:Array<Float>, b :Int) {
        return new Vec3(a[b],a[b+1],a[b+2]);
    }
    public static function make_vec4(a:Array<Float>, b :Int) {
        return new Vec4(a[b],a[b+1],a[b+2],a[b+3]);
    }


    inline public static function isEpsilonEqual(a, b, EPSILON = 1.19209290e-007) {
        return (Math.abs(a - b) < EPSILON);
    }

    inline public static function isEpsilonEqualVec3(a:Vec3, b:Vec3, EPSILON = 1.19209290e-007) {
        return (Math.abs(Vec3.subtractVec(a, b, new Vec3()).lengthSquared()) < EPSILON);
    }


    inline public static function linearRand(from:Float, to:Float) {
        return Random.toFloatRange(Random.makeRandomSeed(), from, to) ;
    }

    public static function sphericalRand(Radius) {
        var z = linearRand(-1, 1);
        var a = linearRand(0, 6.283185307179586476925286766559);

        var r = Math.sqrt((1) - z * z);

        var x = r * Math.cos(a);
        var y = r * Math.sin(a);

        return new Vec3(x, y, z) * Radius;

    }

    public static function diskRand(Radius:Float) {
        var Result:Vec2 = null;
        var LenRadius:Float = 0;
        do {
            Result = new Vec2(linearRand(-Radius, Radius), linearRand(-Radius, Radius));
            LenRadius = Result.length();
        }
        while (LenRadius > Radius);

        return Result;
    }

    inline public static function rand01() {
        return Math.random() ;
    }

    inline public static function clamp(x, minVal, maxVal) {
        return Math.min(Math.max(x, minVal), maxVal);
    }




    inline public static function mat4_mat3(a:Mat4) {
        return new Mat3(a.r0c0, a.r0c1, a.r0c2,
        a.r1c0, a.r1c1, a.r1c2,
        a.r2c0, a.r2c2, a.r2c2);
    }

    inline public static function vec4_vec3(v:Vec4) {
        return new Vec3(v.x, v.y, v.z);
    }

    inline public static function vec3_vec4(v:Vec3, z:Float) {
        return new Vec4(v.x, v.y, v.z, z);
    }


    inline public static function mat4_copyFrom(a:Mat4, b:Mat4) {
        Mat4.copy(b, a);
    }

     public static function getp2(x) {
        var tmp = x;
        var p = 0;
        while ((tmp >>= 1)>0) {
            ++p;
        }


        return p;
    }

    inline public static function mix(v:Float, n:Float, rt:Float) {
        return n * rt + v * (1 - rt);
    }

    inline public static function clp2(x) {
        x = x - 1;
        x = x | (x >> 1);
        x = x | (x >> 2);
        x = x | (x >> 4);
        x = x | (x >> 8);
        x = x | (x >> 16);

        return x + 1;
    }

    inline public static function rgba(x) {
        return new Vec4(
        ((x >> 24) & 0xff) / 255,
        ((x >> 16) & 0xff) / 255,
        ((x >> 8) & 0xff) / 255,
        (x & 0xff) / 255
        );
    }


    inline public static function vec2_equals(a:Vec2, b:Vec2):Bool {
        return a.equals(b);
    }

    inline public static function vec3_equals(a:Vec3, b:Vec3):Bool {
        return a.equals(b);
    }

    inline public static function vec4_equals(a:Vec4, b:Vec4):Bool {
        return a.equals(b);
    }

    inline public static function vec3_max(a:Vec3, b:Vec3):Vec3 {
        //todo
        return a ;
    }


}
