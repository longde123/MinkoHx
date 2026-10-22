package minko;
import minko.math.Random;
using Std;
using EReg;
using StringTools;
@:expose("minko.Uuid")
class Uuid {

    private static var CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".split("");

    public static function getUuid() {
        var seed = Random.makeRandomSeed();
        var chars = CHARS, uuid = new Array(), rnd = 0, r;
        for (i in 0...36) {
            if (i == 8 || i == 13 || i == 18 || i == 23) {
                uuid[i] = "-";
            } else if (i == 14) {
                uuid[i] = "4";
            } else {
                if (rnd <= 0x02) rnd = 0x2000000 + Math.floor((seed = Random.nextParkMiller(seed)) * 0x1000000) | 0;
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
