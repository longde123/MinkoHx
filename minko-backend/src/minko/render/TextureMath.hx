package minko.render;

/**
 * Power-of-two helpers used by the texture resources.
 *
 * Kept in the backend so texture sizes can be computed without depending on
 * `minko.utils.MathUtil` (which lives in `minko-hx`).
 */
class TextureMath {
    public static function getp2(x:Int):Int {
        var tmp = x;
        var p = 0;
        while ((tmp >>= 1) > 0) {
            ++p;
        }

        return p;
    }

    inline public static function clp2(x:Int):Int {
        x = x - 1;
        x = x | (x >> 1);
        x = x | (x >> 2);
        x = x | (x >> 4);
        x = x | (x >> 8);
        x = x | (x >> 16);

        return x + 1;
    }
}
