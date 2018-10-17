package minko.render;
@:enum abstract Source(Int) from Int to Int {
    var ZERO = 1 << 0;
    var ONE = 1 << 1;
    var SRC_COLOR = 1 << 2;
    var ONE_MINUS_SRC_COLOR = 1 << 3;
    var SRC_ALPHA = 1 << 4;
    var ONE_MINUS_SRC_ALPHA = 1 << 5;
    var DST_ALPHA = 1 << 6;
    var ONE_MINUS_DST_ALPHA = 1 << 7;
}
@:enum abstract Destination(Int) from Int to Int {
    var ZERO = 1 << 8;
    var ONE = 1 << 9;
    var DST_COLOR = 1 << 10;
    var ONE_MINUS_DST_COLOR = 1 << 11;
    var SRC_ALPHA_SATURATE = 1 << 12;
    var ONE_MINUS_SRC_ALPHA = 1 << 13;
    var DST_ALPHA = 1 << 14;
    var ONE_MINUS_DST_ALPHA = 1 << 15;
}
@:enum abstract Mode(Int) from Int to Int {
    var DEFAULT = Source.ONE | Destination.ZERO;
    var ALPHA = Source.SRC_ALPHA | Destination.ONE_MINUS_SRC_ALPHA;
    var ADDITIVE = Source.SRC_ALPHA | Destination.ONE;
}
class Blending {
    public function new() {
    }
}
