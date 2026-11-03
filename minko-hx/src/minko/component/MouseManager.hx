package minko.component;

import minko.input.Mouse;
import minko.math.Ray;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal3.SignalSlot3;

typedef Hit = Tuple<Node, Float>;

@:expose("minko.component.MouseManager")
class MouseManager extends AbstractComponent {
    private var _mouse:Mouse;
    private var _lastItemUnderCursor:Node;
    private var _lastHits:Array<Hit>;
    private var _ray:Ray;
    private var _mouseMoveSlot:SignalSlot3<Mouse, Int, Int>;
    private var _mouseLeftButtonDownSlot:SignalSlot<Mouse>;
    private var _mouseLeftButtonUpSlot:SignalSlot<Mouse>;

    public static function create(mouse = null) {
        return new MouseManager(mouse);
    }

    public var mouse(get, null):Mouse;

    function get_mouse() {
        return _mouse;
    }

    public function pick(ray:Ray):Array<Hit> {
        var hits:Array<Hit> = [];
        var descendants:NodeSet = NodeSet.createbyNode(target.root).descendants(true).where(function(node:Node) {
            return node.hasComponent(BoundingBox);
        });

        for (descendant in descendants.nodes) {
            for (component in descendant.getComponents(BoundingBox)) {
                var boundingBox:BoundingBox = cast component;
                var distance = boundingBox.box.intersectRay(ray);
                if (distance != null) {
                    hits.push(new Hit(descendant, distance));
                }
            }
        }

        hits.sort(function(a:Hit, b:Hit) {
            return a.second < b.second ? -1 : (a.second > b.second ? 1 : 0);
        });

        var rayChanged = !sameRay(_ray, ray);
        var previousPicking = currentPicking();
        var nextNode:Node = hits.length > 0 ? hits[0].first : null;
        if (_lastItemUnderCursor != nextNode && previousPicking != null) {
            previousPicking.updatePicking(_lastHits, ray, rayChanged, false);
        }

        _lastItemUnderCursor = nextNode;
        _lastHits = hits;
        _ray = ray;
        var picking = currentPicking();
        if (picking != null) {
            picking.updatePicking(hits, ray, rayChanged, true);
        }
        return hits;
    }

    function currentPicking():MousePicking {
        return _lastItemUnderCursor == null ? null : cast _lastItemUnderCursor.getComponent(MousePicking);
    }

    function sameRay(a:Ray, b:Ray):Bool {
        return a != null && b != null
            && a.origin.x == b.origin.x && a.origin.y == b.origin.y && a.origin.z == b.origin.z
            && a.direction.x == b.direction.x && a.direction.y == b.direction.y && a.direction.z == b.direction.z;
    }

    function pickFromMouse(mouse:Mouse) {
        var camera:PerspectiveCamera = cast target.getComponent(PerspectiveCamera);
        if (camera != null) {
            pick(camera.unproject(mouse.normalizedX, mouse.normalizedY));
        }
    }

    function dispatchLeftButton(down:Bool) {
        var picking = currentPicking();
        if (picking != null) {
            picking.dispatchLeftButton(_lastHits, _ray, down);
        }
    }

    override public function targetAdded(target:Node) {
        if (_mouse == null) return;
        _mouseMoveSlot = _mouse.move.connect(function(m:Mouse, _, _) pickFromMouse(m));
        _mouseLeftButtonDownSlot = _mouse.leftButtonDown.connect(function(_) dispatchLeftButton(true));
        _mouseLeftButtonUpSlot = _mouse.leftButtonUp.connect(function(_) dispatchLeftButton(false));
    }

    override public function targetRemoved(target:Node) {
        if (_mouseMoveSlot != null) _mouseMoveSlot.dispose();
        if (_mouseLeftButtonDownSlot != null) _mouseLeftButtonDownSlot.dispose();
        if (_mouseLeftButtonUpSlot != null) _mouseLeftButtonUpSlot.dispose();
        _mouseMoveSlot = null;
        _mouseLeftButtonDownSlot = null;
        _mouseLeftButtonUpSlot = null;
        _lastItemUnderCursor = null;
        _lastHits = [];
    }

    override public function dispose() {
        if (target != null) targetRemoved(target);
        _mouse = null;
        _ray = null;
        super.dispose();
    }

    public function new(mouse) {
        super();
        _mouse = mouse;
        _ray = null;
        _lastHits = [];
        _lastItemUnderCursor = null;
    }
}
