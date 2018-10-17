package test.component;
import minko.utils.MathUtil;
import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.StringMap;
import Lambda;
import minko.component.DirectionalLight;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.ShadowMappingTechnique;
import minko.component.Surface;
import minko.component.Transform;
import minko.data.BindingMap.MacroType;
import minko.file.AssetLibrary;
import minko.geometry.CubeGeometry;
import minko.material.BasicMaterial;
import minko.render.DrawCallPool;
import minko.render.DrawCallPool.DrawCallList2U;
import minko.render.Pass;
import minko.render.States;
import minko.render.Texture;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.utils.MathUtil;
class DirectionalLightTest extends haxe.unit.TestCase {
/*
    public function testCreate() {

        var al = DirectionalLight.create();
        assertTrue(true);

    }


    public function testAddLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        lights.addComponent(DirectionalLight.create(.1, .3));
        root.addChild(lights);

        assertTrue(root.data.hasProperty("directionalLight.length"));
        assertEquals(root.data.get("directionalLight.length"), 1);
        assertTrue(root.data.hasProperty("directionalLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].color"), new Vec3(1.0, 1.0, 1.0)));
        assertTrue(root.data.hasProperty("directionalLight[0].diffuse"));
        assertEquals(root.data.get("directionalLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("directionalLight[0].specular"));
        assertEquals(root.data.get("directionalLight[0].specular"), .3);
        assertTrue(root.data.hasProperty("directionalLight[0].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));
    }


    public function testRemoveSingleLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");
        var al = DirectionalLight.create();

        lights.addComponent(al);
        root.addChild(lights);
        lights.removeComponent(al);

        assertEquals(root.data.get("directionalLight.length"), 0);
        assertFalse(root.data.hasProperty("directionalLight[0].color"));
        assertFalse(root.data.hasProperty("directionalLight[0].diffuse"));
        assertFalse(root.data.hasProperty("directionalLight[0].specular"));
        assertFalse(root.data.hasProperty("directionalLight[0].direction"));
    }


    public function testAddMultipleLights() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        assertEquals(root.data.get("directionalLight.length"), 1);
        assertTrue(root.data.hasProperty("directionalLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertTrue(root.data.hasProperty("directionalLight[0].diffuse"));
        assertEquals(root.data.get("directionalLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("directionalLight[0].specular"));
        assertEquals(root.data.get("directionalLight[0].specular"), .2);
        assertTrue(root.data.hasProperty("directionalLight[0].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));

        var al2 = DirectionalLight.create(.3, .4);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        assertEquals(root.data.get("directionalLight.length"), 2);
        assertTrue(root.data.hasProperty("directionalLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("directionalLight[1].diffuse"));
        assertEquals(root.data.get("directionalLight[1].diffuse"), .3);
        assertTrue(root.data.hasProperty("directionalLight[1].specular"));
        assertEquals(root.data.get("directionalLight[1].specular"), .4);
        assertTrue(root.data.hasProperty("directionalLight[1].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].direction"), new Vec3(0.0, 0.0, -1.0)));

        var al3 = DirectionalLight.create(.5, .6);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        assertEquals(root.data.get("directionalLight.length"), 3);
        assertTrue(root.data.hasProperty("directionalLight[2].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[2].color"), new Vec3(0.0, 0.0, 1.0)));
        assertTrue(root.data.hasProperty("directionalLight[2].diffuse"));
        assertEquals(root.data.get("directionalLight[2].diffuse"), .5);
        assertTrue(root.data.hasProperty("directionalLight[2].specular"));
        assertEquals(root.data.get("directionalLight[2].specular"), .6);
        assertTrue(root.data.hasProperty("directionalLight[2].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[2].direction"), new Vec3(0.0, 0.0, -1.0)));
    }


    public function testRemoveFirstLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = DirectionalLight.create(.3, .4);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = DirectionalLight.create(.5, .6);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al1);

        assertEquals(root.data.get("directionalLight.length"), 2);
        assertTrue(root.data.hasProperty("directionalLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("directionalLight[0].diffuse"));
        assertEquals(root.data.get("directionalLight[0].diffuse"), .3);
        assertTrue(root.data.hasProperty("directionalLight[0].specular"));
        assertEquals(root.data.get("directionalLight[0].specular"), .4);
        assertTrue(root.data.hasProperty("directionalLight[0].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));

        assertTrue(root.data.hasProperty("directionalLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertTrue(root.data.hasProperty("directionalLight[1].diffuse"));
        assertEquals(root.data.get("directionalLight[1].diffuse"), .5);
        assertTrue(root.data.hasProperty("directionalLight[1].specular"));
        assertEquals(root.data.get("directionalLight[1].specular"), .6);
        assertTrue(root.data.hasProperty("directionalLight[1].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].direction"), new Vec3(0.0, 0.0, -1.0)));
    }


    public function testRemoveNthLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = DirectionalLight.create(.3, .4);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = DirectionalLight.create(.5, .6);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al2);

        assertEquals(root.data.get("directionalLight.length"), 2);
        assertTrue(root.data.hasProperty("directionalLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertTrue(root.data.hasProperty("directionalLight[0].diffuse"));
        assertEquals(root.data.get("directionalLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("directionalLight[0].specular"));
        assertEquals(root.data.get("directionalLight[0].specular"), .2);
        assertTrue(root.data.hasProperty("directionalLight[0].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));

        assertTrue(root.data.hasProperty("directionalLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].color"), new Vec3(0.0, 0.0, 1.0)));
        assertTrue(root.data.hasProperty("directionalLight[1].diffuse"));
        assertEquals(root.data.get("directionalLight[1].diffuse"), .5);
        assertTrue(root.data.hasProperty("directionalLight[1].specular"));
        assertEquals(root.data.get("directionalLight[1].specular"), .6);
        assertTrue(root.data.hasProperty("directionalLight[1].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].direction"), new Vec3(0.0, 0.0, -1.0)));
    }

    public function testRemoveLastLight() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var al2 = DirectionalLight.create(.3, .4);
        al2.color = (new Vec3(0.0, 1.0, 0.0));
        lights.addComponent(al2);

        var al3 = DirectionalLight.create(.5, .6);
        al3.color = (new Vec3(0.0, 0.0, 1.0));
        lights.addComponent(al3);

        lights.removeComponent(al3);

        assertEquals(root.data.get("directionalLight.length"), 2);
        assertTrue(root.data.hasProperty("directionalLight[0].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].color"), new Vec3(1.0, 0.0, 0.0)));
        assertTrue(root.data.hasProperty("directionalLight[0].diffuse"));
        assertEquals(root.data.get("directionalLight[0].diffuse"), .1);
        assertTrue(root.data.hasProperty("directionalLight[0].specular"));
        assertEquals(root.data.get("directionalLight[0].specular"), .2);
        assertTrue(root.data.hasProperty("directionalLight[0].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));

        assertTrue(root.data.hasProperty("directionalLight[1].color"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].color"), new Vec3(0.0, 1.0, 0.0)));
        assertTrue(root.data.hasProperty("directionalLight[1].diffuse"));
        assertEquals(root.data.get("directionalLight[1].diffuse"), .3);
        assertTrue(root.data.hasProperty("directionalLight[1].specular"));
        assertEquals(root.data.get("directionalLight[1].specular"), .4);
        assertTrue(root.data.hasProperty("directionalLight[1].direction"));
        assertTrue(MathUtil.vec3_equals(root.data.get("directionalLight[1].direction"), new Vec3(0.0, 0.0, -1.0)));
    }



    public function testRotateXPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var rot:Quat = Quat.axisAngle(new Vec3(1.0, 0.0, 0.0), Math.PI, new Quat());
        var mat4:Mat4 = GLM.rotate(rot, Mat4.identity(new Mat4())) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, 1.0)));
    }


    public function testRotateXHalfPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);


        var rot:Quat = Quat.axisAngle(new Vec3(1.0, 0.0, 0.0), Math.PI / 2, new Quat());
        var mat4:Mat4 = GLM.rotate(rot, Mat4.identity(new Mat4())) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 1.0, 0.0)));


    }


    public function testRotateYPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), Math.PI, new Quat());
        var mat4:Mat4 = GLM.rotate(rot, Mat4.identity(new Mat4())) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, 1.0)));

    }


    public function testRotateYHalfPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), Math.PI/2, new Quat());
        var mat4:Mat4 = GLM.rotate(rot, Mat4.identity(new Mat4())) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("directionalLight[0].direction"), new Vec3(-1.0, 0.0, 0.0)));

    }


    public function testRotateZPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), Math.PI, new Quat());
        var mat4:Mat4 = GLM.rotate(rot, Mat4.identity(new Mat4())) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));

    }


    public function testRotateZHalfPi() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);

        var rot:Quat = Quat.axisAngle(new Vec3(0.0, 0.0, 1.0), Math.PI / 2, new Quat());
        var mat4:Mat4 = GLM.rotate(rot, Mat4.identity(new Mat4())) ;
        lights.addComponent(Transform.createbyMatrix4(mat4));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));

    }

    public function testTranslateXYZ() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        root.addChild(lights);

        var al1 = DirectionalLight.create(.1, .2);
        al1.color = (new Vec3(1.0, 0.0, 0.0));
        lights.addComponent(al1);


        lights.addComponent(Transform.createbyMatrix4(GLM.translate(MathUtil.sphericalRand(100.0), new Mat4())));
        var transform:Transform = cast lights.getComponent(Transform);
        transform.updateModelToWorldMatrix();

        assertTrue(MathUtil.isEpsilonEqualVec3(root.data.get("directionalLight[0].direction"), new Vec3(0.0, 0.0, -1.0)));

    }

    public function testRemoveLightThenChangeTargetRoot() {
        var root = Node.create("root");
        var lights = Node.create("lights");

        var al = DirectionalLight.create();
        lights.addComponent(al);
        lights.removeComponent(al);

        root.addChild(lights);
     assertFalse(root.data.hasProperty("directionalLight.length"));
    }

    public function testOneCascadeNumDeferredPasses() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.createbyLayout("root", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(renderer)
        .addComponent(ShadowMappingTechnique.create(Technique.ESM));

        var light = Node.create().addComponent(DirectionalLight.create());
        var directionalLight:DirectionalLight = cast light.getComponent(DirectionalLight);
        directionalLight.enableShadowMapping(256, 1);
        root.addChild(light);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var geom = CubeGeometry.create(MinkoTests.canvas.context);

        var s1 = Surface.create(geom, material, fx);
        var s2 = Surface.create(geom, material, fx);
        var s3 = Surface.create(geom, material, fx);

        root.addComponent(s1);
        root.addComponent(s2);
        root.addComponent(s3);

        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.0);

        var shadowRenderer:Renderer = cast light.getComponent(Renderer);

        assertEquals(renderer.numDrawCalls, 3);
        assertEquals(shadowRenderer.numDrawCalls, 5);

        root.removeComponent(s1);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 2);
        assertEquals(shadowRenderer.numDrawCalls, 4);

        root.removeComponent(s2);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 1);
        assertEquals(shadowRenderer.numDrawCalls, 3);

        root.removeComponent(s3);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 0);
        assertEquals(shadowRenderer.numDrawCalls, 0);
    }


    public function testTwoCascadesNumDeferredPasses() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.createbyLayout("root", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(renderer)
        .addComponent(ShadowMappingTechnique.create(Technique.ESM));

        var light = Node.create().addComponent(DirectionalLight.create());
        var directionalLight:DirectionalLight = cast light.getComponent(DirectionalLight);
        directionalLight.enableShadowMapping(256, 2);
        root.addChild(light);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var geom = CubeGeometry.create(MinkoTests.canvas.context);

        var s1 = Surface.create(geom, material, fx);
        var s2 = Surface.create(geom, material, fx);
        var s3 = Surface.create(geom, material, fx);

        root.addComponent(s1);
        root.addComponent(s2);
        root.addComponent(s3);
        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.0);

        var shadowRenderer0:Renderer = cast light.getComponents(Renderer)[0];
        var shadowRenderer1:Renderer = cast light.getComponents(Renderer)[1];

        assertEquals(renderer.numDrawCalls, 3);
        assertEquals(shadowRenderer0.numDrawCalls, 5);
        assertEquals(shadowRenderer1.numDrawCalls, 5);

        root.removeComponent(s1);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 2);
        assertEquals(shadowRenderer0.numDrawCalls, 4);
        assertEquals(shadowRenderer1.numDrawCalls, 4);

        root.removeComponent(s2);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 1);
        assertEquals(shadowRenderer0.numDrawCalls, 3);
        assertEquals(shadowRenderer1.numDrawCalls, 3);

        root.removeComponent(s3);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 0);
        assertEquals(shadowRenderer0.numDrawCalls, 0);
        assertEquals(shadowRenderer1.numDrawCalls, 0);
    }


    public function testThreeCascadesNumDeferredPasses() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.createbyLayout("root", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(renderer)
        .addComponent(ShadowMappingTechnique.create(Technique.ESM));

        var light = Node.create().addComponent(DirectionalLight.create());
        var directionalLight:DirectionalLight = cast light.getComponent(DirectionalLight);
        directionalLight.enableShadowMapping(256, 3);
        root.addChild(light);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var geom = CubeGeometry.create(MinkoTests.canvas.context);

        var s1 = Surface.create(geom, material, fx);
        var s2 = Surface.create(geom, material, fx);
        var s3 = Surface.create(geom, material, fx);

        root.addComponent(s1);
        root.addComponent(s2);
        root.addComponent(s3);

        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.0);

        var shadowRenderer0:Renderer = cast light.getComponents(Renderer)[0];
        var shadowRenderer1:Renderer = cast light.getComponents(Renderer)[1];
        var shadowRenderer2:Renderer = cast light.getComponents(Renderer)[2];

        assertEquals(renderer.numDrawCalls, 3);
        assertEquals(shadowRenderer0.numDrawCalls, 5);
        assertEquals(shadowRenderer1.numDrawCalls, 5);
        assertEquals(shadowRenderer2.numDrawCalls, 5);

        root.removeComponent(s1);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 2);
        assertEquals(shadowRenderer0.numDrawCalls, 4);
        assertEquals(shadowRenderer1.numDrawCalls, 4);
        assertEquals(shadowRenderer2.numDrawCalls, 4);

        root.removeComponent(s2);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 1);
        assertEquals(shadowRenderer0.numDrawCalls, 3);
        assertEquals(shadowRenderer1.numDrawCalls, 3);
        assertEquals(shadowRenderer2.numDrawCalls, 3);

        root.removeComponent(s3);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 0);
        assertEquals(shadowRenderer0.numDrawCalls, 0);
        assertEquals(shadowRenderer1.numDrawCalls, 0);
        assertEquals(shadowRenderer2.numDrawCalls, 0);
    }

    public function testShadowMappingEffect() {
        var assets = AssetLibrary.create(MinkoTests.canvas.context);
        var texture = Texture.create(assets.context, 1, 1, false, true);
        texture.upload();
        assets.setTexture("shadow-map-tmp", texture);
        assets.setTexture("shadow-map-tmp-2", texture);

        var fx = MinkoTests.loadEffect("effect/ShadowMap.effect", assets);

        assertFalse(fx == null);
        assertEquals(Lambda.count(fx.techniques), 8);

        for (i in 0...4) {
            var technique:Array<Pass> = cast fx.techniques.get("shadow-map-cascade" + (i));

            assertEquals(technique.length, 1);
            assertTrue(technique[0].macroBindings.defaultValues.hasProperty("SHADOW_CASCADE_INDEX"));
            assertTrue(technique[0].macroBindings.types.exists("SHADOW_CASCADE_INDEX"));
            assertEquals(technique[0].macroBindings.types.get("SHADOW_CASCADE_INDEX"), MacroType.INT);
            assertEquals(technique[0].macroBindings.defaultValues.get("SHADOW_CASCADE_INDEX"), i);
            assertEquals(technique[0].states.priority, States.DEFAULT_PRIORITY);
        }
    }
    public function testFourCascadesNumDeferredPasses() {
        var fx = MinkoTests.loadEffect("effect/Basic.effect");
        var renderer = Renderer.create();
        var root = Node.createbyLayout("root", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(renderer)
        .addComponent(ShadowMappingTechnique.create(Technique.ESM));

        var light = Node.create().addComponent(DirectionalLight.create());
        var directionalLight:DirectionalLight = cast light.getComponent(DirectionalLight);
        directionalLight.enableShadowMapping(256, 4);
        root.addChild(light);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var geom = CubeGeometry.create(MinkoTests.canvas.context);

        var s1 = Surface.create(geom, material, fx);
        var s2 = Surface.create(geom, material, fx);
        var s3 = Surface.create(geom, material, fx);

        root.addComponent(s1);
        root.addComponent(s2);
        root.addComponent(s3);

        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.0);

        var shadowRenderer0:Renderer = cast light.getComponents(Renderer)[0];
        var shadowRenderer1:Renderer = cast light.getComponents(Renderer)[1];
        var shadowRenderer2:Renderer = cast light.getComponents(Renderer)[2];
        var shadowRenderer3:Renderer = cast light.getComponents(Renderer)[3];

        assertEquals(renderer.numDrawCalls, 3);
        assertEquals(shadowRenderer0.numDrawCalls, 5);
        assertEquals(shadowRenderer1.numDrawCalls, 5);
        assertEquals(shadowRenderer2.numDrawCalls, 5);
        assertEquals(shadowRenderer3.numDrawCalls, 5);

        root.removeComponent(s1);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 2);
        assertEquals(shadowRenderer0.numDrawCalls, 4);
        assertEquals(shadowRenderer1.numDrawCalls, 4);
        assertEquals(shadowRenderer2.numDrawCalls, 4);
        assertEquals(shadowRenderer3.numDrawCalls, 4);

        root.removeComponent(s2);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 1);
        assertEquals(shadowRenderer0.numDrawCalls, 3);
        assertEquals(shadowRenderer1.numDrawCalls, 3);
        assertEquals(shadowRenderer2.numDrawCalls, 3);
        assertEquals(shadowRenderer3.numDrawCalls, 3);

        root.removeComponent(s3);
        sceneManager.nextFrame(0.0, 0.0);
        assertEquals(renderer.numDrawCalls, 0);
        assertEquals(shadowRenderer0.numDrawCalls, 0);
        assertEquals(shadowRenderer1.numDrawCalls, 0);
        assertEquals(shadowRenderer2.numDrawCalls, 0);
        assertEquals(shadowRenderer3.numDrawCalls, 0);
    }



*/

