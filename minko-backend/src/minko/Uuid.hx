package minko;
using Std;
using EReg;
using StringTools;
@:expose("minko.Uuid")
class Uuid {

    private inline static var MPM = 2147483647.0;
    private inline static var MINSTD = 16807.0;

    private static var CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".split("");

    // Same Park-Miller seed/step as minko.math.Random, inlined so minko.Uuid can
    // stay in minko-core while Random lives in minko-hx.
    private static function makeSeed():Int {
        return Math.floor(Math.random() * MPM);
    }

    private inline static function nextParkMiller(seed:Int):Int {
        return Math.floor((seed * MINSTD) % MPM);
    }

    public static function getUuid() {
        var seed = makeSeed();
        var chars = CHARS, uuid = new Array(), rnd = 0, r;
        for (i in 0...36) {
            if (i == 8 || i == 13 || i == 18 || i == 23) {
                uuid[i] = "-";
            } else if (i == 14) {
                uuid[i] = "4";
            } else {
                if (rnd <= 0x02) rnd = 0x2000000 + Math.floor((seed = nextParkMiller(seed)) * 0x1000000) | 0;
                r = rnd & 0xf;
                rnd = rnd >> 4;
                uuid[i] = chars[(i == 19) ? (r & 0x3) | 0x8 : r];
            }
        }
        return uuid.join("");
    }
}
@:expose("minko.Has_uuid")
class Has_uuid {
    public function new() {

    }
    public var uuid(get, set):String ;
    var _uuid:String;

    function set_uuid(value) {
        _uuid = (value);
        return value;
    }

    function get_uuid() {
        return _uuid;
    }
}
@:expose("minko.Enable_uuid")
class Enable_uuid extends Has_uuid {


    public function enable_uuid() {
        _uuid = Uuid.getUuid();
    }

}
