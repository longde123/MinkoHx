package test.scene;

import minko.component.AbstractComponent;
import minko.scene.Node;

class NodeLifecycleTest extends haxe.unit.TestCase {
    function expectFailure(callback:Void->Void) {
        var failed = false;
        try callback() catch (_) failed = true;
        assertTrue(failed);
    }

    public function testInvalidHierarchyDoesNotMutate() {
        var root = Node.create("root");
        var child = Node.create("child");
        root.addChild(child);
        expectFailure(function() root.addChild(root));
        expectFailure(function() child.addChild(root));
        expectFailure(function() root.addChild(child));
        expectFailure(function() root.addChild(null));
        assertEquals(root.children.length, 1);
        assertEquals(child.parent, root);
        assertEquals(root.parent, null);
    }

    public function testDisposeEntireSubtreeOnce() {
        CountingComponent.disposeCount = 0;
        var first = new CountingComponent();
        var second = new CountingComponent();
        var childComponent = new CountingComponent();
        var child = Node.create().addComponent(childComponent);
        var root = Node.create().addComponent(first).addComponent(second).addChild(child);
        var parent = Node.create().addChild(root);

        root.dispose();
        root.dispose();
        assertEquals(CountingComponent.disposeCount, 3);
        assertEquals(parent.children.length, 0);
        assertTrue(first.target == null);
        assertTrue(second.target == null);
        assertTrue(childComponent.target == null);
        assertTrue(root.components == null);
        assertTrue(child.parent == null);
    }
}

class CountingComponent extends AbstractComponent {
    public static var disposeCount = 0;

    override public function dispose() {
        disposeCount++;
        super.dispose();
    }
}
