package minko.render;
@:enum abstract Priority(Float) from Float to Float {
    static public var FIRST = 4000.0;
    static public var BACKGROUND = 3000.0;
    static public var OPAQUE = 2000.0;
    static public var TRANSPARENT = 1000.0;
    static public var LAST = 0.0;


}
