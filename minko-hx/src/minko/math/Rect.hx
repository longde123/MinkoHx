package minko.math;
class Rect {
    public var x:Float;
    public var y:Float;
    public var width:Float;
    public var height:Float;
    public function new(x:Float=0,y:Float=0,w:Float=0,h:Float=0) {
        this.x=x;
        this.y=y;
        this.width=w;
        this.height=h;
    }

    public function clone():Rect {
        var c=new Rect();
        c.x=x;
        c.y=y;
        c.width=width;
        c.height=height;
        return c;
    }
}
