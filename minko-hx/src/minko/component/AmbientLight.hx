package minko.component;
@:expose("minko.component.AmbientLight")
class AmbientLight extends AbstractLight {

    private var _ambient:Float;

    public static function create(ambient = .2):AmbientLight {
        return new AmbientLight(ambient);
    }

    override public function clone(option:CloneOption) {
        var al = create().copyFrom(this, option);

        return cast al;
    }
    public var ambient(get, set):Float;

    function get_ambient() {
        return _ambient;
    }

    function set_ambient(ambient) {
        _ambient = ambient;
        data.set("ambient", ambient);

        return ambient;
    }

    public function new(ambient = .2) {
        super("ambientLight");
        this._ambient = ambient;
        data.set("ambient", ambient);
    }

    public function copyFrom(ambientLight:AmbientLight, option:CloneOption) {
        this._ambient = ambientLight._ambient;
        data.set("ambient", ambientLight._ambient);
        return this;
    }
}
