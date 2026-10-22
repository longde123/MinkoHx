package minko.data;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import Lambda;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3;
import minko.Uuid.Enable_uuid;
//typedef PropertyChangedSignal =Signal<Store, Provider, String>;

typedef ProviderAndToken = Tuple<Provider, String>;

@:expose("minko.data.Store")
class Store extends Enable_uuid {

    private var _providers:Array<Provider> ;
    private var _collections:Array<Collection> ;
    private var _lengthProvider:Provider;

    private var _propertyAdded:Signal3<Store, Provider, String>;
    private var _propertyRemoved:Signal3<Store, Provider, String>;
    private var _propertyChanged:Signal3<Store, Provider, String>;

    private var _propertyNameToChangedSignal:StringMap<Signal3<Store, Provider, String>>;
    private var _propertyNameToAddedSignal:StringMap<Signal3<Store, Provider, String>>;
    private var _propertyNameToRemovedSignal:StringMap<Signal3<Store, Provider, String>>;

    private var _propertySlots:ObjectMap<Provider, Array<SignalSlot2<Provider, String>>>;//SortedDictionary<Provider, LinkedList<Signal<Provider, PropertyName>.Slot>>
    private var _collectionItemAddedSlots:ObjectMap<Collection, SignalSlot2<Collection, Provider>>;
    private var _collectionItemRemovedSlots:ObjectMap<Collection, SignalSlot2<Collection, Provider>>;

    public function new() {
        super();
        enable_uuid();
        initialize();
    }

    private function initialize() :Void{
        _providers = [] ;
        _collections = [] ;
        _lengthProvider = null;

        _propertyAdded = new Signal3<Store, Provider, String>();
        _propertyRemoved = new Signal3<Store, Provider, String>();
        _propertyChanged = new Signal3<Store, Provider, String>();
        _propertyNameToChangedSignal = new StringMap<Signal3<Store, Provider, String>>();
        _propertyNameToAddedSignal = new StringMap<Signal3<Store, Provider, String>>();
        _propertyNameToRemovedSignal = new StringMap<Signal3<Store, Provider, String>>();

        _propertySlots = new ObjectMap<Provider, Array<SignalSlot2<Provider, String>>>();
        _collectionItemAddedSlots = new ObjectMap<Collection, SignalSlot2<Collection, Provider>>();
        _collectionItemRemovedSlots = new ObjectMap<Collection, SignalSlot2<Collection, Provider>>();
    }

    public function dispose() :Void{
        if (_collectionItemAddedSlots != null) {
            for(c in _collectionItemAddedSlots.keys()){
                removeCollection(c);
            }
        }
        if (_collectionItemRemovedSlots != null) {
            for(c in _collectionItemRemovedSlots.keys())
                removeCollection(c);
        }
        if (_collections != null) {
            for(c in _collections)
                removeCollection(c);

        }
        _collectionItemRemovedSlots = null;
        _collectionItemAddedSlots = null;
        _collections=null;
        if (_providers != null) {
            for(p in _providers)
                removeProvider(p);


        }
        if (_propertyNameToChangedSignal != null) {
            for (it in _propertyNameToChangedSignal) {
                if (it != null) {
                    it.dispose();
                }
            }
        }
        if (_propertyNameToAddedSignal != null) {
            for (it in _propertyNameToAddedSignal) {
                if (it != null) {
                    it.dispose();
                }
            }
        }
        if (_propertyNameToRemovedSignal != null) {
            for (it in _propertyNameToRemovedSignal) {
                if (it != null) {
                    it.dispose();
                }
            }
        }
        if (_propertySlots != null) {

            for(_ps in _propertySlots)
                for(_p in _ps)
                    _p.dispose();

        }
        _propertyNameToChangedSignal=null;
        _propertyNameToAddedSignal=null;
        _propertyNameToRemovedSignal=null;
        _propertySlots = null;
        _providers=null;


    }

    public function propertyHasType(propertyName):Bool {
        var providerAndToken = getProviderByPropertyName(propertyName);
        var provider = providerAndToken.first;

        if (provider == null) {
            throw "";
        }

        return provider.propertyHasType(providerAndToken.second);
    }

    public function get(propertyName:String):Dynamic {
        var providerAndToken = getProviderByPropertyName(propertyName);
        var provider = providerAndToken.first;

        if (provider == null) {
            throw "";
        }

        return provider.get(providerAndToken.second);
    }


    public function getUnsafePointer(propertyName:String):Dynamic {
        var providerAndToken = getProviderByPropertyName(propertyName);
        var provider = providerAndToken.first;

        if (provider == null) {
            return null;
            //throw;
        }

        return provider.getUnsafePointer(providerAndToken.second);
    }

