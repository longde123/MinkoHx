package minko.component;

import minko.component.MouseManager.Hit;
import minko.math.Ray;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal3;

@:expose("minko.component.MousePicking")
class MousePicking extends AbstractComponent {
    private var _move:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _over:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _out:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _rollOver:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _rollOut:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _leftButtonUp:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _leftButtonDown:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _hovering:Bool;
    private var _previousRay:Ray;

    public static function create() {
        return new MousePicking();
    }

    public var move(get, null):Signal3<MousePicking, Array<Hit>, Ray>;
    public var over(get, null):Signal3<MousePicking, Array<Hit>, Ray>;
    public var out(get, null):Signal3<MousePicking, Array<Hit>, Ray>;
    public var rollOver(get, null):Signal3<MousePicking, Array<Hit>, Ray>;
    public var rollOut(get, null):Signal3<MousePicking, Array<Hit>, Ray>;
    public var leftButtonUp(get, null):Signal3<MousePicking, Array<Hit>, Ray>;
    public var leftButtonDown(get, null):Signal3<MousePicking, Array<Hit>, Ray>;

    function get_move() return _move;
    function get_over() return _over;
    function get_out() return _out;
    function get_rollOver() return _rollOver;
    function get_rollOut() return _rollOut;
    function get_leftButtonUp() return _leftButtonUp;
    function get_leftButtonDown() return _leftButtonDown;

    public function pick(ray:Ray):Array<Hit> {
        var hits:Array<Hit> = [];
        var descendants:NodeSet = NodeSet.createbyNode(target).descendants(true).where(function(node:Node) {
            return (node.layout & layoutMask) != 0 && node.hasComponent(BoundingBox);
        });
        for (descendant in descendants.nodes) {
            for (component in descendant.getComponents(BoundingBox)) {
                var box:BoundingBox = cast component;
                var distance = box.shape.intersectRay(ray);
                if (distance != null) hits.push(new Hit(descendant, distance));
            }
        }
        hits.sort(function(a:Hit, b:Hit) {
            return a.second < b.second ? -1 : (a.second > b.second ? 1 : 0);
        });
        updatePicking(hits, ray, !sameRay(_previousRay, ray), hits.length > 0);
        _previousRay = ray;
        return hits;
    }

    @:allow(minko.component.MouseManager)
    function updatePicking(hits:Array<Hit>, ray:Ray, rayChanged:Bool, active:Bool) {
        if (active) {
            if (!_hovering) _rollOver.execute(this, hits, ray);
            if (rayChanged) _move.execute(this, hits, ray);
            _over.execute(this, hits, ray);
        }
        else if (_hovering) {
            _out.execute(this, hits, ray);
            _rollOut.execute(this, hits, ray);
        }
        _hovering = active;
        _previousRay = ray;
    }

    @:allow(minko.component.MouseManager)
    function dispatchLeftButton(hits:Array<Hit>, ray:Ray, down:Bool) {
        if (down) _leftButtonDown.execute(this, hits, ray);
        else _leftButtonUp.execute(this, hits, ray);
    }

    function sameRay(a:Ray, b:Ray):Bool {
        return a != null && b != null
            && a.origin.x == b.origin.x && a.origin.y == b.origin.y && a.origin.z == b.origin.z
            && a.direction.x == b.direction.x && a.direction.y == b.direction.y && a.direction.z == b.direction.z;
    }

    public function new() {
        super();
        _move = new Signal3<MousePicking, Array<Hit>, Ray>();
        _over = new Signal3<MousePicking, Array<Hit>, Ray>();
        _out = new Signal3<MousePicking, Array<Hit>, Ray>();
        _rollOver = new Signal3<MousePicking, Array<Hit>, Ray>();
        _rollOut = new Signal3<MousePicking, Array<Hit>, Ray>();
        _leftButtonUp = new Signal3<MousePicking, Array<Hit>, Ray>();
        _leftButtonDown = new Signal3<MousePicking, Array<Hit>, Ray>();
        _hovering = false;
    }

    override public function dispose() {
        _move.dispose();
        _over.dispose();
        _out.dispose();
        _rollOver.dispose();
        _rollOut.dispose();
        _leftButtonUp.dispose();
        _leftButtonDown.dispose();
        _previousRay = null;
        super.dispose();
    }
}
