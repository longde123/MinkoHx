package test.data;
import Lambda;
import minko.data.Collection;
import minko.data.Provider;
import minko.data.Store;
import minko.signal.Signal3;
class StoreTest extends haxe.unit.TestCase {
    public function test_AddProvider() {
        var c = new Store();
        var p = Provider.create();
        p.set("foo", 42);
        c.addProvider(p);
        assertTrue(Lambda.has(c.providers, p));
        assertTrue(c.hasProperty("foo"));
        assertEquals(c.get("foo"), 42);
    }

    public function test_RemoveProvider() {
        var c = new Store();
        var p = Provider.create();
        p.set("foo", 42);
        c.addProvider(p);
        c.removeProvider(p);
        assertTrue(!Lambda.has(c.providers, p));
        assertFalse(c.hasProperty("foo"));
    }

    public function test_PropertyAdded() {
        var c = new Store();
        var p = Provider.create();
        var v = 0;
        p.set("foo", 42);
        var _ = c.propertyAdded.connect(function(container:Store, provider:Provider, propertyName:String) {
            if (propertyName == "foo") {
                v = container.get("foo");
            }
        });
        c.addProvider(p);
        assertEquals(v, 42);
    }

    public function test_PropertyRemoved() {
        var c = new Store();
        var p = Provider.create();
        var v = 0;
        p.set("foo", 42);
        var _ = c.propertyAdded.connect(function(container:Store, provider:Provider, propertyName:String) {
            if (propertyName == "foo") {
                v = 42;
            }
        });
        c.addProvider(p);
        c.removeProvider(p);
        assertEquals(v, 42);
    }

    public function test_propertyChangedWhenAdded() {
        var c = new Store();
        var p = Provider.create();
        var v = 0;
        p.set("foo", 42);
        var _ = c.getPropertyChanged("foo").connect(function(container:Store, provider:Provider, propertyName:String) {
            if (propertyName == "foo") {
                v = container.get("foo");
            }
        });
        c.addProvider(p);
        assertEquals(v, 42);
    }

    public function test_propertyChangedWhenAddedOnProvider() {
        var c = new Store();
        var p = Provider.create();
        var v = 0;
        c.addProvider(p);
        var _ = c.getPropertyChanged("foo").connect(function(container:Store, provider:Provider, propertyName:String) {
            if (propertyName == "foo") {
                v = container.get("foo");
            }
        });
        p.set("foo", 42);

        assertEquals(v, 42);
    }

    public function test_propertyChangedWhenSetOnProvider() {
        var c = new Store();
        var p = Provider.create();
        var v = 0;
        c.addProvider(p);
        p.set("foo", 23);
        var _ = c.getPropertyChanged("foo").connect(function(container:Store, provider:Provider, propertyName:String) {
            if (propertyName == "foo") {
                v = container.get("foo");
            }
        });
        p.set("foo", 42);

        assertEquals(v, 42);
    }

    public function test_propertyChangedNot() {
        var c = new Store();
        var p = Provider.create();
        var v = 0;

        c.addProvider(p);
        p.set("foo", 42);

        var _ = c.getPropertyChanged("foo").connect(function(container:Store, provider:Provider, propertyName:String) {
            if (propertyName == "foo") {
                v = container.get("foo");
            }
        });

        p.set("foo", 42);

        assertFalse(v == 42);
    }

    public function test_addCollection() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");

        cc.pushBack(p);
        c.addCollection(cc);