    public function set(propertyName:String, value:Dynamic):Store {
        var providerAndToken = getProviderByPropertyName(propertyName);
        var provider = providerAndToken.first;

        if (provider == null) {
            throw "";
        }


        provider.set(providerAndToken.second, value);
        return this;
    }


    public var propertyAdded(get, null):Signal3<Store, Provider, String>;

    public function get_propertyAdded() {
        return _propertyAdded;
    }

    public var propertyRemoved(get, null):Signal3<Store, Provider, String>;

    function get_propertyRemoved() {
        return _propertyRemoved;
    }

    public var propertyChanged(get, null):Signal3<Store, Provider, String>;

    function get_propertyChanged() {
        return _propertyChanged;
    }

    public function getPropertyAdded(propertyName):Signal3<Store, Provider, String> {
        return getOrInsertSignal(_propertyNameToAddedSignal, propertyName);
    }

    public function getPropertyRemoved(propertyName):Signal3<Store, Provider, String> {
        return getOrInsertSignal(_propertyNameToRemovedSignal, propertyName);
    }


    public function getPropertyChanged(propertyName):Signal3<Store, Provider, String> {
        return getOrInsertSignal(_propertyNameToChangedSignal, propertyName);
    }

    public var providers(get, set):Array<Provider>;

    function get_providers() {
        return _providers;
    }

    function set_providers(v) {
        _providers = v;
        return v;
    }
    public var collections(get, null):Array<Collection>;

    function get_collections() {
        return _collections;
    }

    public function addProvider(provider:Provider):Void {
        doAddProvider(provider);
    }

    public function addProviderbyName(provider:Provider, collectionName:String):Void {
        addProviderToCollection(provider, collectionName);
    }

    public function removeProvider(provider:Provider):Void {
        doRemoveProvider(provider);
    }

    public function removeProviderbyName(provider:Provider, collectionName:String):Void {
        removeProviderFromCollection(provider, collectionName);
    }

    public function addCollection(collection:Collection) {
        _collections.push(collection);

        _collectionItemAddedSlots.set(collection, collection.itemAdded.connect(function(UnnamedParameter1, provider) {
            doAddProvider(provider, collection);
        }));
        _collectionItemRemovedSlots.set(collection, collection.itemRemoved.connect(function(UnnamedParameter1, provider) {
            doRemoveProvider(provider, collection);
        }));

        if (collection.items.length != 0) {
            for (provider in collection.items) {
                doAddProvider(provider, collection);
            }
        }
        else {
            updateCollectionLength(collection);
        }
    }

    public function removeCollection(collection:Collection):Void {
        _collections.remove(collection);


        _collectionItemAddedSlots.get(collection).dispose();
        _collectionItemAddedSlots.remove(collection);
        _collectionItemRemovedSlots.get(collection).dispose();
        _collectionItemRemovedSlots.remove(collection);

        for (provider in collection.items) {
            doRemoveProvider(provider, collection);
        }
    }

    public function hasProperty(propertyName:String) {
        return getProviderByPropertyName(propertyName).first != null;
    }


    public function hasPropertyAddedSignal(propertyName:String) {
        return _propertyNameToAddedSignal.exists(propertyName) ;
    }


    public function hasPropertyRemovedSignal(propertyName:String) {
        return _propertyNameToRemovedSignal.exists(propertyName) ;
    }

    public function hasPropertyChangedSignal(propertyName:String) {
        return _propertyNameToChangedSignal.exists(propertyName) ;
    }

    static public function getActualPropertyName(vars:Array<Tuple<String, String>>, propertyName:String) {
        var s = propertyName;

        // FIXME: order vars keys from longer to shorter in order to match the longest matching var name
        // or use regex_replace

        for (variableName in vars) {
            var pos = propertyName.indexOf("@{" + variableName.first + "}");

            if (pos != -1) {
                s = s.substr(0, pos) + variableName.second + s.substr(pos + variableName.first.length + 3);
                break;
            }
            else if ((pos = propertyName.indexOf("@" + variableName.first)) != -1) {
                s = s.substr(0, pos) + variableName.second + s.substr(pos + variableName.first.length + 1);
                break;
            }
        }

        return s;
    }

