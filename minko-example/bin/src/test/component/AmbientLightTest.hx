package test.component;
import minko.utils.MathUtil;
import glm.Mat4;
import glm.Vec3;
import minko.CloneOption;
import minko.component.AmbientLight;
import minko.component.SceneManager;
import minko.component.Transform;
import minko.scene.Node;
class AmbientLightTest extends haxe.unit.TestCase {


    private function testCreate() {
        var root = Node.create();
        var n1 = Node.create().addComponent(AmbientLight.create(10.0));
        var ambientLight1:AmbientLight = cast n1.getComponent(AmbientLight);
        assertTrue(n1.hasComponent(AmbientLight));
        assertTrue(ambientLight1.ambient == 10.0);
    }


    private function testAddLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        lights.addComponent(AmbientLight.create());
        root.addChild(lights);

        assertTrue(root.data.hasProperty("ambientLight.length"));
        assertEquals(root.data.get("ambientLight.length"), 1);
        assertTrue(root.data.hasProperty("ambientLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[0].color"), new Vec3(1.0,1.0,1.0)));
        assertTrue(root.data.hasProperty("ambientLight[0].ambient"));
        assertEquals(root.data.get("ambientLight[0].ambient"), .2);
    }


    private function testRemoveSingleLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");
        var al = AmbientLight.create();

        lights.addComponent(al);
        root.addChild(lights);
        lights.removeComponent(al);

        assertEquals(root.data.get("ambientLight.length"), 0);
        assertFalse(root.data.hasProperty("ambientLight[0].color"));
        assertFalse(root.data.hasProperty("ambientLight[0].ambient"));
    }


    private function testAddMultipleLights() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = AmbientLight.create(.1);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        assertEquals(root.data.get("ambientLight.length"), 1);
        assertTrue(root.data.hasProperty("ambientLight[0].color"));
        assertTrue(root.data.hasProperty("ambientLight[0].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertEquals(root.data.get("ambientLight[0].ambient"), .1);

        var al2 = AmbientLight.create(.2);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        assertEquals(root.data.get("ambientLight.length"), 2);
        assertTrue(root.data.hasProperty("ambientLight[1].color"));
        assertTrue(root.data.hasProperty("ambientLight[1].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertEquals(root.data.get("ambientLight[1].ambient"), .2);

        var al3 = AmbientLight.create(.3);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        assertEquals(root.data.get("ambientLight.length"), 3);
        assertTrue(root.data.hasProperty("ambientLight[2].color"));
        assertTrue(root.data.hasProperty("ambientLight[2].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[2].color"), new Vec3(0.0, 0.0, 1.0)));
        assertEquals(root.data.get("ambientLight[2].ambient"), .3);
    }


    private function testRemoveFirstLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = AmbientLight.create(.1);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = AmbientLight.create(.2);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = AmbientLight.create(.3);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al1);

        assertEquals(root.data.get("ambientLight.length"), 2);
        assertTrue(root.data.hasProperty("ambientLight[0].color"));
        assertTrue(root.data.hasProperty("ambientLight[0].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[0].color"), new Vec3(0.0, 1.0, 0.0)));
        assertEquals(root.data.get("ambientLight[0].ambient"), .2);
        assertTrue(root.data.hasProperty("ambientLight[1].color"));
        assertTrue(root.data.hasProperty("ambientLight[1].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertEquals(root.data.get("ambientLight[1].ambient"), .3);
    }


    private function testRemoveNthLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = AmbientLight.create(.1);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = AmbientLight.create(.2);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = AmbientLight.create(.3);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al2);

        assertEquals(root.data.get("ambientLight.length"), 2);
        assertTrue(root.data.hasProperty("ambientLight[0].color"));
        assertTrue(root.data.hasProperty("ambientLight[0].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertEquals(root.data.get("ambientLight[0].ambient"), .1);
        assertTrue(root.data.hasProperty("ambientLight[1].color"));
        assertTrue(root.data.hasProperty("ambientLight[1].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertEquals(root.data.get("ambientLight[1].ambient"), .3);
    }


    private function testRemoveLastLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = AmbientLight.create(.1);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = AmbientLight.create(.2);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = AmbientLight.create(.3);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al3);

        assertEquals(root.data.get("ambientLight.length"), 2);
        assertTrue(root.data.hasProperty("ambientLight[0].color"));
        assertTrue(root.data.hasProperty("ambientLight[0].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertEquals(root.data.get("ambientLight[0].ambient"), .1);
        assertTrue(root.data.hasProperty("ambientLight[1].color"));
        assertTrue(root.data.hasProperty("ambientLight[1].ambient"));
        assertTrue(MathUtil.vec3_equals(root.data.get("ambientLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertEquals(root.data.get("ambientLight[1].ambient"), .2);
    }


    private function testClone() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create().addComponent(sceneManager);
        var n1 = Node.create().addComponent(Transform.createbyMatrix4(Mat4.identity(new Mat4()))).addComponent(AmbientLight.create(10.0));

        var n2 = n1.clone(CloneOption.DEEP);
        var ambientLight2:AmbientLight = cast n2.getComponent(AmbientLight);

        var ambientLight1:AmbientLight = cast n1.getComponent(AmbientLight);
        ambientLight2.ambient = (.1);

        root.addChild(n1);
        root.addChild(n2);

        sceneManager.nextFrame(0.0, 0.0);

        assertTrue(n1.hasComponent(AmbientLight));
        assertTrue(ambientLight1.ambient == 10.0);
        assertTrue(n2.hasComponent(AmbientLight));
        assertTrue(ambientLight2.ambient == 0.1);
    }

}
