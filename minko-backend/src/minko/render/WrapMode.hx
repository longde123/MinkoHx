package minko.render;
@:expose("minko.render.WrapMode")
@:enum abstract WrapMode(Int) from Int to Int {
    var CLAMP = 0;
    var REPEAT = 1;
}
