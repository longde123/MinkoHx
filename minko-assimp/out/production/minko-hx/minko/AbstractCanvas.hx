package minko;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import minko.async.Worker;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Transform;
import minko.data.Provider;
import minko.input.Joystick;
import minko.input.Keyboard;
import minko.input.Mouse;
import minko.input.Touch;
import minko.render.AbstractContext;
import minko.scene.Node;
import minko.signal.Signal2;
import minko.signal.Signal3;
import minko.signal.Signal;
@:expose("minko.Flags")
@:enum abstract Flags(Int) from Int to Int
{
    var FULLSCREEN = (1 << 0);
    var RESIZABLE = (1 << 1);
    var HIDDEN = (1 << 2);
    var CHROMELESS = (1 << 3);
    var STENCIL = (1 << 4);
}
@:expose("minko.AbstractCanvas")
class AbstractCanvas {


    private var _active:Bool;

    private var _swapBuffersAtEnterFrame:Bool;

    // Events
    private var _enterFrame:Signal3<AbstractCanvas, Float, Float>;
    private var _resized:Signal3<AbstractCanvas, Int, Int>;
    private var _resizedSlot:SignalSlot3<AbstractCanvas, Int, Int>;
    // File dropped
    private var _fileDropped:Signal<String>;
    // Joystick events
    private var _joystickAdded:Signal2<AbstractCanvas, Joystick>;
    private var _joystickRemoved:Signal2<AbstractCanvas, Joystick>;

    private var _suspended:Signal<AbstractCanvas>;
    private var _resumed:Signal<AbstractCanvas>;

    private var _activeWorkers:Array<Worker> ;
    private var _workerCompleteSlots:Array<Any>;

    private var _onWindow:Bool;
    private var _camera:Node;
    private var _enableRendering:Bool;

    private var _context:AbstractContext;
    private var _backend:AbstractBackend;


    private var _mouse:Mouse;
    private var _joysticks:IntMap<Joystick> ;
    private var _keyboard:Keyboard;
    private var _touch:Touch;

    private var _name:String;
    private var _x:Int;
    private var _y:Int;
    private var _width:Int;
    private var _height:Int;
    private var _data:Provider;
    private var _flags:Int;

    public var framerate(get, null):Float;
    public var active(get, null):Bool;
    public var x(get, set):Int;
    public var y(get, set):Int;
    public var width(get, set):Int;
    public var height(get, set):Int;
    public var aspectRatio(get, null):Float;
    public var data(get, null):Provider;
    public var context(get, null):AbstractContext;
    public var mouse(get, null):Mouse;
    public var keyboard(get, null):Keyboard;
    public var touch(get, null):Touch;
    public var numJoysticks(get, null):Int;
    public var enterFrame(get, null):Signal3<AbstractCanvas, Float, Float>;
    public var resized(get, null):Signal3<AbstractCanvas, Int, Int>;
    public var joystickAdded(get, null):Signal2<AbstractCanvas, Joystick >;
    public var joystickRemoved(get, null):Signal2<AbstractCanvas, Joystick >;
    public var suspended(get, null):Signal<AbstractCanvas >;
    public var resumed(get, null):Signal<AbstractCanvas >;
    var _workers:StringMap<String -> Worker> = new StringMap<String -> Worker>();

    function get_framerate():Float {
        return Timer.fps();
    }
    public function getJoystickAxis(joystick:Joystick, axis:Int):Int {
        return 0;
    }


    public function isWorkerRegistered(name:String):Bool {
        return false;
    }

    //todo
    public function registerWorker(name:String, cls:String -> Worker) {
        var key = name.toString();
        _workers.set(key, cls);
    }


    static var _defaultCanvas:AbstractCanvas;
    public static var defaultCanvas(get, set):AbstractCanvas;


    static function get_defaultCanvas() {
        return _defaultCanvas;
    }

    static function set_defaultCanvas(value) {
        _defaultCanvas = value;
        return value;
    }


    public function new(name, width, height, flags) {
        this._name = name;
        this._flags = flags;
        this._data = Provider.create();
        this._active = false;

        this._swapBuffersAtEnterFrame = true;
        this._enterFrame = new Signal3<AbstractCanvas, Float, Float>();
        this._resized = new Signal3<AbstractCanvas, Int, Int>();
        this._fileDropped = new Signal<String>();
        this._joystickAdded = new Signal2<AbstractCanvas, Joystick>();
        this._joystickRemoved = new Signal2<AbstractCanvas, Joystick>();
        this._suspended = new Signal<AbstractCanvas>();
        this._resumed = new Signal<AbstractCanvas>();
        this._width = width;
        this._height = height;
        this._x = 0;
        this._y = 0;
        this._onWindow = false;
        this._enableRendering = true;
        this._activeWorkers = [];
        _data.set("viewport", new Vec4(0.0, 0.0, width, height));
    }

