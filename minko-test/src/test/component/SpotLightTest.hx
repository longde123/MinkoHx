package test.component;
import minko.utils.MathUtil;
import js.html.webgl.GL;
import minko.utils.MathUtil;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import minko.CloneOption;
import minko.component.SceneManager;
import minko.component.SpotLight;
import minko.component.Transform;
import minko.scene.Node;
import minko.utils.MathUtil;
class SpotLightTest extends haxe.unit.TestCase {

    public function testCreate() {
        var root = Node.create();
        var n1 = Node.create().addComponent(SpotLight.create(10.0, - 1.0, Math.PI * 0.25));
        var spotLight:SpotLight=cast n1.getComponent(SpotLight);
        var diffuse =spotLight.diffuse ;

        assertTrue(n1.hasComponent(SpotLight));
        assertTrue(spotLight.diffuse == 10.0);
    }


    public function testAddLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        lights.addComponent(SpotLight.create(.1, .3));
        root.addChild(lights);

        assertTrue(root.data.hasProperty("spotLight.length"));
        assertEquals(root.data.get("spotLight.length"), 1);
        assertTrue(root.data.hasProperty("spotLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[0].color"), new Vec3(1.0,1.0,1.0)));
        assertTrue(root.data.hasProperty("spotLight[0].diffuse"));
        assertEquals(root.data.get("spotLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("spotLight[0].specular"));
        assertEquals(root.data.get("spotLight[0].specular"), .3);
    }

    public function testRemoveSingleLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");
        var al = SpotLight.create();

        lights.addComponent(al);
        root.addChild(lights);
        lights.removeComponent(al);

        assertEquals(root.data.get("spotLight.length"), 0);
        assertFalse(root.data.hasProperty("spotLight[0].color"));
        assertFalse(root.data.hasProperty("spotLight[0].diffuse"));
        assertFalse(root.data.hasProperty("spotLight[0].specular"));
    }


    public function testAddMultipleLights() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color=(new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        assertEquals(root.data.get("spotLight.length"), 1);
        assertTrue(root.data.hasProperty("spotLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[0].color"),new Vec3(1.0, 0.0, 0.0)));
        assertTrue(root.data.hasProperty("spotLight[0].diffuse"));
        assertEquals(root.data.get("spotLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("spotLight[0].specular"));
        assertEquals(root.data.get("spotLight[0].specular"), .2);

        var al2 = SpotLight.create(.3, .4);
        al2.color=(new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        assertEquals(root.data.get("spotLight.length"), 2);
        assertTrue(root.data.hasProperty("spotLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("spotLight[1].diffuse"));
        assertEquals(root.data.get("spotLight[1].diffuse"), .3);
        assertTrue(root.data.hasProperty("spotLight[1].specular"));
        assertEquals(root.data.get("spotLight[1].specular"), .4);

        var al3 = SpotLight.create(.5, .6);
        al3.color=(new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        assertEquals(root.data.get("spotLight.length"), 3);
        assertTrue(root.data.hasProperty("spotLight[2].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[2].color"), new Vec3(0.0, 0.0, 1.0)));
        assertTrue(root.data.hasProperty("spotLight[2].diffuse"));
        assertEquals(root.data.get("spotLight[2].diffuse"), .5);
        assertTrue(root.data.hasProperty("spotLight[2].specular"));
        assertEquals(root.data.get("spotLight[2].specular"), .6);
    }


    public function testRemoveFirstLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = SpotLight.create(.3, .4);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = SpotLight.create(.5, .6);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al1);

        assertEquals(root.data.get("spotLight.length"), 2);
        assertTrue(root.data.hasProperty("spotLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[0].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("spotLight[0].diffuse"));
        assertEquals(root.data.get("spotLight[0].diffuse"), .3);
        assertTrue(root.data.hasProperty("spotLight[0].specular"));
        assertEquals(root.data.get("spotLight[0].specular"), .4);
        assertTrue(root.data.hasProperty("spotLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertTrue(root.data.hasProperty("spotLight[1].diffuse"));
        assertEquals(root.data.get("spotLight[1].diffuse"), .5);
        assertTrue(root.data.hasProperty("spotLight[1].specular"));
        assertEquals(root.data.get("spotLight[1].specular"), .6);
    }

    public function testRemoveNthLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = SpotLight.create(.3, .4);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = SpotLight.create(.5, .6);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al2);

        assertEquals(root.data.get("spotLight.length"), 2);
        assertTrue(root.data.hasProperty("spotLight[0].color"));
        assertTrue(root.data.hasProperty("spotLight[0].diffuse"));
        assertTrue(root.data.hasProperty("spotLight[0].specular"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertEquals(root.data.get("spotLight[0].diffuse"), .1);
        assertEquals(root.data.get("spotLight[0].specular"), .2);
        assertTrue(root.data.hasProperty("spotLight[1].color"));
        assertTrue(root.data.hasProperty("spotLight[1].diffuse"));
        assertTrue(root.data.hasProperty("spotLight[1].specular"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertEquals(root.data.get("spotLight[1].diffuse"), .5);
        assertEquals(root.data.get("spotLight[1].specular"), .6);
    }


    public function testRemoveLastLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = SpotLight.create(.3, .4);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = SpotLight.create(.5, .6);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al3);

        assertEquals(root.data.get("spotLight.length"), 2);
        assertTrue(root.data.hasProperty("spotLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertTrue(root.data.hasProperty("spotLight[0].diffuse"));
        assertEquals(root.data.get("spotLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("spotLight[0].specular"));
        assertEquals(root.data.get("spotLight[0].specular"), .2);
        assertTrue(root.data.hasProperty("spotLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("spotLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("spotLight[1].diffuse"));
        assertEquals(root.data.get("spotLight[1].diffuse"), .3);
        assertTrue(root.data.hasProperty("spotLight[1].specular"));
        assertEquals(root.data.get("spotLight[1].specular"), .4);
    }
    static var PI=3.14159274;
    public function testRotateXPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);
        var rot:Quat = Quat.axisAngle(new Vec3(1.0, 0.0, 0.0),PI   ,  new Quat()  );
        var mat4:Mat4=GLM.rotate(rot,Mat4.identity(new Mat4())   ) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].direction"), new Vec3(0.0, 0.0, 1.0)));
    }
    public function testRotateXHalfPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);
        var rot:Quat = Quat.axisAngle(new Vec3(1.0, 0.0, 0.0), PI / 2, new Quat());
        var mat4:Mat4=GLM.rotate(rot,Mat4.identity(new Mat4())   ) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].direction"), new Vec3(0.0, 1.0, 0.0)));
    }


    public function testRotateYPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);
        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), Math.PI, new Quat());
        var mat4:Mat4=GLM.rotate(rot,Mat4.identity(new Mat4())   ) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].direction"), new Vec3(0.0, 0.0, 1.0)));
    }


    public function testRotateYHalfPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);
        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), Math.PI / 2, new Quat());
        var mat4:Mat4=GLM.rotate(rot,Mat4.identity(new Mat4())   ) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));

        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].direction"), new Vec3(-1.0, 0.0, 0.0)));
    }


    public function testRotateZPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);
        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), Math.PI, new Quat());
        var mat4:Mat4=GLM.rotate(rot,Mat4.identity(new Mat4())   ) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));
    }


    public function testRotateZHalfPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);
        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), Math.PI / 2, new Quat());
        var mat4:Mat4=GLM.rotate(rot,Mat4.identity(new Mat4())   ) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));
    }


    public function testTranslateXYZ() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = SpotLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var t = MathUtil.sphericalRand(100.0);
        lights.addComponent(Transform.createbyMatrix4(GLM.translate(t, new Mat4())));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        var epsilon = 0.00001;

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));
        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("spotLight[0].position"), t,epsilon));
    }

    public function testClone() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create().addComponent(sceneManager);
        var n1 = Node.create()
        .addComponent(Transform.createbyMatrix4(Mat4.identity(new Mat4())))
        .addComponent(SpotLight.create(10.0, -1.0, Math.PI * 0.25));
        var spotLight1:SpotLight =cast n1.getComponent(SpotLight);
        var n2 = n1.clone(CloneOption.DEEP);
        var spotLight2:SpotLight =cast n2.getComponent(SpotLight);
        spotLight2.diffuse = (.1);

        root.addChild(n1);
        root.addChild(n2);

        sceneManager.nextFrame(0.0, 0.0);

        assertTrue(n1.hasComponent(SpotLight));
        assertTrue(spotLight1.diffuse == 10.0);
        assertTrue(n2.hasComponent(SpotLight));
        assertTrue(spotLight2.diffuse == 0.1);

        var l1 = spotLight1;
        var l2 = spotLight2;
        assertTrue(l1.attenuationCoefficients == l2.attenuationCoefficients);

        var newCoeffs = new Vec3(1.5, 1, 1.5);

        l2.attenuationCoefficients=(newCoeffs);
        assertTrue(l2.attenuationCoefficients == newCoeffs);
        assertFalse(l1.attenuationCoefficients == l2.attenuationCoefficients);

        assertTrue(MathUtil.vec3_equals(l1.position , l2.position));
        var n2Transform:Transform =cast n2.getComponent(Transform);
        n2Transform.matrix=(GLM.translate(new Vec3( -5.0, 0, 2), new Mat4()) * n2Transform.matrix);
        sceneManager.nextFrame(0.0, 0.0);

        assertFalse(MathUtil.vec3_equals(l1.position , l2.position));
    }


}
