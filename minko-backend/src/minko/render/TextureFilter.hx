package minko.render;
@:expose("minko.render.TextureFilter")
@:enum abstract TextureFilter(Int) from Int to Int {
    var NEAREST = 0;
    var LINEAR = 1;
}
