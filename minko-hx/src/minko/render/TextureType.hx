package minko.render;
@:expose("minko.render.TextureType")
@:enum abstract TextureType(Int) from Int to Int {
    var Texture2D = 0;
    var CubeTexture = 1;
}
