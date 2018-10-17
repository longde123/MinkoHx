package minko.component;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
class PointLight extends AbstractDiscreteLight {
    private var _attenuationCoeffs:Vec3;
    private var _worldPosition:Vec3;

    public static function create(diffuse = 1.0, specular = 1.0, attenuationConstant = -1.0, attenuationLinear = -1.0, attenuationQuadratic = -1.0):PointLight {
        return new PointLight(diffuse, specular, attenuationConstant, attenuationLinear, attenuationQuadratic);
    }

    override public function clone(option:CloneOption) {
        var light = create().copyFrom(this, option);
        return light;
    }

    public var attenuationEnabled(get, null):Bool;

    function get_attenuationEnabled() {
        return !(_attenuationCoeffs.x < 0.0 || _attenuationCoeffs.y < 0.0 || _attenuationCoeffs.z < 0.0);
    }

    public var attenuationCoefficients(get, set):Vec3;

    function get_attenuationCoefficients() {
        return _attenuationCoeffs;
    }

    public function setAttenuationCoefficients(constant, linear, quadratic) {
        return attenuationCoefficients = (new Vec3(constant, linear, quadratic));
    }

    function set_attenuationCoefficients(value) {
        data.set("attenuationCoeffs", _attenuationCoeffs = value);

        return value;
    }

    public var position(get, null):Vec3;

    function get_position() {
        return data.get("position");
    }

    override public function updateModelToWorldMatrix(modelToWorld:Mat4) {
        var tmp:Vec4 = modelToWorld * (new Vec4(0.0, 0.0, 0.0, 1.0));
        data.set("position", new Vec3(tmp.x, tmp.y, tmp.z));
    }

    public function new(diffuse, specular, attenuationConstant, attenuationLinear, attenuationQuadratic) {
        super("pointLight", diffuse, specular);
        this._attenuationCoeffs = new Vec3(attenuationConstant, attenuationLinear, attenuationQuadratic);
        this._worldPosition = new Vec3();
        data.set("attenuationCoeffs", _attenuationCoeffs);
        updateModelToWorldMatrix(Mat4.identity(new Mat4()));
    }

    public function copyFrom(pointLight:PointLight, option:CloneOption) {
        data.set("diffuse", pointLight.diffuse).set("specular", pointLight.specular);
        this._attenuationCoeffs = pointLight.attenuationCoefficients;
        updateModelToWorldMatrix(Mat4.identity(new Mat4()));
        return this;
    }

}
