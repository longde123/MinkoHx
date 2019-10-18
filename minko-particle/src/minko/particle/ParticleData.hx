package minko.particle;
class ParticleData {
    public var alive(get, null):Bool;

    public var x:Float;
    public var y:Float;
    public var z:Float;

    public var oldx:Float;
    public var oldy:Float;
    public var oldz:Float;

    public var startvx:Float;
    public var startvy:Float;
    public var startvz:Float;

    public var startfx:Float;
    public var startfy:Float;
    public var startfz:Float;

    public var r:Float;
    public var g:Float;
    public var b:Float;

    public var size:Float;

    public var rotation:Float;
    public var startAngularVelocity:Float;

    public var lifetime:Float;
    public var timeLived:Float;

    public var spriteIndex:Float;

    function get_alive() {
        return timeLived < lifetime;
    }

    public function kill() {
        timeLived = lifetime;
    }

    public function new() {
        //alive (false),
        this.x = 0;
        this.y = 0;
        this.z = 0;
        this.startvx = 0;
        this.startvy = 0;
        this.startvz = 0;
        this.startfx = 0;
        this.startfy = 0;
        this.startfz = 0;
        this.r = 1;
        this.g = 1;
        this.b = 1;
        this.size = 1;
        this.rotation = 0;
        this.lifetime = 0;
        this.timeLived = 0;
        this.spriteIndex = 0;

    }
}
