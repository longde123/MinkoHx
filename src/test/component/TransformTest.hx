package test.component;
import minko.component.Transform.RootTransform;
import minko.CloneOption;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.component.SceneManager;
import minko.component.Transform;
import minko.scene.Node;
import minko.utils.MathUtil;
class TransformTest extends haxe.unit.TestCase {
    public function testUniqueRootTransform() {
        var root = Node.create();
        var n1 = Node.create().addComponent(Transform.create());
        var n2 = Node.create().addComponent(Transform.create());
        var n3 = Node.create();

        assertFalse(root.hasComponent(RootTransform));
        assertTrue(n1.hasComponent(RootTransform));
        assertTrue(n2.hasComponent(RootTransform));
        assertFalse(n3.hasComponent(RootTransform));

        n3.addChild(n1);
        assertFalse(root.hasComponent(RootTransform));
        assertFalse(n1.hasComponent(RootTransform));
        assertTrue(n2.hasComponent(RootTransform));
        assertTrue(n3.hasComponent(RootTransform));

        root.addChild(n3);
        assertTrue(root.hasComponent(RootTransform));
        assertFalse(n1.hasComponent(RootTransform));
        assertTrue(n2.hasComponent(RootTransform));
        assertFalse(n3.hasComponent(RootTransform));

        root.addChild(n2);
        assertTrue(root.hasComponent(RootTransform));
        assertFalse(n1.hasComponent(RootTransform));
        assertFalse(n2.hasComponent(RootTransform));
        assertFalse(n3.hasComponent(RootTransform));

        var n4 = Node.create().addComponent(Transform.create());
        assertTrue(n4.hasComponent(RootTransform));

        n2.addChild(n4);
        assertTrue(root.hasComponent(RootTransform));
        assertFalse(n1.hasComponent(RootTransform));
        assertFalse(n2.hasComponent(RootTransform));
        assertFalse(n3.hasComponent(RootTransform));
        assertFalse(n4.hasComponent(RootTransform));
    }

    public function testModelToWorldUpdate() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create().addComponent(sceneManager);
        var n1Transform = Transform.create();
        var n1 = Node.create().addComponent(n1Transform);
        var n2 = Node.create().addComponent(Transform.create());

        root.addChild(n1).addChild(n2);
        // init. modelToWorldMatrix by performing a first frame
        sceneManager.nextFrame(0.0, 0.0);

        var updated1 = false;

        var _ = n1.data.getPropertyChanged("modelToWorldMatrix").connect(function(c, p, propertyName) {
            updated1 = true;
        });

        var updated2 = false;

        var __ = n2.data.getPropertyChanged("modelToWorldMatrix").connect(function(c, p, propertyName) {
            updated2 = true;
        });

        n1Transform.matrix = GLM.translate(new Vec3(1.0, 0.0, 0.0), n1Transform.matrix) ;
        //n2->component<Transform>()->matrix()->appendTranslation(1.f);

        sceneManager.nextFrame(0.0, 0.0);

