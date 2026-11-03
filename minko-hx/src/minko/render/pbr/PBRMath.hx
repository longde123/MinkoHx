package minko.render.pbr;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;

/**
 * Small math helpers shared by the PBR renderers.
 */
class PBRMath {
    public static function writeVec3(v:Vec3, out:Array<Float>):Void {
        out[0] = v.x;
        out[1] = v.y;
        out[2] = v.z;
    }

    public static function writeVec4(v:Vec4, out:Array<Float>):Void {
        out[0] = v.x;
        out[1] = v.y;
        out[2] = v.z;
        out[3] = v.w;
    }

    public static function writeMat4(m:Mat4, out:Array<Float>):Void {
        // Column-major, matching Mat4.toFloatArray() and OpenGL.
        out[0] = m.r0c0;
        out[1] = m.r1c0;
        out[2] = m.r2c0;
        out[3] = m.r3c0;
        out[4] = m.r0c1;
        out[5] = m.r1c1;
        out[6] = m.r2c1;
        out[7] = m.r3c1;
        out[8] = m.r0c2;
        out[9] = m.r1c2;
        out[10] = m.r2c2;
        out[11] = m.r3c2;
        out[12] = m.r0c3;
        out[13] = m.r1c3;
        out[14] = m.r2c3;
        out[15] = m.r3c3;
    }

    /**
     * Computes the normal matrix for a model matrix: transpose(inverse(world)).
     *
     * Using the model matrix directly (as the early implementations did) is
     * only correct for uniform scale plus rotation; under non-uniform scale it
     * skews normals so lighting picks the wrong hemisphere.
     *
     * Singular matrices (for example a node with a zero scale) cannot be
     * inverted; the model matrix is copied through instead of throwing.
     */
    public static function normalMatrix(world:Mat4, dest:Mat4):Mat4 {
        var det = Mat4.determinant(world);
        if (det > -1e-8 && det < 1e-8) {
            return Mat4.copy(world, dest);
        }
        // invert/transpose both support in-place operation, so a per-item
        // normal matrix costs no allocation.
        Mat4.invert(world, dest);
        return Mat4.transpose(dest, dest);
    }
}
