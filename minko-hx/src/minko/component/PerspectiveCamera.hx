package minko.component;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.data.Provider;
import minko.data.Store;
import minko.math.Ray;
import minko.render.AbstractContext;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.utils.MathUtil;
@:expose("minko.component.PerspectiveCamera")
class PerspectiveCamera extends AbstractComponent {
    private var _data:Provider;
    private var _fov:Float;
    private var _aspectRatio:Float;
    private var _zNear:Float;
    private var _zFar:Float;

    private var _view:Mat4;
    private var _projection:Mat4;
    private var _viewProjection:Mat4;
    private var _position:Vec3;
    private var _direction:Vec3;
    private var _postProjection:Mat4;

    private var _modelToWorldChangedSlot:SignalSlot3<Store, Provider, String>;

    public static function create(aspectRatio, fov = .785, zNear = 0.1, zFar = 1000.0, postProjection:Mat4 = null) {
        return new PerspectiveCamera(fov, aspectRatio, zNear, zFar, postProjection == null ? Mat4.identity(new Mat4()) : postProjection);
    }

    // TODO #Clone
    /*
			AbstractComponent::Ptr
			clone(const CloneOption& option);
			*/
    public var fieldOfView(get, set):Float;

    function get_fieldOfView() {
        return _fov;
    }

    function set_fieldOfView(fov) {
        if (fov != _fov) {
            _fov = fov;
            updateProjection(_fov, _aspectRatio, _zNear, _zFar);
        }
        return fov;
    }
    public var aspectRatio(get, set):Float;

    function get_aspectRatio() {
        return _aspectRatio;
    }

    function set_aspectRatio(v) {
        if (v != _aspectRatio) {
            _aspectRatio = v;
            updateProjection(_fov, _aspectRatio, _zNear, _zFar);
        }
        return v;
    }
    public var zNear(get, set):Float;

    function get_zNear() {
        return _zNear;
    }

    function set_zNear(v) {
        if (v != _zNear) {
            _zNear = v;
            updateProjection(_fov, _aspectRatio, _zNear, _zFar);
        }
        return v;
    }
    public var zFar(get, set):Float;

    function get_zFar() {
        return _zFar;
    }

    function set_zFar(v) {
        if (v != _zFar) {
            _zFar = v;
            updateProjection(_fov, _aspectRatio, _zNear, _zFar);
        }
        return v;
    }
    public var data(get, null):Provider;

    function get_data() {
        return _data;
    }
    public var viewMatrix(get, null):Mat4;

    function get_viewMatrix() {
        return _view;
    }
    public var projectionMatrix(get, null):Mat4;

    function get_projectionMatrix() {
        return _projection;
    }
    public var viewProjectionMatrix(get, null):Mat4;

    function get_viewProjectionMatrix() {
        return _viewProjection;
    }


    public function updateProjection(fov, aspectRatio, zNear, zFar) {
        _fov = fov;
        _aspectRatio = aspectRatio;
        _zNear = zNear;
        _zFar = zFar;

        //math
        _projection = _postProjection * (GLM.perspective(fov, aspectRatio, zNear, zFar, new Mat4()));
        _viewProjection = _projection * (_view);

        _data.set("fov", _fov)
        .set("aspectRatio", _aspectRatio)
        .set("zNear", _zNear)
        .set("zFar", _zFar)
        .set("projectionMatrix", _projection)
        .set("worldToScreenMatrix", _viewProjection);
    }

