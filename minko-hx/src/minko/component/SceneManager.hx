package minko.component;
import minko.data.Provider;
import minko.file.AssetLibrary;
import minko.render.AbstractTexture;
import minko.scene.Node;
import minko.signal.Signal3;
import minko.signal.Signal;
@:expose("minko.component.SceneManager")
class SceneManager extends AbstractComponent {
    private var _frameId:Int;
    private var _time:Float;
    private var _assets:AssetLibrary;
    private var _frameBegin:Signal3<SceneManager, Float, Float>;
    private var _frameEnd:Signal3<SceneManager, Float, Float>;
    private var _cullBegin:Signal<SceneManager>;
    private var _cullEnd:Signal<SceneManager>;
    private var _renderBegin:Signal3<SceneManager, Int, AbstractTexture>;
    private var _renderEnd:Signal3<SceneManager, Int, AbstractTexture>;

    private var _data:Provider;
    private var _addedSlot:SignalSlot3<Node, Node, Node>;

    private var _canvas:AbstractCanvas;

    public static function create(canvas:AbstractCanvas):SceneManager {
        var sm = new SceneManager(canvas);
        return sm;
    }

    public var canvas(get, null):AbstractCanvas;

    function get_canvas() {
        return _canvas;
    }
    public var frameId(get, null):Int;

    function get_frameId() {
        return _frameId;
    }
    public var assets(get, null):AssetLibrary;

    function get_assets() {
        return _assets;
    }

    public var frameBegin(get, null):Signal3<SceneManager, Float, Float>;
    public var frameEnd(get, null):Signal3<SceneManager, Float, Float>;

    function get_frameBegin() {
        return _frameBegin;
    }

    function get_frameEnd() {
        return _frameEnd;
    }
    public var cullingBegin(get, null):Signal<SceneManager>;
    public var cullingEnd(get, null):Signal<SceneManager>;

    function get_cullingBegin() {
        return _cullBegin;
    }

    function get_cullingEnd() {
        return _cullEnd;
    }

    public var renderingBegin(get, null):Signal3<SceneManager, Int, AbstractTexture>;
    public var renderingEnd(get, null):Signal3<SceneManager, Int, AbstractTexture>;

    function get_renderingBegin() {
        return _renderBegin;
    }

    function get_renderingEnd() {
        return _renderEnd;
    }

    public var time(get, null):Float;

    function get_time() {
        return _time;
    }


    public function new(canvas:AbstractCanvas) {
        super();
        this._canvas = canvas;
        this._frameId = 0;
        this._time = 0.0;
        this._assets = AssetLibrary.create(canvas.context);
        this._frameBegin = new Signal3<SceneManager, Float, Float>();
        this._frameEnd = new Signal3<SceneManager, Float, Float>();
        this._cullBegin = new Signal<SceneManager>();
        this._cullEnd = new Signal<SceneManager>();
        this._renderBegin = new Signal3<SceneManager, Int, AbstractTexture>();
        this._renderEnd = new Signal3<SceneManager, Int, AbstractTexture>();
        this._data = Provider.create();
    }

    override public function targetAdded(target:Node) {
        if (target.root != target) {
            throw ("SceneManager must be on the root node only.");
        }
        if (target.getComponents(SceneManager).length > 1) {
            throw ("The same root node cannot have more than one SceneManager.");
        }

        target.data.addProvider(_data);
        target.data.addProvider(_canvas.data);

        _addedSlot = target.added.connect(addedHandler);
    }

    override public function targetRemoved(target:Node) {
        _addedSlot = null;

        target.data.removeProvider(_data);
        target.data.removeProvider(_canvas.data);
    }

    public function addedHandler(node:Node, target:Node, ancestor:Node) {
        if (target == this.target) {
            throw ("SceneManager must be on the root node only.");
        }

        //        if (!target.root.hasComponent(RootTransform)) {
//            target.root.addComponent(RootTransform.create());
//        }
    }

    public function nextFrame(time:Float, deltaTime:Float, renderTarget:AbstractTexture = null) {

        _time = time;
        _data.set("time", _time);

        _frameBegin.execute((this), time, deltaTime);
        _cullBegin.execute((this));
        _cullEnd.execute((this));
        _renderBegin.execute((this), _frameId, renderTarget);
        _renderEnd.execute((this), _frameId, renderTarget);
        _frameEnd.execute((this), time, deltaTime);

        ++_frameId;
    }


}
