package minko.component;
import haxe.ds.ObjectMap;
import minko.scene.Layout.LayoutMask;
import minko.scene.Layout;
import minko.scene.Node;
import minko.signal.Signal;
import minko.Uuid.Enable_uuid;
@:expose("minko.component.AbstractComponent")
class AbstractComponent extends Enable_uuid {
    public function new(layoutMask = LayoutMask.EVERYTHING) {
        super();
        this._layoutMask = layoutMask;
        this._layoutMaskChanged = new Signal<AbstractComponent>();
    }
    private var _target:Node;
    private var _layoutMask:Layout;
    private var _layoutMaskChanged:Signal<AbstractComponent>;


    public function dispose() {
        _target = null;
    }

    public function clone(option:CloneOption) {
        throw ("Missing clone function for a component.");
        return null;
    }

    public var target(get, set):Node;

    function get_target() {
        return _target;
    }

    public var layoutMask(get, set):Int;

    function get_layoutMask() {
        return _layoutMask;
    }

    function set_layoutMask(value:Layout) {
        if (_layoutMask != value) {
            _layoutMask = value;
            _layoutMaskChanged.execute(this);
        }
        return value;
    }
    public var layoutMaskChanged(get, null):Signal<AbstractComponent>;

    function get_layoutMaskChanged() {
        return _layoutMaskChanged;
    }

    function set_target(v) {
        if (_target != v) {
            if (v == null) {
                var oldTarget = _target;

                targetRemoved(oldTarget);
                _target = null;
            }
            else {
                _target = v;
                targetAdded(_target);
            }
        }
        return v;
    }

    public function targetAdded(node:Node) {

    }

    public function targetRemoved(node:Node) {

    }

    public function rebindDependencies(componentsMap:ObjectMap<AbstractComponent, AbstractComponent>, nodeMap:ObjectMap<Node, Node>, option:Int) {

    }

}
