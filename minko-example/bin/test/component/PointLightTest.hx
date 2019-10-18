package test.component;
import minko.utils.MathUtil;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import minko.CloneOption;
import minko.component.PointLight;
import minko.component.SceneManager;
import minko.component.Transform;
import minko.scene.Node;
import minko.utils.MathUtil;
class PointLightTest extends haxe.unit.TestCase {


    public function testCreate() {
        var root = Node.create();
        var n1 = Node.create().addComponent(PointLight.create(10.0));

        var pointLight:PointLight = cast n1.getComponent(PointLight);
        assertTrue(n1.hasComponent(PointLight));
        assertTrue(pointLight.diffuse == 10.0);
    }


    public function testAddLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        lights.addComponent(PointLight.create(.1, .3));
        root.addChild(lights);

        assertTrue(root.data.hasProperty("pointLight.length"));
        assertEquals(root.data.get("pointLight.length"), 1);
        assertTrue(root.data.hasProperty("pointLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[0].color"), new Vec3(1.0, 1.0, 1.0)));
        assertTrue(root.data.hasProperty("pointLight[0].diffuse"));
        assertEquals(root.data.get("pointLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("pointLight[0].specular"));
        assertEquals(root.data.get("pointLight[0].specular"), .3);
    }


    public function testRemoveSingleLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");
        var al = PointLight.create();

        lights.addComponent(al);
        root.addChild(lights);
        lights.removeComponent(al);

        assertEquals(root.data.get("pointLight.length"), 0);
        assertFalse(root.data.hasProperty("pointLight[0].color"));
        assertFalse(root.data.hasProperty("pointLight[0].diffuse"));
        assertFalse(root.data.hasProperty("pointLight[0].specular"));
    }


    public function testAddMultipleLights() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = PointLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        assertEquals(root.data.get("pointLight.length"), 1);
        assertTrue(root.data.hasProperty("pointLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertTrue(root.data.hasProperty("pointLight[0].diffuse"));
        assertEquals(root.data.get("pointLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("pointLight[0].specular"));
        assertEquals(root.data.get("pointLight[0].specular"), .2);

        var al2 = PointLight.create(.3, .4);
        al2.color=(new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        assertEquals(root.data.get("pointLight.length"), 2);
        assertTrue(root.data.hasProperty("pointLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("pointLight[1].diffuse"));
        assertEquals(root.data.get("pointLight[1].diffuse"), .3);
        assertTrue(root.data.hasProperty("pointLight[1].specular"));
        assertEquals(root.data.get("pointLight[1].specular"), .4);

        var al3 = PointLight.create(.5, .6);
        al3.color=(new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        assertEquals(root.data.get("pointLight.length"), 3);
        assertTrue(root.data.hasProperty("pointLight[2].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[2].color"), new Vec3(0.0, 0.0, 1.0)));
        assertTrue(root.data.hasProperty("pointLight[2].diffuse"));
        assertEquals(root.data.get("pointLight[2].diffuse"), .5);
        assertTrue(root.data.hasProperty("pointLight[2].specular"));
        assertEquals(root.data.get("pointLight[2].specular"), .6);
    }


    public function testRemoveFirstLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = PointLight.create(.1, .2);
        al1.color=(new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = PointLight.create(.3, .4);
        al2.color=(new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = PointLight.create(.5, .6);
        al3.color=(new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al1);

        assertEquals(root.data.get("pointLight.length"), 2);
        assertTrue(root.data.hasProperty("pointLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[0].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("pointLight[0].diffuse"));
        assertEquals(root.data.get("pointLight[0].diffuse"), .3);
        assertTrue(root.data.hasProperty("pointLight[0].specular"));
        assertEquals(root.data.get("pointLight[0].specular"), .4);
        assertTrue(root.data.hasProperty("pointLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertTrue(root.data.hasProperty("pointLight[1].diffuse"));
        assertEquals(root.data.get("pointLight[1].diffuse"), .5);
        assertTrue(root.data.hasProperty("pointLight[1].specular"));
        assertEquals(root.data.get("pointLight[1].specular"), .6);
    }


    public function testRemoveNthLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = PointLight.create(.1, .2);
        al1.color=(new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = PointLight.create(.3, .4);
        al2.color=(new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = PointLight.create(.5, .6);
        al3.color=(new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al2);

        assertEquals(root.data.get("pointLight.length"), 2);
        assertTrue(root.data.hasProperty("pointLight[0].color"));
        assertTrue(root.data.hasProperty("pointLight[0].diffuse"));
        assertTrue(root.data.hasProperty("pointLight[0].specular"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertEquals(root.data.get("pointLight[0].diffuse"), .1);
        assertEquals(root.data.get("pointLight[0].specular"), .2);
        assertTrue(root.data.hasProperty("pointLight[1].color"));
        assertTrue(root.data.hasProperty("pointLight[1].diffuse"));
        assertTrue(root.data.hasProperty("pointLight[1].specular"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertEquals(root.data.get("pointLight[1].diffuse"), .5);
        assertEquals(root.data.get("pointLight[1].specular"), .6);
    }


    public function testRemoveLastLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = PointLight.create(.1, .2);
        al1.color=(new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = PointLight.create(.3, .4);
        al2.color=(new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = PointLight.create(.5, .6);
        al3.color=(new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al3);

        assertEquals(root.data.get("pointLight.length"), 2);
        assertTrue(root.data.hasProperty("pointLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertTrue(root.data.hasProperty("pointLight[0].diffuse"));
        assertEquals(root.data.get("pointLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("pointLight[0].specular"));
        assertEquals(root.data.get("pointLight[0].specular"), .2);
        assertTrue(root.data.hasProperty("pointLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("pointLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("pointLight[1].diffuse"));
        assertEquals(root.data.get("pointLight[1].diffuse"), .3);
        assertTrue(root.data.hasProperty("pointLight[1].specular"));
        assertEquals(root.data.get("pointLight[1].specular"), .4);
    }


    public function testTranslateXYZ() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = PointLight.create(.1, .2);
        al1.color=(new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var t = MathUtil.sphericalRand(100.0);
        lights.addComponent(Transform.createbyMatrix4(GLM.translate(t, new Mat4())));
        var transform:Transform =cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        var epsilon = 0.00001;

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("pointLight[0].position"), t, epsilon));
    }


    public function testClone() {
        var sceneManager = SceneManager.create(MinkoTests.canvas );
        var root = Node.create().addComponent(sceneManager);
        var n1 = Node.create().addComponent(Transform.createbyMatrix4(Mat4.identity(new Mat4()))).addComponent(PointLight.create(10.0));

        var pointLight1:PointLight = cast n1.getComponent(PointLight);
        var n2 = n1.clone(CloneOption.DEEP);
        var pointLight2:PointLight = cast n2.getComponent(PointLight);
        pointLight2.diffuse = (.1);


        root.addChild(n1);
        root.addChild(n2);

        sceneManager.nextFrame(0.0, 0.0);

        assertTrue(n1.hasComponent(PointLight));
        assertTrue(pointLight1.diffuse == 10.0);
        assertTrue(n2.hasComponent(PointLight));
        assertTrue(pointLight2.diffuse == 0.1);

        var l1 = pointLight1;
        var l2 = pointLight2;
        assertTrue(l1.attenuationCoefficients == l2.attenuationCoefficients);

        var newCoeffs = new Vec3(1.5, 1, 1.5);

        l2.attenuationCoefficients = (newCoeffs);
        assertTrue(l2.attenuationCoefficients == newCoeffs);
        assertFalse(l1.attenuationCoefficients == l2.attenuationCoefficients);
 
        assertTrue(MathUtil.vec3_equals(l1.position , l2.position));
        var n2Transform:Transform = cast n2.getComponent(Transform);
        n2Transform.matrix = (GLM.translate(new Vec3( -5.0, 0, 2), new Mat4()) * n2Transform.matrix);


        sceneManager.nextFrame(0.0, 0.0);
        assertFalse(MathUtil.vec3_equals(l1.position , l2.position));

    }

}
