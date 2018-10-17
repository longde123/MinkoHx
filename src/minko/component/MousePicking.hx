package minko.component;
import glm.Vec3;
import haxe.ds.ObjectMap;
import minko.component.MouseManager.Hit;
import minko.math.Ray;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal3;
class MousePicking extends AbstractComponent {

    private var _move:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _over:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _out:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _rollOver:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _rollOut:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _leftButtonUp:Signal3<MousePicking, Array<Hit>, Ray>;
    private var _leftButtonDown:Signal3<MousePicking, Array<Hit>, Ray>;

    private var _previousRayOrigin:Vec3 ;
    private var _lastItemUnderCursor:Node;

    public static function create() {
        var mp = new MousePicking();

        mp.initialize();

        return mp;
    }

    public var move(get, null):Signal3<MousePicking, Array<Hit>, Ray>;

    function get_move() {
        return _move;
    }
    public var over(get, null):Signal3<MousePicking, Array<Hit>, Ray>;

    function get_over() {
        return _over;
    }

    public function pick(ray:Ray) {
        var hits:Array<Hit> = [];

        var descendants:NodeSet = NodeSet.createbyNode(target).descendants(true).where(function(node:Node) {
            return (node.layout & layoutMask) != 0 && node.hasComponent(BoundingBox);
        });

        var distance:ObjectMap<Node, Float> = new ObjectMap<Node, Float>();

        for (descendant in descendants.nodes) {
            var boxs:Array<BoundingBox> = cast descendant.getComponents(BoundingBox);
            for (box in boxs) {
                var distance = 0.0;

                if (box.shape.castRay(ray, distance)) {
                    hits.push(new Hit(descendant, distance));
                }
            }
        }

        hits.sort(function(a:Hit, b:Hit) {
            return Math.floor(a.second - b.second);
        });

        if (hits.length > 0) {
            if (_previousRayOrigin == ray.origin) {
                _move.execute((this), hits, ray);
                _previousRayOrigin = ray.origin;
            }

            _over.execute((this), hits, ray);
        }
    }

    public function new() {
        super();
        this._move = new Signal3<MousePicking, Array<Hit>, Ray>();
        this._over = new Signal3<MousePicking, Array<Hit>, Ray>();
        this._out = new Signal3<MousePicking, Array<Hit>, Ray>();
        this._rollOver = new Signal3<MousePicking, Array<Hit>, Ray>();
        this._rollOut = new Signal3<MousePicking, Array<Hit>, Ray>();
        this._leftButtonUp = new Signal3<MousePicking, Array<Hit>, Ray>();
        this._leftButtonDown = new Signal3<MousePicking, Array<Hit>, Ray>();
        this._previousRayOrigin = new Vec3() ;

    }

    private function initialize() {
    }

}
