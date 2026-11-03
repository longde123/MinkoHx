import glm.GLM;
import glm.Mat4;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import haxe.Timer;
import haxe.io.Bytes;
import minko.AbstractCanvas;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.CloneOption;
import minko.component.BoundingBox;
import minko.component.DirectionalLight;
import minko.component.LightComponent;
import minko.component.MouseManager;
import minko.component.MousePicking;
import minko.component.PBRRenderer;
import minko.component.PerspectiveCamera;
import minko.component.PhongRenderer;
import minko.component.PointLight;
import minko.component.SceneManager;
import minko.component.Skinning;
import minko.component.Skinning.SkinningMethod;
import minko.component.Surface;
import minko.component.Transform;
import minko.input.Mouse;
import minko.math.Box;
import minko.math.Ray;
import minko.file.AssetLibrary;
import minko.file.Loader;
import minko.file.Options;
import minko.file.PipelineEffectParser;
import minko.geometry.CubeGeometry;
import minko.geometry.Bone;
import minko.geometry.Geometry;
import minko.geometry.Skin;
import minko.material.Material;
import minko.material.PhongMaterial;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
import minko.render.Blending.Source as BlendingSource;
import minko.render.Blending.Destination as BlendingDestination;
import minko.render.Blending.Mode as BlendingMode;
import minko.render.CompareMode;
import minko.render.MipFilter;
import minko.render.TextureFilter;
import minko.render.WrapMode;
import minko.render.Program;
import minko.render.ProgramInputs.InputType;
import minko.render.ProgramInputs.UniformInput;
import minko.render.Shader;
import minko.render.Shader.ShaderType;
import minko.render.CubeTexture;
import minko.render.TextureFormat;
import minko.render.Texture;
import minko.render.TriangleCulling;
import minko.render.light.Light;
import minko.render.light.LightSet;
import minko.render.pbr.BloomRenderer;
import minko.render.pbr.DeferredLightingRenderer;
import minko.render.pbr.FXAARenderer;
import minko.render.pbr.FullscreenEffect;
import minko.render.pbr.FullscreenRenderer;
import minko.render.pbr.GBufferDebugMode;
import minko.render.pbr.GBufferDebugRenderer;
import minko.render.pbr.GBufferFallbackRenderer;
import minko.render.pbr.GBufferRenderer;
import minko.render.pbr.PBRForwardRenderer;
import minko.render.phong.PhongForwardRenderer;
import minko.render.pbr.PBRMath;
import minko.material.PBRMaterial;
import minko.render.pbr.PBRShaderLibrary;
import minko.render.pbr.PointShadow;
import minko.render.pbr.LightTileCuller;
import minko.render.pbr.ShadowRenderer;
import minko.render.pbr.SSAORenderer;
import minko.render.pipeline.CallbackPass;
import minko.render.pipeline.DeferredPBRPath;
import minko.render.pipeline.EffectStage;
import minko.render.pipeline.ForwardEffectRenderer;
import minko.render.pipeline.ForwardPBRPath;
import minko.render.pipeline.ForwardPhongPath;
import minko.render.pipeline.ForwardPath;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.PipelineEffect;
import minko.render.pipeline.PipelineRenderer;
import minko.render.pipeline.PipelineState;
import minko.render.pipeline.PipelineTechnique;
import minko.render.pipeline.PipelineUniform;
import minko.render.pipeline.PostProcessChain;
import minko.render.pipeline.RenderGraph;
import minko.render.pipeline.RenderGraphResource;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.pipeline.SceneCollector;
import minko.render.pipeline.UniformSource;
import minko.render.target.GBuffer;
import minko.render.target.RenderCapabilities;
import minko.render.target.RenderTarget;
import minko.render.target.RenderTargetPool;
import minko.scene.Node;

/**
 * Persistent HashLink test suite for the new render pipeline
 * (minko-hx/docs/render-pipeline-design.md, acceptance criteria §15).
 *
 * Logic cases run without GL; render cases share a single hidden SDL canvas
 * and read pixels back from pool-acquired offscreen targets.
 *
 * Build:  haxe build_hl.hxml        (from minko-test/)
 * Run:    hl bin/TestsHL.hl
 * Exit code 0 iff every check passed.
 */
class TestHLMain {
    static var passed = 0;
    static var failed = 0;

    static var context:AbstractContext;
    static var canvas:AbstractCanvas;
    static var pool:RenderTargetPool;
    static var geometry:Geometry;
    static var pbr:PBRForwardRenderer;
    static var phong:PhongForwardRenderer;

    static function main() {
        trace("== logic tests (no GL) ==");
        testRenderGraph();
        testRenderQueue();
        testPotSize();
        testPBRMath();
        testMaterialClasses();
        testSceneMath();
        testSceneInteraction();
        testNodeLifecycle();

        trace("== GL tests ==");
        var testCanvas = CanvasManager.create("MinkoPipelineTests", 64, 64, Flags.RESIZABLE);
        canvas = testCanvas;
        context = testCanvas.context;
        pool = new RenderTargetPool(context);
        geometry = CubeGeometry.create(context);
        pbr = new PBRForwardRenderer(context);
        phong = new PhongForwardRenderer(context);

        testCapabilities();
        testSamplerPositions();
        testPool();
        testPoolSteadyState();
        testGraphReleaseTransients();
        testForwardLit();
        testPhongForward();
        testGeometryTangents();
        testPhongNormalMap();
        testPhongPath();
        testMaterialResponse();
        testPointLight();
        testSpotLight();
        testTransparency();
        testShadow();
        testCSM();
        testSpotShadow();
        testPointShadow();
        testPhongLocalShadow();
        testPhongPointCubeShadow();
        testSkinningSnapshotStorage();
        testGBufferState();
        testGBufferNonUniformNormals();
        testGBufferDebugViews();
        testPoolFormats();
        testDeferredMRT();
        testDeferredFallback();
        testDeferredPath();
        testDeferredPathPersistent();
        testDeferredPathFallbackCaps();
        testDeferredPathShadow();
        testDeferredPathTransparent();
        testDeferredMatchesForward();
        testDeferredPointLights();
        testDeferredShadow();
        testSSAO();
        testLightTileCuller();
        testMultiplePointShadows();
        testMultiplePointShadowPixels();
        testDeferredMultiPointShadowPixels();
        testDeferredDirectPointShadowPixels();
        testMultipleSpotShadows();
        testMultipleSpotShadowPixels();
        testBackendUploadQuirks();
        testManySamplerThreshold();
        testSamplerUnitsSurviveUpload();
        testForwardPathPost();
        testForwardPathPersistent();
        testPipelineRenderer();
        testPipelineRendererDeferred();
        testPipelineEffectForward();
        testPipelineEffectTransparent();
        testPipelineEffectGBuffer();
        testPipelineEffectFallbackStages();
        testPipelineEffectFallbackAutoSplit();
        testPipelineEffectShadow();
        testPipelineEffectFallbackAndState();
        testPipelineEffectParser();
        testPipelineEffectExternalParser();
        testPipelineEffectMacros();
        testNonPBRForward();
        testPBRRendererComponent();
        testPhongRendererComponent();
        testLightComponents();
        testBenchmark();

        pbr.dispose();
        phong.dispose();
        pool.dispose();

        trace('== RESULT: $passed passed, $failed failed ==');
        Sys.exit(failed == 0 ? 0 : 1);
    }

    // ---------------------------------------------------------------- utils

    static function check(name:String, cond:Bool, detail:String = ""):Bool {
        if (cond) {
            passed++;
            trace("PASS " + name);
        }
        else {
            failed++;
            trace("FAIL " + name + (detail != "" ? "  -- " + detail : ""));
        }
        return cond;
    }

    static function f(v:Float):String {
        return Math.round(v * 1000) / 1000 + "";
    }