    public function testRenderersAndDrawCalls() {
        var fx = MinkoTests.loadEffect("effect/Phong.effect");
        var renderer = Renderer.create();
        var root = Node.createbyLayout("root", BuiltinLayout.DEFAULT | BuiltinLayout.CAST_SHADOW)
        .addComponent(PerspectiveCamera.create(1.0))
        .addComponent(SceneManager.create(MinkoTests.canvas))
        .addComponent(renderer);

        var light = Node.create().addComponent(DirectionalLight.create());
        var directionalLight:DirectionalLight = cast light.getComponent(DirectionalLight);
        directionalLight.enableShadowMapping(256, 4);
        root.addChild(light);

        var material = BasicMaterial.create();
        material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, 1.0));

        var geom = CubeGeometry.create(MinkoTests.canvas.context);

        root.addComponent(Surface.create(geom, material, fx));

        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.0);

        var rendererIndex = 0;
        var renderers:Array<Renderer> = cast light.getComponents(Renderer);
        for (renderer in renderers) {
            var shadowMappingDepthPass:Pass = renderer.effect.technique(renderer.effectTechnique)[0];

            assertTrue(shadowMappingDepthPass.macroBindings.defaultValues.hasProperty("SHADOW_CASCADE_INDEX"));
            assertTrue(shadowMappingDepthPass.macroBindings.types.exists("SHADOW_CASCADE_INDEX"));
            assertEquals(shadowMappingDepthPass.macroBindings.types.get("SHADOW_CASCADE_INDEX"), MacroType.INT);
            assertEquals(shadowMappingDepthPass.macroBindings.defaultValues.get("SHADOW_CASCADE_INDEX"), rendererIndex);
            assertEquals(shadowMappingDepthPass.states.priority, States.DEFAULT_PRIORITY);

            var drawCalls:StringMap<DrawCallList2U > = renderer.drawCallPool.drawCalls;
            var depthTarget = shadowMappingDepthPass.states.target.id;

            assertEquals(depthTarget, 0);
            //todo
            assertTrue(drawCalls.exists(DrawCallPool.sortPropertyTuple( States.DEFAULT_PRIORITY, depthTarget)));

            ++rendererIndex;
        }
    }
}
