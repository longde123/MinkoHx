package assimp.format;
/**
         * Created by elect on 14/11/2016.
         */

import glm.Mat4;
import glm.Quat;
import glm.Vec2;
import glm.Mat4;
import glm.Mat3;
import glm.Vec4;
import glm.Vec3;
typedef Ai_real = Float;
typedef AiVector4D = Vec4;
typedef AiVector3D = Vec3;
typedef AiColor3D = Vec3;
typedef AiColor4D = Vec4;
typedef AiVector2D = Vec2;
typedef AiQuaternion = Quat;
typedef AiMatrix4x4 = Mat4;
typedef AiMatrix3x3 = Mat3;
/*
*

			_r0c0:Float = 0, _r0c1:Float = 0, _r0c2:Float = 0,
            _r1c0:Float = 0, _r1c1:Float = 0, _r1c2:Float = 0,
            _r2c0:Float = 0, _r2c1:Float = 0, _r2c2:Float = 0


aiMatrix4x4t (  TReal _a1, TReal _a2, TReal _a3, TReal _a4,
TReal _b1, TReal _b2, TReal _b3, TReal _b4,
TReal _c1, TReal _c2, TReal _c3, TReal _c4,
TReal _d1, TReal _d2, TReal _d3, TReal _d4);
            */
class AiDefines {

/// <summary>
/// Default value for <see cref="AiConfigs.AI_CONFIG_PP_SLM_TRIANGLE_LIMIT"/>.
/// </summary>
    public static var AI_SLM_DEFAULT_MAX_TRIANGLES = 1000000;

    /// <summary>
    /// Default value for <see cref="AiConfigs.AI_CONFIG_PP_SLM_VERTEX_LIMIT"/>.
    /// </summary>
    public static var AI_SLM_DEFAULT_MAX_VERTICES = 1000000;

    /// <summary>
    /// Default value for <see cref="AiConfigs.AI_CONFIG_PP_LBW_MAX_WEIGHTS"/>.
    /// </summary>
    public static var AI_LBW_MAX_WEIGHTS = 0x4;

    /// <summary>
    /// Default value for <see cref="AiConfigs.AI_CONFIG_PP_ICL_PTCACHE_SIZE"/>.
    /// </summary>
    public static var PP_ICL_PTCACHE_SIZE = 12;

    /// <summary>
    /// Default value for <see cref="AiConfigs.AI_CONFIG_PP_TUV_EVALUATE"/>
    /// </summary>
//todo
// public const int AI_UVTRAFO_ALL = (int) (UVTransformFlags.Rotation | UVTransformFlags.Scaling | UVTransformFlags.Translation);


    /// <summary>
    /// Defines the maximum number of indices per face (polygon).
    /// </summary>
    public static var AI_MAX_FACE_INDICES = 0x7fff;

    /// <summary>
    /// Defines the maximum number of bone weights.
    /// </summary>
    public static var AI_MAX_BONE_WEIGHTS = 0x7fffffff;

    /// <summary>
    /// Defines the maximum number of vertices per mesh.
    /// </summary>
    public static var AI_MAX_VERTICES = 0x7fffffff;

    /// <summary>
    /// Defines the maximum number of faces per mesh.
    /// </summary>
    public static var AI_MAX_FACES = 0x7fffffff;

    /// <summary>
    /// Defines the maximum number of vertex color sets per mesh.
    /// </summary>
    public static var AI_MAX_NUMBER_OF_COLOR_SETS = 0x8;

    /// <summary>
    /// Defines the maximum number of texture coordinate sets (UV(W) channels) per mesh.
    /// </summary>
    public static var AI_MAX_NUMBER_OF_TEXTURECOORDS = 0x8;

    /// <summary>
    /// Defines the default bone count limit.
    /// </summary>
    public static var AI_SBBC_DEFAULT_MAX_BONES = 60;

    /// <summary>
    /// Defines the deboning threshold.
    /// </summary>
    public static var AI_DEBONE_THRESHOLD = 1.0;


    /// <summary>
    /// Defines the maximum length of a string used in AiString.
    /// </summary>
    public static var MAX_LENGTH = 1024;


    /// <summary>
    /// Defines the default color material.
    /// </summary>
    public static var AI_DEFAULT_MATERIAL_NAME = "DefaultMaterial";

    /// <summary>
    /// Defines the default textured material (if the meshes have UV coords).
    /// </summary>
    public static var AI_DEFAULT_TEXTURED_MATERIAL_NAME = "TexturedDefaultMaterial";

}
class Defs {


/* To avoid running out of memory
 * This can be adjusted for specific use cases
 * It's NOT a total limit, just a limit for individual allocations
 */
    public static function AI_MAX_ALLOC(size:Int) return (256 * 1024 * 1024) / size;
/** Consider using extension property Float.rad */
    public static function AI_DEG_TO_RAD(x:Float) return ((x) * 0.0174532925);
/** Consider using extension property Float.deg */
    public static function AI_RAD_TO_DEG(x:Float) return ((x) * 57.2957795);

