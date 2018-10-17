package minko.component;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.utils.MathUtil;
class SpotLight extends AbstractDiscreteLight {
    public static inline var PI = 3.141592653589793 ;

    public static function create(diffuse = 1.0, specular = 1.0, innerAngleRadians = PI * 0.20, outerAngleRadians = PI * 0.25, attenuationConstant = -1.0, attenuationLinear = -1.0, attenuationQuadratic = -1.0):SpotLight {
        return new SpotLight(diffuse, specular, innerAngleRadians, outerAngleRadians, attenuationConstant, attenuationLinear, attenuationQuadratic);
    }

    override public function clone(option:CloneOption) {
        var light = create().copyFrom(this, option);

        return light;
    }

    public var innerConeAngle(get, set):Float;

    function get_innerConeAngle() {
        return Math.acos(data.get("cosInnerConeAngle"));
    }

    function set_innerConeAngle(radians) {
        data.set("cosInnerConeAngle", Math.cos(Math.max(0.0, Math.min(0.5 * Math.PI, radians))));

        return radians;
    }

    public var outerConeAngle(get, set):Float;

    function get_outerConeAngle() {
        return Math.acos(data.get("cosOuterConeAngle"));
    }

    function set_outerConeAngle(radians) {
        data.set("cosOuterConeAngle", Math.cos(Math.max(0.0, Math.min(0.5 * Math.PI, radians))));

        return radians;
    }

    public var attenuationEnabled(get, null):Bool;

    function get_attenuationEnabled() {
        var coef = attenuationCoefficients;

        return !(coef.x < 0.0 || coef.y < 0.0 || coef.z < 0.0);
    }

    public var attenuationCoefficients(get, set):Vec3;

    function get_attenuationCoefficients() {
        return data.get("attenuationCoeffs");
    }

    public function setAttenuationCoefficients(constant, linear, quadratic) {
        return attenuationCoefficients = (new Vec3(constant, linear, quadratic));
    }

    function set_attenuationCoefficients(value) {
        data.set("attenuationCoeffs", value);

        return value;
    }

    public var position(get, null):Vec3;

    function get_position() {
        return data.get("position");
    }

    override public function updateModelToWorldMatrix(modelToWorld:Mat4) {

        var tmp2:Vec3 = Vec3.normalize(MathUtil.mat4_mat3(modelToWorld) * new Vec3(0.0, 0.0, -1.0), new Vec3());
        data.set("position", MathUtil.vec4_vec3(modelToWorld * (new Vec4(0.0, 0.0, 0.0, 1.0))))
        .set("direction", tmp2);
    }

    public function new(diffuse, specular, innerAngleRadians, outerAngleRadians, attenuationConstant, attenuationLinear, attenuationQuadratic) {
        super("spotLight", diffuse, specular);
        updateModelToWorldMatrix(Mat4.identity(new Mat4()));

        attenuationCoefficients = (new Vec3(attenuationConstant, attenuationLinear, attenuationQuadratic));
        innerConeAngle = (innerAngleRadians);
        outerConeAngle = (outerAngleRadians);
    }

    private function copyFrom(spotlight:SpotLight, option:CloneOption) {
        //: base("spotLights", spotlight.diffuse(), spotlight.specular())
        data.set("diffuse", spotlight.diffuse).set("specular", spotlight.specular);
        updateModelToWorldMatrix(Mat4.identity(new Mat4()));

        var test = spotlight.attenuationCoefficients;

        data.set("attenuationCoeffs", spotlight.attenuationCoefficients);
        data.set("cosInnerConeAngle", spotlight.innerConeAngle);
        data.set("cosOuterConeAngle", spotlight.outerConeAngle);
        return this;
    }

}