    private function getProviderByPropertyName(propertyName:String):ProviderAndToken {
        var pos = propertyName.indexOf("[") ;

        if (pos != -1) {
            var collectionName = propertyName.substr(0, pos);

            for (collection in _collections) {
                if (collection.name == collectionName) {
                    var pos2 = propertyName.indexOf("]");
                    var indexStr = propertyName.substr(pos + 1, pos2 - pos - 1);
                    var pos3 = indexStr.indexOf("-");
                    var token = propertyName.substr(pos2 + 2);


                    // fetch provider by uuid
                    if (pos3 != -1 && pos3 < pos2) {
                        for (provider in collection.items) {
                            if (provider.uuid == indexStr && provider.hasProperty(token)) {
                                return new ProviderAndToken(provider, token);
                            }
                        }
                    }
                    else { // fetch provider by index
                        var index = Std.parseInt(indexStr);

                        if (index < collection.items.length) {
                            var provider = collection.items[index];

                            if (provider.hasProperty(token)) {
                                return new ProviderAndToken(provider, token);
                            }
                        }
                    }
                    return new ProviderAndToken(null, token);
                }
            }
        }
        else {
            for (provider in _providers) {
                if (provider.hasProperty(propertyName)) {
                    return new ProviderAndToken(provider, propertyName);
                }
            }
        }

        return new ProviderAndToken(null, propertyName);
    }


    public function doRemoveProvider(provider:Provider, ?collection:Collection = null) {


        // var it = std::find(_providers.begin(), _providers.end(), provider);

        // Debug.Assert(provider != null);
        // Debug.Assert(it != _providers.end());

        _providers.remove(provider);
        //if (std::find(_providers.begin(), _providers.end(), provider) != _providers.end())
        //return;

        // execute all the "property removed" signals
        for (property in provider.keys()) {
            providerPropertyRemovedHandler(provider, collection, property);
        }

        // erase all the slots (property added, changed, removed) for this provider

        if (_propertySlots.exists(provider)) {

            var _slots:Array<SignalSlot2<Provider, String>> = _propertySlots.get(provider);
            for (s in _slots) {
                s.dispose();
            }
            _propertySlots.remove(provider);
        }


        // destroy all signals that might have been created for each property declared by the provider
        // warning! erase the signal only if it has no callbacks anymore, otherwise it should be kept valid
        if (collection == null) {
            for (nameAndValue in provider.keys()) {
                if (_propertyNameToChangedSignal.exists(nameAndValue) && _propertyNameToChangedSignal.get(nameAndValue).numCallbacks == 0) {

                    _propertyNameToChangedSignal.remove(nameAndValue);
                }
            }
        }
        else {
            var providerIndex = collection.items.indexOf(provider) ;
            var prefix = collection.name + "[" + (providerIndex) + "].";

            for (nameAndValue in provider.keys()) {
                if (_propertyNameToChangedSignal.exists(prefix + nameAndValue)) {
                    _propertyNameToChangedSignal.get(prefix + nameAndValue).dispose();
                    _propertyNameToChangedSignal.remove(prefix + nameAndValue);
                }
            }

            updateCollectionLength(collection);

            // the removed provider might very well be anything but the last item of the collection
            // thus, all properties of all providers will have a different name.
            // Ex: "material[2].diffuseMap" will become "material[1].diffuseMap" when the material 1
            // is removed.
            // In other words, the value targeted by "material[1].diffuseMap" will be different and thus
            // we should trigger the "property changed" signal for each property of each provider which is
            // "after" the one being removed from the collection.
            for (provider in collection.items) {
                for (property in provider.keys()) {
                    executePropertySignal(provider, collection, property, _propertyChanged, _propertyNameToChangedSignal);
                }
            }
        }

    }

    public function formatPropertyName(collection:Collection, provider:Provider, propertyName:String, ?useUuid = false) {
        if (collection == null) {
            return propertyName;
        }

        if (useUuid) {
            return formatPropertyIndexName(collection, provider.uuid, propertyName);
        }

        var it:Int = collection.items.indexOf(provider);

        return formatPropertyIndexName(collection, Std.string(it), propertyName);
    }

    public function formatPropertyIndexName(collection:Collection, index:String, propertyName:String) {
        if (collection == null) {
            return propertyName;
        }

        return collection.name + "[" + index + "]." + propertyName ;
    }

    public function executePropertySignal(provider:Provider, collection:Collection, propertyName:String, anyChangedSignal:Signal3<Store, Provider, String>, propertyNameToSignal:StringMap<Signal3<Store, Provider, String>>) {
        anyChangedSignal.execute(this, provider, propertyName);
        if (collection != null) {
            var formattedPropertyName = formatPropertyName(collection, provider, propertyName, true);
            if (propertyNameToSignal.exists(formattedPropertyName)) {
                propertyNameToSignal.get(formattedPropertyName).execute(this, provider, propertyName);
            }

            formattedPropertyName = formatPropertyName(collection, provider, propertyName);
            if (propertyNameToSignal.exists(formattedPropertyName)) {
                propertyNameToSignal.get(formattedPropertyName).execute(this, provider, propertyName);
            }
        }
        else if (propertyNameToSignal.exists(propertyName)) {
            propertyNameToSignal.get(propertyName).execute(this, provider, propertyName);
        }
    }

