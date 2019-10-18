package test.data;
import minko.data.Provider;
class ProviderTest extends haxe.unit.TestCase {
    public function test_CreateCopy() {

        var p1 = Provider.create();

        p1.set("foo", 42);

        var p2 = Provider.createbyProvider(p1);

        assertEquals(p2.get("foo"), 42);

    }

    public function test_TestInt() {
        var provider = Provider.create();

        provider.set("foo", 42);

        assertEquals(provider.get("foo"), 42);
    }

    public function test_TestUint() {
        var provider = Provider.create();
        var v = 42;

        provider.set("foo", v);

        assertEquals(provider.get("foo"), v);
    }

    public function test_TestFloat() {
        var provider = Provider.create();
        var v = 42.0;

        provider.set("foo", v);

        assertEquals(provider.get("foo"), v);
    }

    public function test_PropertyAdded() {
        var p = Provider.create();
        var v = 0;
        var _ = p.propertyAdded.connect(function(provider:Provider, propertyName:String) {
            if (provider == p && propertyName == "foo") {
                v = provider.get("foo");
            }
        });

        p.set("foo", 42);

        assertEquals(v, 42);
    }

    public function test_PropertyRemoved() {
        var p = Provider.create();
        var v = 0;
        var _ = p.propertyRemoved.connect(function(provider:Provider, propertyName:String) {
            if (provider == p && propertyName == "foo") {
                v = 42;
            }
        });

        p.set("foo", 42);
        p.unset("foo");

        assertEquals(v, 42);
    }

    public function test_PropertyChanged() {
        var p = Provider.create();
        var v = 0;
        var _ = p.propertyChanged.connect(function(provider:Provider, propertyName:String) {
            if (provider == p && propertyName == "foo") {
                v = provider.get("foo");
            }
        });

        p.set("foo", 42);

        assertEquals(v, 42);
    }

    public function test_ValueChangedNot() {
        var p = Provider.create();
        var v = 0;

        p.set("foo", 42);

        var _ = p.propertyChanged.connect(function(provider:Provider, propertyName:String) {
            if (provider == p && propertyName == "foo") {
                v = provider.get("foo");
            }
        });

        p.set("foo", 42);

        assertFalse(v== 42);
    }

}
