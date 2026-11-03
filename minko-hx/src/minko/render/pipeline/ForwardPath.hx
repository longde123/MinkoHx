package minko.render.pipeline;

import glm.Mat4;
import glm.Vec3;
import minko.render.AbstractContext;
import minko.render.CubeTexture;
import minko.render.TextureFormat;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.render.pbr.PointShadow;
import minko.render.pbr.ShadowRenderer;
import minko.render.pbr.SpotShadow;
import minko.render.target.RenderTarget;

/**
 * Generic forward render path.
 *
 * The path owns the graph shape (scene color + optional shadow + post chain);
 * the actual scene draw is supplied by the caller. It does not depend on PBR:
 * PBRForwardPath is a thin specialization, and non-PBR renderers can use
 * ForwardPath directly.
 */
class ForwardPath extends RenderPath {
    public var renderScene:RenderQueue -> FrameContext -> RenderTarget -> Void;
    public var postProcess:PostProcessChain;
    public var shadowRenderer:ShadowRenderer;
    public var lightViewProjection:Mat4;
    public var shadowMapSize:Int;
    public var passName:String;

    /** Number of directional cascades (1 keeps the legacy single-map path). */
    public var shadowCascadeCount:Int;
    public var shadowSplitLambda:Float;
    public var shadowLightDirection:Vec3;
    public var shadowMaxDistance:Float;
    public var spotShadowSize:Int;
    public var pointShadowSize:Int;
    public var maxSpotShadows:Int;
    public var maxPointShadows:Int;
    public var enableLocalShadows:Bool;

    private var _graph:RenderGraph;
    private var _sceneColor:RenderGraphResource;
    private var _shadowResources:Array<RenderGraphResource>;
    private var _spotShadowResource:RenderGraphResource;
    private var _pointShadowResource:RenderGraphResource;
    private var _postResources:Array<RenderGraphResource>;
    private var _activeQueue:RenderQueue;
    private var _cachedWidth:Int;
    private var _cachedHeight:Int;
    private var _cachedSceneFormat:Int;
    private var _cachedShadow:Bool;
    private var _cachedShadowSize:Int;
    private var _cachedShadowCount:Int;
    private var _cachedLocalShadows:Bool;
    private var _cachedSpotShadowSize:Int;
    private var _cachedPointShadowSize:Int;
    private var _pointCubes:Array<CubeTexture>;
    private var _cachedPost:PostProcessChain;
    private var _cachedPostStages:Int;
    private var _cachedPassName:String;

    public function new(renderScene:RenderQueue -> FrameContext -> RenderTarget -> Void = null,
                        postProcess:PostProcessChain = null,
                        name:String = "forward",
                        passName:String = "ForwardPass") {
        super(name);
        this.renderScene = renderScene;
        this.postProcess = postProcess;
        this.shadowRenderer = null;
        this.lightViewProjection = Mat4.identity(new Mat4());
        this.shadowMapSize = 512;
        this.passName = passName;
        this.shadowCascadeCount = 1;
        this.shadowSplitLambda = 0.5;
        this.shadowLightDirection = new Vec3(0.0, -1.0, 0.0);
        this.shadowMaxDistance = 100.0;
        this.spotShadowSize = 512;
        this.pointShadowSize = 512;
        this.maxSpotShadows = 2;
        this.maxPointShadows = 2;
        this.enableLocalShadows = true;
        _graph = null;
        _sceneColor = null;
        _shadowResources = [];
        _spotShadowResource = null;
        _pointShadowResource = null;
        _postResources = [];
        _activeQueue = null;
        _cachedWidth = -1;
        _cachedHeight = -1;
        _cachedSceneFormat = -1;
        _cachedShadow = false;
        _cachedShadowSize = -1;
        _cachedShadowCount = -1;
        _cachedLocalShadows = false;
        _cachedSpotShadowSize = -1;
        _cachedPointShadowSize = -1;
        _pointCubes = [];
        _cachedPost = null;
        _cachedPostStages = -1;
        _cachedPassName = null;
    }

