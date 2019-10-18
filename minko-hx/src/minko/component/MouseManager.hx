package minko.component;
import glm.Vec3;
import haxe.ds.ObjectMap;
import minko.input.Mouse;
import minko.math.Ray;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
typedef Hit = Tuple<Node, Float>;
@:expose("minko.component.MouseManager")
class MouseManager extends AbstractComponent {
    private var _mouse:Mouse;
    private var _previousRayOrigin:Vec3;
    private var _lastItemUnderCursor:Node;
    private var _ray:Ray;
    private var _targetAddedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _targetRemovedSlot:SignalSlot2<AbstractComponent, Node>;
    private var _mouseMoveSlot:SignalSlot3<Mouse, Int, Int>;
    private var _mouseLeftButtonDownSlot:SignalSlot<Mouse>;

    public static function create(mouse = null) {
        return new MouseManager(mouse);
    }

    public var mouse(get, null):Mouse;

    function get_mouse() {
        return _mouse;
    }

    public function pick(ray:Ray) {
        var hits:Array<Hit> = [];

        var descendants:NodeSet = NodeSet.createbyNode(target.root).descendants(true).where(function(node:Node) {
            return node.hasComponent(BoundingBox);
        });

        var distance:ObjectMap<Node, Float> = new ObjectMap<Node, Float>();
        var localRay:Ray = Ray.create();

        for (descendant in descendants.nodes) {
            var distance = 0.0 ;
            var boundingBox:BoundingBox = cast descendant.getComponent(BoundingBox);
            if (boundingBox.box.castRay(ray, distance)) {
                hits.push(new Hit(descendant, distance));

                /*
						auto transform = descendant->component<Transform>();
						uint triangleId = 0;

						if (transform)
						{
							transform->worldToModel(ray->origin(), localRay->origin());
							transform->deltaWorldToModel(ray->direction(), localRay->direction());
						}

						for (auto& surface : descendant->components<Surface>())
						{
							if (surface->geometry()->cast(transform ? localRay : ray, distance, triangleId))
							{
								hits.push_back(Hit(descendant, distance));
							}
						}
						*/
            }
        }

        hits.sort(function(a:Hit, b:Hit) {
            return Math.floor(a.second - b.second);
        });

        if (hits.length > 0) {
            var node:Node =cast hits[0].first;
            var mp:MousePicking = cast node.getComponent(MousePicking) ;

            if (_previousRayOrigin != ray.origin) {
                //_move->execute(shared_from_this(), hits, ray);
                if (mp != null) {
                    mp.move.execute(mp, hits, ray);
                }

                _previousRayOrigin = ray.origin;
            }

            //_over->execute(shared_from_this(), hits, ray);
        }
    }

    override public function targetAdded(target:Node) {
        if (_mouse == null) {
            return;
        }

        _mouseMoveSlot = _mouse.move.connect(function(m:Mouse, dx, dy) {
            // FIXME: should unproject from properties stored in data()
            var cam:PerspectiveCamera = cast target.getComponent(PerspectiveCamera);

            if (cam != null) {
                pick(_ray = cam.unproject(m.normalizedX, m.normalizedY));
            }
        });
        _mouseLeftButtonDownSlot = _mouse.leftButtonDown.connect(function(m:Mouse) {
            // FIXME
        });
    }

    override public function targetRemoved(target:Node) {
        _mouseMoveSlot = null;
        _mouseLeftButtonDownSlot = null;
    }

    public function new(mouse) {
        super();
        this._mouse = mouse;
        this._ray = Ray.create();
        this._previousRayOrigin = new Vec3();
        this._lastItemUnderCursor = null;
    }

    public function initialize() {
    }
}
