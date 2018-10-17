package minko.render;
@:enum abstract CompareMode(Int) from Int to Int {
    var ALWAYS = 0;
    var EQUAL = 1;
    var GREATER = 2;
    var GREATER_EQUAL = 3;
    var LESS = 4;
    var LESS_EQUAL = 5;
    var NEVER = 6;
    var NOT_EQUAL = 7;
    var UNSET = 8;
}
