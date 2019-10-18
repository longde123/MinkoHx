package minko.component;
import minko.signal.Signal2;
import glm.Mat4;
import minko.data.Provider;
import minko.file.AssetLibrary;
import minko.render.AbstractTexture;
import minko.render.Effect;
import minko.render.Texture;
import minko.scene.Node;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal;
import minko.utils.MathUtil;
@:expose("minko.component.Reflection")
class Reflection extends AbstractScript {
    // Signals
    private var _rootAdded:Signal2<AbstractComponent, Node>;

// Slots
//private var _targetAddedSlot :SignalSlot2<AbstractComponent , Node>;
//private var _targetRemovedSlot :SignalSlot2<AbstractComponent , Node>;
    private var _rootAddedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _viewMatrixChangedSlot:SignalSlot2<Provider, String>;
    private var _addedToSceneSlot:SignalSlot3<Node, Node, Node>;
    private var _frameRenderingSlot:SignalSlot3<SceneManager, Int, AbstractTexture>;

    private var _width:Int;
    private var _height:Int;
    private var _clearColor:Int;
    private var _assets:AssetLibrary;

    // One active camera only
    private var _renderTarget:Texture;
    private var _virtualCamera:Node;
    private var _activeCamera:Node;
    private var _perspectiveCamera:PerspectiveCamera;
    private var _cameraTransform:Transform;
    private var _virtualCameraTransform:Transform;
    private var _reflectionRenderer:Renderer;
    private var _reflectedViewMatrix:Mat4;

    // Multiple active cameras
    private var _reflectionEffect:Effect;
    private var _cameras:Array<Node>;
    private var _virtualCameras:Array<Node>;
    private var _renderTargets:Array<Texture>;
    private var _clipPlane:Array<Float>;//new float[4];

//private var _enabled:Bool;

    public static function create(assets, renderTargetWidth, renderTargetHeight, clearColor) {
        return new Reflection(assets, renderTargetWidth, renderTargetHeight, clearColor);
    }
    public var renderTarget(get, null):Texture;

    function get_renderTarget() {
        return _renderTarget;
    }

    public function new(assets:AssetLibrary, renderTargetWidth:Int = 2, renderTargetHeight:Int = 2, clearColor:Int = 0xffffffff) {
        super();
        this._assets = assets;
        this._width = renderTargetWidth;
        this._height = renderTargetWidth;
        this._clearColor = clearColor;
        this._rootAdded = new Signal2<AbstractComponent, Node>();
        this._clipPlane = [for (i in 0...4) 0];
        this._activeCamera = null;
        this._enabled = true;
        this._reflectedViewMatrix = Mat4.identity(new Mat4());
        _renderTarget = Texture.create(_assets.context, MathUtil.clp2(_width), MathUtil.clp2(_height), false, true);

    }

    public function copyFrom(reflection:Reflection, option:CloneOption) {
        this._assets = reflection._assets;
        this._width = reflection._width;
        this._height = reflection._height;
        this._clearColor = reflection._clearColor;
        this._rootAdded = new Signal2<AbstractComponent, Node>();
        this._clipPlane = [for (i in 0...4) 0];
        this._activeCamera = reflection._activeCamera;
        this._enabled = reflection._enabled;
        this._reflectedViewMatrix = Mat4.identity(new Mat4());
        this._renderTarget = Texture.create(_assets.context, MathUtil.clp2(_width), MathUtil.clp2(_height), false, true);
        return this;
    }

    override public function clone(option:CloneOption) {
        var reflection = new Reflection(null).copyFrom(this, option);

        return reflection;
    }

    override public function start(target:Node) {
        // Load reflection effect
        // _reflectionEffect = _assets->effect("effect/Reflection/PlanarReflection.effect");
        _addedToSceneSlot = null;

        var renderTarget = Texture.create(_assets.context, _width, _height, false, true);

        // Create a new render target
        _renderTargets.push(renderTarget);

        var originalCamera:PerspectiveCamera = cast target.getComponents(PerspectiveCamera)[0];

        // Create a virtual camera
        var virtualPerspectiveCameraComponent = PerspectiveCamera.create(originalCamera.aspectRatio, originalCamera.fieldOfView, originalCamera.zNear, originalCamera.zFar);

        // auto cameraTarget = Vector3::create();
        // auto reflectedPosition = Vector3::create();
        //
        // auto renderer = Renderer::create(_clearColor, _renderTarget, _reflectionEffect, 1000000.f, "Reflection");
        //
        // renderer->layoutMask(scene::Layout::Group::REFLECTION);

        // _virtualCamera = scene::Node::create("virtualCamera")
        // 	->addComponent(renderer)
        // 	->addComponent(virtualPerspectiveCameraComponent)
        // 	->addComponent(Transform::create());
        //
        // enabled(_enabled);

        // Add the virtual camera to the scene
        target.root.addChild(_virtualCamera);

        // Bind this camera with a virtual camera (by index for now)
        // TODO: Use unordered_map instead
        //_cameras.push_back(child);
        //_virtualCameras.push_back(virtualCamera);

        // We first check that the target has a camera component
        if (target.getComponents(PerspectiveCamera).length < 1) {
            throw ("Reflection must be added to a camera");
        }

        // We save the target as active camera
        //_activeCamera = target;
    }

    override public function update(target:Node) {
        updateReflectionMatrix();
    }

    override public function stop(target:Node) {
    }

    public function updateReflectionMatrix() {
        // if (!_enabled)
        // 	return;
        //
        // auto transformCmp = target()->component<Transform>();
        // auto transform = transformCmp->modelToWorldMatrix();
        // auto camera = target()->component<PerspectiveCamera>();
        // auto virtualCamera = _virtualCamera->component<PerspectiveCamera>();
        //
        // virtualCamera->fieldOfView(camera->fieldOfView());
        // virtualCamera->aspectRatio(camera->aspectRatio());
        //
        // // Compute active camera data
        // auto cameraPosition = transform->translation();
        // auto cameraDirection = transform->deltaTransform(Vector3::create(0.f, 0.f, -1.f));
        // auto targetPosition = Vector3::create(cameraPosition)->add(cameraDirection);
        //
        // // Compute virtual camera data
        // auto reflectedPosition = Vector3::create()->setTo(cameraPosition->x(), -cameraPosition->y(), cameraPosition->z());
        // auto reflectedTargetPosition = Vector3::create()->setTo(targetPosition->x(), -targetPosition->y(), targetPosition->z());
        //
        // // Compute reflected view matrix
        // _reflectedViewMatrix->lookAt(reflectedTargetPosition, reflectedPosition);
        //
        // _reflectedViewMatrix->lock();
        // _reflectedViewMatrix->transform(Vector3::zero(), reflectedPosition);
        // _reflectedViewMatrix->invert();
        // _reflectedViewMatrix->unlock();
        //
        // _reflectionEffect->setUniform("ReflectedViewMatrix", _reflectedViewMatrix);
    }
}