    public function initialize() {
    }

    function get_enterFrame() {
        return _enterFrame;
    }

    public function joystick(id) {
        return id < numJoysticks ? _joysticks.get(id) : null;
    }

    function get_aspectRatio() {
        return width / height;
    }

    function get_data() {
        return _data;
    }

    function get_context() {
        return _context;
    }

    function get_mouse() {
        return _mouse;
    }

    function get_keyboard() {
        return _keyboard;
    }

    function get_touch() {
        return _touch;
    }


    function get_numJoysticks() {
        return Lambda.count(_joysticks);
    }

    function get_resized() {
        return _resized;
    }

    function get_joystickAdded() {
        return _joystickAdded;
    }

    function get_joystickRemoved() {
        return _joystickRemoved;
    }

    function get_suspended() {
        return _suspended;
    }

    function get_resumed() {
        return _resumed;
    }

    function get_active() {
        return _active;
    }


    public function createScene() {
        var sceneManager = SceneManager.create(this);
        var root = Node.create("root").addComponent(sceneManager);

        var camera_mat:Mat4 = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        camera_mat = Mat4.invert(camera_mat, new Mat4());

        _camera = Node.create("camera").addComponent(Renderer.create(0x7f7f7fff))
        .addComponent(Transform.createbyMatrix4(camera_mat))
        .addComponent(PerspectiveCamera.create(this.aspectRatio));
        root.addChild(_camera);
        _resizedSlot = _resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast _camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = (w / h);
        });
        return root;
    }




    function get_x() {
        return _x;
    }


    function get_y() {
        return _y;
    }


    function get_width() {
        return _width;
    }


    function get_height() {
        return _height;
    }

    function set_x(value) {
        if (value != _x) {
            var viewport:Vec4 = cast _data.get("viewport");

            _x = value;
            viewport.x = value;
            _data.set("viewport", viewport);
        }
        return value;
    }

    function set_y(value) {
        if (value != _y) {
            var viewport:Vec4 = cast _data.get("viewport");

            _y = value;
            viewport.y = value;
            _data.set("viewport", viewport);
        }
        return value;
    }

    function set_width(value) {
        if (value != _width) {
            var viewport:Vec4 = cast _data.get("viewport");

            _width = value;
            viewport.z = value;
            _data.set("viewport", viewport);
        }
        return value;
    }

    function set_height(value) {
        if (value != _height) {
            var viewport:Vec4 = cast _data.get("viewport");

            _height = value;
            viewport.w = value;
            _data.set("viewport", viewport);
        }
        return value;
    }

    public function step() {
        // framerate in seconds
        var that = this;


#if MINKO_PLATFORM != MINKO_PLATFORM_HTML5
		for (  worker in _activeWorkers)
		{
			worker.poll();
		}
	#end


        Timer.update();

        if (_enableRendering) {
            _enterFrame.execute(that, (Timer.lastTimeStamp-Timer.startTimeStamp) * 1000.0, Timer.dt * 1000.0);

            if (_swapBuffersAtEnterFrame) {
                swapBuffers();
            }
        }


        if (Timer.remainingTime > 0) {
            _backend.wait(that, (Timer.remainingTime ));

        }

    }

    public function run() {
        _active = true;

        _backend.run(this);
    }

    public function quit() {
        _active = false;

    }

    public function getWorker(name:String):Worker {
        if (!_workers.exists(name)) {
            return null;
        }

        var worker = _workers.get(name)(name);

        _activeWorkers.push(worker);

        return worker;
    }


    public function swapBuffers() {
        _backend.swapBuffers(this);
    }



    public function resetInputs() {
        while (_touch.numTouches > 0) {
            var id = _touch.identifiers[0];
            var touch = _touch.touches.get(id);

            var x = touch.x;
            var y = touch.y;

            _touch.updateTouch(id, x, y, 0, 0);
            _touch.touchMove.execute(_touch, id, 0, 0);

            _touch.removeTouch(id);
            _touch.touchUp.execute(_touch, id, x, y);
        }

        _mouse.dX = (0);
        _mouse.dY = (0);

        if (_mouse.leftButtonIsDown) {
            _mouse.leftButtonUp.execute(_mouse);
        }
        if (_mouse.rightButtonIsDown) {
            _mouse.rightButtonUp.execute(_mouse);
        }
        if (_mouse.middleButtonIsDown) {
            _mouse.middleButtonUp.execute(_mouse);
        }
    }


}