        assertTrue(Lambda.has(c.collections, cc));
    }

    public function test_addProviderToCollection() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");

        p.set("foo", 42);
        c.addCollection(cc);
        cc.pushBack(p);

        assertTrue(Lambda.has(c.providers, p));
        assertTrue(c.hasProperty("test[0].foo"));
        assertEquals(c.get("test[0].foo"), 42);
    }

    public function test_removeCollection() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");
        var collectionRemoved = false;
        var providerRemoved = false;

        p.set("foo", 42);
        cc.pushBack(p);
        c.addCollection(cc);
        c.removeCollection(cc);

        assertFalse(Lambda.has(c.collections, cc));
        assertFalse(Lambda.has(c.providers, p));
        assertFalse(c.hasProperty("test[0].foo"));
    }

    public function test_removeProviderFromCollection() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");

        p.set("foo", 42);
        cc.pushBack(p);
        c.addCollection(cc);
        cc.remove(p);

        assertTrue(Lambda.has(c.collections, cc));
        assertFalse(Lambda.has(c.providers, p));
        assertEquals(c.get("test.length"), 0);
    }


    public function test_getCollectionNth() {
        var c = new Store();
        var p0 = Provider.create();
        var p1 = Provider.create();
        var p2 = Provider.create();
        var cc = Collection.create("test");

        p0.set("foo", 42);
        p1.set("foo", 4242);
        p2.set("foo", 424242);
        c.addCollection(cc);
        assertEquals(c.get("test.length"), 0);
        cc.pushBack(p0);
        assertEquals(c.get("test.length"), 1);
        cc.pushBack(p1);
        assertEquals(c.get("test.length"), 2);
        cc.pushBack(p2);
        assertEquals(c.get("test.length"), 3);

        assertEquals(c.get("test[0].foo"), 42);
        assertEquals(c.get("test[1].foo"), 4242);
        assertEquals(c.get("test[2].foo"), 424242);
    }

