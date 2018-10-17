package test.scene;
import minko.component.SceneManager;
import minko.scene.Node;
class NodeTest extends haxe.unit.TestCase {


    public function testCreate() {

        var node = Node.create();

        assertTrue(true);

    }


    public function testCreateWithName() {
        var node = new Node();

        node = Node.create("test");


        assertEquals(node.name, "test");
    }


    public function testAddChild() {
        var n1 = Node.create("a");
        var n2 = Node.create("b");

        n1.addChild(n2);

        assertEquals(n1.children.length, 1);
        assertEquals(n1.children[0], n2);
        assertEquals(n1.root, n1);
        assertEquals(n1.parent, null);
        assertEquals(n2.children.length, 0);
        assertEquals(n2.parent, n1);
        assertEquals(n2.root, n1);
    }


    public function testRemoveChild() {
        var n1 = Node.create("a");
        var n2 = Node.create("b");

        n1.addChild(n2);
        n1.removeChild(n2);

        assertEquals(n1.children.length, 0);
        assertEquals(n1.root, n1);
        assertEquals(n1.parent, null);
        assertEquals(n2.children.length, 0);
        assertEquals(n2.root, n2);
        assertEquals(n2.parent, null);
    }


    public function testAdded() {
        var n1 = Node.create("a");
        var n2 = Node.create("b");
        var added1 = false;
        var added2 = false;

        var _ = n1.added.connect(function(node, target, ancestor) {
            added1 = node == n1 && target == n2 && ancestor == n1;
        });
        var __ = n2.added.connect(function(node, target, ancestor) {
            added2 = node == n2 && target == n2 && ancestor == n1;
        });

        n1.addChild(n2);

        assertTrue(added1);
        assertTrue(added2);
    }


    public function testRemoved() {
        var n1 = Node.create("a");
        var n2 = Node.create("b");
        var removed1 = false;
        var removed2 = false;
        var _ = n1.removed.connect(function(node, target, ancestor) {
            removed1 = node == n1 && target == n2 && ancestor == n1;
        });
        var __ = n2.removed.connect(function(node, target, ancestor) {
            removed2 = node == n2 && target == n2 && ancestor == n1;
        });

        n1.addChild(n2);
        n1.removeChild(n2);

        assertTrue(removed1);
        assertTrue(removed2);
    }


    public function testComponentAdded() {
        var node = Node.create();
        var componentAdded = false;
        var comp:SceneManager = SceneManager.create(MinkoTests.canvas);
        var _ = node.componentAdded.connect(function(n, t, c) {
            componentAdded = node == n && node == t && c == comp;
        });

        node.addComponent(comp);

        assertTrue(componentAdded);
        assertEquals(node.getComponent(SceneManager), comp);
        assertEquals(comp.target, node);
    }


    public function testComponentRemoved() {
        var node = Node.create();
        var componentRemoved = false;
        var comp:SceneManager = SceneManager.create(MinkoTests.canvas);
        var _ = node.componentAdded.connect(function(n, t, c) {
            componentRemoved = node == n && node == t && c == comp;
        });

        node.addComponent(comp);
        node.removeComponent(comp);

        assertTrue(componentRemoved);
        assertEquals(node.getComponents(SceneManager).length, 0);
        assertEquals(comp.target, null);
    }


    public function testLayoutChanged() {
        var node = Node.create();
        var changed = false;
        var _ = node.layoutChanged.connect(function(node, target:Node) {
            changed = target.layout == 42;
        });

        node.layout = (42);

        assertTrue(changed);
    }

}
