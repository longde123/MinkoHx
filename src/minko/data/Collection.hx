package minko.data;
import minko.signal.Signal2;
class Collection {

    private var _name:String ;
    private var _items:Array<Provider> ;

    private var _itemAdded:Signal2<Collection, Provider>;
    private var _itemRemoved:Signal2<Collection, Provider>;

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
            copy._items = collection._items;
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
    public var front(get, null):Provider;

    function get_front() {
        return _items[0];
    }
    public var back(get, null):Provider;

    function get_back() {
        return _items[_items.length - 1];
    }


    public function insert(position, provider) {
        _items.insert(position, provider);
        _itemAdded.execute(this, provider);

        return this;
    }

    public function erase(position) {

        var provider = _items[position];
        return remove(provider);
    }

    public function remove(provider) {

        _items.remove(provider);
        _itemRemoved.execute(this, provider);

        return this;
    }

    public function pushBack(provider) {
        _items.push(provider);
        _itemAdded.execute(this, provider);

        return this;
    }

    public function popBack() {
        var provider = _items.pop();
        _itemRemoved.execute(this, provider);

        return this;
    }

    public function new(name) {
        this._name = name;
        this._items = [] ;
        this._itemAdded = new Signal2<Collection, Provider>();
        this._itemRemoved = new Signal2<Collection, Provider>();
    }
}
