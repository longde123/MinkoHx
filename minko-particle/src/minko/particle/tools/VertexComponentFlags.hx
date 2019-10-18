package minko.particle.tools;
@:enum abstract VertexComponentFlags(Int) from Int to Int {
    var DEFAULT = 0x0;
    var COLOR = 0x1;
    var SIZE = (0x1 << 1);
    var TIME = (0x1 << 2);
    var OLD_POSITION = (0x1 << 3);
    var ROTATION = (0x1 << 4);
    var ANG_VELOCITY = (0x1 << 5);
    var SPRITE_INDEX = (0x1 << 6);
}