    public static function is_special_float(f:Float):Bool {
        return f == (1 << 8) - 1;
    }

    public static function distance(this1:Vec3, other:Vec3):Float {
        return Math.sqrt(Math.pow(this1.x + other.x, 2.0)
        + Math.pow(this1.y + other.y, 2.0)
        + Math.pow(this1.z + other.z, 2.0));
    }

    public static function squareLength(this1:Vec3) {
        return Math.sqrt(Math.pow(this1.x, 2.0)
        + Math.pow(this1.y, 2.0)
        + Math.pow(this1.z, 2.0));
    }

/* This is PI. Hi PI. */
    public static var AI_MATH_TWO_PI = Math.PI * 2;
    public static var AI_MATH_TWO_PIf = Math.PI * 2;
    public static var AI_MATH_HALF_PI = Math.PI;


    /// <summary>
    /// Constructs a new Quaternion from a rotation matrix.
    /// </summary>
    /// <param name="matrix">Rotation matrix to create the Quaternion from.</param>
    static function toQuaternion(matrix:AiMatrix3x3) {

    }

    public static function decompose(this1:Mat4, pScaling:AiVector3D, pRotation:AiQuaternion, pPosition:AiVector3D) {

    }

    static public function mat4_cast(q:Quat):Mat4 {
        var result = new Mat4();
        var qxx:Float = (q.x * q.x);
        var qyy:Float = (q.y * q.y);
        var qzz:Float = (q.z * q.z);
        var qxz:Float = (q.x * q.z);
        var qxy:Float = (q.x * q.y);
        var qyz:Float = (q.y * q.z);
        var qwx:Float = (q.w * q.x);
        var qwy:Float = (q.w * q.y);
        var qwz:Float = (q.w * q.z);
        result.r0c0 = 1 - 2 * (qyy + qzz);
        result.r1c0 = 2 * (qxy + qwz);
        result.r2c0 = 2 * (qxz - qwy);

        result.r0c1 = 2 * (qxy - qwz);
        result.r1c1 = 1 - 2 * (qxx + qzz);
        result.r2c1 = 2 * (qyz + qwx);

        result.r0c2 = 2 * (qxz + qwy);
        result.r1c2 = 2 * (qyz - qwx);
        result.r2c2 = 1 - 2 * (qxx + qyy);
        return result;
    }

    static public function mat3_cast(q:Quat):Mat3 {
        var result = new Mat3();
        var qxx:Float = (q.x * q.x);
        var qyy:Float = (q.y * q.y);
        var qzz:Float = (q.z * q.z);
        var qxz:Float = (q.x * q.z);
        var qxy:Float = (q.x * q.y);
        var qyz:Float = (q.y * q.z);
        var qwx:Float = (q.w * q.x);
        var qwy:Float = (q.w * q.y);
        var qwz:Float = (q.w * q.z);
        result.r0c0 = 1 - 2 * (qyy + qzz);
        result.r1c0 = 2 * (qxy + qwz);
        result.r2c0 = 2 * (qxz - qwy);

        result.r0c1 = 2 * (qxy - qwz);
        result.r1c1 = 1 - 2 * (qxx + qzz);
        result.r2c1 = 2 * (qyz + qwx);

        result.r0c2 = 2 * (qxz + qwy);
        result.r1c2 = 2 * (qyz - qwx);
        result.r2c2 = 1 - 2 * (qxx + qyy);
        return result;
    }
    static public function slerp(x:AiQuaternion, y:AiQuaternion, a:Float):AiQuaternion {
        var z = y;
        var cosTheta = Quat.dot(x, y);
        if (cosTheta < 0) {
            z.x = -y.x;
            z.y = -y.y;
            z.z = -y.z;
            z.w = -y.w;
            cosTheta = -cosTheta;
        }
        return if (cosTheta > 1 - Defs.epsilon) {
            Quat.lerp(x, z, a, new Quat());
        }
        else {
            var angle = Math.acos(cosTheta);
            var sclp = Math.sin((1.0 - a) * angle) / Math.sin(angle) ;
            var sclq = Math.sin(a * angle) / Math.sin(angle) ;
            var o = new Quat();
            o.x = sclp * x.x + sclq * z.x;
            o.y = sclp * x.y + sclq * z.y;
            o.z = sclp * x.z + sclq * z.z;
            o.w = sclp * x.w + sclq * z.w;
            o;
        }
    }


    public static var epsilon = 1.401298E-45;

    public static function isBlack(this1:Vec3) return Math.abs(this1.x) < epsilon && Math.abs(this1.y) < epsilon && Math.abs(this1.z) < epsilon;

}