//C++ TO C# CONVERTER CRACKED BY X-CRACKER 2017 WARNING: The following constructor is declared outside of its associated class:
    public function test_collectionPropertyAdded() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");
        var propertyAdded = false;

        cc.pushBack(p);
        c.addCollection(cc);

        var _ = c.propertyAdded.connect(function(container:Store, provider:Provider, propertyName:String) {
            propertyAdded = propertyName == "foo" && provider.get(propertyName) == 42;
        });

        p.set("foo", 42);

        assertTrue(propertyAdded);
    }

    public function test_collectionPropertyChanged() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");
        var propertyChanged = false;

        cc.pushBack(p);
        c.addCollection(cc);
        p.set("foo", 42);

        var _ = c.getPropertyChanged("test[0].foo").connect(function(container:Store, provider:Provider, propertyName:String) {
            propertyChanged = propertyName == "foo" && provider.get(propertyName) == 4242;
        });

        p.set("foo", 4242);

        assertTrue(propertyChanged);
    }

    public function test_collectionPropertyChangedNot() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");
        var propertyChanged = false;

        cc.pushBack(p);
        c.addCollection(cc);
        p.set("foo", 42);

        var _ = c.getPropertyChanged("test[0].foo").connect(function(container:Store, provider:Provider, propertyName:String) {
            propertyChanged = propertyName == "foo" && provider.get(propertyName) == 42;
        });

        p.set("foo", 42);

        assertFalse(propertyChanged);
    }

    public function test_collectionPropertyRemoved() {
        var c = new Store();
        var p = Provider.create();
        var cc = Collection.create("test");
        var propertyRemoved = false;

        p.set("foo", 42);
        cc.pushBack(p);
        c.addCollection(cc);

        var _ = c.propertyRemoved.connect(function(container:Store, provider:Provider, propertyName:String) {
            propertyRemoved = propertyName == "foo";
        });

        p.unset("foo");

        assertTrue(propertyRemoved);
    }

    public function test_collectionNthPropertyChanged() {
        var c = new Store();
        var p0 = Provider.create();
        var p1 = Provider.create();
        var cc = Collection.create("test");
        var propertyChanged = false;

        p0.set("foo", 42);
        p1.set("foo", 4242);
        cc.pushBack(p0).pushBack(p1);
        c.addCollection(cc);

        var _ = c.getPropertyChanged("test[1].foo").connect(function(container:Store, provider:Provider, propertyName:String) {
            propertyChanged = propertyName == "foo" && provider.get(propertyName) == 42;
        });

        p1.set("foo", 42);

        assertTrue(propertyChanged);
    }

    public function test_collectionPropertyPointerConsistency() {
        var c = new Store();
        var p0 = Provider.create();
        var p1 = Provider.create();
        var cc = Collection.create("test");
        var propertyChanged = false;

        p0.set("foo", 42);
        p1.set("foo", 4242);
        cc.pushBack(p0).pushBack(p1);
        c.addCollection(cc);

        assertEquals(c.get("test[0].foo"), c.get("test[0].foo"));
        assertEquals(c.get("test[0].foo"), p0.get("foo"));
        assertEquals(p0.get("foo"), 42);
        assertEquals(c.get("test[1].foo"), c.get("test[1].foo"));
        assertEquals(c.get("test[1].foo"), p1.get("foo"));
        assertEquals(p1.get("foo"), 4242);
    }

    public function test_providerAddedTwiceRemovedOnce() {
        var c = new Store();
        var p = Provider.create();
        var propertyAdded = 0;
        var propertyRemoved = false;

        p.set("foo", 42);

        var addedSlod = c.getPropertyAdded("foo").connect(function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
            propertyAdded++;
        });
        var removedSlot = c.getPropertyRemoved("foo").connect(function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
            assertFalse(propertyRemoved);
            propertyRemoved = true;
        });

        c.addProvider(p);
        c.addProvider(p);

        c.removeProvider(p);

        assertEquals(propertyAdded, 2);
        assertTrue(c.hasProperty("foo"));
    }

    public function test_providerAddedTwiceInCollectionRemovedOnce() {
        var c = new Store();
        var p = Provider.create();
        var propertyAdded = 0;
        var propertyRemoved = false;

        p.set("foo", 42);

        var addedSlod = c.getPropertyAdded("bar[0].foo").connect(function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
            propertyAdded++;
        });
        var removedSlot = c.getPropertyRemoved("bar[0].foo").connect(function(UnnamedParameter1, UnnamedParameter2, UnnamedParameter3) {
            assertFalse(propertyRemoved);
            propertyRemoved = true;
        });

        c.addProviderbyName(p, "bar");
        c.addProviderbyName(p, "bar");

        c.removeProviderbyName(p, "bar");

        assertEquals(propertyAdded, 2);
        assertTrue(c.hasProperty("bar[0].foo"));
    }

    public function test_specificPropertyAddedSignal() {
        var s = new Store();

        assertFalse(s.hasPropertyAddedSignal("test"));

        var s1:Signal3<Store, Provider, String> = s.getPropertyAdded("test");

        assertTrue(s.hasPropertyAddedSignal("test"));
        assertEquals(s1.numCallbacks, 0);

        var callbackPropertyName = "";
        var callbackStore;
        var callbackProvider = new Provider();
        var executed = false;
        var _ = s1.connect(function(store, provider, propertyName) {
            executed = true;
            callbackStore = store;
            callbackProvider = provider;
            callbackPropertyName = propertyName;
        });

        assertEquals(s1.numCallbacks, 1);

        var p = Provider.create();

        p.set("test", 42);
        assertFalse(executed);
        s.addProvider(p);

        assertTrue(executed);
        assertEquals(callbackStore, s);
        assertEquals(callbackProvider, p);
        assertEquals(callbackPropertyName, "test");
    }

    public function test_specificPropertyRemovedSignal() {
        var s = new Store();

        assertFalse(s.hasPropertyAddedSignal("test"));

        var s1:Signal3<Store, Provider, String> = s.getPropertyRemoved("test");

        assertTrue(s.hasPropertyRemovedSignal("test"));
        assertEquals(s1.numCallbacks, 0);

        var callbackPropertyName = "";
        var callbackStore;
        var callbackProvider = new Provider();
        var executed = false;
        var _ = s1.connect(function(store, provider, propertyName) {
            executed = true;
            callbackStore = store;
            callbackProvider = provider;
            callbackPropertyName = propertyName;
        });

        assertEquals(s1.numCallbacks, 1);

        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);
        assertFalse(executed);
        s.removeProvider(p);

        assertTrue(executed);
        assertEquals(callbackStore, s);
        assertEquals(callbackProvider, p);
        assertEquals(callbackPropertyName, "test");
    }

    public function test_specificPropertyChangedSignal() {
        var s = new Store();
        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);

        assertFalse(s.hasPropertyChangedSignal("test"));

        var s1:Signal3<Store, Provider, String> = s.getPropertyChanged("test");

        assertTrue(s.hasPropertyChangedSignal("test"));
        assertEquals(s1.numCallbacks, 0);

        var callbackPropertyName = "";
        var callbackStore;
        var callbackProvider = new Provider();
        var executed = false;
        var _ = s1.connect(function(store, provider, propertyName) {
            executed = true;
            callbackStore = store;
            callbackProvider = provider;
            callbackPropertyName = propertyName;
        });

        assertEquals(s1.numCallbacks, 1);

        assertFalse(executed);
        p.set("test", 24);

        assertTrue(executed);
        assertEquals(callbackStore, s);
        assertEquals(callbackProvider, p);
        assertEquals(callbackPropertyName, "test");
    }

    public function test_doNotFreeUsedPropertyAddedSignals() {
        var s = new Store();
        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);

        assertFalse(s.hasPropertyAddedSignal("test"));

        var s1:Signal3<Store, Provider, String> = s.getPropertyAdded("test");

        assertEquals(s1.numCallbacks, 0);
        assertTrue(s.hasPropertyAddedSignal("test"));

        var _ = s1.connect(function(store, provider, propertyName) {
            // nothing
        });

        assertEquals(s1.numCallbacks, 1);

        s.removeProvider(p);

        assertTrue(s.hasPropertyAddedSignal("test"));
    }

    public function test_doNotFreeUsedPropertyChangedSignals() {
        var s = new Store();
        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);

        assertFalse(s.hasPropertyChangedSignal("test"));

        var s1:Signal3<Store, Provider, String> = s.getPropertyChanged("test");

        assertEquals(s1.numCallbacks, 0);
        assertTrue(s.hasPropertyChangedSignal("test"));

        var _ = s1.connect(function(store, provider, propertyName) {
            // nothing
        });

        assertEquals(s1.numCallbacks, 1);

        s.removeProvider(p);

        assertTrue(s.hasPropertyChangedSignal("test"));
    }

    public function test_doNotFreeUsedPropertyRemovedSignals() {
        var s = new Store();
        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);

        assertFalse(s.hasPropertyRemovedSignal("test"));

        var s1:Signal3<Store, Provider, String> = s.getPropertyRemoved("test");

        assertEquals(s1.numCallbacks, 0);
        assertTrue(s.hasPropertyRemovedSignal("test"));

        var _ = s1.connect(function(store, provider, propertyName) {
            // nothing
        });

        assertEquals(s1.numCallbacks, 1);

        s.removeProvider(p);

        assertTrue(s.hasPropertyRemovedSignal("test"));
    }

    public function test_freeUnusedPropertyAddedSignals() {
        var s = new Store();
        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);

        assertFalse(s.hasPropertyAddedSignal("test"));

        var s1:Signal3<Store, Provider, String> = s.getPropertyAdded("test");

        assertEquals(s1.numCallbacks, 0);
        assertTrue(s.hasPropertyAddedSignal("test"));

        s.removeProvider(p);

        assertFalse(s.hasPropertyAddedSignal("test"));
    }

    public function test_freeUnusedPropertyChangedSignals() {
        var s = new Store();
        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);

        assertFalse(s.hasPropertyChangedSignal("test"));

        var s1 = s.getPropertyChanged("test");

        assertEquals(s1.numCallbacks, 0);
        assertTrue(s.hasPropertyChangedSignal("test"));

        s.removeProvider(p);

        assertFalse(s.hasPropertyChangedSignal("test"));
    }

    public function test_freeUnusedPropertyRemovedSignals() {
        var s = new Store();
        var p = Provider.create();

        p.set("test", 42);
        s.addProvider(p);

        assertFalse(s.hasPropertyRemovedSignal("test"));

        var s1 = s.getPropertyRemoved("test");

        assertEquals(s1.numCallbacks, 0);
        assertTrue(s.hasPropertyRemovedSignal("test"));

        s.removeProvider(p);

        assertFalse(s.hasPropertyRemovedSignal("test"));
    }

}
