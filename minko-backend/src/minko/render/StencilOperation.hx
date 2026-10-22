package minko.render;
@:expose("minko.render.StencilOperation")
@:enum abstract StencilOperation(Int) from Int to Int {
    var KEEP = 0;
    var ZERO = 1;
    var REPLACE = 2;
    var INCR = 3;
    var INCR_WRAP = 4;
    var DECR = 5;
    var DECR_WRAP = 6;
    var INVERT = 7;
    var UNSET = 8;
}
