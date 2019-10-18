package minko.component;
import minko.data.Collection;
import minko.data.Provider;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
@:expose("minko.component.AbstractRootDataComponent")
class AbstractRootDataComponent extends AbstractComponent {


    private var _provider:Provider;
    private var _collectionName:String;
    private var _enabled:Bool;
    private var _root:Node;

    private var _addedSlot:SignalSlot3<Node, Node, Node>;
    private var _removedSlot:SignalSlot3<Node, Node, Node>;

    override public function dispose() {
        _provider = null;
        _root = null;
        _addedSlot = null;
        _removedSlot = null;
        super.dispose();
    }

    public var provider(get, null):Provider;

    function get_provider() {
        return _provider;
    }
    public var root(get, null):Node;

    function get_root() {
        return _root;
    }

    public function new(collectionName) {
        super();
        this._provider = new Provider();
        this._collectionName = collectionName;
        this._enabled = true;
    }

    override public function targetAdded(target:Node) {

        _addedSlot = target.added.connect(this.addedOrRemovedHandler);
        _removedSlot = target.removed.connect(this.addedOrRemovedHandler);

        updateRoot(target.root);
    }

    override public function targetRemoved(target:Node) {
        _addedSlot.dispose();
        _addedSlot = null;
        _removedSlot.dispose();
        _removedSlot = null;

        updateRoot(null);
    }

    public function addedOrRemovedHandler(node:Node, target:Node, ancestor:Node) {
        updateRoot(node.root);
    }

    public function updateRoot(root) {
        if (root == _root) {
            return;
        }

        if (_root != null) {
            var collections:Array<Collection> = _root.data.collections;
            var collectionIt = Lambda.find(collections, function(c:Collection) {
                return c.name == _collectionName;
            });
            var collection:Collection = collectionIt;

            collection.remove(_provider);
        }

        _root = root;

        if (_root != null) {
            var collections:Array<Collection> = _root.data.collections;
            var collectionIt:Collection = Lambda.find(collections, function(c:Collection) {
                return c.name == _collectionName;
            });

            if (collectionIt == null) {
                var collection:Collection = Collection.create(_collectionName);

                collection.pushBack(_provider);
                _root.data.addCollection(collection);
            }
            else {
                collectionIt.pushBack(_provider);
            }
        }
    }
}
