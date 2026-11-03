package minko.render.light;

class LightSet {
    public var lights:Array<Light>;

    public function new() {
        lights = [];
    }

    public function add(light:Light):Light {
        lights.push(light);
        return light;
    }

    public function clear():Void {
        lights.resize(0);
    }

    public var count(get, null):Int;

    function get_count():Int {
        return lights.length;
    }
}