    public function providerPropertyAddedHandler(provider, collection, propertyName) {
        executePropertySignal(provider, collection, propertyName, _propertyAdded, _propertyNameToAddedSignal);
        executePropertySignal(provider, collection, propertyName, _propertyChanged, _propertyNameToChangedSignal);
    }

    public function providerPropertyRemovedHandler(provider:Provider, collection:Collection, propertyName:String) {
        executePropertySignal(provider, collection, propertyName, _propertyChanged, _propertyNameToChangedSignal);
        executePropertySignal(provider, collection, propertyName, _propertyRemoved, _propertyNameToRemovedSignal);

        var formattedName = formatPropertyName(collection, provider, propertyName);


        //用不用 dispose?
        var it = _propertyNameToAddedSignal.get(formattedName);
        if (it != null && it.numCallbacks == 0) {
            _propertyNameToAddedSignal.remove(formattedName);
        }
        it = _propertyNameToRemovedSignal.get(formattedName);
        if (it != null && it.numCallbacks == 0) {
            _propertyNameToRemovedSignal.remove(formattedName);
        }
        it = _propertyNameToChangedSignal.get(formattedName);
        if (it != null && it.numCallbacks == 0) {
            _propertyNameToChangedSignal.remove(formattedName);
        }

        formattedName = formatPropertyName(collection, provider, propertyName, true);
        it = _propertyNameToAddedSignal.get(formattedName);
        if (it != null && it.numCallbacks == 0) {
            _propertyNameToAddedSignal.remove(formattedName);
        }
        it = _propertyNameToRemovedSignal.get(formattedName);
        if (it != null && it.numCallbacks == 0) {
            _propertyNameToRemovedSignal.remove(formattedName);
        }
        it = _propertyNameToChangedSignal.get(formattedName);
        if (it != null && it.numCallbacks == 0) {
            _propertyNameToChangedSignal.remove(formattedName);
        }
    }

    private function addProviderToCollection(provider, collectionName) {
        var collectionIt = Lambda.find(_collections, function(c:Collection) {
            return c.name == collectionName;
        });

        var collection:Collection = null;

        // if the collection does not already exist
        if (collectionIt == null) {
            // create and add it
            collection = Collection.create(collectionName);
            addCollection(collection);
        }
        else {
            // just use the existing collection
            collection = collectionIt;
        }

        collection.pushBack(provider);
    }

    private function removeProviderFromCollection(provider:Provider, collectionName:String) {
        var collectionIt:Collection = Lambda.find(_collections, function(c:Collection) {
            return c.name == collectionName;
        });

        if (collectionIt == null) {
            throw ("collectionName = " + collectionName);
        }

        collectionIt.remove(provider);
    }

    public function doAddProvider(provider:Provider, ?collection:Collection = null) {
        _providers.push(provider);
        _propertySlots.set(provider, [
            provider.propertyAdded.connect(function(p, propertyName) {
                providerPropertyAddedHandler(p, collection, propertyName);
            }),
            provider.propertyRemoved.connect(function(p, propertyName) {
                providerPropertyRemovedHandler(p, collection, propertyName);
            }),
            provider.propertyChanged.connect(function(p, propertyName) {
                executePropertySignal(p, collection, propertyName, _propertyChanged, _propertyNameToChangedSignal);
            })
        ]);

        for (property in provider.keys()) {
            providerPropertyAddedHandler(provider, collection, property);
        }

        if (collection != null) {
            updateCollectionLength(collection);
        }
    }

    public function updateCollectionLength(collection:Collection) {
        if (_lengthProvider == null) {
            _lengthProvider = Provider.create();
            doAddProvider(_lengthProvider);
        }

        _lengthProvider.set(collection.name + ".length", collection.items.length);
    }

    public function copyFrom(store:Store, ?deepCopy = false) {
        if (deepCopy) {
            var added = new Array<Provider>();

            for (collection in store._collections) {
                added = added.concat(collection.items);
                addCollection(Collection.createbyCollection(collection));
            }

            for (provider in store._providers) {
                //Provider
                var it = Lambda.has(added, provider);

                if (it == false) {
                    _providers.push(Provider.createbyProvider(provider));
                }
            }
        }
        else {
            _collections = new Array<Collection>().concat(store._collections);
            _providers = new Array<Provider>().concat(store._providers);
            if (store._lengthProvider != null) {
                _lengthProvider = Provider.createbyProvider(store._lengthProvider);
            }
        }
        return this;
    }

    public function getOrInsertSignal(signals:StringMap<Signal3<Store, Provider, String>>, propertyName:String) {
        var signal:Signal3<Store, Provider, String>;
        if (!signals.exists(propertyName)) {
            signal = new Signal3<Store, Provider, String>();
            signals.set(propertyName, signal);
        }
        else {
            signal = signals.get(propertyName);
        }

        return signal;
    }


}
