package minko.component;
import glm.Vec3;
import minko.data.Provider;
class AbstractLight extends AbstractRootDataComponent {


    private var _color:Vec3;

    public var data(get, null):Provider;

    function get_data() {
        return provider;
    }

    public override function dispose() {
        super.dispose();
    }

    public var color(get, set):Vec3;

    function get_color() {
        return _color;
    }

    function set_color(value) {
        if (value != _color) {
            _color = value;
            data.set("color", _color);
        }

        return value;
    }

    override function get_layoutMask() {
        return super.layoutMask;
    }

    override function set_layoutMask(value) {
        data.set("layoutMask", value);
        super.layoutMask = (value);
        return value;
    }

    public function new(collectionName) {
        super(collectionName);
        this._color = new Vec3(1.0, 1.0, 1.0);
        data.set("color", _color);
    }
}
