package minko.scene;
typedef Layout = Int;
@:expose("minko.scene.BuiltinLayout")
@:enum abstract BuiltinLayout(Layout) from Layout to Layout{
    var DEFAULT = 1 << 0;
    var DEBUG_ONLY = 1 << 1;
    var STATIC = 1 << 2;
    var IGNORE_RAYCASTING = 1 << 3;
    var IGNORE_CULLING = 1 << 4;
    var HIDDEN = 1 << 5;
    var PICKING = 1 << 6;
    var INSIDE_FRUSTUM = 1 << 7;
    var MINOR_OBJECT = 1 << 8;
    var PICKING_DEPTH = 1 << 9;
    var CAST_SHADOW = 1 << 10;


}
@:expose("minko.scene.LayoutMask")
@:enum abstract LayoutMask(Layout) from Layout to Layout{
    var NOTHING = 0;
    var COLLISIONS_DYNAMIC_DEFAULT = EVERYTHING & ~BuiltinLayout.STATIC;
    var EVERYTHING = 0xffffffff;
}