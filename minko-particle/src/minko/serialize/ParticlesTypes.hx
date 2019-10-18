package minko.serialize;
@:enum abstract SamplerId(Int) from Int to Int {
    var UNKNOWN = 0;
    var CONSTANT_COLOR = 2;
    var CONSTANT_NUMBER = 1;
    var LINEAR_COLOR = 3;
    var LINEAR_NUMBER = 4;
    var RANDOM_COLOR = 6;
    var RANDOM_NUMBER = 7;
}
@:enum abstract EmitterShapeId(Int) from Int to Int {
    var UNKNOWN = 0;
    var CYLINDER = 1;
    var CONE = 2;
    var SPHERE = 3;
    var POINT = 4;
    var BOX = 5;
}
@:enum abstract ModifierId(Int) from Int to Int {
    var START_COLOR = 0;
    var START_FORCE = 1;
    var START_ROTATION = 2;
    var START_SIZE = 3;
    var START_SPRITE = 4;
    var START_VELOCITY = 5;
    var START_ANGULAR_VELOCITY = 12;
    var COLOR_BY_SPEED = 6;
    var COLOR_OVER_TIME = 7;
    var FORCE_OVER_TIME = 8;
    var SIZE_BY_SPEED = 9;
    var SIZE_OVER_TIME = 10;
    var VELOCITY_OVER_TIME = 11;
}

class ParticlesTypes {
    public function new() {
    }
}
