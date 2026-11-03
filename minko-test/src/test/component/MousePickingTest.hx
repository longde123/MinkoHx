package test.component;

import glm.Vec3;
import minko.component.BoundingBox;
import minko.component.MouseManager;
import minko.component.MousePicking;
import minko.input.Mouse;
import minko.math.Ray;
import minko.scene.Node;

class MousePickingTest extends haxe.unit.TestCase {
    var near:Node;
    var far:Node;
    var nearPicking:MousePicking;
    var farPicking:MousePicking;
    var mouse:Mouse;
    var manager:MouseManager;
    var root:Node;

    override public function setup() {
        mouse = Mouse.create(null);
        manager = MouseManager.create(mouse);
        root = Node.create().addComponent(manager);
        nearPicking = MousePicking.create();
        farPicking = MousePicking.create();
        near = Node.create("near").addComponent(BoundingBox.createbySize(2.0, new Vec3())).addComponent(nearPicking);
        far = Node.create("far").addComponent(BoundingBox.createbySize(2.0, new Vec3(0.0, 0.0, -4.0))).addComponent(farPicking);
        root.addChild(near).addChild(far);
    }

    function ray(?origin:Vec3):Ray {
        return Ray.createbyVector3(origin == null ? new Vec3(0.0, 0.0, 5.0) : origin, new Vec3(0.0, 0.0, -1.0));
    }

    public function testNearestHoverAndButtons() {
        var move = 0;
        var over = 0;
        var rollOver = 0;
        var down = 0;
        var up = 0;
        nearPicking.move.connect(function(_, _, _) move++);
        nearPicking.over.connect(function(_, _, _) over++);
        nearPicking.rollOver.connect(function(_, _, _) rollOver++);
        nearPicking.leftButtonDown.connect(function(_, _, _) down++);
        nearPicking.leftButtonUp.connect(function(_, _, _) up++);

        var hits = manager.pick(ray());
        assertEquals(hits.length, 2);
        assertEquals(hits[0].first, near);
        assertTrue(Math.abs(hits[0].second - 4.0) < 0.0001);
        manager.pick(ray());
        assertEquals(move, 1);
        assertEquals(over, 2);
        assertEquals(rollOver, 1);
        mouse.leftButtonDown.execute(mouse);
        mouse.leftButtonUp.execute(mouse);
        assertEquals(down, 1);
        assertEquals(up, 1);
    }

    public function testOutAndTargetSwitch() {
        var nearOut = 0;
        var nearRollOut = 0;
        var farRollOver = 0;
        nearPicking.out.connect(function(_, _, _) nearOut++);
        nearPicking.rollOut.connect(function(_, _, _) nearRollOut++);
        farPicking.rollOver.connect(function(_, _, _) farRollOver++);

        manager.pick(ray());
        manager.pick(ray(new Vec3(10.0, 0.0, 5.0)));
        assertEquals(nearOut, 1);
        assertEquals(nearRollOut, 1);
        var farHits = manager.pick(ray(new Vec3(0.0, 0.0, -2.0)));
        assertEquals(farHits.length, 1);
        assertEquals(farHits[0].first, far);
        assertEquals(farRollOver, 1);
        manager.pick(ray(new Vec3(0.0, 0.0, -2.0)));
        assertEquals(farRollOver, 1);
    }

    public function testRemovalAndManagerDispose() {
        var nearOut = 0;
        var down = 0;
        nearPicking.out.connect(function(_, _, _) nearOut++);
        nearPicking.leftButtonDown.connect(function(_, _, _) down++);
        manager.pick(ray());
        root.removeChild(near);
        var hits = manager.pick(ray());
        assertEquals(hits[0].first, far);
        assertEquals(nearOut, 1);
        mouse.leftButtonDown.execute(mouse);
        assertEquals(down, 0);
        root.removeComponent(manager);
        mouse.leftButtonDown.execute(mouse);
        assertEquals(down, 0);
    }
}