        assertTrue(updated1);
        assertFalse(updated2);
    }

    public function testModelToWorldMultipleUpdates() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create().addComponent(sceneManager);
        var n1Transform = Transform.create();
        var n1 = Node.create().addComponent(n1Transform);
        var n2 = Node.create().addComponent(Transform.create());
        var n3Transform = Transform.create();
        var n3 = Node.create().addComponent(n3Transform);

        root.addChild(n1).addChild(n2);
        n2.addChild(n3);
        // init. modelToWorldMatrix by performing a first frame
        sceneManager.nextFrame(0.0, 0.0);

        var updated1 = false;

        var _ = n1.data.getPropertyChanged("modelToWorldMatrix").connect(function(c, p, propertyName) {
            updated1 = true;
        });

        var updated2 = false;

        var __ = n3.data.getPropertyChanged("modelToWorldMatrix").connect(function(c, p, propertyName) {
            updated2 = true;
        });

        n1Transform.matrix = (GLM.translate(new Vec3(1.0, 0.0, 0.0), n1Transform.matrix));
        n3Transform.matrix = (GLM.translate(new Vec3(1.0, 0.0, 0.0), n3Transform.matrix));

        sceneManager.nextFrame(0.0, 0.0);

        assertTrue(updated1);
        assertTrue(updated2);
    }

    public function testModelToWorldMultipleUpdatesMultipleFrames() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create().addComponent(sceneManager);
        var n1Transform = Transform.create();
        var n1 = Node.create().addComponent(n1Transform);
        var n2 = Node.create().addComponent(Transform.create());
        var n3Transform = Transform.create();
        var n3 = Node.create().addComponent(n3Transform);

        root.addChild(n1).addChild(n2);

        // init. modelToWorldMatrix by performing a first frame
        sceneManager.nextFrame(0.0, 0.0);

        var updated1 = false;

        var _ = n1.data.getPropertyChanged("modelToWorldMatrix").connect(function(c, p, propertyName) {
            updated1 = true;
        });

        var updated2 = false;

        var __ = n3.data.getPropertyChanged("modelToWorldMatrix").connect(function(c, p, propertyName) {
            updated2 = true;
        });

        n1Transform.matrix = (GLM.translate(new Vec3(42.0, 0.0, 0.0), n1Transform.matrix));

        sceneManager.nextFrame(0.0, 0.0);

        n2.addChild(n3);
        n3Transform.matrix = (GLM.translate(new Vec3(42.0, 0.0, 0.0), n3Transform.matrix));

        sceneManager.nextFrame(0.0, 0.0);

        assertTrue(updated1);
        assertTrue(updated2);
    }


    public function testNodeHierarchyTransformIssueWithBlockingNode() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);

        var root = Node.create("root").addComponent(sceneManager);

        var n1 = Node.create("b");
        var n2 = Node.create("j");
        var n3 = Node.create("r");
        var n4 = Node.create("g");
        var p3 = Node.create("z");
        var p2 = Node.create("t");
        p2.addComponent(Transform.create());
        var p1 = Node.create("f");
        //p1->addComponent(Transform::create());


        var n5 = Node.create("cb");
        n5.addComponent(Transform.create());
        n1.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-4.0, 0.0, 0.0), new Mat4())));
        n2.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-5.0, 0.0, 0.0), new Mat4())));
        n3.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(4.0, 0, 0.0), new Mat4())));
        n4.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(5.0, 0.0, 0.0), new Mat4())));

        root.addChild(p2);
        p2.addChild(p1);
        p1.addChild(n3);
        p1.addChild(n4);
        p2.addChild(n5);

        root.addChild(p3);
        p3.addChild(n1);
        p3.addChild(n2);

        sceneManager.nextFrame(0.0, 0.0);

        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n2Transform:Transform = cast n2.getComponent(Transform);

        var n3Transform:Transform = cast n3.getComponent(Transform);
        var n4Transform:Transform = cast n4.getComponent(Transform);


        var p2Transform:Transform = cast p2.getComponent(Transform);
        n1Transform.matrix = (GLM.translate(new Vec3(0.0, -1.0, 0.0), new Mat4()) * n1Transform.matrix);
        p2Transform.matrix = (GLM.translate(new Vec3(0.0, 1.0, 0.0), new Mat4()) * p2Transform.matrix );

        sceneManager.nextFrame(0.0, 0.0);

        var zero = new Vec4(0.0, 0.0, 0.0, 1.0);


        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n1Transform.matrix * zero), new Vec3(-4.0, -1.0, 0.0)));
        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n2Transform.matrix * zero), new Vec3(-5.0, 0.0, 0.0)));
        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n3Transform.modelToWorldMatrix * zero), new Vec3(4.0, 1.0, 0.0)));
        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n4Transform.modelToWorldMatrix * zero), new Vec3(5.0, 1.0, 0.0)));
    }

    public function testNodeHierarchyTransformIssueWithoutBlockingNode() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);

        var root = Node.create("root").addComponent(sceneManager);

        var n1 = Node.create("b");
        var n2 = Node.create("j");
        var n3 = Node.create("r");
        var n4 = Node.create("g");
        var p3 = Node.create("z");
        var p2 = Node.create("t");
        var p1 = Node.create("f");
        p2.addComponent(Transform.create());

        var n5 = Node.create("cb");
        n5.addComponent(Transform.create());

        n1.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-4.0, 0.0, 0.0), new Mat4())));

        n2.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-5.0, 0.0, 0.0), new Mat4())));


        n3.addComponent(Transform.createbyMatrix4(GLM.scale(new Vec3(5, 5, 5), new Mat4()) * GLM.translate(new Vec3(4.0, 0.0, 0.0), new Mat4())));

        n4.addComponent(Transform.createbyMatrix4(GLM.scale(new Vec3(10, 10, 10), new Mat4()) * GLM.translate(new Vec3(5.0, 0.0, 0.0), new Mat4())));

        root.addChild(p2);
        p2.addChild(p1);
        p1.addChild(n3);
        p1.addChild(n4);
        p2.addChild(n5);

        root.addChild(p3);
        p3.addChild(n1);
        p3.addChild(n2);

        sceneManager.nextFrame(0.0, 0.0);

        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n2Transform:Transform = cast n2.getComponent(Transform);

        var n3Transform:Transform = cast n3.getComponent(Transform);
        var n4Transform:Transform = cast n4.getComponent(Transform);

        var p2Transform:Transform = cast p2.getComponent(Transform);

        n1Transform.matrix = (GLM.translate(new Vec3(0.0, -1.0, 0.0), new Mat4()) * n1Transform.matrix);
        p2Transform.matrix = (GLM.translate(new Vec3(0.0, 1.0, 0.0), new Mat4()) * p2Transform.matrix);

        sceneManager.nextFrame(0.0, 0.0);

        var zero = new Vec4(0.0, 0.0, 0.0, 1.0);


        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n1Transform.matrix * zero), new Vec3(-4.0, -1.0, 0.0)));
        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n2Transform.matrix * zero), new Vec3(-5.0, 0.0, 0.0)));
        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n3Transform.modelToWorldMatrix * zero), new Vec3(20.0, 1.0, 0.0)));
        assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n4Transform.modelToWorldMatrix * zero), new Vec3(50.0, 1.0, 0.0)));

    }



    public function testRemoveParentTransform() {
        var root = Node.create("root");
        var a = Node.create("a");
        var b = Node.create("b");
        var c = Node.create("c");

        root.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));
        a.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4())));

        root.addChild(a);


        b.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(0.0, 1.0, 0.0), new Mat4())));

        root.addChild(b);

        c.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(2.0, 1.0, 0.0), new Mat4())));

        b.addChild(c);

        b.removeComponent(b.getComponent(Transform));

        var cTransform:Transform = cast c.getComponent(Transform);
        cTransform.updateModelToWorldMatrix();

        assertTrue(cTransform.modelToWorldMatrix.equals(GLM.translate(new Vec3(2.0, 1.0, 1.0), new Mat4())));
    }


    public function testClone() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);
        var root = Node.create().addComponent(sceneManager);
        var n1:Node = Node.create().addComponent(Transform.createbyMatrix4(  Mat4.identity(new Mat4())));

        var n2 = n1.clone(CloneOption.DEEP);

        root.addChild(n1);
        root.addChild(n2);

        sceneManager.nextFrame(0.0, 0.0);


        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n2Transform:Transform = cast n2.getComponent(Transform);

        assertTrue(n2Transform.matrix.equals(n1Transform.matrix));

        n2Transform.matrix = (GLM.translate(new Vec3(-5.0, 0, 2), new Mat4()) * n2Transform.matrix);
        sceneManager.nextFrame(0.0, 0.0);

        assertFalse(n2Transform.matrix.equals(n1Transform.matrix));
    }

    public function testWrongModelToWorldIssue() {
        var sceneManager = SceneManager.create(MinkoTests.canvas);

        var root = Node.create().addComponent(sceneManager);
        var n1_mat4:Mat4 = Mat4.invert(GLM.lookAt(new Vec3(42.0, 42.0, 42.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4());
        var n1 = Node.create("n1").addComponent(Transform.createbyMatrix4(n1_mat4));

        var n2 = Node.create("n2").addComponent(Transform.create());
        var n21 = Node.create("n21").addComponent(Transform.create());

        root.addChild(n1);
        root.addChild(n2);
        n2.addChild(n21);
        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n2Transform:Transform = cast n2.getComponent(Transform);
        var n21Transform:Transform = cast n21.getComponent(Transform);
        sceneManager.nextFrame(0.0, 0.0);

     assertTrue(MathUtil.vec3_equals(MathUtil.vec4_vec3(n1Transform.matrix * MathUtil.vec3_vec4(new Vec3(), 1)), new Vec3(42.0, 42.0, 42.0)));
        assertTrue(n2Transform.modelToWorldMatrix.equals( Mat4.identity(new Mat4())));
        assertTrue(n21Transform.modelToWorldMatrix.equals( Mat4.identity(new Mat4())));
    }


    public function testRemoveTransformRow() {
        var root = Node.create("root");

        var n0 = Node.create("n0");
        var n1 = Node.create("n1");

        var n00 = Node.create("n00");
        var n10 = Node.create("n10");

        var n000 = Node.create("n000");
        var n100 = Node.create("n100");

        root.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        n0.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n1.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4())));

        n00.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n10.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));

        n000.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n100.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));

        root.addChild(n0);
        root.addChild(n1);

        n0.addChild(n00);
        n1.addChild(n10);

        n00.addChild(n000);
        n10.addChild(n100);


        var rootTransform:Transform = cast root.getComponent(Transform);
        var n0Transform:Transform = cast n0.getComponent(Transform);
        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n00Transform:Transform = cast n00.getComponent(Transform);
        var n10Transform:Transform = cast n10.getComponent(Transform);
        var n000Transform:Transform = cast n000.getComponent(Transform);
        var n100Transform:Transform = cast n100.getComponent(Transform);

        rootTransform.updateModelToWorldMatrix();

        assertTrue(rootTransform.modelToWorldMatrix.equals(GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        assertTrue(n0Transform.modelToWorldMatrix.equals(GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));
        assertTrue(n1Transform.modelToWorldMatrix.equals(GLM.translate(new Vec3(1.0, 0.0, 1.0), new Mat4())));

        assertTrue(n00Transform.modelToWorldMatrix.equals(GLM.translate(new Vec3(-2.0, 0.0, 1.0), new Mat4())));
        assertTrue(n10Transform.modelToWorldMatrix.equals(GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        assertTrue(n000Transform.modelToWorldMatrix.equals(GLM.translate(new Vec3(-3.0, 0.0, 1.0), new Mat4())));
        assertTrue(n100Transform.modelToWorldMatrix.equals(GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));

        n00.removeComponent(n00Transform);
        n10.removeComponent(n10Transform);

        rootTransform.updateModelToWorldMatrix();

        assertTrue(rootTransform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        assertTrue(n0Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));
        assertTrue(n1Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(1.0, 0.0, 1.0), new Mat4())));

        assertTrue(n000Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-2.0, 0.0, 1.0), new Mat4())));
        assertTrue(n100Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));
    }


    public function testRemoveMultipleTransformRow() {
        var root = Node.create("root");

        var n0 = Node.create("n0");
        var n1 = Node.create("n1");

        var n00 = Node.create("n00");
        var n10 = Node.create("n10");

        var n000 = Node.create("n000");
        var n100 = Node.create("n100");

        root.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        n0.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n1.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4())));

        n00.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n10.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));

        n000.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n100.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));

        root.addChild(n0);
        root.addChild(n1);

        n0.addChild(n00);
        n1.addChild(n10);

        n00.addChild(n000);
        n10.addChild(n100);
        var rootTransform:Transform = cast root.getComponent(Transform);
        var n0Transform:Transform = cast n0.getComponent(Transform);
        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n00Transform:Transform = cast n00.getComponent(Transform);
        var n10Transform:Transform = cast n10.getComponent(Transform);
        var n000Transform:Transform = cast n000.getComponent(Transform);
        var n100Transform:Transform = cast n100.getComponent(Transform);
        rootTransform.updateModelToWorldMatrix();

        assertTrue(rootTransform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        assertTrue(n0Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));
        assertTrue(n1Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(1.0, 0.0, 1.0), new Mat4())));

        assertTrue(n00Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-2.0, 0.0, 1.0), new Mat4())));
        assertTrue(n10Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        assertTrue(n000Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-3.0, 0.0, 1.0), new Mat4())));
        assertTrue(n100Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));

        n0.removeComponent(n0Transform);
        n1.removeComponent(n1Transform);

        n00.removeComponent(n00Transform);
        n10.removeComponent(n10Transform);

        rootTransform.updateModelToWorldMatrix();

        assertTrue(rootTransform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        assertTrue(n000Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));
        assertTrue(n100Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));
    }

    public function testDiscreteRemoveTransform() {
        var root = Node.create("root");

        var n0 = Node.create("n0");
        var n1 = Node.create("n1");

        var n00 = Node.create("n00");
        var n01 = Node.create("n01");
        var n10 = Node.create("n10");
        var n11 = Node.create("n11");

        var n000 = Node.create("n000");
        var n100 = Node.create("n100");


        root.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        n0.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n1.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4())));

        n00.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n01.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4())));

        n10.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n11.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4())));

        n000.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n100.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));

        root.addChild(n0);
        root.addChild(n1);

        n0.addChild(n00);
        n0.addChild(n01);
        n1.addChild(n10);
        n1.addChild(n11);

        n00.addChild(n000);
        n10.addChild(n100);

        var rootTransform:Transform = cast root.getComponent(Transform);
        var n0Transform:Transform = cast n0.getComponent(Transform);
        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n00Transform:Transform = cast n00.getComponent(Transform);
        var n01Transform:Transform = cast n01.getComponent(Transform);

        var n10Transform:Transform = cast n10.getComponent(Transform);
        var n11Transform:Transform = cast n11.getComponent(Transform);

        var n000Transform:Transform = cast n000.getComponent(Transform);
        var n100Transform:Transform = cast n100.getComponent(Transform);

        n00.removeComponent(n00Transform);
        n10.removeComponent(n10Transform);

        rootTransform.updateModelToWorldMatrix();


        assertTrue(rootTransform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));

        assertTrue(n0Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-1.0, 0.0, 1.0), new Mat4())));
        assertTrue(n1Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(1.0, 0.0, 1.0), new Mat4())));

        assertTrue(n01Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));
        assertTrue(n11Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(2.0, 0.0, 1.0), new Mat4())));

        assertTrue(n000Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-2.0, 0.0, 1.0), new Mat4())));
        assertTrue(n100Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 1.0), new Mat4())));


    }


    public function testEmptyAncestorPath() {
        var root = Node.create("root");

        var n0 = Node.create("n0");
        var n1 = Node.create("n1");
        var n2 = Node.create("n2");

        var n00 = Node.create("n00");
        var n10 = Node.create("n01");
        var n20 = Node.create("n20");

        var n100 = Node.create("n100");
        var n101 = Node.create("n101");

        n0.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n1.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(0.0, 0.0, 0.0), new Mat4())));

        n00.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(3.0, 0.0, 0.0), new Mat4())));
        n10.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(5.0, 0.0, 0.0), new Mat4())));
        n20.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(8.0, 0.0, 0.0), new Mat4())));

        n100.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        n101.addComponent(Transform.createbyMatrix4(GLM.translate(new Vec3(1.0, 0.0, 0.0), new Mat4())));

        root.addChild(n0);
        root.addChild(n1);
        root.addChild(n2);

        n0.addChild(n00);
        n1.addChild(n10);
        n2.addChild(n20);

        n10.addChild(n100);
        n10.addChild(n101);

        var rootTransform:Transform = cast root.getComponent(Transform);
        var n0Transform:Transform = cast n0.getComponent(Transform);
        var n1Transform:Transform = cast n1.getComponent(Transform);
        var n00Transform:Transform = cast n00.getComponent(Transform);

        var n10Transform:Transform = cast n10.getComponent(Transform);

        var n100Transform:Transform = cast n100.getComponent(Transform);

        var n20Transform:Transform = cast n20.getComponent(Transform);

        var n101Transform:Transform = cast n101.getComponent(Transform);

        n0Transform.updateModelToWorldMatrix();

        assertTrue(n0Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(-1.0, 0.0, 0.0), new Mat4())));
        assertTrue(n1Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(0.0, 0.0, 0.0), new Mat4())));

        assertTrue(n00Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(2.0, 0.0, 0.0), new Mat4())));
        assertTrue(n10Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(5.0, 0.0, 0.0), new Mat4())));
        assertTrue(n20Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(8.0, 0.0, 0.0), new Mat4())));

        assertTrue(n100Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(4.0, 0.0, 0.0), new Mat4())));
        assertTrue(n101Transform.modelToWorldMatrix.equals( GLM.translate(new Vec3(6.0, 0.0, 0.0), new Mat4())));
    }

}
