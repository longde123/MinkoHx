package test.data;
import minko.data.Collection;
import minko.data.Provider;
class CollectionTest extends haxe.unit.TestCase {
    public function test_insert() {
        var c:Collection = Collection.create("test");
        var added = false;
        var p:Provider = Provider.create();
        var _ = c.itemAdded.connect(function(collection, provider) {
            added = provider == p;
        });

        c.insert(0, p);

        assertTrue(added);
        assertEquals(c.front, p);
    }

    public function test_erase() {
        var c:Collection = Collection.create("test");
        var removed = false;
        var p = Provider.create();
        var _ = c.itemRemoved.connect(function(collection, provider) {
            removed = provider == p;
        });

        c.insert(0, p);
        c.erase(0);

        assertTrue(removed);
        assertEquals(c.items.length, 0);
    }

    public function test_pushBack() {
        var c = Collection.create("test");
        var added = false;
        var p1 = Provider.create();
        var p2 = Provider.create();

        c.pushBack(p1);

        assertEquals(c.front, p1);

        var _ = c.itemAdded.connect(function(collection, provider) {
            added = provider == p2;
        });

        c.pushBack(p2);

        assertTrue(added);
        assertEquals(c.front, p1);
        assertEquals(c.back, p2);
        assertEquals(c.items.length, 2);
    }

    public function test_popBack() {
        var c = Collection.create("test");
        var removed = false;
        var p1 = Provider.create();
        var p2 = Provider.create();

        c.pushBack(p1);
        c.pushBack(p2);

        var _ = c.itemRemoved.connect(function(collection, provider) {
            removed = provider == p2;
        });

        c.popBack();

        assertEquals(c.front, c.back);
        assertEquals(c.front, p1);
        assertTrue(removed);

        removed = false;
        _ = c.itemRemoved.connect(function(collection, provider) {
            removed = provider == p1;
        });
        c.popBack();

        assertTrue(removed);
        assertEquals(c.items.length, 0);
    }


}
