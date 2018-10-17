package test.scene;
import minko.scene.Node;
import minko.scene.NodeSet;
class NodeSetTest extends haxe.unit.TestCase {

    public function testDescendantsBreadthFirst() {
        var scene = Node.create().addChild(Node.create()).addChild(Node.create());
        var nodeSet = NodeSet.createbyNode(scene).descendants(true, false);

        assertEquals(nodeSet.nodes[0], scene);
        assertEquals(nodeSet.nodes[1], scene.children[0]);
        assertEquals(nodeSet.nodes[2], scene.children[1]);
    }


    public function testDescendantsBreadthFirst2() {
        var scene = Node.create().addChild(Node.create().addChild(Node.create())).addChild(Node.create());
        var nodeSet = NodeSet.createbyNode(scene).descendants(true, false);

        assertEquals(nodeSet.nodes[0], scene);
        assertEquals(nodeSet.nodes[1], scene.children[0]);
        assertEquals(nodeSet.nodes[2], scene.children[1]);
        assertEquals(nodeSet.nodes[3], scene.children[0].children[0]);
    }


    public function testDescendantsBreadthFirst3() {
        var scene = Node.create().addChild(Node.create().addChild(Node.create()).addChild(Node.create())).addChild(Node.create());
        var nodeSet = NodeSet.createbyNode(scene).descendants(true, false);

        assertEquals(nodeSet.nodes[0], scene);
        assertEquals(nodeSet.nodes[1], scene.children[0]);
        assertEquals(nodeSet.nodes[2], scene.children[1]);
        assertEquals(nodeSet.nodes[3], scene.children[0].children[0]);
        assertEquals(nodeSet.nodes[4], scene.children[0].children[1]);
    }


    public function testDescendantsBreadthFirst4() {
        var scene = Node.create().addChild(Node.create().addChild(Node.create().addChild(Node.create())).addChild(Node.create())).addChild(Node.create().addChild(Node.create()));
        var nodeSet = NodeSet.createbyNode(scene).descendants(true, false);

        assertEquals(nodeSet.nodes[0], scene);
        assertEquals(nodeSet.nodes[1], scene.children[0]);
        assertEquals(nodeSet.nodes[2], scene.children[1]);
        assertEquals(nodeSet.nodes[3], scene.children[0].children[0]);
        assertEquals(nodeSet.nodes[4], scene.children[0].children[1]);
        assertEquals(nodeSet.nodes[5], scene.children[1].children[0]);
        assertEquals(nodeSet.nodes[6], scene.children[0].children[0].children[0]);
    }


    public function testDescendantsBreadthFirst5() {
        var scene = Node.create().addChild(Node.create().addChild(Node.create().addChild(Node.create().addChild(Node.create().addChild(Node.create().addChild(Node.create()))))));
        var nodeSet = NodeSet.createbyNode(scene).descendants(true, false);

        for (i in 0...6) {
            assertEquals(nodeSet.nodes[i], scene);
            scene = scene.children[0];
        }
    }

}