    public function unproject(x:Float, y:Float) {
        var fovDiv2 = _fov * .5 ;
        var dx = Math.tan(fovDiv2) * x * _aspectRatio;
        var dy = -Math.tan(fovDiv2) * y;
        var origin:Vec3 = new Vec3(dx * _zNear, dy * _zNear, -_zNear);
        var direction:Vec3 = new Vec3(dx * _zNear, dy * _zNear, -_zNear) ;
        direction = Vec3.normalize(direction, new Vec3());
        var t:Transform = cast target.getComponent(Transform);
        if (t != null) {
            var tModelToWorld:Mat4 = t.modelToWorldMatrix;
            //math
            var tmp:Vec4 = tModelToWorld * (MathUtil.vec3_vec4(origin, 1));
            origin = MathUtil.vec4_vec3(tmp);
            direction =  (MathUtil.mat4_mat3(tModelToWorld)*direction);
            direction = Vec3.normalize(direction, new Vec3());
        }
        return Ray.createbyVector3(origin, direction);
    }

    public function project(worldPosition:Vec3) {
        var sm:SceneManager = cast target.root.getComponent(SceneManager);
        var context:AbstractContext = sm.assets.context;

        return projectWorldPosition(worldPosition, context.viewportWidth, context.viewportHeight, _view, _viewProjection);
    }

    public static function projectWorldPosition(worldPosition:Vec3, viewportWidth:Int, viewportHeight:Int, viewMatrix:Mat4, viewProjectionMatrix:Mat4) {
        var width = viewportWidth;
        var height = viewportHeight;
        var pos:Vec4 = new Vec4(worldPosition.x, worldPosition.y, worldPosition.z, 1.0 );
        //math
        var vector:Vec4 = viewProjectionMatrix * (pos);

        vector = vector / vector.w;
        pos = (viewMatrix * pos);

        return new Vec3(width * (vector.x + 1.0) * .5, height * (1.0 - ((vector.y + 1.0) * .5)), -pos.z);
    }

    override public function targetAdded(target:Node) {
        target.data.addProvider(_data);
        _modelToWorldChangedSlot = target.data.getPropertyChanged("modelToWorldMatrix").connect(function(s, p, s1) {
            localToWorldChangedHandler(s);
        });

        if (target.data.hasProperty("modelToWorldMatrix"))
            updateMatrices(target.data.get("modelToWorldMatrix"));
    }

    override public function targetRemoved(target:Node) {
        target.data.removeProvider(_data);
    }

    public function new(fov:Float, aspectRatio:Float, zNear:Float, zFar:Float, postPerspective:Mat4) {
        super();
        this._data = Provider.create();
        this._fov = fov;
        this._aspectRatio = aspectRatio;
        this._zNear = zNear;
        this._zFar = zFar;
        this._view = Mat4.identity(new Mat4());
        this._projection = GLM.perspective(fov, aspectRatio, zNear, zFar, new Mat4());
        this._viewProjection = _projection;
        this._position = new Vec3();
        this._direction = new Vec3(0.0, 0.0, 1.0);
        this._postProjection = postPerspective;
        _data.set("eyeDirection", _direction)
        .set("eyePosition", _position)
        .set("viewMatrix", _view)
        .set("projectionMatrix", _projection)
        .set("worldToScreenMatrix", _viewProjection)
        .set("fov", _fov)
        .set("aspectRatio", _aspectRatio)
        .set("zNear", _zNear)
        .set("zFar", _zFar);
    }


    private function localToWorldChangedHandler(data:Store) {
        updateMatrices(data.get("modelToWorldMatrix"));
    }

    private function updateMatrices(modelToWorldMatrix:Mat4) {
        //math
        var tmp:Vec4 = modelToWorldMatrix * (new Vec4(0.0, 0.0, 0.0, 1.0));
        _position = MathUtil.vec4_vec3(tmp);
        _direction =  (MathUtil.mat4_mat3(modelToWorldMatrix)*new Vec3(0.0, 0.0, 1.0));
        _direction = Vec3.normalize(_direction, new Vec3());
        _view = Mat4.invert(modelToWorldMatrix, new Mat4());

        _data.set("eyeDirection", _direction)
        .set("eyePosition", _position)
        .set("viewMatrix", _view);

        updateProjection(_fov, _aspectRatio, _zNear, _zFar);
    }

}
