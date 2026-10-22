package minko.data;
import Lambda;
import minko.signal.Signal2;
@:expose("minko.data.Collection")
class Collection {

    private var _name:String ;
    private var _items:Array<Provider> ;

    private var _itemAdded:Signal2<Collection, Provider>;
    private var _itemRemoved:Signal2<Collection, Provider>;
    private var _lastRemovedIndex:Int;

    public function dispose():Void {
        if(_itemAdded!=null)_itemAdded.dispose();
        _itemAdded=null;
        if(_itemRemoved!=null)_itemRemoved.dispose();
        _itemRemoved=null;
            //todo
        _items=null;
    }
    public static function create(name):Collection {
        return new Collection(name);
    }

    public static function createbyCollection(collection:Collection, deepCopy = false) {
        var copy:Collection = create(collection._name);

        if (deepCopy) {
            for (item in collection._items) {
                copy._items.push(Provider.createbyProvider(item));
            }
        }
        else {
            copy._items = collection._items.concat([]);
        }

        return copy;
    }
    public var name(get, null):String;

    function get_name() {
        return _name;
    }
    public var items(get, null):Array<Provider>;

    function get_items() {
        return _items;
    }
    public var itemAdded(get, null):Signal2<Collection, Provider>;

    function get_itemAdded() {
        return _itemAdded;
    }
    public var itemRemoved(get, null):Signal2<Collection, Provider>;

    function get_itemRemoved() {
        return _itemRemoved;
    }

    public var lastRemovedIndex(get, null):Int;

    function get_lastRemovedIndex():Int {
        return _lastRemovedIndex;
    }
    public var front(get, null):Provider;

    function get_front() {
        return _items.length == 0 ? null : _items[0];
    }
    public var back(get, null):Provider;

    function get_back() {
        return _items.length == 0 ? null : _items[_items.length - 1];
    }


    public function insert(position, provider) {
        if (position < 0) {
            position = 0;
        }
        else if (position > _items.length) {
            position = _items.length;
        }
        _items.insert(position, provider);
        _itemAdded.execute(this, provider);

        return this;
    }

    public function erase(position) {
        if (position < 0 || position >= _items.length) {
            return this;
        }
        return remove(_items[position]);
    }

    public function remove(provider) {
        var index = _items.indexOf(provider);
        if (index == -1) {
            return this;
        }

        _items.remove(provider);
        _lastRemovedIndex = index;
        _itemRemoved.execute(this, provider);

        return this;
    }

    public function pushBack(provider) {
        _items.push(provider);
        _itemAdded.execute(this, provider);

        return this;
    }

    public function popBack() {
        if (_items.length == 0) {
            return this;
        }

        var index = _items.length - 1;
        var provider = _items.pop();
        _lastRemovedIndex = index;
        _itemRemoved.execute(this, provider);

        return this;
    }

    public function new(name) {
        this._name = name;
        this._items = [] ;
        this._itemAdded = new Signal2<Collection, Provider>();
        this._itemRemoved = new Signal2<Collection, Provider>();
        this._lastRemovedIndex = -1;
    }
}