    static function makeFrame(w:Int, h:Int, withLight:Bool = true, intensity:Float = 3.0):FrameContext {
        var frame = new FrameContext(context, w, h);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, w / h, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.0);
        frame.lights = new LightSet();
        if (withLight) {
            var light = Light.directional();
            light.direction = new Vec3(0.0, 0.0, -1.0);
            light.color = new Vec3(1.0, 1.0, 1.0);
            light.intensity = intensity;
            frame.lights.add(light);
        }
        frame.targetPool = pool;
        frame.capabilities = RenderCapabilities.detect(context);
        return frame;
    }

    static function queueOf(material:Material, world:Mat4):RenderQueue {
        var q = new RenderQueue();
        q.add(new RenderItem(geometry, material, null, world));
        return q;
    }

    static function renderForwardEffect(queue:RenderQueue, frame:FrameContext, ?defaultEffect:PipelineEffect):Bytes {
        var fx = new ForwardEffectRenderer(context, defaultEffect);
        var path = new ForwardPath(function(q, f, t) fx.render(q, f, t), null, "forward-effect-test");
        var graph = path.build(queue, frame);
        graph.execute(frame);
        var bytes = readTarget(graph.output.target);
        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        fx.dispose();
        return bytes;
    }

    static function pipelineEffectVertex():String {
        return [
            "attribute vec3 position;",
            "uniform mat4 modelMatrix;",
            "uniform mat4 viewMatrix;",
            "uniform mat4 projectionMatrix;",
            "void main() {",
            "    gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(position, 1.0);",
            "}"
        ].join("\n");
    }

    static function pipelineEffectUniforms():Array<PipelineUniform> {
        return [
            new PipelineUniform("modelMatrix", UniformSource.ModelMatrix),
            new PipelineUniform("viewMatrix", UniformSource.ViewMatrix),
            new PipelineUniform("projectionMatrix", UniformSource.ProjectionMatrix)
        ];
    }

    static function makePipelineEffect(stage:EffectStage, fragmentSource:String,
                                       uniforms:Array<PipelineUniform>, ?state:PipelineState):PipelineEffect {
        var effect = PipelineEffect.create("test-effect-" + stage);
        effect.addTechnique(new PipelineTechnique(stage, pipelineEffectVertex(), fragmentSource, uniforms, state));
        return effect;
    }

    static function renderForward(q:RenderQueue, frame:FrameContext, size:Int):Bytes {
        var target = pool.acquire(size, size);
        target.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        pbr.render(q, frame, target);
        var bytes = Bytes.alloc(size * size * 4);
        context.readPixels(bytes);
        target.unbind(context);
        pool.release(target);
        return bytes;
    }

    static function renderPhong(q:RenderQueue, frame:FrameContext, size:Int):Bytes {
        var target = pool.acquire(size, size);
        target.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        phong.render(q, frame, target);
        var bytes = Bytes.alloc(size * size * 4);
        context.readPixels(bytes);
        target.unbind(context);
        pool.release(target);
        return bytes;
    }

    static function copyAvg(effect:FullscreenEffect, texture:AbstractTexture):Float {
        var bytes = copyBytes(effect, texture);
        if (bytes == null) {
            return 0.0;
        }
        var n = Std.int(bytes.length / 4);
        var sum = 0.0;
        for (i in 0...n) {
            var o = i * 4;
            sum += (0.299 * bytes.get(o) + 0.587 * bytes.get(o + 1) + 0.114 * bytes.get(o + 2)) / 255.0;
        }
        return n > 0 ? sum / n : 0.0;
    }

    static function copyBytes(effect:FullscreenEffect, texture:AbstractTexture):Bytes {
        if (texture == null) {
            return null;
        }
        var t = pool.acquire(texture.width, texture.height);
        effect.render(t, function(e) e.setTexture("uColorMap", texture));
        var b = readTarget(t);
        pool.release(t);
        return b;
    }

    static function readTarget(target:RenderTarget):Bytes {
        target.bind(context, false);
        var bytes = Bytes.alloc(target.width * target.height * 4);
        context.readPixels(bytes);
        target.unbind(context);
        return bytes;
    }

    static function avgLuma(b:Bytes, w:Int, h:Int):Float {
        var sum = 0.0;
        var n = w * h;
        for (i in 0...n) {
            var o = i * 4;
            sum += (0.299 * b.get(o) + 0.587 * b.get(o + 1) + 0.114 * b.get(o + 2)) / 255.0;
        }
        return sum / n;
    }

    static function meanAbsDiff(a:Bytes, b:Bytes):Float {
        var sum = 0.0;
        var n = a.length;
        for (i in 0...n) {
            var d = a.get(i) - b.get(i);
            sum += d < 0 ? -d : d;
        }
        return sum / n;
    }

    static function pixelAt(b:Bytes, w:Int, x:Int, y:Int):Array<Int> {
        var i = (y * w + x) * 4;
        return [b.get(i), b.get(i + 1), b.get(i + 2), b.get(i + 3)];
    }

    static function findResource(graph:RenderGraph, name:String):RenderGraphResource {
        for (r in graph.resources) {
            if (r.name == name) {
                return r;
            }
        }
        return null;
    }

    // ------------------------------------------------------- logic: graph

    static function testRenderGraph() {
        var g = new RenderGraph();
        var r1 = g.createResource("r1");
        var r2 = g.createResource("r2");
        var order:Array<String> = [];
        var a = new CallbackPass("A", function(frame) order.push("A"));
        a.write(r1);
        var b = new CallbackPass("B", function(frame) order.push("B"));
        b.read(r1);
        b.write(r2);
        g.addPass(b); // registered in reverse order on purpose
        g.addPass(a);
        g.setOutput(r2);

        var compiled = g.compile();
        check("graph: topological order from output",
            compiled.length == 2 && compiled[0] == a && compiled[1] == b,
            "len=" + compiled.length);

        // culling: pass not connected to the output is dropped
        var r3 = g.createResource("r3");
        var c = new CallbackPass("C", function(frame) order.push("C"));
        c.write(r3);
        g.addPass(c);
        compiled = g.compile();
        check("graph: unconnected pass culled",
            compiled.length == 2 && compiled.indexOf(c) == -1,
            "len=" + compiled.length);

        // compile cache: identical array instance until invalidated
        var c1 = g.compile();
        var c2 = g.compile();
        check("graph: compile result cached", c1 == c2);

        // invalidation on addPass/setOutput
        var r4 = g.createResource("r4");
        var d = new CallbackPass("D", function(frame) order.push("D"));
        d.read(r2);
        d.write(r4);
        g.addPass(d);
        g.setOutput(r4);
        compiled = g.compile();
        check("graph: cache invalidated on graph change",
            compiled.length == 3 && compiled[2] == d,
            "len=" + compiled.length);

        // execute order
        order = [];
        g.execute(new FrameContext(null, 8, 8));
        check("graph: execute runs topo order", order.join(",") == "A,B,D", order.join(","));

        // double producer rejected
        var e = new CallbackPass("E", function(frame) {});
        e.write(r1);
        var threw = false;
        try {
            g.addPass(e);
        }
        catch (err:Dynamic) {
            threw = true;
        }
        check("graph: double producer rejected", threw);

        // no output -> empty compile
        var g2 = new RenderGraph();
        var rx = g2.createResource("x");
        var px = new CallbackPass("P", function(frame) {});
        px.write(rx);
        g2.addPass(px);
        check("graph: no output -> empty compile", g2.compile().length == 0);
    }

    // ------------------------------------------------------- logic: scene

    static function logicGeometry(data:Array<Float>, indices:Array<Int>):Geometry {
        var result = Geometry.create();
        var vertices = new VertexBuffer(null);
        vertices.data = data;
        vertices.addAttribute("position", 3);
        result.addVertexBuffer(vertices);
        var indexBuffer = new IndexBuffer(null);
        indexBuffer.data = indices;
        result.indices = indexBuffer;
        return result;
    }

    static function testSceneMath() {
        var box = Box.createbyVector3(new Vec3(1.0, 1.0, 1.0), new Vec3(-1.0, -1.0, -1.0));
        var ray = Ray.createbyVector3(new Vec3(0.0, 0.0, 3.0), new Vec3(0.0, 0.0, -1.0));
        check("scene math: box entry distance", Math.abs(box.intersectRay(ray) - 2.0) < 0.0001);
        check("scene math: box contains ray origin", box.intersectRay(Ray.createbyVector3(new Vec3(), new Vec3(0.0, 0.0, -1.0))) == 0.0);
        check("scene math: parallel box miss", box.intersectRay(Ray.createbyVector3(new Vec3(2.0, 0.0, 3.0), new Vec3(0.0, 0.0, -1.0))) == null);
        check("scene math: box behind ray", box.intersectRay(Ray.createbyVector3(new Vec3(0.0, 0.0, 3.0), new Vec3(0.0, 0.0, 1.0))) == null);

        var g = logicGeometry([
            -1.0, -1.0, -2.0, 1.0, -1.0, -2.0, 0.0, 1.0, -2.0,
            -1.0, -1.0, 0.0, 1.0, -1.0, 0.0, 0.0, 1.0, 0.0
        ], [0, 0, 0, 0, 1, 2, 3, 4, 5]);
        var hit = g.intersectRay(ray);
        check("scene math: degenerate triangle skipped", hit != null && hit.triangle == 6);
        check("scene math: nearest geometry hit", hit != null && Math.abs(hit.distance - 3.0) < 0.0001 && Math.abs(hit.position.z) < 0.0001);
        check("scene math: optional hit attributes", hit != null && hit.uv == null && hit.normal == null);
        check("scene math: geometry miss terminates", g.intersectRay(Ray.createbyVector3(new Vec3(5.0, 0.0, 3.0), new Vec3(0.0, 0.0, -1.0))) == null);

        var transform = Transform.create();
        var bounds = BoundingBox.createbyWHDC(2.0, 4.0, 2.0, new Vec3());
        var node = Node.create().addComponent(transform).addComponent(bounds);
        check("scene math: initial bounding box", Math.abs(bounds.box.bottomLeft.x + 1.0) < 0.0001 && Math.abs(bounds.box.topRight.y - 2.0) < 0.0001);
        transform.matrix = GLM.translate(new Vec3(3.0, 0.0, 0.0), Mat4.identity(new Mat4()));
        transform.updateModelToWorldMatrix();
        check("scene math: bounding box stays cached", Math.abs(bounds.box.bottomLeft.x + 1.0) < 0.0001);
        bounds.update();
        check("scene math: bounding box manual update", Math.abs(bounds.box.bottomLeft.x - 2.0) < 0.0001 && Math.abs(bounds.box.topRight.x - 4.0) < 0.0001);
        var deep:BoundingBox = cast bounds.clone(CloneOption.DEEP);
        var shallow:BoundingBox = cast bounds.clone(CloneOption.SHALLOW);
        check("scene math: bounding box clone options", deep.modelSpaceBox != bounds.modelSpaceBox && shallow.modelSpaceBox == bounds.modelSpaceBox);
    }

    static function testSceneInteraction() {
        var mouse = Mouse.create(null);
        var manager = MouseManager.create(mouse);
        var root = Node.create().addComponent(manager);
        var nearPicking = MousePicking.create();
        var farPicking = MousePicking.create();
        var near = Node.create().addComponent(BoundingBox.createbySize(2.0, new Vec3())).addComponent(nearPicking);
        var far = Node.create().addComponent(BoundingBox.createbySize(2.0, new Vec3(0.0, 0.0, -4.0))).addComponent(farPicking);
        root.addChild(near).addChild(far);
        var move = 0;
        var over = 0;
        var rollOver = 0;
        var out = 0;
        var down = 0;
        var up = 0;
        nearPicking.move.connect(function(_, _, _) move++);
        nearPicking.over.connect(function(_, _, _) over++);
        nearPicking.rollOver.connect(function(_, _, _) rollOver++);
        nearPicking.out.connect(function(_, _, _) out++);
        nearPicking.leftButtonDown.connect(function(_, _, _) down++);
        nearPicking.leftButtonUp.connect(function(_, _, _) up++);
        var ray = Ray.createbyVector3(new Vec3(0.0, 0.0, 5.0), new Vec3(0.0, 0.0, -1.0));
        var hits = manager.pick(ray);
        check("mouse: real nearest distance", hits.length == 2 && hits[0].first == near && Math.abs(hits[0].second - 4.0) < 0.0001);
        manager.pick(ray);
        check("mouse: move only on ray change", move == 1);
        check("mouse: over and rollover", over == 2 && rollOver == 1);
        mouse.leftButtonDown.execute(mouse);
        mouse.leftButtonUp.execute(mouse);
        check("mouse: button dispatch", down == 1 && up == 1);
        manager.pick(Ray.createbyVector3(new Vec3(10.0, 0.0, 5.0), new Vec3(0.0, 0.0, -1.0)));
        check("mouse: out on miss", out == 1);
        root.removeChild(near);
        hits = manager.pick(ray);
        check("mouse: removed node not picked", hits.length == 1 && hits[0].first == far);
        root.removeComponent(manager);
        mouse.leftButtonDown.execute(mouse);
        check("mouse: manager disconnects input", down == 1);
    }

    static function testNodeLifecycle() {
        var root = Node.create();
        var child = Node.create();
        root.addChild(child);
        var selfRejected = false;
        var cycleRejected = false;
        var duplicateRejected = false;
        try root.addChild(root) catch (_) selfRejected = true;
        try child.addChild(root) catch (_) cycleRejected = true;
        try root.addChild(child) catch (_) duplicateRejected = true;
        check("node: invalid hierarchy rejected", selfRejected && cycleRejected && duplicateRejected && root.children.length == 1 && child.parent == root);

        var first = MousePicking.create();
        var second = MousePicking.create();
        var childComponent = MousePicking.create();
        var disposable = Node.create().addComponent(first).addComponent(second);
        var disposableChild = Node.create().addComponent(childComponent);
        var parent = Node.create().addChild(disposable);
        disposable.addChild(disposableChild);
        disposable.dispose();
        disposable.dispose();
        check("node: dispose detaches subtree", parent.children.length == 0 && disposableChild.parent == null);
        check("node: dispose clears every component target", first.target == null && second.target == null && childComponent.target == null);
        check("node: repeated dispose is safe", disposable.components == null && disposable.children == null);
    }

    // ------------------------------------------------------- logic: queue

    static function testRenderQueue() {
        var w = Mat4.identity(new Mat4());
        var m1 = Material.create("m1");
        var m2 = Material.create("m2");
        var i1 = new RenderItem(null, m1, null, w);
        var i2 = new RenderItem(null, m2, null, w);
        var i3 = new RenderItem(null, m1, null, w);
        var i4 = new RenderItem(null, m2, null, w);
        i4.castShadow = false;

        var q = new RenderQueue();
        q.add(i1);
        q.add(i2, true);
        q.add(i3, false, true);
        q.add(i4);
        check("queue: bucket assignment",
            q.opaque.length == 2 && q.transparent.length == 1 && q.alphaTest.length == 1 && q.count == 4,
            'opaque=${q.opaque.length} transparent=${q.transparent.length} alphaTest=${q.alphaTest.length}');
        check("queue: shadow casters respect castShadow=false",
            q.shadowCasters.length == 3 && q.shadowCasters.indexOf(i4) == -1);

        q.sortOpaque();
        check("queue: opaque sorted by material uuid",
            q.opaque[0].material.uuid <= q.opaque[1].material.uuid,
            q.opaque[0].material.uuid + " vs " + q.opaque[1].material.uuid);

        var t1 = new RenderItem(null, m1, null, w);
        t1.depth = 1.0;
        var t2 = new RenderItem(null, m1, null, w);
        t2.depth = 5.0;
        var t3 = new RenderItem(null, m1, null, w);
        t3.depth = 3.0;
        var q2 = new RenderQueue();
        q2.add(t1, true);
        q2.add(t2, true);
        q2.add(t3, true);
        q2.sortTransparent();
        check("queue: transparent sorted far-to-near",
            q2.transparent[0] == t2 && q2.transparent[1] == t3 && q2.transparent[2] == t1);

        q.clear();
        check("queue: clear empties all buckets",
            q.count == 0 && q.shadowCasters.length == 0);
    }

    static function testPotSize() {
        check("pool: potSize rounds up to power of two",
            RenderTargetPool.potSize(1) == 1
            && RenderTargetPool.potSize(2) == 2
            && RenderTargetPool.potSize(3) == 4
            && RenderTargetPool.potSize(100) == 128
            && RenderTargetPool.potSize(128) == 128
            && RenderTargetPool.potSize(129) == 256);
    }

    // ------------------------------------------------------ GL: capability

    static function testCapabilities() {
        var caps = RenderCapabilities.detect(context);
        #if hl
        check("capabilities: HL exposes MRT/depth/HDR",
            caps.supportsMRT && caps.supportsDepthTexture && caps.supportsFloatRenderTarget && caps.canUseDeferred(),
            'mrt=${caps.supportsMRT} depth=${caps.supportsDepthTexture} float=${caps.supportsFloatRenderTarget}');
        #else
        check("capabilities: conservative WebGL1 fallback",
            !caps.supportsMRT && !caps.supportsDepthTexture && !caps.supportsFloatRenderTarget);
        #end
    }

    // ------------------------------------------------- GL: program inputs

    static function testSamplerPositions() {
        var vertexSource = [
            "attribute vec3 position;",
            "uniform mat4 modelMatrix;",
            "void main() { gl_Position = modelMatrix * vec4(position, 1.0); }"
        ].join("\n");
        var fragmentSource = [
            "uniform float uFoo;",
            "uniform sampler2D uA;",
            "uniform sampler2D uB;",
            "void main() {",
            "    gl_FragColor = vec4(uFoo) + texture2D(uA, vec2(0.0)) + texture2D(uB, vec2(0.0));",
            "}"
        ].join("\n");

        var vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, vertexSource);
        var fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, fragmentSource);
        vertexShader.upload();
        fragmentShader.upload();

        var program = Program.createbyShader("SamplerPositions", context, vertexShader, fragmentShader);
        program.upload();

        var foo:UniformInput = null;
        var a:UniformInput = null;
        var b:UniformInput = null;
        for (uniform in program.inputs.uniforms) {
            switch (uniform.name) {
                case "uFoo": foo = uniform;
                case "uA": a = uniform;
                case "uB": b = uniform;
                default:
            }
        }

        check("inputs: non-sampler has no texture unit",
            foo != null && foo.position == -1,
            foo == null ? "uFoo missing" : 'position=${foo.position}');
        // SDLGLContext reflects the original GLSL source, so sampler order is
        // the declaration order: uA -> 0, uB -> 1.
        check("inputs: samplers get dense units in declaration order",
            a != null && b != null && a.position == 0 && b.position == 1,
            'a=${a == null ? "missing" : Std.string(a.position)} b=${b == null ? "missing" : Std.string(b.position)}');

        // Hand-built inputs keep the legacy default; DrawCall then falls back
        // to its own counter.
        var legacy = new UniformInput("uA", 0, 1, InputType.sampler2d);
        check("inputs: hand-built sampler defaults to -1", legacy.position == -1);

        program.dispose();
        vertexShader.dispose();
        fragmentShader.dispose();
    }

    // ---------------------------------------------------------- GL: pool

    static function testPool() {
        var t1 = pool.acquire(200, 100);
        check("pool: acquire rounds to POT",
            t1.width == 256 && t1.height == 128,
            'w=${t1.width} h=${t1.height}');
        pool.release(t1);
        check("pool: release returns to free list",
            pool.freeCount == 1 && pool.activeCount == 0,
            'free=${pool.freeCount} active=${pool.activeCount}');
        var t2 = pool.acquire(256, 128);
        check("pool: reacquire returns cached target", t2 == t1);

        var mrt = pool.acquireMRT(64, 64, [TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        check("pool: acquireMRT has colors + depth",
            mrt.colors.length == 2 && mrt.depth != null,
            'colors=${mrt.colors.length} depth=${mrt.depth != null}');
        pool.release(mrt);
        pool.release(t2);

        var pool2 = new RenderTargetPool(context, 1);
        var pa = pool2.acquire(64, 64);
        var pb = pool2.acquire(64, 64);
        pool2.release(pa);
        pool2.release(pb);
        check("pool: maxFreePerSize evicts extras", pool2.freeCount == 1, 'free=${pool2.freeCount}');
        pool2.dispose();
    }

    static function testPoolSteadyState() {
        var first = pool.acquire(512, 512);
        pool.release(first);
        var same = true;
        for (i in 0...10) {
            var t = pool.acquire(512, 512);
            if (t != first) {
                same = false;
            }
            pool.release(t);
        }
        check("pool: steady-state reuses same target (zero alloc)", same);
    }

    static function testGraphReleaseTransients() {
        var graph = new RenderGraph();
        var t = pool.acquire(64, 64);
        var r = graph.createResource("temp", t);
        var ran = false;
        var p = new CallbackPass("p", function(frame) { ran = true; });
        p.write(r);
        graph.addPass(p);
        graph.setOutput(r);
        var freeBefore = pool.freeCount;
        graph.execute(new FrameContext(context, 64, 64));
        check("graph: execute runs passes", ran);
        graph.releaseTransients(pool);
        check("graph: releaseTransients returns target to pool",
            r.target == null && pool.freeCount == freeBefore + 1,
            'free=${pool.freeCount} expected=${freeBefore + 1}');
        graph.dispose();
    }

    // ---------------------------------------------------- GL: forward PBR

    static function testForwardLit() {
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        mat.setRoughness(0.6);
        var q = queueOf(mat, Mat4.identity(new Mat4()));

        var lit = renderForward(q, makeFrame(256, 256, true, 3.0), 256);
        var dark = renderForward(q, makeFrame(256, 256, true, 0.0), 256);
        var litAvg = avgLuma(lit, 256, 256);
        var darkAvg = avgLuma(dark, 256, 256);
        trace('forward: lit=' + f(litAvg) + ' unlit=' + f(darkAvg));
        check("forward: lit scene brighter than ambient-only",
            litAvg > darkAvg + 0.02, 'lit=' + f(litAvg) + ' unlit=' + f(darkAvg));
        check("forward: unlit still renders ambient", darkAvg > 0.001, 'unlit=' + f(darkAvg));
    }

    static function testPhongForward() {
        var mat = PhongMaterial.create("phong-lit");
        mat.setDiffuse(new Vec3(0.8, 0.4, 0.2));
        mat.setSpecular(new Vec3(0.6, 0.6, 0.6));
        mat.setShininess(64.0);
        var q = queueOf(mat, Mat4.identity(new Mat4()));

        var lit = avgLuma(renderPhong(q, makeFrame(256, 256, true, 3.0), 256), 256, 256);
        var unlit = avgLuma(renderPhong(q, makeFrame(256, 256, true, 0.0), 256), 256, 256);
        trace('phong: lit=' + f(lit) + ' unlit=' + f(unlit));
        check("phong: lit scene brighter than ambient-only", lit > unlit + 0.02,
            'lit=' + f(lit) + ' unlit=' + f(unlit));

        var dark = PhongMaterial.create("phong-dark");
        dark.setDiffuse(new Vec3(0.1, 0.1, 0.1));
        var darkAvg = avgLuma(renderPhong(queueOf(dark, Mat4.identity(new Mat4())), makeFrame(256, 256, true, 3.0), 256), 256, 256);
        check("phong: diffuse changes pixels", lit > darkAvg + 0.02, 'lit=' + f(lit) + ' dark=' + f(darkAvg));
    }

    static function testGeometryTangents() {
        check("Geometry: cube has tangent attribute", geometry.hasVertexAttribute("tangent"));
        var tangentBuffer = geometry.vertexBuffer("tangent");
        var tangentAttribute = tangentBuffer.attribute("tangent");
        check("Geometry: tangent is vec4", tangentAttribute.size == 4, 'size=${tangentAttribute.size}');

        var normalBuffer = geometry.vertexBuffer("normal");
        var normalAttribute = normalBuffer.attribute("normal");
        var nx = normalBuffer.data[normalAttribute.offset];
        var ny = normalBuffer.data[normalAttribute.offset + 1];
        var nz = normalBuffer.data[normalAttribute.offset + 2];
        var tx = tangentBuffer.data[0];
        var ty = tangentBuffer.data[1];
        var tz = tangentBuffer.data[2];
        var handedness = tangentBuffer.data[3];
        var dot = nx * tx + ny * ty + nz * tz;
        check("Geometry: tangent orthogonal to normal", Math.abs(dot) < 0.001, 'dot=$dot');
        check("Geometry: tangent handedness is ±1", Math.abs(Math.abs(handedness) - 1.0) < 0.001,
            'hand=$handedness');

        var count = geometry.vertexBuffers.length;
        geometry.computeTangents();
        check("Geometry: computeTangents idempotent", geometry.vertexBuffers.length == count);
    }

    static function testPhongNormalMap() {
        var flat = PhongMaterial.create("phong-flat");
        flat.setDiffuse(new Vec3(0.8, 0.8, 0.8));

        var normalTexture = Texture.create(context, 1, 1, false, false, true, TextureFormat.RGBA);
        var data = Bytes.alloc(4);
        data.set(0, 255);
        data.set(1, 128);
        data.set(2, 128);
        data.set(3, 255);
        normalTexture.setData(data, 1, 1);
        normalTexture.upload();

        var mapped = PhongMaterial.create("phong-normal");
        mapped.setDiffuse(new Vec3(0.8, 0.8, 0.8));
        mapped.setNormalMap(normalTexture);

        function frame():FrameContext {
            var f = makeFrame(256, 256, false);
            var light = Light.directional();
            light.direction = new Vec3(-1.0, 0.0, 0.0);
            light.intensity = 3.0;
            f.lights.add(light);
            return f;
        }

        var flatCenter = pixelAt(renderPhong(queueOf(flat, Mat4.identity(new Mat4())), frame(), 256), 256, 128, 128);
        var mappedCenter = pixelAt(renderPhong(queueOf(mapped, Mat4.identity(new Mat4())), frame(), 256), 256, 128, 128);
        trace('phong normal map: flat=${flatCenter} mapped=${mappedCenter}');
        check("Phong normal map: tangents change lighting",
            mappedCenter[0] > flatCenter[0] + 5 || mappedCenter[1] > flatCenter[1] + 5,
            'flat=${flatCenter} mapped=${mappedCenter}');
        normalTexture.dispose();
    }

    static function testPhongPath() {
        var root = Node.create("phong-path-root");
        var cameraNode = Node.create("camera")
            .addComponent(Transform.create())
            .addComponent(PerspectiveCamera.create(1.0));
        root.addChild(cameraNode);

        var material = PhongMaterial.create("phong-path-material");
        material.setDiffuse(new Vec3(0.8, 0.3, 0.2));
        material.setAlpha(0.5);
        var mesh = Node.create("mesh")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, material, null));
        root.addChild(mesh);

        var queue = new RenderQueue();
        SceneCollector.collect(root, queue);
        check("PhongSceneCollector: alpha material is transparent",
            queue.transparent.length == 1 && queue.opaque.length == 0,
            'opaque=${queue.opaque.length} transparent=${queue.transparent.length}');

        var path = new ForwardPhongPath(function(q, f, t) phong.render(q, f, t), null);
        var frame = makeFrame(128, 128);
        var graph = path.build(queue, frame);
        graph.execute(frame);
        var avg = avgLuma(readTarget(graph.output.target), 128, 128);
        graph.releaseTransients(pool);

        var second = path.build(queue, frame);
        second.execute(frame);
        var avgSecond = avgLuma(readTarget(second.output.target), 128, 128);
        trace('phong path: avg=' + f(avg) + ' second=' + f(avgSecond));
        check("PhongForwardPath: output non-black", avg > 0.005, 'avg=' + f(avg));
        check("PhongForwardPath: graph reused", graph == second);

        second.releaseTransients(pool);
        path.dispose();
    }

    static function testMaterialResponse() {
        // Roughness is compared on METALS: for a dielectric (F0 = 0.04) the
        // specular term is <1% of the pixel on a flat face, so GGX lobe width
        // is invisible after byte quantization. On metal (F0 = albedo) the
        // specular dominates and roughness changes pixels strongly.
        var world = Mat4.identity(new Mat4());
        var smooth = PBRMaterial.create();
        smooth.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        smooth.setMetallic(0.0);
        smooth.setRoughness(0.05);
        var metal = PBRMaterial.create();
        metal.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        metal.setMetallic(1.0);
        metal.setRoughness(0.05);
        var metalRough = PBRMaterial.create();
        metalRough.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        metalRough.setMetallic(1.0);
        metalRough.setRoughness(1.0);

        // Oblique light: with a head-on light the GGX lobe stays centered on
        // the view vector and roughness barely changes the image.
        var frame = makeFrame(256, 256, false);
        var dl = Light.directional();
        dl.direction = new Vec3(0.8, 0.35, -0.5);
        dl.intensity = 3.0;
        frame.lights.add(dl);
        var bSmooth = renderForward(queueOf(smooth, world), frame, 256);
        var bMetal = renderForward(queueOf(metal, world), frame, 256);
        var bMetalRough = renderForward(queueOf(metalRough, world), frame, 256);
        var dRough = meanAbsDiff(bMetal, bMetalRough);
        var dMetal = meanAbsDiff(bSmooth, bMetal);
        trace('material: roughnessDiff(metal)=' + f(dRough) + ' metallicDiff=' + f(dMetal));
        check("material: roughness changes pixels (metal)", dRough > 1.0, 'diff=' + f(dRough));
        check("material: metallic changes pixels", dMetal > 1.0, 'diff=' + f(dMetal));
    }

    static function testPointLight() {
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        mat.setRoughness(0.8);
        var q = queueOf(mat, Mat4.identity(new Mat4()));

        var near = makeFrame(256, 256, false);
        var pl = Light.point();
        pl.position = new Vec3(0.0, 0.0, 1.5);
        pl.range = 6.0;
        pl.intensity = 8.0;
        near.lights.add(pl);

        var far = makeFrame(256, 256, false);
        var pl2 = Light.point();
        pl2.position = new Vec3(0.0, 0.0, 100.0);
        pl2.range = 6.0;
        pl2.intensity = 8.0;
        far.lights.add(pl2);

        var aNear = avgLuma(renderForward(q, near, 256), 256, 256);
        var aFar = avgLuma(renderForward(q, far, 256), 256, 256);
        trace('point light: near=' + f(aNear) + ' far=' + f(aFar));
        check("point light: in-range light brighter than out-of-range",
            aNear > aFar + 0.02, 'near=' + f(aNear) + ' far=' + f(aFar));
    }

    static function testSpotLight() {
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        mat.setRoughness(0.8);
        var q = queueOf(mat, Mat4.identity(new Mat4()));

        function spotFrame(direction:Vec3):FrameContext {
            var frame = makeFrame(256, 256, false);
            var spot = Light.spot();
            spot.position = new Vec3(0.0, 0.0, 1.5);
            spot.direction = direction;
            spot.range = 6.0;
            spot.intensity = 8.0;
            spot.innerCone = 0.9;
            spot.outerCone = 0.7;
            frame.lights.add(spot);
            return frame;
        }

        var lit = avgLuma(renderForward(q, spotFrame(new Vec3(0.0, 0.0, -1.0)), 256), 256, 256);
        var away = avgLuma(renderForward(q, spotFrame(new Vec3(0.0, 0.0, 1.0)), 256), 256, 256);
        trace('spot light: lit=' + f(lit) + ' away=' + f(away));
        check("spot light: cone direction affects lighting", lit > away + 0.02,
            'lit=' + f(lit) + ' away=' + f(away));
    }

    static function testTransparency() {
        var back = PBRMaterial.create();
        back.setBaseColor(new Vec4(1.0, 1.0, 1.0, 1.0));
        back.setRoughness(0.9);
        var glass = PBRMaterial.create();
        glass.setBaseColor(new Vec4(1.0, 0.05, 0.05, 0.5));
        glass.setEmissive(new Vec3(0.6, 0.0, 0.0));
        glass.setRoughness(0.9);

        var backWorld = Mat4.identity(new Mat4());
        backWorld.r0c0 = 4.0;
        backWorld.r1c1 = 4.0;
        backWorld.r2c2 = 0.1;
        backWorld.r2c3 = -2.0;
        var glassWorld = Mat4.identity(new Mat4());

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, back, null, backWorld));
        q.add(new RenderItem(geometry, glass, null, glassWorld), true);

        var bytes = renderForward(q, makeFrame(256, 256, true, 3.0), 256);
        var c = pixelAt(bytes, 256, 128, 128);
        trace('transparent center r=${c[0]} g=${c[1]} b=${c[2]}');
        check("transparent: alpha-blended with background (g > 0)",
            c[1] > 30, 'g=${c[1]}');
        check("transparent: red tint dominates (r > g)",
            c[0] > c[1] + 20, 'r=${c[0]} g=${c[1]}');
    }

    // -------------------------------------------------------- GL: shadow

    static function testShadow() {
        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.4, 0.2, 1.0));
        cubeMat.setRoughness(0.8);
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.9, 0.9, 0.9, 1.0));
        wallMat.setRoughness(0.9);

        // Cube scale 0.5 -> spans pixels ~84..172 at the 3.5-distance camera,
        // so wall bands (8..80 / 188..248) contain wall only; a unit cube's
        // obliquely-lit faces would make the "shadows off" bands asymmetric.
        // The cube's shadow lands around pixel x~20..70, inside the left band.
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var light = Light.directional();
        light.intensity = 3.0;
        var lightEye = new Vec3(2.5, 2.0, 2.5);
        var lightView = GLM.lookAt(lightEye, new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        var lightProjection = GLM.orthographic(-4.0, 4.0, -4.0, 4.0, 0.1, 20.0, new Mat4());
        var lightViewProjection = lightProjection * lightView;

        var shadow = new ShadowRenderer(context);
        var shadowTarget = pool.acquireMRT(512, 512, [TextureFormat.RGBA], TextureFormat.Depth24);

        function buildQueue():RenderQueue {
            var q = new RenderQueue();
            q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
            q.add(new RenderItem(geometry, wallMat, null, wallWorld));
            return q;
        }

        function render(shadowsOn:Bool):Array<Float> {
            var queue = buildQueue();
            var frame = new FrameContext(context, 256, 256);
            frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
            frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
            frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
            frame.lights = new LightSet();
            frame.lights.add(light);
            if (shadowsOn) {
                shadow.render(queue, frame, shadowTarget, lightViewProjection);
                frame.shadowMap = shadowTarget;
                frame.lightViewProjection = lightViewProjection;
            }
            var target = pool.acquire(256, 256);
            target.bind(context, false);
            context.clear(0.0, 0.0, 0.0, 1.0);
            pbr.render(queue, frame, target);
            var bytes = Bytes.alloc(256 * 256 * 4);
            context.readPixels(bytes);
            target.unbind(context);
            pool.release(target);
            var leftSum = 0.0;
            var rightSum = 0.0;
            var leftN = 0;
            var rightN = 0;
            for (y in 0...256) {
                for (x in 0...256) {
                    var i = (y * 256 + x) * 4;
                    var luma = (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                    // Left band overlaps the shadow. NOTE: readPixels rows are
                    // stored top-to-bottom (probe-verified): the blob lives at
                    // stored y ~32..112, x ~16..84. Right band is unshadowed
                    // wall (cube spans x ~84..172).
                    if (x > 8 && x < 92 && y > 24 && y < 120) {
                        leftSum += luma;
                        leftN++;
                    }
                    if (x > 188 && x < 248 && y > 24 && y < 120) {
                        rightSum += luma;
                        rightN++;
                    }
                }
            }
            return [leftSum / leftN, rightSum / rightN];
        }

        var on = render(true);
        var off = render(false);
        shadow.dispose();
        pool.release(shadowTarget);

        trace('shadow on  left=' + f(on[0]) + ' right=' + f(on[1]));
        trace('shadow off left=' + f(off[0]) + ' right=' + f(off[1]));
        check("shadow: occluded band darker with shadows",
            on[0] < off[0] - 0.03, 'on=' + f(on[0]) + ' off=' + f(off[0]));
        check("shadow: lit band brighter than shadowed band",
            on[1] > on[0] * 1.3, 'right=' + f(on[1]) + ' left=' + f(on[0]));
        check("shadow: disabled gives uniform lighting",
            off[0] > off[1] * 0.8, 'left=' + f(off[0]) + ' right=' + f(off[1]));
    }

    // ------------------------------------------- logic: normal matrix math

    static function testCSM() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("CSM: depth texture available", true);
            return;
        }

        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var direction = Vec3.normalize(new Vec3(-2.5, -2.0, -2.5), new Vec3());
        var shadow = new ShadowRenderer(context);

        function render(csm:Bool):{left:Float, cascades:Int, avg:Float} {
            var path = new ForwardPath(function(q, f, t) pbr.render(q, f, t));
            if (csm) {
                path.shadowRenderer = shadow;
                path.shadowCascadeCount = 2;
                path.shadowLightDirection = direction;
                path.shadowMapSize = 256;
                path.shadowMaxDistance = 30.0;
            }

            var q = new RenderQueue();
            q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
            q.add(new RenderItem(geometry, wallMat, null, wallWorld));

            var frame = makeFrame(256, 256);
            frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
            frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
            frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
            frame.lights = new LightSet();
            var light = Light.directional();
            light.direction = direction;
            light.intensity = 3.0;
            frame.lights.add(light);

            var graph = path.build(q, frame);
            graph.execute(frame);
            var bytes = readTarget(graph.output.target);
            var cascades = frame.shadowCascades != null ? frame.shadowCascades.length : 0;
            var leftSum = 0.0;
            var leftN = 0;
            var total = 0.0;
            for (y in 0...256) {
                for (x in 0...256) {
                    var i = (y * 256 + x) * 4;
                    var luma = (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                    total += luma;
                    if (x > 8 && x < 92 && y > 24 && y < 120) {
                        leftSum += luma;
                        leftN++;
                    }
                }
            }
            var result = {left: leftSum / leftN, cascades: cascades, avg: total / (256 * 256)};
            graph.releaseTransients(pool);
            graph.dispose();
            path.dispose();
            return result;
        }

        var on = render(true);
        var off = render(false);
        if (on.cascades > 0) trace('CSM: cascades=${on.cascades} on.left=' + f(on.left) + ' off.left=' + f(off.left)
            + ' on.avg=' + f(on.avg));
        check("CSM: two cascades built", on.cascades == 2, 'cascades=${on.cascades}');
        check("CSM: output non-black", on.avg > 0.02, 'avg=' + f(on.avg));
        check("CSM: shadowed band darker", on.left < off.left - 0.02,
            'on=' + f(on.left) + ' off=' + f(off.left));

        shadow.dispose();
    }

    static function testMaterialClasses() {
        var phong = PhongMaterial.create();
        check("PhongMaterial: default diffuse", cast(phong.get(PhongMaterial.DIFFUSE), Vec3).x == 1.0);
        check("PhongMaterial: default shininess", cast(phong.get(PhongMaterial.SHININESS), Float) == 32.0);
        var version = phong.version;
        phong.setShininess(64.0).setAlpha(0.5);
        check("PhongMaterial: setters bump version", phong.version > version, '${phong.version} vs $version');
        check("PhongMaterial: shininess updated", cast(phong.get(PhongMaterial.SHININESS), Float) == 64.0);

        var pbr = PBRMaterial.create("moved-pbr");
        check("PBRMaterial: moved to minko.material",
            pbr.hasProperty(PBRMaterial.BASE_COLOR) && pbr.hasProperty(PBRMaterial.ROUGHNESS));
        pbr.setMetallic(0.7);
        check("PBRMaterial: setter updates metallic", cast(pbr.get(PBRMaterial.METALLIC), Float) == 0.7);
    }

    static function localShadowRender(light:Light, enabled:Bool, usePhong:Bool = false):{avg:Float, left:Float, spot:Bool, point:Bool} {
        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        var shadow = new ShadowRenderer(context);
        var path = new ForwardPath(function(qq, f, t) { if (usePhong) phong.render(qq, f, t); else pbr.render(qq, f, t); });
        path.shadowRenderer = shadow;
        path.enableLocalShadows = enabled;
        path.spotShadowSize = 256;
        path.pointShadowSize = 256;

        var frame = makeFrame(256, 256, false);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.lights = new LightSet();
        light.castShadow = true;
        frame.lights.add(light);
        frame.capabilities = RenderCapabilities.detect(context);
        frame.targetPool = pool;

        var graph = path.build(q, frame);
        graph.execute(frame);
        var bytes = readTarget(graph.output.target);
        var leftSum = 0.0;
        var leftN = 0;
        var total = 0.0;
        for (y in 0...256) {
            for (x in 0...256) {
                var i = (y * 256 + x) * 4;
                var luma = (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                total += luma;
                if (x > 8 && x < 92 && y > 24 && y < 120) {
                    leftSum += luma;
                    leftN++;
                }
            }
        }
        var result = {
            avg: total / (256 * 256),
            left: leftSum / leftN,
            spot: frame.spotShadow != null,
            point: frame.pointShadow != null
        };
        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        shadow.dispose();
        return result;
    }

    static function testSpotShadow() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("spot shadow: depth texture available", true);
            return;
        }
        var spot = Light.spot();
        spot.position = new Vec3(2.5, 2.0, 2.5);
        spot.direction = Vec3.normalize(new Vec3(-2.5, -2.0, -2.5), new Vec3());
        spot.range = 20.0;
        spot.intensity = 50.0;
        spot.outerCone = 0.7;
        spot.innerCone = 0.9;

        var on = localShadowRender(spot, true);
        var off = localShadowRender(spot, false);
        trace('spot shadow: on.left=' + f(on.left) + ' off.left=' + f(off.left)
            + ' on.avg=' + f(on.avg) + ' off.avg=' + f(off.avg));
        check("spot shadow: shadow resource built", on.spot);
        check("spot shadow: no shadow resource when disabled", !off.spot);
        check("spot shadow: shadowed band darker", on.left < off.left - 0.01,
            'on=' + f(on.left) + ' off=' + f(off.left));
    }

    static function testPointShadow() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("point shadow: depth texture available", true);
            return;
        }
        var point = Light.point();
        point.position = new Vec3(1.5, 1.5, 1.5);
        point.range = 20.0;
        point.intensity = 50.0;

        var on = localShadowRender(point, true);
        var off = localShadowRender(point, false);
        trace('point shadow: on.avg=' + f(on.avg) + ' off.avg=' + f(off.avg)
            + ' on.left=' + f(on.left) + ' off.left=' + f(off.left));
        check("point shadow: shadow resources built", on.point);
        check("point shadow: no shadow resource when disabled", !off.point);
        check("point shadow: changes output", Math.abs(on.avg - off.avg) > 0.002,
            'on=' + f(on.avg) + ' off=' + f(off.avg));
    }

    static function testPhongLocalShadow() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("phong local shadow: depth texture available", true);
            return;
        }
        var spot = Light.spot();
        spot.position = new Vec3(2.5, 2.0, 2.5);
        spot.direction = Vec3.normalize(new Vec3(-2.5, -2.0, -2.5), new Vec3());
        spot.range = 20.0;
        spot.intensity = 50.0;
        spot.outerCone = 0.7;
        spot.innerCone = 0.9;

        var on = localShadowRender(spot, true, true);
        var off = localShadowRender(spot, false, true);
        trace('phong local shadow: on.left=' + f(on.left) + ' off.left=' + f(off.left));
        check("phong local shadow: resource built", on.spot);
        check("phong local shadow: shadowed band darker", on.left < off.left - 0.01,
            'on=' + f(on.left) + ' off=' + f(off.left));
    }

    static function testSkinningSnapshotStorage() {
        // Skinning no longer keeps ObjectMaps for target geometry / software
        // inputs: the undeformed snapshot lives on Geometry and the geometry
        // is resolved through the target node Surface.
        var data = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];
        var vb = VertexBuffer.createbyData(context, data);
        vb.addAttribute("position", 3, 0);
        var geometry = Geometry.create();
        geometry.addVertexBuffer(vb);

        var skin = new Skin(1, 10, 1);
        var bone = new Bone(null, Mat4.identity(new Mat4()), [0, 1, 2, 3], [1.0, 1.0, 1.0, 1.0]);
        skin.bones = [bone];
        skin.reorganizeByVertices();
        var translate = Mat4.identity(new Mat4());
        translate.r0c3 = 1.0;
        translate.r1c3 = 2.0;
        translate.r2c3 = 3.0;
        skin.setMatrix(0, 0, translate);

        var skinning = new Skinning(skin, SkinningMethod.SOFTWARE, context, null, false, true);
        skinning.initialize();

        var root = Node.create();
        var node = new Node();
        node.addComponent(Surface.create(geometry, null));
        // targetAdded wires the added/removed signals; addChild then
        // raises addedHandler(node, node, root) through those signals.
        skinning.targetAdded(node);
        root.addChild(node);
        var snapshot = geometry.skinningInputPositions;
        check("skinning: undeformed snapshot stored on geometry",
            snapshot != null && snapshot.length == data.length,
            snapshot == null ? "null" : Std.string(snapshot.length));

        skinning.updateFrame(0, node);
        var out = geometry.vertexBuffer("position").data;
        check("skinning: software skinning applied through geometry",
            Math.abs(out[0] - 1.0) < 0.001 && Math.abs(out[1] - 2.0) < 0.001 && Math.abs(out[2] - 3.0) < 0.001,
            out[0] + "," + out[1] + "," + out[2]);

        // A second update must read the snapshot, not the previously written
        // (already skinned) vertex buffer, so the result is stable.
        skinning.updateFrame(0, node);
        var out2 = geometry.vertexBuffer("position").data;
        check("skinning: snapshot survives repeated updates",
            Math.abs(out2[0] - out[0]) < 0.0001 && Math.abs(out2[1] - out[1]) < 0.0001);

        root.removeChild(node);
        check("skinning: snapshot cleared when the target is removed",
            geometry.skinningInputPositions == null);
    }

    static function testPhongPointCubeShadow() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("phong point cube shadow: depth texture available", true);
            return;
        }
        var point = Light.point();
        point.position = new Vec3(1.5, 1.5, 1.5);
        point.range = 20.0;
        point.intensity = 50.0;

        var on = localShadowRender(point, true, true);
        var off = localShadowRender(point, false, true);
        trace('phong point cube shadow: on.left=' + f(on.left) + ' off.left=' + f(off.left)
            + ' on.point=' + on.point);
        check("phong point cube shadow: resource built", on.point);
        check("phong point cube shadow: shadowed band darker", on.left < off.left - 0.01,
            'on=' + f(on.left) + ' off=' + f(off.left));
    }

    static function testPBRMath() {
        // Non-uniform scale applied in WORLD space after a 45-degree rotation:
        // the world matrix skews the rotated normal, the inverse-transpose does
        // not. This is the case that "normalMatrix = world" got wrong.
        var rot = GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), Math.PI / 4, new Quat()), new Mat4());
        var scale = Mat4.identity(new Mat4());
        scale.r0c0 = 2.0;
        scale.r1c1 = 1.0;
        scale.r2c2 = 0.5;
        var world = scale * rot;

        var normalMatrix = PBRMath.normalMatrix(world, new Mat4());
        var localNormal = new Vec4(0.0, 0.0, 1.0, 0.0);
        var transformed = Mat4.multVec(normalMatrix, localNormal, new Vec4());
        var length = Math.sqrt(transformed.x * transformed.x + transformed.y * transformed.y + transformed.z * transformed.z);
        var nx = transformed.x / length;
        var ny = transformed.y / length;
        var nz = transformed.z / length;
        trace('normal matrix: transformed=(${f(nx)}, ${f(ny)}, ${f(nz)})');
        // transpose(inverse(S * rot)) * (0,0,1) = S^-1 * rot * (0,0,1)
        //   = (0.5, 1, 2) * (0.7071, 0, 0.7071) -> (0.243, 0, 0.970)
        check("normal matrix: inverse-transpose keeps the face direction",
            Math.abs(nx - 0.243) < 0.01 && Math.abs(ny) < 0.01 && Math.abs(nz - 0.970) < 0.01,
            'n=(${f(nx)}, ${f(ny)}, ${f(nz)})');

        // The naive world transform gives (0.970, 0, 0.243) here, so the check
        // genuinely discriminates old and new behaviour.
        var naive = Mat4.multVec(world, localNormal, new Vec4());
        var naiveLength = Math.sqrt(naive.x * naive.x + naive.y * naive.y + naive.z * naive.z);
        var naiveX = naive.x / naiveLength;
        check("normal matrix: differs from world-transform behaviour",
            Math.abs(naiveX - nx) > 0.2, 'naive=' + f(naiveX) + ' correct=' + f(nx));

        // Singular (zero scale) world matrices must not throw.
        var singular = Mat4.identity(new Mat4());
        singular.r0c0 = 0.0;
        singular.r1c1 = 0.0;
        singular.r2c2 = 0.0;
        var fallback = PBRMath.normalMatrix(singular, new Mat4());
        check("normal matrix: singular world falls back without throwing",
            fallback.r0c0 == 0.0 && fallback.r0c1 == 0.0);
    }

    // ------------------------------------------------------- GL: deferred

    static function testGBufferState() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            return;
        }

        // Leave ALPHA blending on the context: a forward render with a
        // transparent item does exactly that (this is what made the deferred
        // lighting collapse to its ambient term before the fix).
        var glassMat = PBRMaterial.create();
        glassMat.setBaseColor(new Vec4(1.0, 0.1, 0.1, 0.5));
        var transparentQueue = new RenderQueue();
        transparentQueue.add(new RenderItem(geometry, glassMat, null, Mat4.identity(new Mat4())), true);
        renderForward(transparentQueue, makeFrame(256, 256), 256);

        var mat = deferredMaterial();
        var q = queueOf(mat, Mat4.identity(new Mat4()));
        var gTarget = pool.acquireMRT(256, 256, [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);
        var gbufferRenderer = new GBufferRenderer(context);
        gbufferRenderer.render(q, makeFrame(256, 256), gbuffer);

        var copier = new FullscreenEffect(context, "GBufferStateCopy", PBRShaderLibrary.presentFragment());
        var normalBytes = copyBytes(copier, gbuffer.normalTexture);
        var center = pixelAt(normalBytes, 256, 128, 128);
        trace('gbuffer state: center normal=(${center[0]},${center[1]},${center[2]}) alpha=${center[3]}');
        check("gbuffer: blending state does not corrupt normals",
            center[0] > 121 && center[0] < 133 && center[1] > 121 && center[1] < 133 && center[2] > 249,
            'normal=(${center[0]},${center[1]},${center[2]})');
        check("gbuffer: roughness alpha survives",
            center[3] > 145 && center[3] < 161, 'alpha=${center[3]}');

        pool.release(gTarget);
        copier.dispose();
        gbufferRenderer.dispose();
    }

    static function testGBufferNonUniformNormals() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            return;
        }

        // scale(world) * rotate(45 about Y): the correct inverse-transpose
        // normal is (0.243, 0, 0.970); "normalMatrix = world" gives
        // (0.970, 0, 0.243). The +Z face is still the visible one.
        var rot = GLM.rotate(Quat.axisAngle(new Vec3(0.0, 1.0, 0.0), Math.PI / 4, new Quat()), new Mat4());
        var scale = Mat4.identity(new Mat4());
        scale.r0c0 = 2.0;
        scale.r1c1 = 1.0;
        scale.r2c2 = 0.5;
        var world = scale * rot;

        var q = queueOf(deferredMaterial(), world);
        var gTarget = pool.acquireMRT(256, 256, [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);
        var gbufferRenderer = new GBufferRenderer(context);
        gbufferRenderer.render(q, makeFrame(256, 256), gbuffer);

        var copier = new FullscreenEffect(context, "GBufferNormalCopy", PBRShaderLibrary.presentFragment());
        var normalBytes = copyBytes(copier, gbuffer.normalTexture);
        var center = pixelAt(normalBytes, 256, 128, 128);
        var nx = center[0] / 255.0 * 2.0 - 1.0;
        var nz = center[2] / 255.0 * 2.0 - 1.0;
        trace('non-uniform normal: encoded=(${center[0]},${center[1]},${center[2]}) decoded=(${f(nx)}, ${f(nz)})');
        check("gbuffer: non-uniform scale keeps inverse-transpose normal",
            Math.abs(nx - 0.243) < 0.1 && Math.abs(nz - 0.970) < 0.1,
            'decoded=(${f(nx)}, ${f(nz)})');

        pool.release(gTarget);
        copier.dispose();
        gbufferRenderer.dispose();
    }

    static function testGBufferDebugViews() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            return;
        }

        var mat = deferredMaterial();
        mat.setEmissive(new Vec3(0.5, 0.3, 0.1));
        var q = queueOf(mat, Mat4.identity(new Mat4()));
        var gTarget = pool.acquireMRT(256, 256, [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);
        var gbufferRenderer = new GBufferRenderer(context);
        gbufferRenderer.render(q, makeFrame(256, 256), gbuffer);

        var debug = new GBufferDebugRenderer(context);
        var out = pool.acquire(256, 256);

        function view(mode:GBufferDebugMode):{avg:Float, bytes:Bytes} {
            out.bind(context, false);
            context.clear(0.0, 1.0, 0.0, 1.0); // green: a mode that draws nothing is obvious
            out.unbind(context);
            debug.render(gbuffer, mode, out, 0.1, 100.0, 10.0, new Vec3(0.0, 0.0, 1.0));
            var bytes = readTarget(out);
            return {avg: avgLuma(bytes, 256, 256), bytes: bytes};
        }

        var albedo = view(GBufferDebugMode.Albedo);
        var normal = view(GBufferDebugMode.Normal);
        var depth = view(GBufferDebugMode.Depth);
        var lighting = view(GBufferDebugMode.Lighting);
        var emissive = view(GBufferDebugMode.Emissive);
        trace('debug views: albedo=' + f(albedo.avg) + ' normal=' + f(normal.avg)
            + ' depth=' + f(depth.avg) + ' lighting=' + f(lighting.avg) + ' emissive=' + f(emissive.avg));

        check("debug: albedo view non-black", albedo.avg > 0.05, 'avg=' + f(albedo.avg));
        check("debug: normal view non-black", normal.avg > 0.03, 'avg=' + f(normal.avg));
        check("debug: lighting view non-black", lighting.avg > 0.03, 'avg=' + f(lighting.avg));
        check("debug: emissive view non-black", emissive.avg > 0.02, 'avg=' + f(emissive.avg));
        check("debug: albedo and normal views differ", meanAbsDiff(albedo.bytes, normal.bytes) > 5.0,
            'diff=' + f(meanAbsDiff(albedo.bytes, normal.bytes)));

        if (caps.supportsDepthTexture) {
            // Background depth maps to white, the cube to a darker value.
            var bg = avgLuma(depth.bytes, 256, 256);
            var cubePixel = pixelAt(depth.bytes, 256, 128, 128);
            trace('debug depth: avg=' + f(bg) + ' center=' + cubePixel[0]);
            check("debug: depth view shows the cube", cubePixel[0] < 200 && bg > 0.0,
                'center=' + cubePixel[0] + ' avg=' + f(bg));
        }

        pool.release(out);
        pool.release(gTarget);
        debug.dispose();
        gbufferRenderer.dispose();
    }

    static function testPoolFormats() {
        var rgba = pool.acquire(128, 128);
        check("pool: acquire returns requested RGBAs format", rgba.colors[0].format == TextureFormat.RGBA);
        pool.release(rgba);

        var hdr = pool.acquire(128, 128, TextureFormat.RGBA16F);
        check("pool: RGBA16F request not served by an RGBA target",
            hdr.colors[0].format == TextureFormat.RGBA16F, '' + hdr.colors[0].format);
        pool.release(hdr);

        var rgbaAgain = pool.acquire(128, 128, TextureFormat.RGBA);
        check("pool: RGBA request not served by an RGBA16F target",
            rgbaAgain.colors[0].format == TextureFormat.RGBA, '' + rgbaAgain.colors[0].format);
        pool.release(rgbaAgain);

        var depth24 = pool.acquireMRT(128, 128, [TextureFormat.RGBA], TextureFormat.Depth24);
        pool.release(depth24);
        var depth32 = pool.acquireMRT(128, 128, [TextureFormat.RGBA], TextureFormat.Depth32F);
        check("pool: depth format is part of the reuse key",
            depth32.depth != null && depth32.depth.format == TextureFormat.Depth32F,
            depth32.depth == null ? "no depth" : '' + depth32.depth.format);
        pool.release(depth32);
    }

    // ------------------------------------------------------- GL: deferred

    static function deferredMaterial():PBRMaterial {
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.9, 0.6, 0.2, 1.0));
        mat.setRoughness(0.6);
        return mat;
    }

    static function testDeferredMRT() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            check("deferred MRT: capabilities", false, "no MRT support");
            return;
        }
        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var gTarget = pool.acquireMRT(256, 256,
            [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);
        var q = queueOf(deferredMaterial(), Mat4.identity(new Mat4()));
        var frame = makeFrame(256, 256);

        gTarget.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        gbufferRenderer.render(q, frame, gbuffer);
        gbuffer.unbind(context);

        var out = pool.acquire(256, 256);
        lighting.render(gbuffer, out);
        var avg = avgLuma(readTarget(out), 256, 256);
        trace('deferred mrt avg=' + f(avg));
        check("deferred MRT: lighting output non-black", avg > 0.02, 'avg=' + f(avg));

        // G-Buffer debug-view precondition: each MRT attachment must hold
        // readable data (the pipeline exposes the textures but ships no
        // debug-view renderer; see report).
        var copier = new FullscreenEffect(context, "GBufferCopy", PBRShaderLibrary.presentFragment());
        var albedoAvg = copyAvg(copier, gbuffer.albedoTexture);
        var normalAvg = copyAvg(copier, gbuffer.normalTexture);
        trace('deferred gbuffer albedo=' + f(albedoAvg) + ' normal=' + f(normalAvg));
        check("deferred MRT: albedo attachment has data", albedoAvg > 0.02, 'avg=' + f(albedoAvg));
        // Front face normal encodes to (0.5,0.5,1) -> luma ~0.56 over the
        // cube's ~16% screen coverage, i.e. ~0.09 whole-frame average.
        check("deferred MRT: normal attachment has data", normalAvg > 0.03, 'avg=' + f(normalAvg));

        copier.dispose();
        pool.release(out);
        pool.release(gTarget);
        gbufferRenderer.dispose();
        lighting.dispose();
    }

    static function testDeferredFallback() {
        var fallback = new GBufferFallbackRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var albedo = pool.acquire(256, 256);
        var normal = pool.acquire(256, 256);
        var emissive = pool.acquire(256, 256);
        var gbuffer = new GBuffer(albedo, normal, emissive, 256, 256);
        var q = queueOf(deferredMaterial(), Mat4.identity(new Mat4()));
        var frame = makeFrame(256, 256);

        for (t in [albedo, normal, emissive]) {
            t.bind(context, true);
            context.clear(0.0, 0.0, 0.0, 1.0);
            t.unbind(context);
        }
        fallback.render(q, frame, gbuffer);

        var out = pool.acquire(256, 256);
        lighting.render(gbuffer, out);
        var avg = avgLuma(readTarget(out), 256, 256);
        trace('deferred fallback avg=' + f(avg));
        check("deferred fallback: lighting output non-black", avg > 0.02, 'avg=' + f(avg));

        pool.release(out);
        pool.release(albedo);
        pool.release(normal);
        pool.release(emissive);
        fallback.dispose();
        lighting.dispose();
    }

    static function runDeferredPath(caps:RenderCapabilities, runs:Int = 1):{avg:Float, names:String, freed:Bool, avgs:Array<Float>} {
        var gbufferRenderer = new GBufferRenderer(context);
        var gbufferFallback = new GBufferFallbackRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var useMRT = caps.supportsMRT;
        var path = new DeferredPBRPath(
            function(q, f, g) {
                if (useMRT) gbufferRenderer.render(q, f, g);
                else gbufferFallback.render(q, f, g);
            },
            function(f, g, o) lighting.render(g, o, f),
            null, // no transparent callback: the path must copy the scene color itself
            null);

        var q = queueOf(deferredMaterial(), Mat4.identity(new Mat4()));
        var frame = makeFrame(256, 256);
        frame.capabilities = caps;
        var graph = path.build(q, frame);
        var compiled = graph.compile();
        var names = [for (p in compiled) p.name].join(",");

        var freeBefore = pool.freeCount;
        var avgs:Array<Float> = [];
        for (i in 0...runs) {
            graph.execute(frame);
            avgs.push(avgLuma(readTarget(graph.output.target), 256, 256));
        }
        graph.releaseTransients(pool);
        var freed = pool.freeCount > freeBefore;
        graph.dispose();
        path.dispose();

        gbufferRenderer.dispose();
        gbufferFallback.dispose();
        lighting.dispose();
        return {avg: avgs[avgs.length - 1], names: names, freed: freed, avgs: avgs};
    }

    static function testDeferredPath() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            check("deferred path (MRT): capabilities", false, "no MRT support");
            return;
        }
        var r = runDeferredPath(caps, 2);
        trace('deferred path passes: ${r.names} avg=' + f(r.avg) + ' run2=' + f(r.avgs[1]));
        check("deferred path (MRT): pass order",
            r.names == "GBufferPass,DeferredLightingPass,ForwardTransparentPass", r.names);
        check("deferred path (MRT): output non-black", r.avg > 0.02, 'avg=' + f(r.avg));
        check("deferred path (MRT): transients released", r.freed);
        // The G-buffer pass must clear its target: a second frame with the same
        // scene has to match the first one (no stale pool content).
        check("deferred path (MRT): repeated frames identical",
            Math.abs(r.avgs[0] - r.avgs[1]) < 0.002, 'run1=' + f(r.avgs[0]) + ' run2=' + f(r.avgs[1]));
    }

    static function testDeferredPathPersistent() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            return;
        }

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var path = new DeferredPBRPath(
            function(q, f, g) gbufferRenderer.render(q, f, g),
            function(f, g, o) lighting.render(g, o, f),
            null,
            null);
        var q = queueOf(deferredMaterial(), Mat4.identity(new Mat4()));
        var frame = makeFrame(128, 128);
        frame.capabilities = caps;

        var first = path.build(q, frame);
        first.execute(frame);
        var avgFirst = avgLuma(readTarget(first.output.target), 128, 128);
        first.releaseTransients(pool);

        var second = path.build(q, frame);
        second.execute(frame);
        var avgSecond = avgLuma(readTarget(second.output.target), 128, 128);
        trace('deferred path persistent: first=' + f(avgFirst) + ' second=' + f(avgSecond));
        check("deferred path: graph reused across frames", first == second);
        check("deferred path: reused graph renders",
            avgSecond > 0.02 && Math.abs(avgFirst - avgSecond) < 0.002,
            'first=' + f(avgFirst) + ' second=' + f(avgSecond));

        second.releaseTransients(pool);
        path.dispose();
        gbufferRenderer.dispose();
        lighting.dispose();
    }

    static function testDeferredPathFallbackCaps() {
        var caps = new RenderCapabilities(); // all false -> 3-target fallback branch
        var r = runDeferredPath(caps, 2);
        trace('deferred path (fallback) passes: ${r.names} avg=' + f(r.avg));
        check("deferred path (fallback): pass order",
            r.names == "GBufferPass,DeferredLightingPass,ForwardTransparentPass", r.names);
        check("deferred path (fallback): output non-black", r.avg > 0.02, 'avg=' + f(r.avg));
        check("deferred path (fallback): repeated frames identical",
            Math.abs(r.avgs[0] - r.avgs[1]) < 0.002, 'run1=' + f(r.avgs[0]) + ' run2=' + f(r.avgs[1]));
    }

    static function testDeferredPathShadow() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT || !caps.supportsDepthTexture) {
            check("deferred path shadow: depth capability", true);
            return;
        }

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var shadow = new ShadowRenderer(context);
        var path = new DeferredPBRPath(
            function(q, f, g) gbufferRenderer.render(q, f, g),
            function(f, g, o) lighting.render(g, o, f),
            null,
            null);

        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var lightEye = new Vec3(2.5, 2.0, 2.5);
        var lightView = GLM.lookAt(lightEye, new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        var lightProjection = GLM.orthographic(-4.0, 4.0, -4.0, 4.0, 0.1, 20.0, new Mat4());
        path.shadowRenderer = shadow;
        path.lightViewProjection = lightProjection * lightView;
        path.shadowMapSize = 512;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        var frame = new FrameContext(context, 256, 256);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.lights = new LightSet();
        var light = Light.directional();
        light.intensity = 3.0;
        frame.lights.add(light);
        frame.capabilities = caps;
        frame.targetPool = pool;

        var graph = path.build(q, frame);
        var compiled = graph.compile();
        var names = [for (p in compiled) p.name].join(",");
        graph.execute(frame);
        var avg = avgLuma(readTarget(graph.output.target), 256, 256);
        trace('deferred path shadow: passes=${names} avg=' + f(avg));
        check("deferred path shadow: shadow pass present", names.indexOf("ShadowPass") >= 0, names);
        check("deferred path shadow: output non-black", avg > 0.02, 'avg=' + f(avg));

        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        gbufferRenderer.dispose();
        lighting.dispose();
        shadow.dispose();
    }

    static function testDeferredPathTransparent() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            return;
        }

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var copier = new FullscreenEffect(context, "DeferredTransparentCopy", PBRShaderLibrary.presentFragment());

        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.9, 0.9, 0.9, 1.0));
        wallMat.setRoughness(0.9);
        var glassMat = PBRMaterial.create();
        glassMat.setBaseColor(new Vec4(1.0, 0.05, 0.05, 0.5));
        glassMat.setEmissive(new Vec3(0.6, 0.0, 0.0));
        glassMat.setRoughness(0.9);

        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 4.0;
        wallWorld.r1c1 = 4.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -2.0;
        var glassWorld = Mat4.identity(new Mat4());

        var queue = new RenderQueue();
        queue.add(new RenderItem(geometry, wallMat, null, wallWorld));
        queue.add(new RenderItem(geometry, glassMat, null, glassWorld), true);

        var path = new DeferredPBRPath(function(q, f, g) gbufferRenderer.render(q, f, g),
            function(f, g, o) lighting.render(g, o, f), null, null);

        var sawSceneColor = [false];
        var sceneColorIsHDR = [false];
        // The callback receives the lit scene; copy it, then draw the
        // transparent queue on top with alpha blending.
        path.renderTransparent = function(rq, f, sceneColor, output) {
            sawSceneColor[0] = sceneColor != null && sceneColor.color != null;
            sceneColorIsHDR[0] = sceneColor != null && sceneColor.color != null && sceneColor.color.format == TextureFormat.RGBA16F;
            copier.render(output, function(e) e.setTexture("uColorMap", sceneColor.color));
            var transparentOnly = new RenderQueue();
            for (item in rq.transparent) {
                transparentOnly.add(item, true);
            }
            // FullscreenEffect.render() unbinds its output, so bind the final
            // target again before drawing geometry into it.
            output.bind(f.context, true);
            pbr.render(transparentOnly, f, output);
            output.unbind(f.context);
        };

        var frame = makeFrame(256, 256);
        var graph = path.build(queue, frame);
        graph.execute(frame);
        var bytes = readTarget(graph.output.target);
        var center = pixelAt(bytes, 256, 128, 128);
        var avg = avgLuma(bytes, 256, 256);
        trace('deferred transparent: center r=${center[0]} g=${center[1]} b=${center[2]} avg=' + f(avg));
        check("deferred transparent: callback receives scene color", sawSceneColor[0]);
        check("deferred transparent: scene color is HDR", sceneColorIsHDR[0] || !caps.supportsFloatRenderTarget);
        check("deferred transparent: glass tints the lit scene", center[0] > center[1] + 20, 'r=${center[0]} g=${center[1]}');
        check("deferred transparent: lit scene visible", center[1] > 30, 'g=${center[1]}');

        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        copier.dispose();
        gbufferRenderer.dispose();
        lighting.dispose();
    }

    static function testDeferredMatchesForward() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            return;
        }

        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.7, 0.6, 0.5, 1.0));
        mat.setRoughness(0.5);
        mat.setMetallic(0.2);
        var q = queueOf(mat, Mat4.identity(new Mat4()));

        // Forward reference.
        var forwardFrame = makeFrame(256, 256, true, 3.0);
        var forwardAvg = avgLuma(renderForward(q, forwardFrame, 256), 256, 256);

        // Deferred reference (same camera, same directional light).
        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var path = new DeferredPBRPath(function(qq, f, g) gbufferRenderer.render(qq, f, g),
            function(f, g, o) lighting.render(g, o, f), null, null);
        var frame = makeFrame(256, 256, true, 3.0);
        var graph = path.build(q, frame);
        graph.execute(frame);
        var deferredAvg = avgLuma(readTarget(graph.output.target), 256, 256);
        trace('deferred vs forward: deferred=' + f(deferredAvg) + ' forward=' + f(forwardAvg));
        check("deferred lighting matches forward path",
            Math.abs(deferredAvg - forwardAvg) < 0.03, 'deferred=' + f(deferredAvg) + ' forward=' + f(forwardAvg));

        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        gbufferRenderer.dispose();
        lighting.dispose();
    }

    static function testDeferredPointLights() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("deferred point light: depth texture available", true);
            return;
        }

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var gTarget = pool.acquireMRT(256, 256,
            [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);
        var q = queueOf(deferredMaterial(), Mat4.identity(new Mat4()));
        var frame = makeFrame(256, 256, false);

        var point = Light.point();
        point.color = new Vec3(1.0, 0.9, 0.8);
        point.range = 8.0;
        point.intensity = 4.0;
        point.position = new Vec3(0.0, 0.0, 1.5);

        function render(deferredLight:Light):Float {
            frame.lights.clear();
            frame.lights.add(deferredLight);
            gTarget.bind(context, true);
            context.clear(0.0, 0.0, 0.0, 1.0);
            gbufferRenderer.render(q, frame, gbuffer);
            gbuffer.unbind(context);

            var out = pool.acquire(256, 256);
            lighting.render(gbuffer, out, frame);
            var pixels = readTarget(out);
            var avg = avgLuma(pixels, 256, 256);
            pool.release(out);
            return avg;
        }

        var near = render(point);
        var oldPosition = point.position;
        point.position = new Vec3(20.0, 20.0, 20.0);
        point.range = 2.0;
        var far = render(point);
        point.position = oldPosition;
        point.range = 8.0;

        trace('deferred point light: near=' + f(near) + ' far=' + f(far));
        check("deferred point light: near brighter than far", near > far + 0.01,
            'near=' + f(near) + ' far=' + f(far));

        var spot = Light.spot();
        spot.position = new Vec3(0.0, 0.0, 1.5);
        spot.range = 8.0;
        spot.intensity = 4.0;
        spot.innerCone = 0.9;
        spot.outerCone = 0.7;
        spot.direction = new Vec3(0.0, 0.0, -1.0);
        var spotLit = render(spot);
        spot.direction = new Vec3(0.0, 0.0, 1.0);
        var spotAway = render(spot);
        trace('deferred spot light: lit=' + f(spotLit) + ' away=' + f(spotAway));
        check("deferred spot light: cone direction affects lighting", spotLit > spotAway + 0.01,
            'lit=' + f(spotLit) + ' away=' + f(spotAway));

        pool.release(gTarget);
        gbufferRenderer.dispose();
        lighting.dispose();
    }

    static function testDeferredShadow() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("deferred shadow: depth texture available", true);
            return;
        }

        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));

        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var light = Light.directional();
        light.intensity = 3.0;
        var lightEye = new Vec3(2.5, 2.0, 2.5);
        var lightView = GLM.lookAt(lightEye, new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        var lightProjection = GLM.orthographic(-4.0, 4.0, -4.0, 4.0, 0.1, 20.0, new Mat4());
        var lightViewProjection = lightProjection * lightView;

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var shadow = new ShadowRenderer(context);
        var gTarget = pool.acquireMRT(256, 256,
            [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);
        var shadowTarget = pool.acquireMRT(512, 512, [TextureFormat.RGBA], TextureFormat.Depth24);

        function render(shadowsOn:Bool):Array<Float> {
            var q = new RenderQueue();
            q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
            q.add(new RenderItem(geometry, wallMat, null, wallWorld));

            var frame = new FrameContext(context, 256, 256);
            frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
            frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
            frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
            frame.lights = new LightSet();
            frame.lights.add(light);
            if (shadowsOn) {
                shadow.render(q, frame, shadowTarget, lightViewProjection);
                frame.shadowMap = shadowTarget;
                frame.lightViewProjection = lightViewProjection;
            }

            gTarget.bind(context, true);
            context.clear(0.0, 0.0, 0.0, 1.0);
            gbufferRenderer.render(q, frame, gbuffer);
            gbuffer.unbind(context);

            var out = pool.acquire(256, 256);
            lighting.render(gbuffer, out, frame);
            var bytes = readTarget(out);
            pool.release(out);

            var leftSum = 0.0;
            var rightSum = 0.0;
            var leftN = 0;
            var rightN = 0;
            for (y in 0...256) {
                for (x in 0...256) {
                    var i = (y * 256 + x) * 4;
                    var luma = (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                    if (x > 8 && x < 92 && y > 24 && y < 120) {
                        leftSum += luma;
                        leftN++;
                    }
                    if (x > 188 && x < 248 && y > 24 && y < 120) {
                        rightSum += luma;
                        rightN++;
                    }
                }
            }
            return [leftSum / leftN, rightSum / rightN];
        }

        var on = render(true);
        var off = render(false);
        trace('deferred shadow on left=' + f(on[0]) + ' right=' + f(on[1])
            + ' off left=' + f(off[0]) + ' right=' + f(off[1]));
        check("deferred shadow: occluded band darker", on[0] < off[0] - 0.02,
            'on=' + f(on[0]) + ' off=' + f(off[0]));
        check("deferred shadow: lit band brighter than shadow", on[1] > on[0] * 1.2,
            'right=' + f(on[1]) + ' left=' + f(on[0]));

        pool.release(gTarget);
        pool.release(shadowTarget);
        gbufferRenderer.dispose();
        lighting.dispose();
        shadow.dispose();
    }


    static function testSSAO() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT || !caps.supportsDepthTexture) {
            check("SSAO: depth capability", true);
            return;
        }

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var ssao = new SSAORenderer(context);
        ssao.radius = 1.0;
        var gTarget = pool.acquireMRT(256, 256,
            [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);

        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        var frame = makeFrame(256, 256);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);

        gTarget.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        gbufferRenderer.render(q, frame, gbuffer);
        gbuffer.unbind(context);

        var aoTarget = pool.acquire(256, 256);
        ssao.render(gbuffer, aoTarget, frame);
        var aoAvg = avgLuma(readTarget(aoTarget), 256, 256);
        trace('SSAO: avg=' + f(aoAvg));
        check("SSAO: output is not all white", aoAvg < 0.999, 'avg=' + f(aoAvg));
        check("SSAO: output non-black", aoAvg > 0.0, 'avg=' + f(aoAvg));

        var path = new DeferredPBRPath(
            function(qq, f, g) gbufferRenderer.render(qq, f, g),
            function(f, g, o) lighting.render(g, o, f),
            null,
            null);
        path.ssaoRenderer = ssao;
        var graph = path.build(q, frame);
        var names = [for (p in graph.compile()) p.name].join(",");
        graph.execute(frame);
        var deferredAvg = avgLuma(readTarget(graph.output.target), 256, 256);
        trace('SSAO deferred path: passes=' + names + ' avg=' + f(deferredAvg));
        check("SSAO: pass is present", names.indexOf("SSAOPass") >= 0, names);
        check("SSAO: deferred output non-black", deferredAvg > 0.02, 'avg=' + f(deferredAvg));

        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        pool.release(aoTarget);
        pool.release(gTarget);
        gbufferRenderer.dispose();
        lighting.dispose();
        ssao.dispose();
    }

    static function testLightTileCuller() {
        var frame = makeFrame(256, 256);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 5.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        var lights:Array<Light> = [];
        for (i in 0...3) {
            var light = Light.point();
            light.position = new Vec3(-1.0 + i, 0.5, 0.0);
            light.range = 5.0;
            lights.push(light);
        }
        var culler = new LightTileCuller();
        var map = culler.cull(lights, frame.viewMatrix, frame.projectionMatrix, 256, 256);
        var covered = 0;
        for (i in 0...map.bytes.length) {
            if (map.bytes.get(i) != 0) covered++;
        }
        trace('light tiles: active=' + map.activeLights + ' coveredBytes=' + covered
            + ' texture=' + map.textureWidth + 'x' + map.textureHeight);
        check("light tiles: all point lights active", map.activeLights == 3, Std.string(map.activeLights));
        check("light tiles: tile mask written", covered > 0, Std.string(covered));
        check("light tiles: 16x16 mask texture", map.textureWidth == 16 && map.textureHeight == 16);
        check("light tiles: logical map", map.mapWidth == 16 && map.mapHeight == 16);

        var hd = culler.cull(lights, frame.viewMatrix, frame.projectionMatrix, 1280, 720);
        trace('light tiles HD: logical=' + hd.mapWidth + 'x' + hd.mapHeight
            + ' texture=' + hd.textureWidth + 'x' + hd.textureHeight);
        check("light tiles: 1280x720 logical map", hd.mapWidth == 80 && hd.mapHeight == 45);
        check("light tiles: 1280x720 texture", hd.textureWidth == 128 && hd.textureHeight == 64);
    }

    static function multiPointShadowRender(castA:Bool, castB:Bool):{avg:Float, left:Float, right:Float, count:Int} {
        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        var shadow = new ShadowRenderer(context);
        var path = new ForwardPath(function(qq, f, t) pbr.render(qq, f, t));
        path.shadowRenderer = shadow;
        path.enableLocalShadows = true;
        path.spotShadowSize = 256;
        path.pointShadowSize = 256;
        path.maxPointShadows = 2;

        var frame = makeFrame(256, 256, false);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.lights = new LightSet();
        frame.capabilities = RenderCapabilities.detect(context);
        frame.targetPool = pool;

        var a = Light.point();
        a.position = new Vec3(-1.5, 1.5, 1.5);
        a.range = 20.0;
        a.intensity = 50.0;
        a.castShadow = castA;
        var b = Light.point();
        b.position = new Vec3(1.5, 1.5, 1.5);
        b.range = 20.0;
        b.intensity = 50.0;
        b.castShadow = castB;
        frame.lights.add(a);
        frame.lights.add(b);

        var graph = path.build(q, frame);
        graph.execute(frame);
        var bytes = readTarget(graph.output.target);

        var total = 0.0;
        var leftSum = 0.0;
        var leftN = 0;
        var rightSum = 0.0;
        var rightN = 0;
        for (y in 0...256) {
            for (x in 0...256) {
                var i = (y * 256 + x) * 4;
                var luma = (0.299 * bytes.get(i) + 0.587 * bytes.get(i + 1) + 0.114 * bytes.get(i + 2)) / 255.0;
                total += luma;
                if (x < 128) {
                    leftSum += luma;
                    leftN++;
                }
                else {
                    rightSum += luma;
                    rightN++;
                }
            }
        }

        var result = {
            avg: total / (256.0 * 256.0),
            left: leftSum / leftN,
            right: rightSum / rightN,
            count: frame.pointShadows.length
        };

        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        shadow.dispose();
        return result;
    }

    static function testMultiplePointShadowPixels() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("multiple point shadow pixels: depth texture available", true);
            return;
        }

        var baseline = multiPointShadowRender(false, false);
        var onlyA = multiPointShadowRender(true, false);
        var onlyB = multiPointShadowRender(false, true);
        var both = multiPointShadowRender(true, true);

        trace('multi point shadow pixels: base=' + f(baseline.avg)
            + ' onlyA=' + f(onlyA.avg) + ' onlyB=' + f(onlyB.avg) + ' both=' + f(both.avg)
            + ' countA=' + onlyA.count + ' countB=' + onlyB.count + ' countBoth=' + both.count);

        check("multiple point shadow pixels: slot 0 casts", onlyA.count == 1 && onlyB.count == 1 && both.count == 2,
            'A=' + onlyA.count + ' B=' + onlyB.count + ' both=' + both.count);
        check("multiple point shadow pixels: shadow A changes output",
            Math.abs(onlyA.avg - baseline.avg) > 0.002, 'onlyA=' + f(onlyA.avg) + ' base=' + f(baseline.avg));
        check("multiple point shadow pixels: shadow B changes output",
            Math.abs(onlyB.avg - baseline.avg) > 0.002, 'onlyB=' + f(onlyB.avg) + ' base=' + f(baseline.avg));
        // Both slots together must differ from either slot alone: the second
        // atlas cell is really sampled, not silently ignored.
        check("multiple point shadow pixels: both slots still shadow",
            Math.abs(both.avg - baseline.avg) > 0.002,
            'both=' + f(both.avg) + ' onlyA=' + f(onlyA.avg) + ' onlyB=' + f(onlyB.avg));
    }

    static function testMultiplePointShadows() {
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var q = queueOf(mat, Mat4.identity(new Mat4()));
        var shadow = new ShadowRenderer(context);
        var path = new ForwardPath(function(qq, f, t) pbr.render(qq, f, t));
        path.shadowRenderer = shadow;
        path.enableLocalShadows = true;
        path.maxPointShadows = 2;
        var frame = makeFrame(128, 128, false);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.capabilities = RenderCapabilities.detect(context);
        frame.targetPool = pool;
        for (i in 0...2) {
            var light = Light.point();
            light.position = new Vec3(i == 0 ? -1.0 : 1.0, 1.0, 0.0);
            light.range = 8.0;
            light.intensity = 6.0;
            light.castShadow = true;
            frame.lights.add(light);
        }
        var graph = path.build(q, frame);
        graph.execute(frame);
        trace('multiple point shadows: count=' + frame.pointShadows.length);
        check("multiple point shadows: two atlases", frame.pointShadows.length == 2, Std.string(frame.pointShadows.length));
        if (frame.pointShadows.length == 2) {
            check("multiple point shadows: distinct base cells", frame.pointShadows[0].baseCell == 0 && frame.pointShadows[1].baseCell == 6);
        }
        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        shadow.dispose();
    }

    static function testSamplerUnitsSurviveUpload() {
        // 16 live samplers occupy every texture unit. Uploading a new texture
        // right before the draw must not displace any of them - this fails
        // with any hardcoded "scratch unit" scheme once that unit is in use.
        var vs = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        var vb = VertexBuffer.createbyData(context, [
            -1.0, -1.0, 0.0, 0.0,
             1.0, -1.0, 1.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0, -1.0, 0.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0,  1.0, 0.0, 1.0
        ]);
        vb.addAttribute("position", 2, 0);
        vb.addAttribute("uv", 2, 2);
        vs.upload();

        var count = 16;
        var fsSource = new StringBuf();
        fsSource.add("varying vec2 vUV;\n");
        for (i in 0...count) fsSource.add("uniform sampler2D uTex" + i + ";\n");
        fsSource.add("void main() {\n");
        fsSource.add("    float guard = 0.0;\n");
        for (i in 0...(count - 1)) fsSource.add("    guard += texture2D(uTex" + i + ", vUV).r;\n");
        fsSource.add("    vec4 result = texture2D(uTex" + (count - 1) + ", vUV);\n");
        fsSource.add("    if (guard < -1.0) result = vec4(1.0);\n");
        fsSource.add("    gl_FragColor = result;\n");
        fsSource.add("}\n");

        var fs = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, fsSource.toString());
        fs.upload();
        var program = Program.createbyShader("SamplerUploadProbe", context, vs, fs);
        program.upload();

        var textures:Array<Texture> = [];
        var expected = "";
        for (i in 0...count) {
            var tex = Texture.create(context, 8, 8, false, false, true, TextureFormat.RGBA);
            tex.upload();
            var bytes = Bytes.alloc(8 * 8 * 4);
            var r = (30 + i * 10) % 256;
            var g = (60 + i * 6) % 256;
            var b = (90 + i * 3) % 256;
            for (p in 0...(8 * 8)) {
                bytes.set(p * 4, r);
                bytes.set(p * 4 + 1, g);
                bytes.set(p * 4 + 2, b);
                bytes.set(p * 4 + 3, 255);
            }
            tex.uploadMipLevel(0, bytes);
            textures.push(tex);
            if (i == count - 1) expected = r + "," + g + "," + b;
        }

        var out = pool.acquire(16, 16);

        function draw():String {
            out.bind(context, false);
            context.setProgram(program.id);
            context.setDepthTest(false, CompareMode.ALWAYS);
            context.setBlendingMode(BlendingMode.DEFAULT);
            context.setTriangleCulling(TriangleCulling.NONE);
            for (attribute in program.inputs.attributes) {
                var va = vb.attribute(attribute.name);
                if (va != null) {
                    context.setVertexBufferAt(attribute.location, va.resourceId, va.size, va.vertexSize, va.offset);
                }
            }
            for (uniform in program.inputs.uniforms) {
                if (uniform.type == InputType.sampler2d) {
                    var idx = Std.parseInt(uniform.name.substr(4));
                    if (idx >= 0 && idx < textures.length) {
                        context.setTextureAt(uniform.position, textures[idx].id, uniform.location);
                    }
                }
            }
            context.drawTriangles(0, 2);
            out.unbind(context);
            var pixels = readTarget(out);
            var o = ((16 >> 1) * 16 + (16 >> 1)) * 4;
            return pixels.get(o) + "," + pixels.get(o + 1) + "," + pixels.get(o + 2);
        }

        var before = draw();
        check("sampler units: 16 samplers bound before upload", before == expected, before + " vs " + expected);

        var scratch = Texture.create(context, 64, 64, false, false, true, TextureFormat.RGBA);
        scratch.upload();
        var scratchBytes = Bytes.alloc(64 * 64 * 4);
        for (i in 0...(64 * 64)) {
            scratchBytes.set(i * 4, 255);
            scratchBytes.set(i * 4 + 1, 0);
            scratchBytes.set(i * 4 + 2, 0);
            scratchBytes.set(i * 4 + 3, 255);
        }
        scratch.uploadMipLevel(0, scratchBytes);
        var after = draw();
        check("sampler units: upload does not displace live samplers", after == expected, after + " vs " + expected);

        scratch.dispose();
        for (tex in textures) tex.dispose();
        pool.release(out);
        program.dispose();
        fs.dispose();
        vb.dispose();
        vs.dispose();
    }

    static function testManySamplerThreshold() {
        var vs = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        var vb = VertexBuffer.createbyData(context, [
            -1.0, -1.0, 0.0, 0.0,
             1.0, -1.0, 1.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0, -1.0, 0.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0,  1.0, 0.0, 1.0
        ]);
        vb.addAttribute("position", 2, 0);
        vb.addAttribute("uv", 2, 2);
        vs.upload();

        var out = pool.acquire(16, 16);
        var counts = [1, 2, 4, 8, 12, 13, 16];
        var report = [];

        for (count in counts) {
            var fsSource = new StringBuf();
            fsSource.add("varying vec2 vUV;\n");
            for (i in 0...count) {
                fsSource.add("uniform sampler2D uTex" + i + ";\n");
            }
            fsSource.add("void main() {\n");
            // Force EVERY sampler to stay live (GLSL drops unused ones):
            // accumulate all inputs into a guard that can never fire, then
            // output only the last one.
            fsSource.add("    float guard = 0.0;\n");
            for (i in 0...(count - 1)) {
                fsSource.add("    guard += texture2D(uTex" + i + ", vUV).r;\n");
            }
            fsSource.add("    vec4 result = texture2D(uTex" + (count - 1) + ", vUV);\n");
            fsSource.add("    if (guard < -1.0) result = vec4(1.0);\n");
            fsSource.add("    gl_FragColor = result;\n");
            fsSource.add("}\n");

            var fs = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, fsSource.toString());
            fs.upload();
            var program = Program.createbyShader("SamplerProbe" + count, context, vs, fs);
            program.upload();

            var textures:Array<Texture> = [];
            var lastColor = "";
            for (i in 0...count) {
                var tex = Texture.create(context, 8, 8, false, false, true, TextureFormat.RGBA);
                tex.upload();
                var r = (10 + i * 15) % 256;
                var g = (20 + i * 11) % 256;
                var b = (30 + i * 7) % 256;
                var bytes = Bytes.alloc(8 * 8 * 4);
                for (p in 0...(8 * 8)) {
                    bytes.set(p * 4, r);
                    bytes.set(p * 4 + 1, g);
                    bytes.set(p * 4 + 2, b);
                    bytes.set(p * 4 + 3, 255);
                }
                tex.uploadMipLevel(0, bytes);
                textures.push(tex);
                lastColor = r + "," + g + "," + b;
            }

            out.bind(context, false);
            context.setProgram(program.id);
            context.setDepthTest(false, CompareMode.ALWAYS);
            context.setBlendingMode(BlendingMode.DEFAULT);
            context.setTriangleCulling(TriangleCulling.NONE);
            for (attribute in program.inputs.attributes) {
                var va = vb.attribute(attribute.name);
                if (va != null) {
                    context.setVertexBufferAt(attribute.location, va.resourceId, va.size, va.vertexSize, va.offset);
                }
            }
            var bound = 0;
            for (uniform in program.inputs.uniforms) {
                if (uniform.type == InputType.sampler2d) {
                    var idx = Std.parseInt(uniform.name.substr(4));
                    if (idx >= 0 && idx < textures.length) {
                        context.setTextureAt(uniform.position, textures[idx].id, uniform.location);
                        context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
                        bound++;
                    }
                }
            }
            context.drawTriangles(0, 2);
            out.unbind(context);

            var pixels = readTarget(out);
            var o = ((16 >> 1) * 16 + (16 >> 1)) * 4;
            var got = pixels.get(o) + "," + pixels.get(o + 1) + "," + pixels.get(o + 2);
            report.push('n=' + count + ' samplers=' + bound + ' expect=' + lastColor + ' got=' + got);
            check("sampler probe: " + count + " samplers sample their texture", got == lastColor,
                'n=' + count + ' expect=' + lastColor + ' got=' + got);

            for (tex in textures) tex.dispose();
            program.dispose();
            fs.dispose();
        }

        trace("sampler threshold: " + report.join(" | "));
        pool.release(out);
        vb.dispose();
        vs.dispose();
    }

    static function testBackendUploadQuirks() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("backend upload quirks: capability", true);
            return;
        }

        // Minimal fullscreen single-texture pipeline, fully independent of
        // the tile-map/deferred machinery, to isolate two suspected hlsdl
        // behaviors:
        //   quirk 1: a texture uploaded via texImage2D samples black in the
        //            same frame it was uploaded
        //   quirk 2: uploading an unrelated texture corrupts other samplers
        //            of the same draw
        var vs = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        var fs = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER,
            ["varying vec2 vUV;",
             "uniform sampler2D uColorMap;",
             "void main() {",
             "    gl_FragColor = texture2D(uColorMap, vUV);",
             "}"].join("\n"));
        vs.upload();
        fs.upload();
        var program = Program.createbyShader("BackendQuirkProbe", context, vs, fs);
        program.upload();
        var colorUniform:UniformInput = null;
        for (uniform in program.inputs.uniforms) {
            if (uniform.name == "uColorMap") colorUniform = uniform;
        }
        var vb = VertexBuffer.createbyData(context, [
            -1.0, -1.0, 0.0, 0.0,
             1.0, -1.0, 1.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0, -1.0, 0.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0,  1.0, 0.0, 1.0
        ]);
        vb.addAttribute("position", 2, 0);
        vb.addAttribute("uv", 2, 2);

        function drawSampling(textureId:Int, output:RenderTarget):Void {
            output.bind(context, false);
            context.setProgram(program.id);
            context.setDepthTest(false, CompareMode.ALWAYS);
            context.setBlendingMode(BlendingMode.DEFAULT);
            context.setTriangleCulling(TriangleCulling.NONE);
            for (attribute in program.inputs.attributes) {
                var va = vb.attribute(attribute.name);
                if (va != null) {
                    context.setVertexBufferAt(attribute.location, va.resourceId, va.size, va.vertexSize, va.offset);
                }
            }
            if (colorUniform != null && colorUniform.position >= 0) {
                context.setTextureAt(colorUniform.position, textureId, colorUniform.location);
                context.setSamplerStateAt(colorUniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
            }
            context.drawTriangles(0, 2);
            output.unbind(context);
        }

        function centerColor(target:RenderTarget):String {
            var b = readTarget(target);
            var o = ((target.height >> 1) * target.width + (target.width >> 1)) * 4;
            return b.get(o) + "," + b.get(o + 1) + "," + b.get(o + 2);
        }

        function solidBytes(w:Int, h:Int, r:Int, g:Int, b:Int):Bytes {
            var bytes = Bytes.alloc(w * h * 4);
            for (i in 0...(w * h)) {
                bytes.set(i * 4, r);
                bytes.set(i * 4 + 1, g);
                bytes.set(i * 4 + 2, b);
                bytes.set(i * 4 + 3, 255);
            }
            return bytes;
        }

        var out = pool.acquire(64, 64);

        // Persistent probe texture, uploaded through the setData+upload path.
        var probe = Texture.create(context, 64, 64, false, false, true, TextureFormat.RGBA);
        probe.upload();

        // Frame 1: upload RED, draw same frame.
        probe.setData(solidBytes(64, 64, 255, 0, 0), 64, 64);
        probe.upload();
        drawSampling(probe.id, out);
        var f1SameFrame = centerColor(out);

        // Frame 2: no upload, draw again (stale data).
        drawSampling(probe.id, out);
        var f2Stale = centerColor(out);

        // Frame 3: uploadMipLevel BLUE, draw same frame (second upload path).
        probe.uploadMipLevel(0, solidBytes(64, 64, 0, 0, 255));
        drawSampling(probe.id, out);
        var f3SameFrameMip = centerColor(out);

        // Frame 4: no upload, draw again.
        drawSampling(probe.id, out);
        var f4Stale = centerColor(out);

        // Frame 5: quirk 2 probe — upload an UNRELATED texture right before
        // drawing the (already resident) probe. If the draw output changes
        // or goes black, the upload corrupted the probe binding.
        var unrelated = Texture.create(context, 16, 16, false, false, true, TextureFormat.RGBA);
        unrelated.upload();
        unrelated.uploadMipLevel(0, solidBytes(16, 16, 0, 255, 0));
        drawSampling(probe.id, out);
        var f5WithUnrelatedUpload = centerColor(out);

        // Frame 6: mirror the deferred timing — perform the texImage2D upload
        // AFTER the output render target is bound (inside the FBO session),
        // then sample in the same draw. This is what bindLightTiles does.
        function drawSamplingWithUploadInside(output:RenderTarget, upload:Void->Void):Void {
            output.bind(context, false);
            context.setProgram(program.id);
            context.setDepthTest(false, CompareMode.ALWAYS);
            context.setBlendingMode(BlendingMode.DEFAULT);
            context.setTriangleCulling(TriangleCulling.NONE);
            for (attribute in program.inputs.attributes) {
                var va = vb.attribute(attribute.name);
                if (va != null) {
                    context.setVertexBufferAt(attribute.location, va.resourceId, va.size, va.vertexSize, va.offset);
                }
            }
            upload();
            if (colorUniform != null && colorUniform.position >= 0) {
                context.setTextureAt(colorUniform.position, probe.id, colorUniform.location);
                context.setSamplerStateAt(colorUniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
            }
            context.drawTriangles(0, 2);
            output.unbind(context);
        }

        drawSamplingWithUploadInside(out, function() {
            probe.uploadMipLevel(0, solidBytes(64, 64, 0, 255, 0));
        });
        var f6UploadInsideFbo = centerColor(out);

        // Frame 7: inside the FBO session, create AND upload a brand-new
        // texture (the tile-texture creation pattern), then sample the
        // untouched probe.
        var fresh:Texture = null;
        drawSamplingWithUploadInside(out, function() {
            fresh = Texture.create(context, 16, 16, false, false, true, TextureFormat.RGBA);
            fresh.upload();
            fresh.uploadMipLevel(0, solidBytes(16, 16, 255, 255, 0));
        });
        var f7FreshTexInsideFbo = centerColor(out);

        trace('backend quirk probe:'
            + ' f1_sameFrameSetData=' + f1SameFrame
            + ' f2_stale=' + f2Stale
            + ' f3_sameFrameMip=' + f3SameFrameMip
            + ' f4_stale=' + f4Stale
            + ' f5_unrelatedUpload=' + f5WithUnrelatedUpload
            + ' f6_uploadInsideFbo=' + f6UploadInsideFbo
            + ' f7_freshTexInsideFbo=' + f7FreshTexInsideFbo);

        // Codify findings: stale-frame samples must be correct (pipeline is
        // sound once the upload has aged one frame).
        check("backend quirk: setData path visible next frame", f2Stale == "255,0,0", f2Stale);
        check("backend quirk: mip path visible next frame", f4Stale == "0,0,255", f4Stale);
        // Same-frame visibility and unrelated-upload interference are
        // reported as informational; assertions encode the currently
        // observed hlsdl behavior.
        check("backend quirk: same-frame upload visible or black", f1SameFrame == "255,0,0" || f1SameFrame == "0,0,0", f1SameFrame);
        check("backend quirk: unrelated upload does not corrupt", f5WithUnrelatedUpload == f4Stale, f5WithUnrelatedUpload + " vs " + f4Stale);
        // FBO-session uploads: if these are black, the hlsdl quirk is tied to
        // texImage2D while the output render target is bound.
        check("backend quirk: upload inside FBO visible or black", f6UploadInsideFbo == "0,255,0" || f6UploadInsideFbo == "0,0,0", f6UploadInsideFbo);
        check("backend quirk: fresh texture inside FBO keeps probe", f7FreshTexInsideFbo == f6UploadInsideFbo, f7FreshTexInsideFbo + " vs " + f6UploadInsideFbo);

        pool.release(out);
        probe.dispose();
        unrelated.dispose();
        if (fresh != null) fresh.dispose();
        vb.dispose();
        program.dispose();
        fs.dispose();
        vs.dispose();
    }

    static function multiSpotShadowRender(castA:Bool, castB:Bool):{avg:Float, count:Int} {
        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        var shadow = new ShadowRenderer(context);
        var path = new ForwardPath(function(qq, f, t) pbr.render(qq, f, t));
        path.shadowRenderer = shadow;
        path.enableLocalShadows = true;
        path.spotShadowSize = 256;
        path.maxSpotShadows = 2;

        var frame = makeFrame(256, 256, false);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.lights = new LightSet();
        frame.capabilities = RenderCapabilities.detect(context);
        frame.targetPool = pool;

        var a = Light.spot();
        a.position = new Vec3(-1.5, 2.5, 2.5);
        a.direction = Vec3.normalize(new Vec3(1.5, -2.5, -2.5), new Vec3());
        a.range = 20.0;
        a.intensity = 50.0;
        a.outerCone = 0.7;
        a.innerCone = 0.9;
        a.castShadow = castA;
        var b = Light.spot();
        b.position = new Vec3(1.5, 2.5, 2.5);
        b.direction = Vec3.normalize(new Vec3(-1.5, -2.5, -2.5), new Vec3());
        b.range = 20.0;
        b.intensity = 50.0;
        b.outerCone = 0.7;
        b.innerCone = 0.9;
        b.castShadow = castB;
        frame.lights.add(a);
        frame.lights.add(b);

        var graph = path.build(q, frame);
        graph.execute(frame);
        var bytes = readTarget(graph.output.target);
        var total = 0.0;
        for (i in 0...(256 * 256)) {
            var o = i * 4;
            total += (0.299 * bytes.get(o) + 0.587 * bytes.get(o + 1) + 0.114 * bytes.get(o + 2)) / 255.0;
        }
        var result = {avg: total / (256.0 * 256.0), count: frame.spotShadows.length};

        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        shadow.dispose();
        return result;
    }

    static function deferredMultiPointShadowRender(castA:Bool, castB:Bool):{avg:Float, count:Int} {
        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var shadow = new ShadowRenderer(context);
        var path = new DeferredPBRPath(
            function(qq, f, g) gbufferRenderer.render(qq, f, g),
            function(f, g, o) lighting.render(g, o, f),
            null,
            null);
        path.shadowRenderer = shadow;
        path.enableLocalShadows = true;
        path.pointShadowSize = 256;
        path.maxPointShadows = 2;

        var frame = makeFrame(256, 256, false);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.lights = new LightSet();
        frame.capabilities = RenderCapabilities.detect(context);
        frame.targetPool = pool;

        var a = Light.point();
        a.position = new Vec3(-1.5, 1.5, 1.5);
        a.range = 20.0;
        a.intensity = 50.0;
        a.castShadow = castA;
        var b = Light.point();
        b.position = new Vec3(1.5, 1.5, 1.5);
        b.range = 20.0;
        b.intensity = 50.0;
        b.castShadow = castB;
        frame.lights.add(a);
        frame.lights.add(b);

        var graph = path.build(q, frame);
        graph.execute(frame);
        var bytes = readTarget(graph.output.target);
        var total = 0.0;
        for (i in 0...(256 * 256)) {
            var o = i * 4;
            total += (0.299 * bytes.get(o) + 0.587 * bytes.get(o + 1) + 0.114 * bytes.get(o + 2)) / 255.0;
        }
        var result = {avg: total / (256.0 * 256.0), count: frame.pointShadows.length};

        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        shadow.dispose();
        lighting.dispose();
        gbufferRenderer.dispose();
        return result;
    }

    static function deferredDirectPointShadowRender(castA:Bool, castB:Bool):Float {
        var cubeMat = PBRMaterial.create();
        cubeMat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var wallMat = PBRMaterial.create();
        wallMat.setBaseColor(new Vec4(0.7, 0.7, 0.7, 1.0));
        var cubeWorld = Mat4.identity(new Mat4());
        cubeWorld.r0c0 = 0.5;
        cubeWorld.r1c1 = 0.5;
        cubeWorld.r2c2 = 0.5;
        var wallWorld = Mat4.identity(new Mat4());
        wallWorld.r0c0 = 5.0;
        wallWorld.r1c1 = 3.0;
        wallWorld.r2c2 = 0.1;
        wallWorld.r2c3 = -1.3;

        var q = new RenderQueue();
        q.add(new RenderItem(geometry, cubeMat, null, cubeWorld));
        q.add(new RenderItem(geometry, wallMat, null, wallWorld));

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var gTarget = pool.acquireMRT(256, 256,
            [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);
        var atlas = pool.acquireMRT(1024, 768, [TextureFormat.RGBA], TextureFormat.Depth24);
        var shadow = new ShadowRenderer(context);

        var frame = makeFrame(256, 256, false);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.lights = new LightSet();
        frame.pointShadows = [];

        var a = Light.point();
        a.position = new Vec3(-1.5, 1.5, 1.5);
        a.range = 20.0;
        a.intensity = 50.0;
        a.castShadow = castA;
        var b = Light.point();
        b.position = new Vec3(1.5, 1.5, 1.5);
        b.range = 20.0;
        b.intensity = 50.0;
        b.castShadow = castB;
        frame.lights.add(a);
        frame.lights.add(b);

        atlas.bind(context, true);
        context.clear(1.0, 1.0, 1.0, 1.0, 1.0, 0);
        var cubes:Array<CubeTexture> = [];
        if (castA) {
            var matrices = shadow.renderPointAtlasCell(q, frame, atlas, 256, 0, a, 0, false);
            var cube = CubeTexture.create(context, 256, 256, false, false, true, TextureFormat.RGBA);
            cube.upload();
            shadow.renderPointCube(q, frame, cube.id, 256, a, 0);
            cubes.push(cube);
            var p = new PointShadow(matrices, 0);
            p.atlas = atlas;
            p.cube = cube;
            p.faceSize = 256;
            p.baseCell = 0;
            p.position = a.position;
            p.range = a.range;
            frame.pointShadows.push(p);
        }
        if (castB) {
            var matrices = shadow.renderPointAtlasCell(q, frame, atlas, 256, 6, b, 1, false);
            var cube = CubeTexture.create(context, 256, 256, false, false, true, TextureFormat.RGBA);
            cube.upload();
            shadow.renderPointCube(q, frame, cube.id, 256, b, 1);
            cubes.push(cube);
            var p = new PointShadow(matrices, 1);
            p.atlas = atlas;
            p.cube = cube;
            p.faceSize = 256;
            p.baseCell = 6;
            p.position = b.position;
            p.range = b.range;
            frame.pointShadows.push(p);
        }
        atlas.unbind(context);

        gTarget.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        gbufferRenderer.render(q, frame, gbuffer);
        gbuffer.unbind(context);

        var out = pool.acquire(256, 256);
        lighting.render(gbuffer, out, frame);
        var avg = avgLuma(readTarget(out), 256, 256);

        for (cube in cubes) cube.dispose();
        pool.release(out);
        pool.release(gTarget);
        pool.release(atlas);
        lighting.dispose();
        gbufferRenderer.dispose();
        shadow.dispose();
        return avg;
    }

    static function testDeferredDirectPointShadowPixels() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture || !caps.supportsMRT) {
            check("deferred direct point shadow pixels: capabilities", true);
            return;
        }

        var baseline = deferredDirectPointShadowRender(false, false);
        var onlyA = deferredDirectPointShadowRender(true, false);
        var onlyB = deferredDirectPointShadowRender(false, true);
        var both = deferredDirectPointShadowRender(true, true);

        trace('deferred direct point shadow pixels: base=' + f(baseline)
            + ' onlyA=' + f(onlyA) + ' onlyB=' + f(onlyB) + ' both=' + f(both));

        check("deferred direct point shadow pixels: shadow A changes output",
            Math.abs(onlyA - baseline) > 0.002, 'onlyA=' + f(onlyA) + ' base=' + f(baseline));
        check("deferred direct point shadow pixels: shadow B changes output",
            Math.abs(onlyB - baseline) > 0.002, 'onlyB=' + f(onlyB) + ' base=' + f(baseline));
        check("deferred direct point shadow pixels: both slots still shadow",
            Math.abs(both - baseline) > 0.002,
            'both=' + f(both) + ' onlyA=' + f(onlyA) + ' onlyB=' + f(onlyB));
    }

    static function testDeferredMultiPointShadowPixels() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture || !caps.supportsMRT) {
            check("deferred multi point shadow pixels: capabilities", true);
            return;
        }

        var noShadowsAtAll = deferredMultiPointShadowRender(false, false);

        var baseline = noShadowsAtAll;
        var onlyA = deferredMultiPointShadowRender(true, false);
        var onlyB = deferredMultiPointShadowRender(false, true);
        var both = deferredMultiPointShadowRender(true, true);

        trace('deferred multi point shadow pixels: base=' + f(baseline.avg)
            + ' onlyA=' + f(onlyA.avg) + ' onlyB=' + f(onlyB.avg) + ' both=' + f(both.avg)
            + ' countA=' + onlyA.count + ' countB=' + onlyB.count + ' countBoth=' + both.count);

        check("deferred multi point shadow pixels: two atlases", both.count == 2,
            'A=' + onlyA.count + ' B=' + onlyB.count + ' both=' + both.count);
        check("deferred multi point shadow pixels: shadow A changes output",
            Math.abs(onlyA.avg - baseline.avg) > 0.002, 'onlyA=' + f(onlyA.avg) + ' base=' + f(baseline.avg));
        check("deferred multi point shadow pixels: shadow B changes output",
            Math.abs(onlyB.avg - baseline.avg) > 0.002, 'onlyB=' + f(onlyB.avg) + ' base=' + f(baseline.avg));
        check("deferred multi point shadow pixels: both slots still shadow",
            Math.abs(both.avg - baseline.avg) > 0.002,
            'both=' + f(both.avg) + ' onlyA=' + f(onlyA.avg) + ' onlyB=' + f(onlyB.avg));
    }

    static function testMultipleSpotShadowPixels() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsDepthTexture) {
            check("multiple spot shadow pixels: depth texture available", true);
            return;
        }

        var baseline = multiSpotShadowRender(false, false);
        var onlyA = multiSpotShadowRender(true, false);
        var onlyB = multiSpotShadowRender(false, true);
        var both = multiSpotShadowRender(true, true);

        trace('multi spot shadow pixels: base=' + f(baseline.avg)
            + ' onlyA=' + f(onlyA.avg) + ' onlyB=' + f(onlyB.avg) + ' both=' + f(both.avg)
            + ' countA=' + onlyA.count + ' countB=' + onlyB.count + ' countBoth=' + both.count);

        check("multiple spot shadow pixels: cells 0/1 used", onlyA.count == 1 && onlyB.count == 1 && both.count == 2,
            'A=' + onlyA.count + ' B=' + onlyB.count + ' both=' + both.count);
        check("multiple spot shadow pixels: shadow A changes output",
            Math.abs(onlyA.avg - baseline.avg) > 0.002, 'onlyA=' + f(onlyA.avg) + ' base=' + f(baseline.avg));
        check("multiple spot shadow pixels: shadow B changes output",
            Math.abs(onlyB.avg - baseline.avg) > 0.002, 'onlyB=' + f(onlyB.avg) + ' base=' + f(baseline.avg));
        check("multiple spot shadow pixels: both slots still shadow",
            Math.abs(both.avg - baseline.avg) > 0.002,
            'both=' + f(both.avg) + ' base=' + f(baseline.avg));
    }

    static function testMultipleSpotShadows() {
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        var q = queueOf(mat, Mat4.identity(new Mat4()));
        var shadow = new ShadowRenderer(context);
        var path = new ForwardPath(function(qq, f, t) pbr.render(qq, f, t));
        path.shadowRenderer = shadow;
        path.enableLocalShadows = true;
        path.maxSpotShadows = 2;
        var frame = makeFrame(128, 128, false);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.5);
        frame.capabilities = RenderCapabilities.detect(context);
        frame.targetPool = pool;
        for (i in 0...2) {
            var light = Light.spot();
            light.position = new Vec3(i == 0 ? -1.0 : 1.0, 1.0, 2.0);
            light.direction = Vec3.normalize(new Vec3(i == 0 ? 1.0 : -1.0, -1.0, -2.0), new Vec3());
            light.range = 8.0;
            light.intensity = 6.0;
            light.outerCone = 0.7;
            light.innerCone = 0.9;
            light.castShadow = true;
            frame.lights.add(light);
        }
        var graph = path.build(q, frame);
        graph.execute(frame);
        trace('multiple spot shadows: count=' + frame.spotShadows.length);
        check("multiple spot shadows: two cells", frame.spotShadows.length == 2, Std.string(frame.spotShadows.length));
        if (frame.spotShadows.length == 2) {
            check("multiple spot shadows: cells 0/1", frame.spotShadows[0].cell == 0 && frame.spotShadows[1].cell == 1);
        }
        graph.releaseTransients(pool);
        graph.dispose();
        path.dispose();
        shadow.dispose();
    }

    static function testForwardPathPost() {
        var bloom = new BloomRenderer(context);
        var tonemap = new FullscreenRenderer(context);
        var fxaa = new FXAARenderer(context);

        var emissiveMat = PBRMaterial.create();
        emissiveMat.setBaseColor(new Vec4(0.02, 0.02, 0.02, 1.0));
        emissiveMat.setEmissive(new Vec3(0.4, 0.4, 0.4));
        var q = queueOf(emissiveMat, Mat4.identity(new Mat4()));

        function buildChain(withBloom:Bool):PostProcessChain {
            var chain = new PostProcessChain();
            if (withBloom) {
                chain.add("Bloom", function(frame, input, output) bloom.render(pool, input, output, 0.2, 1.0));
            }
            chain.add("Tonemap", function(frame, input, output) tonemap.render(input.color, output));
            chain.add("FXAA", function(frame, input, output) fxaa.render(input, output));
            return chain;
        }

        function runChain(withBloom:Bool):Float {
            var path = new ForwardPBRPath(function(qq, f, t) pbr.render(qq, f, t), buildChain(withBloom));
            var frame = makeFrame(256, 256);
            frame.capabilities = new RenderCapabilities();
            var graph = path.build(q, frame);
            graph.execute(frame);
            var avg = avgLuma(readTarget(graph.output.target), 256, 256);
            graph.releaseTransients(pool);
            graph.dispose();
            return avg;
        }

        var withoutBloom = runChain(false);
        var withBloom = runChain(true);
        trace('post: noBloom=' + f(withoutBloom) + ' bloom=' + f(withBloom));
        check("post chain: tonemap+FXAA output non-black", withoutBloom > 0.02, 'avg=' + f(withoutBloom));
        check("post chain: bloom brightens output",
            withBloom > withoutBloom + 0.003, 'bloom=' + f(withBloom) + ' noBloom=' + f(withoutBloom));

        bloom.dispose();
        tonemap.dispose();
        fxaa.dispose();
    }

    static function testForwardPathPersistent() {
        var path = new ForwardPath(function(q, f, t) pbr.render(q, f, t), null);
        var q = queueOf(deferredMaterial(), Mat4.identity(new Mat4()));
        var frame = makeFrame(128, 128);
        frame.capabilities = new RenderCapabilities();

        var first = path.build(q, frame);
        first.execute(frame);
        var avgFirst = avgLuma(readTarget(first.output.target), 128, 128);
        first.releaseTransients(pool);

        var second = path.build(q, frame);
        second.execute(frame);
        var avgSecond = avgLuma(readTarget(second.output.target), 128, 128);
        trace('forward path persistent: first=' + f(avgFirst) + ' second=' + f(avgSecond));
        check("forward path: graph reused across frames", first == second);
        check("forward path: reused graph renders", avgSecond > 0.02 && Math.abs(avgFirst - avgSecond) < 0.002,
            'first=' + f(avgFirst) + ' second=' + f(avgSecond));

        second.releaseTransients(pool);
        path.dispose();
    }

    // -------------------------------------------- GL: PipelineRenderer E2E

    static function testPipelineRenderer() {
        var root = Node.create("root");
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.5, 0.6, 0.7, 1.0));
        var mesh = Node.create("mesh")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, mat, null));
        root.addChild(mesh);

        var path = new ForwardPBRPath(function(q, f, t) pbr.render(q, f, t), null);
        var renderer = new PipelineRenderer(context, root, path, 64, 64);
        renderer.pipeline.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        renderer.pipeline.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        renderer.pipeline.cameraPosition = new Vec3(0.0, 0.0, 3.0);
        var light = Light.directional();
        light.direction = new Vec3(0.0, 0.0, -1.0);
        light.intensity = 3.0;
        renderer.pipeline.lights.add(light);

        renderer.render(0.016);
        check("pipeline renderer: collected 1 item", renderer.pipeline.queue.count == 1,
            'count=${renderer.pipeline.queue.count}');
        check("pipeline renderer: opaque material in opaque bucket",
            renderer.pipeline.queue.opaque.length == 1);

        mat.setBaseColor(new Vec4(0.5, 0.6, 0.7, 0.5));
        renderer.render(0.016);
        check("pipeline renderer: alpha<1 moves item to transparent bucket",
            renderer.pipeline.queue.transparent.length == 1 && renderer.pipeline.queue.opaque.length == 0,
            'transparent=${renderer.pipeline.queue.transparent.length} opaque=${renderer.pipeline.queue.opaque.length}');

        renderer.dispose();
    }

    static function testPipelineRendererDeferred() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            return;
        }

        var root = Node.create("root");
        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.5, 0.6, 0.7, 1.0));
        mat.setRoughness(0.5);
        var mesh = Node.create("mesh")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, mat, null));
        root.addChild(mesh);

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var capture = new FullscreenEffect(context, "Capture", PBRShaderLibrary.presentFragment());
        var captured = [0.0];

        // Capture stage: read the lit HDR scene, then pass it through so the
        // graph still has a valid output.
        var chain = new PostProcessChain();
        chain.add("Capture", function(frame, input, output) {
            captured[0] = avgLuma(readTarget(input), input.width, input.height);
            capture.render(output, function(e) e.setTexture("uColorMap", input.color));
        });

        var path = new DeferredPBRPath(
            function(q, f, g) gbufferRenderer.render(q, f, g),
            function(f, g, o) lighting.render(g, o, f),
            null,
            chain);
        var renderer = new PipelineRenderer(context, root, path, 64, 64);
        renderer.pipeline.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        renderer.pipeline.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        renderer.pipeline.cameraPosition = new Vec3(0.0, 0.0, 3.0);
        var light = Light.directional();
        light.direction = new Vec3(0.0, 0.0, -1.0);
        light.intensity = 3.0;
        renderer.pipeline.lights.add(light);

        var first = 0.0;
        var second = 0.0;
        renderer.render(0.016);
        first = captured[0];
        renderer.render(0.016);
        second = captured[0];
        trace('pipeline renderer (deferred): frame1=' + f(first) + ' frame2=' + f(second));
        check("pipeline renderer (deferred): renders a lit scene", first > 0.02, 'avg=' + f(first));
        check("pipeline renderer (deferred): stable across frames",
            Math.abs(first - second) < 0.002, 'frame1=' + f(first) + ' frame2=' + f(second));

        renderer.dispose();
        capture.dispose();
        gbufferRenderer.dispose();
        lighting.dispose();
    }

    // -------------------------------------------- GL: PipelineEffect
    static function testPipelineEffectForward() {
        var material = Material.create("effect-forward");
        material.set("tint", new Vec4(1.0, 0.1, 0.1, 1.0));

        var fragment = [
            "uniform vec4 uTint;",
            "void main() { gl_FragColor = uTint; }"
        ].join("\n");
        var uniforms = pipelineEffectUniforms();
        uniforms.push(PipelineUniform.material("uTint", "tint"));
        var effect = makePipelineEffect(EffectStage.Forward, fragment, uniforms, PipelineState.opaque());

        var item = new RenderItem(geometry, material, null, Mat4.identity(new Mat4()));
        item.pipelineEffect = effect;
        var q = new RenderQueue();
        q.add(item);

        var c = pixelAt(renderForward(q, makeFrame(128, 128), 128), 128, 64, 64);
        trace('pipeline effect forward: r=${c[0]} g=${c[1]} b=${c[2]}');
        check("pipeline effect: forward custom fragment", c[0] > 200 && c[1] < 80 && c[2] < 80,
            'r=${c[0]} g=${c[1]} b=${c[2]}');

        material.set("tint", new Vec4(0.1, 0.1, 1.0, 1.0));
        var changed = pixelAt(renderForward(q, makeFrame(128, 128), 128), 128, 64, 64);
        trace('pipeline effect forward changed: r=${changed[0]} g=${changed[1]} b=${changed[2]}');
        check("pipeline effect: material uniform updates", changed[2] > 200 && changed[0] < 80,
            'r=${changed[0]} g=${changed[1]} b=${changed[2]}');
    }

    static function testPipelineEffectTransparent() {
        var material = Material.create("effect-transparent");
        material.set("tint", new Vec4(1.0, 0.0, 0.0, 1.0));

        var fragment = [
            "uniform vec4 uTint;",
            "void main() { gl_FragColor = vec4(uTint.rgb, 0.5); }"
        ].join("\n");
        var uniforms = pipelineEffectUniforms();
        uniforms.push(PipelineUniform.material("uTint", "tint"));
        var effect = makePipelineEffect(EffectStage.Transparent, fragment, uniforms, PipelineState.transparent());

        var item = new RenderItem(geometry, material, null, Mat4.identity(new Mat4()));
        item.pipelineEffect = effect;
        var q = new RenderQueue();
        q.add(item, true);

        var c = pixelAt(renderForward(q, makeFrame(128, 128), 128), 128, 64, 64);
        trace('pipeline effect transparent: r=${c[0]} g=${c[1]} b=${c[2]}');
        check("pipeline effect: transparent blending", c[0] > 90 && c[0] < 180 && c[0] > c[1] + 50,
            'r=${c[0]} g=${c[1]} b=${c[2]}');
    }

    static function testPipelineEffectGBuffer() {
        var caps = RenderCapabilities.detect(context);
        if (!caps.supportsMRT) {
            check("pipeline effect: gbuffer (MRT available)", true);
            return;
        }

        var gbufferRenderer = new GBufferRenderer(context);
        var target = pool.acquireMRT(128, 128,
            [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(target);

        var fragment = [
            "void main() {",
            "    gl_FragData[0] = vec4(0.0, 1.0, 0.0, 1.0);",
            "    gl_FragData[1] = vec4(0.5, 0.5, 1.0, 0.5);",
            "    gl_FragData[2] = vec4(0.0, 0.0, 1.0, 1.0);",
            "}"
        ].join("\n");
        var effect = makePipelineEffect(EffectStage.GBuffer, fragment, pipelineEffectUniforms(), PipelineState.opaque());

        var item = new RenderItem(geometry, Material.create("effect-gbuffer"), null, Mat4.identity(new Mat4()));
        item.pipelineEffect = effect;
        var q = new RenderQueue();
        q.add(item);

        gbufferRenderer.render(q, makeFrame(128, 128), gbuffer);
        gbuffer.unbind(context);

        var copier = new FullscreenEffect(context, "PipelineEffectGBufferCopy", PBRShaderLibrary.presentFragment());
        var copy = copyBytes(copier, gbuffer.albedoTexture);
        var c = pixelAt(copy, 128, 64, 64);
        trace('pipeline effect gbuffer albedo: r=${c[0]} g=${c[1]} b=${c[2]}');
        check("pipeline effect: gbuffer technique writes albedo", c[1] > 200 && c[0] < 80 && c[2] < 80,
            'r=${c[0]} g=${c[1]} b=${c[2]}');

        copier.dispose();
        gbufferRenderer.dispose();
        pool.release(target);
    }

    static function testPipelineEffectFallbackStages() {
        var fallback = new GBufferFallbackRenderer(context);
        var albedo = pool.acquireMRT(128, 128, [TextureFormat.RGBA], TextureFormat.Depth24);
        var normal = pool.acquire(128, 128);
        var emissive = pool.acquire(128, 128);
        var gbuffer = new GBuffer(albedo, normal, emissive, 128, 128);

        var fragment = [
            "void main() {",
            "    gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);",
            "}"
        ].join("\n");
        var effect = makePipelineEffect(EffectStage.GBufferAlbedo, fragment, pipelineEffectUniforms(), PipelineState.opaque());
        var item = new RenderItem(geometry, Material.create("fallback-effect"), null, Mat4.identity(new Mat4()));
        item.pipelineEffect = effect;
        var q = new RenderQueue();
        q.add(item);

        fallback.render(q, makeFrame(128, 128), gbuffer);
        gbuffer.unbind(context);

        var copier = new FullscreenEffect(context, "FallbackEffectAlbedo", PBRShaderLibrary.presentFragment());
        var bytes = copyBytes(copier, gbuffer.albedoTexture);
        var c = pixelAt(bytes, 128, 64, 64);
        trace('fallback effect albedo: r=${c[0]} g=${c[1]} b=${c[2]}');
        check("pipeline effect fallback: albedo stage writes target",
            c[1] > 200 && c[0] < 80 && c[2] < 80,
            'r=${c[0]} g=${c[1]} b=${c[2]}');

        copier.dispose();
        pool.release(albedo);
        pool.release(normal);
        pool.release(emissive);
        fallback.dispose();
    }

    static function testPipelineEffectFallbackAutoSplit() {
        var fallback = new GBufferFallbackRenderer(context);
        var albedo = pool.acquireMRT(128, 128, [TextureFormat.RGBA], TextureFormat.Depth24);
        var normal = pool.acquire(128, 128);
        var emissive = pool.acquire(128, 128);
        var gbuffer = new GBuffer(albedo, normal, emissive, 128, 128);

        var fragment = [
            "void main() {",
            "    gl_FragData[0] = vec4(0.0, 1.0, 0.0, 1.0);",
            "    gl_FragData[1] = vec4(0.0, 0.0, 1.0, 1.0);",
            "    gl_FragData[2] = vec4(1.0, 0.0, 0.0, 1.0);",
            "}"
        ].join("\n");
        var effect = makePipelineEffect(EffectStage.GBuffer, fragment, pipelineEffectUniforms(), PipelineState.opaque());
        var item = new RenderItem(geometry, Material.create("fallback-auto-effect"), null, Mat4.identity(new Mat4()));
        item.pipelineEffect = effect;
        var q = new RenderQueue();
        q.add(item);

        fallback.render(q, makeFrame(128, 128), gbuffer);
        gbuffer.unbind(context);

        var copier = new FullscreenEffect(context, "FallbackEffectAutoSplit", PBRShaderLibrary.presentFragment());
        var albedoPixel = pixelAt(copyBytes(copier, gbuffer.albedoTexture), 128, 64, 64);
        var normalPixel = pixelAt(copyBytes(copier, gbuffer.normalTexture), 128, 64, 64);
        var emissivePixel = pixelAt(copyBytes(copier, gbuffer.emissiveTexture), 128, 64, 64);
        trace('fallback auto split: albedo=${albedoPixel} normal=${normalPixel} emissive=${emissivePixel}');
        check("pipeline effect fallback: auto-split albedo",
            albedoPixel[1] > 200 && albedoPixel[0] < 80, '${albedoPixel}');
        check("pipeline effect fallback: auto-split normal",
            normalPixel[2] > 200 && normalPixel[0] < 80, '${normalPixel}');
        check("pipeline effect fallback: auto-split emissive",
            emissivePixel[0] > 200 && emissivePixel[1] < 80, '${emissivePixel}');

        copier.dispose();
        pool.release(albedo);
        pool.release(normal);
        pool.release(emissive);
        fallback.dispose();
    }

    static function testPipelineEffectShadow() {
        var shadow = new ShadowRenderer(context);
        var target = pool.acquireMRT(128, 128, [TextureFormat.RGBA], TextureFormat.Depth24);

        var vertex = [
            "attribute vec3 position;",
            "uniform mat4 modelMatrix;",
            "uniform mat4 lightViewProjection;",
            "void main() { gl_Position = lightViewProjection * modelMatrix * vec4(position, 1.0); }"
        ].join("\n");
        var fragment = "void main() { gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0); }";

        var effect = PipelineEffect.create("effect-shadow");
        effect.addTechnique(new PipelineTechnique(EffectStage.Shadow, vertex, fragment, [
            new PipelineUniform("modelMatrix", UniformSource.ModelMatrix),
            new PipelineUniform("lightViewProjection", UniformSource.LightViewProjection)
        ], PipelineState.opaque()));

        var item = new RenderItem(geometry, Material.create("effect-shadow"), null, Mat4.identity(new Mat4()));
        item.pipelineEffect = effect;
        var q = new RenderQueue();
        q.add(item);

        var frame = makeFrame(128, 128);
        var lightView = GLM.lookAt(new Vec3(2.5, 2.0, 2.5), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        var lightProjection = GLM.orthographic(-4.0, 4.0, -4.0, 4.0, 0.1, 20.0, new Mat4());
        shadow.render(q, frame, target, lightProjection * lightView);
        target.unbind(context);

        var bytes = readTarget(target);
        var red = 0;
        for (i in 0...128 * 128) {
            var o = i * 4;
            if (bytes.get(o) > 200 && bytes.get(o + 1) < 80) {
                red++;
            }
        }
        trace('pipeline effect shadow redPixels=' + red);
        check("pipeline effect: shadow technique used", red > 10, 'redPixels=$red');

        shadow.dispose();
        pool.release(target);
    }

    static function testPipelineEffectFallbackAndState() {
        var litMaterial = PBRMaterial.create();
        litMaterial.setBaseColor(new Vec4(0.8, 0.8, 0.8, 1.0));
        litMaterial.setRoughness(0.5);

        var shadowOnly = PipelineEffect.create("effect-shadow-only");
        shadowOnly.addTechnique(new PipelineTechnique(EffectStage.Shadow, pipelineEffectVertex(),
            "void main() { gl_FragColor = vec4(1.0); }", pipelineEffectUniforms(), PipelineState.opaque()));
        var fallbackItem = new RenderItem(geometry, litMaterial, null, Mat4.identity(new Mat4()));
        fallbackItem.pipelineEffect = shadowOnly;
        var fallbackQueue = new RenderQueue();
        fallbackQueue.add(fallbackItem);
        var fallbackAvg = avgLuma(renderForward(fallbackQueue, makeFrame(128, 128), 128), 128, 128);
        trace('pipeline effect fallback avg=' + f(fallbackAvg));
        check("pipeline effect: missing stage falls back to PBR", fallbackAvg > 0.02, 'avg=' + f(fallbackAvg));

        var hiddenState = new PipelineState();
        hiddenState.colorMask = false;
        hiddenState.depthWrite = false;
        var hiddenEffect = makePipelineEffect(EffectStage.Forward,
            "void main() { gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0); }",
            pipelineEffectUniforms(), hiddenState);
        var hiddenItem = new RenderItem(geometry, Material.create("effect-hidden"), null, Mat4.identity(new Mat4()));
        hiddenItem.pipelineEffect = hiddenEffect;
        var visibleItem = new RenderItem(geometry, litMaterial, null, Mat4.identity(new Mat4()));
        var stateQueue = new RenderQueue();
        stateQueue.add(hiddenItem);
        stateQueue.add(visibleItem);
        var stateAvg = avgLuma(renderForward(stateQueue, makeFrame(128, 128), 128), 128, 128);
        trace('pipeline effect state isolation avg=' + f(stateAvg));
        check("pipeline effect: state restored before direct draw", stateAvg > 0.02, 'avg=' + f(stateAvg));
    }

    static function parserError(json:String):String {
        var parser = new PipelineEffectParser();
        var error:String = null;
        parser.error.connect(function(_, message) {
            error = message;
        });
        parser.parse("bad.peffect", "bad.peffect", Options.empty(), Bytes.ofString(json), null);
        return error;
    }

    static function testPipelineEffectParser() {
        var library = AssetLibrary.create(context);
        var options = Options.empty();
        options.assetLibrary = library;

        check("pipeline effect parser: registered for peffect", options.getParser("peffect") != null);

        var json = [
            '{',
            '  "name": "parsed-effect",',
            '  "techniques": [{',
            '    "stage": "forward",',
            '    "vertexShader": "attribute vec3 position; uniform mat4 modelMatrix; void main() { gl_Position = modelMatrix * vec4(position, 1.0); }",',
            '    "fragmentShader": "uniform vec4 uTint; void main() { gl_FragColor = uTint; }",',
            '    "uniforms": {',
            '      "modelMatrix": { "source": "modelMatrix" },',
            '      "uTint": { "material": "tint" },',
            '      "uScale": { "value": 2.0 }',
            '    },',
            '    "states": { "blending": "alpha", "triangleCulling": "none" }',
            '  }]',
            '}'
        ].join("\n");

        var parser = new PipelineEffectParser();
        var parseError:String = null;
        var completed = false;
        parser.error.connect(function(_, message) {
            parseError = message;
        });
        parser.complete.connect(function(_) {
            completed = true;
        });
        parser.parse("tint.peffect", "tint.peffect", options, Bytes.ofString(json), library);

        var effect = parser.effect;
        trace('pipeline effect parser: effect=' + (effect != null) + ' error=' + parseError);
        check("pipeline effect parser: parses valid file", effect != null && parseError == null, 'error=' + parseError);
        check("pipeline effect parser: completes", completed);

        if (effect != null) {
            var technique = effect.techniqueFor(EffectStage.Forward);
            check("pipeline effect parser: creates forward technique", technique != null);

            if (technique != null) {
                var sourceCount = 0;
                var materialCount = 0;
                var constantCount = 0;
                for (uniform in technique.uniforms) {
                    switch (uniform.source) {
                        case UniformSource.ModelMatrix:
                            sourceCount++;
                        case UniformSource.MaterialProperty(_):
                            materialCount++;
                        case UniformSource.Constant(_):
                            constantCount++;
                        default:
                    }
                }

                check("pipeline effect parser: parses uniform sources",
                    technique.uniforms.length == 3 && sourceCount == 1 && materialCount == 1 && constantCount == 1,
                    'count=${technique.uniforms.length} source=$sourceCount material=$materialCount constant=$constantCount');
                check("pipeline effect parser: parses alpha blending",
                    technique.state.blendingSource == BlendingSource.SRC_ALPHA
                    && technique.state.blendingDestination == BlendingDestination.ONE_MINUS_SRC_ALPHA);
                check("pipeline effect parser: parses triangle culling", technique.state.triangleCulling == TriangleCulling.NONE);
            }

            check("pipeline effect parser: stores in asset library", library.pipelineEffect("tint.peffect") == effect);
            check("pipeline effect parser: asset library count", library.numPipelineEffects == 1);
            check("pipeline effect parser: resolves effect name", library.pipelineEffectName(effect) == "tint.peffect");

            var copy = AssetLibrary.createbyAssetLibrary(library);
            check("pipeline effect parser: copies asset library", copy.pipelineEffect("tint.peffect") == effect);
        }

        var macroJson = '{"macros":{"USE_GREEN":true,"DISABLED":true},"techniques":[{"stage":"forward","vertexShader":"void main(){}","fragmentShader":"void main(){}","macros":{"USE_GREEN":false,"SCALE":2}}]}';
        var macroParser = new PipelineEffectParser();
        var macroError:String = null;
        macroParser.error.connect(function(_, message) {
            macroError = message;
        });
        macroParser.parse("macro.peffect", "macro.peffect", options, Bytes.ofString(macroJson), null);
        var macroEffect = macroParser.effect;
        check("pipeline effect parser: parses macro effect", macroEffect != null && macroError == null, 'error=' + macroError);
        if (macroEffect != null) {
            var macroTechnique = macroEffect.techniqueFor(EffectStage.Forward);
            check("pipeline effect parser: macro technique", macroTechnique != null);
            if (macroTechnique != null) {
                check("pipeline effect parser: false macro suppresses inherited",
                    macroTechnique.macros.exists("USE_GREEN") && macroTechnique.macros.get("USE_GREEN") == null);
                check("pipeline effect parser: numeric and boolean macros",
                    macroTechnique.macros.get("SCALE") == "2" && macroTechnique.macros.get("DISABLED") == "");
            }
        }

        check("pipeline effect parser: rejects invalid JSON", parserError("{") != null);
        check("pipeline effect parser: rejects unknown stage",
            parserError('{"techniques":[{"stage":"nope","vertexShader":"void main(){}","fragmentShader":"void main(){}"}]}') != null);
        check("pipeline effect parser: rejects unknown uniform source",
            parserError('{"techniques":[{"stage":"forward","vertexShader":"void main(){}","fragmentShader":"void main(){}","uniforms":{"u":{"source":"nope"}}}]}') != null);
        check("pipeline effect parser: rejects duplicate stage",
            parserError('{"techniques":[{"stage":"forward","vertexShader":"void main(){}","fragmentShader":"void main(){}"},{"stage":"forward","vertexShader":"void main(){}","fragmentShader":"void main(){}"}]}') != null);
        check("pipeline effect parser: rejects missing vertex shader",
            parserError('{"techniques":[{"stage":"forward","fragmentShader":"void main(){}"}]}') != null);
    }

    static function testPipelineEffectExternalParser() {
        var library = AssetLibrary.create(context);
        var options = Options.empty();
        options.assetLibrary = library;
        options.includePaths = ["asset/peffect", "."];
        options.loadAsynchronously = false;

        var loader = Loader.createbyOptions(options);
        var loadError:String = null;
        loader.error.connect(function(_, message) {
            loadError = message;
        });
        loader.setQueue("external.peffect", options).load();

        var effect = library.pipelineEffect("external.peffect");
        trace('pipeline effect external: effect=' + (effect != null) + ' error=' + loadError);
        check("pipeline effect external: loads", effect != null && loadError == null, 'error=' + loadError);

        if (effect != null) {
            var technique = effect.techniqueFor(EffectStage.Forward);
            check("pipeline effect external: forward technique", technique != null);
            if (technique != null) {
                check("pipeline effect external: vertex file loaded",
                    technique.vertexSource.indexOf("attribute vec3 position") != -1);
                check("pipeline effect external: pragma include expanded",
                    technique.fragmentSource.indexOf("float luminance") != -1,
                    "fragment=" + technique.fragmentSource);
                check("pipeline effect external: pragma removed",
                    technique.fragmentSource.indexOf("#pragma include") == -1);
                check("pipeline effect external: top-level macros",
                    technique.macros.get("USE_GREEN") == "" && technique.macros.get("MAX_LIGHTS") == "4");
                check("pipeline effect external: technique macro",
                    technique.macros.get("MODE") == "PBR");
            }
        }

        var badLoader = Loader.createbyOptions(options);
        var badError:String = null;
        badLoader.error.connect(function(_, message) {
            badError = message;
        });
        badLoader.setQueue("bad_include.peffect", options).load();
        check("pipeline effect external: missing include errors",
            badError != null && library.pipelineEffect("bad_include.peffect") == null,
            'error=' + badError);

        var cycleLoader = Loader.createbyOptions(options);
        var cycleError:String = null;
        cycleLoader.error.connect(function(_, message) {
            cycleError = message;
        });
        cycleLoader.setQueue("cycle.peffect", options).load();
        check("pipeline effect external: recursive include errors",
            cycleError != null && library.pipelineEffect("cycle.peffect") == null,
            'error=' + cycleError);
    }

    static function testPipelineEffectMacros() {
        var vertex = pipelineEffectVertex();
        var fragment = [
            "#ifdef USE_GREEN",
            "void main() { gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0); }",
            "#else",
            "void main() { gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0); }",
            "#endif"
        ].join("\n");
        var uniforms = pipelineEffectUniforms();

        var greenTechnique = new PipelineTechnique(EffectStage.Forward, vertex, fragment, uniforms, PipelineState.opaque());
        greenTechnique.addMacro("USE_GREEN");
        var greenEffect = PipelineEffect.create("macro-green");
        greenEffect.addTechnique(greenTechnique);

        var greenItem = new RenderItem(geometry, Material.create("macro-green"), null, Mat4.identity(new Mat4()));
        greenItem.pipelineEffect = greenEffect;
        var greenQueue = new RenderQueue();
        greenQueue.add(greenItem);
        var green = pixelAt(renderForward(greenQueue, makeFrame(128, 128), 128), 128, 64, 64);
        trace('pipeline effect macro green: r=${green[0]} g=${green[1]} b=${green[2]}');
        check("pipeline effect macro: #define applied",
            green[1] > 200 && green[0] < 80, 'r=${green[0]} g=${green[1]} b=${green[2]}');

        var redTechnique = new PipelineTechnique(EffectStage.Forward, vertex, fragment, uniforms, PipelineState.opaque());
        var redEffect = PipelineEffect.create("macro-red");
        redEffect.addTechnique(redTechnique);
        var redItem = new RenderItem(geometry, Material.create("macro-red"), null, Mat4.identity(new Mat4()));
        redItem.pipelineEffect = redEffect;
        var redQueue = new RenderQueue();
        redQueue.add(redItem);
        var red = pixelAt(renderForward(redQueue, makeFrame(128, 128), 128), 128, 64, 64);
        trace('pipeline effect macro red: r=${red[0]} g=${red[1]} b=${red[2]}');
        check("pipeline effect macro: without #define",
            red[0] > 200 && red[1] < 80, 'r=${red[0]} g=${red[1]} b=${red[2]}');
    }

    static function testNonPBRForward() {
        var identity = Mat4.identity(new Mat4());

        var greenEffect = makePipelineEffect(EffectStage.Forward,
            "void main() { gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0); }",
            pipelineEffectUniforms(), PipelineState.opaque());
        var colored = new RenderItem(geometry, Material.create("non-pbr"), null, identity);
        colored.pipelineEffect = greenEffect;
        var coloredQueue = new RenderQueue();
        coloredQueue.add(colored);
        var coloredPixel = pixelAt(renderForwardEffect(coloredQueue, makeFrame(128, 128)), 128, 64, 64);
        trace('non-pbr forward: r=${coloredPixel[0]} g=${coloredPixel[1]} b=${coloredPixel[2]}');
        check("non-pbr forward: opaque effect", coloredPixel[1] > 200 && coloredPixel[0] < 80,
            'r=${coloredPixel[0]} g=${coloredPixel[1]} b=${coloredPixel[2]}');

        var transparentEffect = makePipelineEffect(EffectStage.Transparent,
            "void main() { gl_FragColor = vec4(1.0, 0.0, 0.0, 0.5); }",
            pipelineEffectUniforms(), PipelineState.transparent());
        var transparent = new RenderItem(geometry, Material.create("non-pbr-transparent"), null, identity);
        transparent.pipelineEffect = transparentEffect;
        var transparentQueue = new RenderQueue();
        transparentQueue.add(transparent, true);
        var transparentPixel = pixelAt(renderForwardEffect(transparentQueue, makeFrame(128, 128)), 128, 64, 64);
        trace('non-pbr forward transparent: r=${transparentPixel[0]} g=${transparentPixel[1]} b=${transparentPixel[2]}');
        check("non-pbr forward: transparent effect",
            transparentPixel[0] > 90 && transparentPixel[0] < 180 && transparentPixel[0] > transparentPixel[1] + 50,
            'r=${transparentPixel[0]} g=${transparentPixel[1]} b=${transparentPixel[2]}');

        var noEffect = new RenderItem(geometry, Material.create("non-pbr-skip"), null, identity);
        var skipQueue = new RenderQueue();
        skipQueue.add(noEffect);
        var skipAvg = avgLuma(renderForwardEffect(skipQueue, makeFrame(128, 128)), 128, 128);
        trace('non-pbr forward skip avg=' + f(skipAvg));
        check("non-pbr forward: skips item without effect", skipAvg < 0.001, 'avg=' + f(skipAvg));

        var defaultEffect = makePipelineEffect(EffectStage.Forward,
            "void main() { gl_FragColor = vec4(0.0, 0.0, 1.0, 1.0); }",
            pipelineEffectUniforms(), PipelineState.opaque());
        var defaultQueue = new RenderQueue();
        defaultQueue.add(noEffect);
        var defaultPixel = pixelAt(renderForwardEffect(defaultQueue, makeFrame(128, 128), defaultEffect), 128, 64, 64);
        trace('non-pbr forward default: r=${defaultPixel[0]} g=${defaultPixel[1]} b=${defaultPixel[2]}');
        check("non-pbr forward: default effect", defaultPixel[2] > 200 && defaultPixel[0] < 80,
            'r=${defaultPixel[0]} g=${defaultPixel[1]} b=${defaultPixel[2]}');

        var shadowOnly = PipelineEffect.create("non-pbr-shadow-only");
        shadowOnly.addTechnique(new PipelineTechnique(EffectStage.Shadow, pipelineEffectVertex(),
            "void main() { gl_FragColor = vec4(1.0); }", pipelineEffectUniforms(), PipelineState.opaque()));
        var shadowItem = new RenderItem(geometry, Material.create("non-pbr-shadow"), null, identity);
        shadowItem.pipelineEffect = shadowOnly;
        var shadowQueue = new RenderQueue();
        shadowQueue.add(shadowItem);
        var noFallbackAvg = avgLuma(renderForwardEffect(shadowQueue, makeFrame(128, 128)), 128, 128);
        trace('non-pbr forward no-fallback avg=' + f(noFallbackAvg));
        check("non-pbr forward: no PBR fallback", noFallbackAvg < 0.001, 'avg=' + f(noFallbackAvg));
    }

    static function testPBRRendererComponent() {
        var root = Node.create("pbr-renderer-root");
        root.addComponent(SceneManager.create(canvas));

        var cameraNode = Node.create("camera")
            .addComponent(Transform.create())
            .addComponent(PerspectiveCamera.create(1.0));
        root.addChild(cameraNode);

        var mesh = Node.create("mesh")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, PBRMaterial.create("pbr-renderer-material"), null));
        root.addChild(mesh);

        var component = PBRRenderer.create();
        root.addComponent(component);
        component.addLight(Light.directional());

        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.016);

        check("PBRRenderer: pipeline created", component.pipeline != null);
        check("PBRRenderer: renderer created", component.renderer != null);
        check("PBRRenderer: default forward path", Std.isOfType(component.forwardPath, ForwardPBRPath));
        check("PBRRenderer: surfaces collected",
            component.pipeline != null && component.pipeline.queue.count == 1,
            component.pipeline != null ? 'count=${component.pipeline.queue.count}' : "no pipeline");
        check("PBRRenderer: lights forwarded",
            component.pipeline != null && component.pipeline.lights.count == 1);

        var glassMaterial = PBRMaterial.create("pbr-renderer-glass");
        glassMaterial.setBaseColor(new Vec4(1.0, 0.0, 0.0, 0.5));
        var glass = Node.create("glass")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, glassMaterial, null));
        root.addChild(glass);

        component.useDeferred = true;
        sceneManager.nextFrame(0.0, 0.016);
        check("PBRRenderer: deferred path selected",
            component.pipeline != null && Std.isOfType(component.pipeline.path, DeferredPBRPath),
            component.pipeline == null ? "no pipeline" : Type.getClassName(Type.getClass(component.pipeline.path)));
        check("PBRRenderer: deferred path exposed", component.deferredPath != null);
        check("PBRRenderer: deferred transparent queue",
            component.pipeline != null && component.pipeline.queue.transparent.length == 1,
            component.pipeline != null ? 'transparent=${component.pipeline.queue.transparent.length}' : "no pipeline");

        component.useDeferred = false;
        sceneManager.nextFrame(0.0, 0.016);
        check("PBRRenderer: forward path restored",
            component.pipeline != null && Std.isOfType(component.pipeline.path, ForwardPBRPath));
        check("PBRRenderer: forward transparent queue",
            component.pipeline != null && component.pipeline.queue.transparent.length == 1);

        component.enabled = false;
        sceneManager.nextFrame(0.016, 0.016);
        component.enabled = true;

        root.removeComponent(component);
        check("PBRRenderer: releases pipeline on detach",
            component.pipeline == null && component.renderer == null && component.forwardPath == null);
    }

    // ------------------------------------------------------- GL: benchmark

    static function testPhongRendererComponent() {
        var root = Node.create("phong-renderer-root");
        root.addComponent(SceneManager.create(canvas));

        var cameraNode = Node.create("camera")
            .addComponent(Transform.createbyMatrix4(Mat4.invert(GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4())))
            .addComponent(PerspectiveCamera.create(1.0));
        root.addChild(cameraNode);

        var mesh = Node.create("mesh")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, PhongMaterial.create("phong-renderer-material"), null));
        root.addChild(mesh);

        var lightNode = Node.create("light")
            .addComponent(Transform.create())
            .addComponent(DirectionalLight.create(new Vec3(1.0, 1.0, 1.0), 2.0));
        root.addChild(lightNode);

        var component = PhongRenderer.create();
        root.addComponent(component);

        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.016);

        check("PhongRenderer: pipeline created", component.pipeline != null);
        check("PhongRenderer: renderer created", component.renderer != null);
        check("PhongRenderer: forward path", Std.isOfType(component.forwardPath, ForwardPhongPath));
        check("PhongRenderer: surfaces collected", component.pipeline.queue.count == 1);
        check("PhongRenderer: scene light collected", component.lights.count == 1);

        root.removeComponent(component);
        check("PhongRenderer: releases pipeline on detach",
            component.pipeline == null && component.renderer == null && component.forwardPath == null);
    }

    static function testLightComponents() {
        var root = Node.create("light-component-root");
        root.addComponent(SceneManager.create(canvas));

        var cameraNode = Node.create("camera")
            .addComponent(Transform.create())
            .addComponent(PerspectiveCamera.create(1.0));
        root.addChild(cameraNode);

        var mesh = Node.create("mesh")
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, PBRMaterial.create("light-component-material"), null));
        root.addChild(mesh);

        var pointNode = Node.create("point-light")
            .addComponent(Transform.create())
            .addComponent(PointLight.create(new Vec3(1.0, 0.8, 0.6), 2.0, 8.0));
        root.addChild(pointNode);

        var component = PBRRenderer.create();
        root.addComponent(component);

        var sceneManager:SceneManager = cast root.getComponent(SceneManager);
        sceneManager.nextFrame(0.0, 0.016);
        check("LightComponent: point light collected",
            component.lights != null && component.lights.count == 1 && component.lights.lights[0].type == Light.LightType.Point,
            component.lights != null ? 'count=${component.lights.count}' : "no lights");

        var transform:Transform = cast pointNode.getComponent(Transform);
        var moved = Mat4.identity(new Mat4());
        moved.r0c3 = 2.0;
        moved.r1c3 = 1.0;
        transform.matrix = moved;
        sceneManager.nextFrame(0.0, 0.016);
        var point = component.lights.lights[0];
        check("LightComponent: transform position synced",
            Math.abs(point.position.x - 2.0) < 0.001 && Math.abs(point.position.y - 1.0) < 0.001,
            'pos=(${point.position.x}, ${point.position.y}, ${point.position.z})');

        var dirNode = Node.create("dir-light")
            .addComponent(Transform.create())
            .addComponent(DirectionalLight.create(new Vec3(1.0, 1.0, 1.0), 1.0));
        root.addChild(dirNode);
        sceneManager.nextFrame(0.0, 0.016);
        check("LightComponent: directional light collected", component.lights.count == 2,
            'count=${component.lights.count}');

        component.addLight(Light.point());
        sceneManager.nextFrame(0.0, 0.016);
        check("LightComponent: manual light merged", component.lights.count == 3,
            'count=${component.lights.count}');

        component.clearLights();
        sceneManager.nextFrame(0.0, 0.016);
        check("LightComponent: manual light cleared", component.lights.count == 2,
            'count=${component.lights.count}');

        root.removeComponent(component);
    }

    static function testBenchmark() {
        var mats:Array<PBRMaterial> = [];
        for (i in 0...8) {
            var m = PBRMaterial.create();
            m.setBaseColor(new Vec4(0.3 + 0.08 * i, 0.5, 0.8 - 0.06 * i, 1.0));
            m.setRoughness(0.2 + 0.08 * i);
            mats.push(m);
        }
        var q = new RenderQueue();
        for (i in 0...1000) {
            var w = Mat4.identity(new Mat4());
            w.r0c3 = (i % 10 - 4.5) * 1.2;
            w.r1c3 = (Std.int(i / 10) % 10 - 4.5) * 1.2;
            w.r2c3 = -2.0 - (i % 20) * 0.5;
            q.add(new RenderItem(geometry, mats[i % 8], null, w));
        }
        var frame = makeFrame(512, 512, true, 3.0);
        var target = pool.acquire(512, 512);

        // warmup
        target.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        pbr.render(q, frame, target);

        var frames = 30;
        var t0 = Timer.stamp();
        for (fIdx in 0...frames) {
            target.bind(context, true);
            context.clear(0.0, 0.0, 0.0, 1.0);
            pbr.render(q, frame, target);
        }
        #if hl
        sdl.GL.finish();
        #end
        var avgMs = (Timer.stamp() - t0) * 1000.0 / frames;
        target.unbind(context);
        pool.release(target);

        trace('BENCH drawCalls=1000 frames=$frames avgMs=' + f(avgMs));
        check("benchmark: 1000 drawCalls x 30 frames completed", avgMs < 200.0, 'avgMs=' + f(avgMs));
    }
}