    override public function build(queue:RenderQueue, ctx:FrameContext):RenderGraph {
        var sceneFormat = ctx.capabilities != null && ctx.capabilities.supportsFloatRenderTarget ? TextureFormat.RGBA16F : TextureFormat.RGBA;
        var hasShadow = shadowRenderer != null && ctx.capabilities != null && ctx.capabilities.supportsDepthTexture;
        var hasLocal = hasShadow && enableLocalShadows;
        var cascadeCount = hasShadow ? Std.int(Math.max(1, Math.min(4, shadowCascadeCount))) : 0;
        var postStages = postProcess != null ? postProcess.stages.length : 0;

        if (_graph != null
            && _cachedWidth == ctx.width
            && _cachedHeight == ctx.height
            && _cachedSceneFormat == sceneFormat
            && _cachedShadow == hasShadow
            && _cachedShadowSize == shadowMapSize
            && _cachedShadowCount == cascadeCount
            && _cachedLocalShadows == hasLocal
            && _cachedSpotShadowSize == spotShadowSize
            && _cachedPointShadowSize == pointShadowSize
            && _cachedPost == postProcess
            && _cachedPostStages == postStages
            && _cachedPassName == passName) {
            _activeQueue = queue;
            _sceneColor.target = ctx.targetPool.acquire(ctx.width, ctx.height, sceneFormat);
            for (resource in _shadowResources) {
                resource.target = ctx.targetPool.acquireMRT(shadowMapSize, shadowMapSize, [TextureFormat.RGBA], TextureFormat.Depth24);
            }
            if (_spotShadowResource != null) {
                _spotShadowResource.target = ctx.targetPool.acquireMRT(spotShadowSize * 2, spotShadowSize, [TextureFormat.RGBA], TextureFormat.Depth24);
            }
            if (_pointShadowResource != null) {
                _pointShadowResource.target = ctx.targetPool.acquireMRT(pointShadowSize * 4, pointShadowSize * 3, [TextureFormat.RGBA], TextureFormat.Depth24);
            }
            for (i in 0..._postResources.length) {
                _postResources[i].target = ctx.targetPool.acquire(ctx.width, ctx.height, postProcess.stages[i].format);
            }
            return _graph;
        }

        if (_graph != null) {
            _graph.releaseTransients(ctx.targetPool);
            _graph.dispose();
            _graph = null;
        }

        var graph = new RenderGraph();
        var sceneColor = graph.createResource("SceneColorHDR", ctx.targetPool.acquire(ctx.width, ctx.height, sceneFormat));

        var shadowResources:Array<RenderGraphResource> = [];
        if (hasShadow) {
            for (i in 0...cascadeCount) {
                var shadowTarget = ctx.targetPool.acquireMRT(shadowMapSize, shadowMapSize, [TextureFormat.RGBA], TextureFormat.Depth24);
                shadowResources.push(graph.createResource("ShadowMap" + i, shadowTarget));
            }
        }

        var spotShadowResource:RenderGraphResource = null;
        var pointShadowResource:RenderGraphResource = null;
        if (hasLocal) {
            spotShadowResource = graph.createResource("SpotShadowMap",
                ctx.targetPool.acquireMRT(spotShadowSize * 2, spotShadowSize, [TextureFormat.RGBA], TextureFormat.Depth24));
            pointShadowResource = graph.createResource("PointShadowAtlas",
                ctx.targetPool.acquireMRT(pointShadowSize * 4, pointShadowSize * 3, [TextureFormat.RGBA], TextureFormat.Depth24));
        }

        if (shadowResources.length > 0 || spotShadowResource != null || pointShadowResource != null) {
            var shadowPass = new CallbackPass("ShadowPass", function(frame:FrameContext) {
                var targets:Array<RenderTarget> = [for (resource in shadowResources) resource.target];
                if (targets.length > 0) {
                    if (targets.length <= 1) {
                        frame.shadowMap = targets[0];
                        frame.lightViewProjection = lightViewProjection;
                        shadowRenderer.render(_activeQueue, frame, targets[0], lightViewProjection);
                    }
                    else {
                        shadowRenderer.cascadeCount = targets.length;
                        shadowRenderer.splitLambda = shadowSplitLambda;
                        shadowRenderer.renderCascades(_activeQueue, frame, targets, shadowLightDirection,
                            frame.viewMatrix, frame.projectionMatrix, 0.1, shadowMaxDistance);
                    }
                }

                var directionalViewProjection = frame.lightViewProjection;
                frame.shadowTexelSize = 1.0 / shadowMapSize;
                frame.shadowSoftness = shadowRenderer.softShadows ? 1.0 : 0.0;
                frame.shadowLightSize = shadowRenderer.lightSize;

                if (spotShadowResource != null && frame.lights != null) {
                    var lights = frame.lights.lights;
                    var count = 0;
                    var maxSpots = Std.int(Math.max(0, Math.min(2, maxSpotShadows)));
                    spotShadowResource.target.bind(frame.context, true);
                    frame.context.clear(1.0, 1.0, 1.0, 1.0, 1.0, 0);
                    for (i in 0...lights.length) {
                        if (count >= maxSpots) break;
                        var light = lights[i];
                        if (light.type != LightType.Spot || !light.castShadow) continue;
                        var matrix = shadowRenderer.renderSpotAtlas(_activeQueue, frame, spotShadowResource.target, spotShadowSize, count, light, i, false);
                        var shadow = new SpotShadow(spotShadowResource.target, matrix, i);
                        shadow.atlas = spotShadowResource.target;
                        shadow.cell = count;
                        frame.spotShadows.push(shadow);
                        if (frame.spotShadow == null) frame.spotShadow = shadow;
                        count++;
                    }
                    spotShadowResource.target.unbind(frame.context);
                }

                if (pointShadowResource != null && frame.lights != null) {
                    var lights = frame.lights.lights;
                    var count = 0;
                    var maxPoints = Std.int(Math.max(0, Math.min(2, maxPointShadows)));
                    pointShadowResource.target.bind(frame.context, true);
                    frame.context.clear(1.0, 1.0, 1.0, 1.0, 1.0, 0);
                    for (i in 0...lights.length) {
                        if (count >= maxPoints) break;
                        var light = lights[i];
                        if (light.type != LightType.Point || !light.castShadow) continue;
                        var cube = getPointCube(frame.context, count);
                        shadowRenderer.renderPointCube(_activeQueue, frame, cube.id, pointShadowSize, light, i);
                        var matrices = shadowRenderer.renderPointAtlasCell(_activeQueue, frame, pointShadowResource.target, pointShadowSize, count * 6, light, i, false);
                        var point = new PointShadow(matrices, i);
                        point.atlas = pointShadowResource.target;
                        point.cube = cube;
                        point.faceSize = pointShadowSize;
                        point.baseCell = count * 6;
                        point.position = light.position;
                        point.range = light.range;
                        frame.pointShadows.push(point);
                        if (frame.pointShadow == null) frame.pointShadow = point;
                        count++;
                    }
                    pointShadowResource.target.unbind(frame.context);
                }

                frame.lightViewProjection = directionalViewProjection;
            });
            for (resource in shadowResources) {
                shadowPass.write(resource);
            }
            if (spotShadowResource != null) {
                shadowPass.write(spotShadowResource);
            }
            if (pointShadowResource != null) {
                shadowPass.write(pointShadowResource);
            }
            graph.addPass(shadowPass);
        }

        var scenePass = new CallbackPass(passName, function(frame:FrameContext) {
            var target = sceneColor.target;
            target.bind(frame.context, true);
            frame.context.clear(0.0, 0.0, 0.0, 1.0, 1.0, 0);
            if (renderScene != null) {
                renderScene(_activeQueue, frame, target);
            }
            target.unbind(frame.context);
        });
        for (resource in shadowResources) {
            scenePass.read(resource);
        }
        if (spotShadowResource != null) {
            scenePass.read(spotShadowResource);
        }
        if (pointShadowResource != null) {
            scenePass.read(pointShadowResource);
        }
        scenePass.write(sceneColor);
        graph.addPass(scenePass);

        _postResources = [];
        if (postStages > 0) {
            var finalColor = postProcess.build(graph, sceneColor, ctx, _postResources);
            graph.setOutput(finalColor);
        }
        else {
            graph.setOutput(sceneColor);
        }

        _graph = graph;
        _sceneColor = sceneColor;
        _shadowResources = shadowResources;
        _spotShadowResource = spotShadowResource;
        _pointShadowResource = pointShadowResource;
        _activeQueue = queue;
        _cachedWidth = ctx.width;
        _cachedHeight = ctx.height;
        _cachedSceneFormat = sceneFormat;
        _cachedShadow = hasShadow;
        _cachedShadowSize = shadowMapSize;
        _cachedShadowCount = cascadeCount;
        _cachedLocalShadows = hasLocal;
        _cachedSpotShadowSize = spotShadowSize;
        _cachedPointShadowSize = pointShadowSize;
        _cachedPost = postProcess;
        _cachedPostStages = postStages;
        _cachedPassName = passName;

        return graph;
    }

    private function getPointCube(context:AbstractContext, index:Int):CubeTexture {
        while (_pointCubes.length <= index) _pointCubes.push(null);
        var cube = _pointCubes[index];
        if (cube == null || cube.width != pointShadowSize) {
            if (cube != null) cube.dispose();
            cube = CubeTexture.create(context, pointShadowSize, pointShadowSize, false, false, true, TextureFormat.RGBA);
            cube.upload();
            _pointCubes[index] = cube;
        }
        return cube;
    }

    override public function dispose():Void {
        for (cube in _pointCubes) {
            if (cube != null) cube.dispose();
        }
        _pointCubes = [];

        if (_graph != null) {
            _graph.dispose();
            _graph = null;
        }
        _sceneColor = null;
        _shadowResources = null;
        _spotShadowResource = null;
        _pointShadowResource = null;
        _postResources = null;
        _activeQueue = null;
        super.dispose();
    }
}
