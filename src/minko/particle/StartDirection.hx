package minko.particle;
@:enum abstract StartDirection(Int) from Int to Int {
    var NONE = 0;
    var SHAPE = 1;
    var RANDOM = 2;
    var UP = 3;
    var OUTWARD = 4;
}
