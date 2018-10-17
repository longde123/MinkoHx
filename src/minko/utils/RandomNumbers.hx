package minko.utils;
class RandomNumbers {

    public static var RAND_MAX = 10;

    public static function nextNumber() {


        return MathUtil.rand01();
    }

    public static function nextNumberCeiling(ceiling) {
        return Math.floor(nextNumber() * ceiling);
    }


}