package minko.render;
@:expose("minko.render.TriangleCulling")
@:enum abstract TriangleCulling(Int) from Int to Int {
    var NONE = 0;
    var FRONT = 1;
    var BACK = 2;
    var BOTH = 3;
}
