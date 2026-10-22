package minko.render;
@:expose("minko.render.MipFilter")
@:enum abstract MipFilter(Int) from Int to Int {
    var NONE = 0;
    var NEAREST = 1;
    var LINEAR = 2;
}
