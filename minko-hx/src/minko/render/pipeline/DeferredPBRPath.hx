package minko.render.pipeline;

import glm.Mat4;
import glm.Vec3;
import minko.render.AbstractContext;
import minko.render.CubeTexture;
import minko.render.TextureFormat;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.render.pbr.FullscreenEffect;
import minko.render.pbr.PBRShaderLibrary;
import minko.render.pbr.PointShadow;
import minko.render.pbr.SSAORenderer;
import minko.render.pbr.ShadowRenderer;
import minko.render.pbr.SpotShadow;
import minko.render.target.GBuffer;
import minko.render.target.RenderTarget;

typedef GBufferDraw = RenderQueue -> FrameContext -> GBuffer -> Void;
typedef LightingDraw = FrameContext -> GBuffer -> RenderTarget -> Void;

/**
 * Opaque G-buffer draw followed by the transparent pass.
 *
 * `sceneColor` is the lighting result and `output` is the final color the
 * transparent geometry must blend into. The callback is expected to start from
 * the scene color (copy it, or re-light it) and then draw the transparent
 * queue; when no callback is supplied the path copies the scene color itself so
 * the deferred output is never left black or stale.
 */
typedef TransparentDraw = RenderQueue -> FrameContext -> RenderTarget -> RenderTarget -> Void;

/**
 * Deferred PBR render path.
 *
 * This is the multi-pass fallback (three independent color targets) that works
 * with the current single-attachment backend. When native MRT is available,
 * GBuffer will be backed by one RenderTarget with three color attachments.
 */
class DeferredPBRPath extends RenderPath {
    public var renderGBuffer:GBufferDraw;
    public var renderLighting:LightingDraw;
    public var renderTransparent:TransparentDraw;
    public var postProcess:PostProcessChain;
    public var shadowRenderer:ShadowRenderer;
    public var lightViewProjection:Mat4;
    public var shadowMapSize:Int;
    public var shadowCascadeCount:Int;
    public var shadowSplitLambda:Float;
    public var shadowLightDirection:Vec3;
    public var shadowMaxDistance:Float;
    public var spotShadowSize:Int;
    public var pointShadowSize:Int;
    public var maxSpotShadows:Int;
    public var maxPointShadows:Int;
    public var enableLocalShadows:Bool;
    public var ssaoRenderer:SSAORenderer;

    /** G-buffer of the last build(); handy for debug views and tools. */
    public var gbuffer:GBuffer;

    private var _copier:FullscreenEffect;
    private var _graph:RenderGraph;
    private var _gbufferResources:Array<RenderGraphResource>;
    private var _sceneColor:RenderGraphResource;
    private var _finalColor:RenderGraphResource;
    private var _shadowResource:RenderGraphResource;
    private var _shadowResources:Array<RenderGraphResource>;
    private var _spotShadowResource:RenderGraphResource;
    private var _pointShadowResource:RenderGraphResource;
    private var _ssaoResource:RenderGraphResource;
    private var _postResources:Array<RenderGraphResource>;
    private var _activeQueue:RenderQueue;
    private var _cachedWidth:Int;
    private var _cachedHeight:Int;
    private var _cachedSceneFormat:Int;
    private var _cachedMrt:Bool;
    private var _cachedDepthFormat:Int;
    private var _cachedShadow:Bool;
    private var _cachedShadowSize:Int;
    private var _cachedShadowCount:Int;
    private var _cachedLocalShadows:Bool;
    private var _cachedSpotShadowSize:Int;
    private var _cachedPointShadowSize:Int;
    private var _pointCubes:Array<CubeTexture>;
    private var _cachedSSAO:Bool;
    private var _cachedPost:PostProcessChain;
    private var _cachedPostStages:Int;

    public function new(renderGBuffer:GBufferDraw = null, renderLighting:LightingDraw = null, renderTransparent:TransparentDraw = null, postProcess:PostProcessChain = null) {
        super("deferred-pbr");
        this.renderGBuffer = renderGBuffer;
        this.renderLighting = renderLighting;
        this.renderTransparent = renderTransparent;
        this.postProcess = postProcess;
        this.gbuffer = null;
        this._copier = null;
        this.shadowRenderer = null;
        this.lightViewProjection = Mat4.identity(new Mat4());
        this.shadowMapSize = 512;
        this.shadowCascadeCount = 1;
        this.shadowSplitLambda = 0.5;
        this.shadowLightDirection = new Vec3(0.0, -1.0, 0.0);
        this.shadowMaxDistance = 100.0;
        this.spotShadowSize = 512;
        this.pointShadowSize = 512;
        this.maxSpotShadows = 2;
        this.maxPointShadows = 2;
        this.enableLocalShadows = true;
        this.ssaoRenderer = null;
        _graph = null;
        _gbufferResources = [];
        _sceneColor = null;
        _finalColor = null;
        _shadowResource = null;
        _shadowResources = [];
        _spotShadowResource = null;
        _pointShadowResource = null;
        _pointCubes = [];
        _ssaoResource = null;
        _postResources = [];
        _activeQueue = null;
        _cachedWidth = -1;
        _cachedHeight = -1;
        _cachedSceneFormat = -1;
        _cachedMrt = false;
        _cachedDepthFormat = -1;
        _cachedShadow = false;
        _cachedShadowSize = -1;
        _cachedShadowCount = -1;
        _cachedLocalShadows = false;
        _cachedSpotShadowSize = -1;
        _cachedPointShadowSize = -1;
        _cachedSSAO = false;
        _cachedPost = null;
        _cachedPostStages = -1;
    }

    override public function build(queue:RenderQueue, ctx:FrameContext):RenderGraph {
        var width = ctx.width;
        var height = ctx.height;
        var sceneFormat = ctx.capabilities != null && ctx.capabilities.supportsFloatRenderTarget ? TextureFormat.RGBA16F : TextureFormat.RGBA;
        var mrt = ctx.capabilities != null && ctx.capabilities.supportsMRT;
        var depthFormat:Int = ctx.capabilities != null && ctx.capabilities.supportsDepthTexture ? TextureFormat.Depth24 : -1;
        var hasShadow = shadowRenderer != null && depthFormat >= 0;
        var hasLocal = hasShadow && enableLocalShadows;
        var hasSSAO = ssaoRenderer != null && depthFormat >= 0;
        var cascadeCount = hasShadow ? Std.int(Math.max(1, Math.min(4, shadowCascadeCount))) : 0;
        var postStages = postProcess != null ? postProcess.stages.length : 0;

        if (_graph != null
            && _cachedWidth == width
            && _cachedHeight == height
            && _cachedSceneFormat == sceneFormat
            && _cachedMrt == mrt
            && _cachedDepthFormat == depthFormat
            && _cachedShadow == hasShadow
            && _cachedShadowSize == shadowMapSize
            && _cachedShadowCount == cascadeCount
            && _cachedLocalShadows == hasLocal
            && _cachedSpotShadowSize == spotShadowSize
            && _cachedPointShadowSize == pointShadowSize
            && _cachedSSAO == hasSSAO
            && _cachedPost == postProcess
            && _cachedPostStages == postStages) {
            _activeQueue = queue;
            var depth = depthFormat >= 0 ? (depthFormat : TextureFormat) : null;

            if (mrt) {
                var gbufferTarget = ctx.targetPool.acquireMRT(width, height, [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], depth);
                _gbufferResources[0].target = gbufferTarget;
                gbuffer.target = gbufferTarget;
                gbuffer.width = width;
                gbuffer.height = height;
            }
            else {
                var albedo = ctx.targetPool.acquireMRT(width, height, [TextureFormat.RGBA], depth);
                var normal = ctx.targetPool.acquire(width, height);
                var emissive = ctx.targetPool.acquire(width, height);
                _gbufferResources[0].target = albedo;
                _gbufferResources[1].target = normal;
                _gbufferResources[2].target = emissive;
                gbuffer.albedo = albedo;
                gbuffer.normal = normal;
                gbuffer.emissive = emissive;
                gbuffer.width = width;
                gbuffer.height = height;
            }

            _sceneColor.target = ctx.targetPool.acquire(width, height, sceneFormat);
            _finalColor.target = ctx.targetPool.acquire(width, height, sceneFormat);
            for (resource in _shadowResources) {
                resource.target = ctx.targetPool.acquireMRT(shadowMapSize, shadowMapSize, [TextureFormat.RGBA], TextureFormat.Depth24);
            }
            if (_spotShadowResource != null) {
                _spotShadowResource.target = ctx.targetPool.acquireMRT(spotShadowSize * 2, spotShadowSize, [TextureFormat.RGBA], TextureFormat.Depth24);
            }
            if (_pointShadowResource != null) {
                _pointShadowResource.target = ctx.targetPool.acquireMRT(pointShadowSize * 4, pointShadowSize * 3, [TextureFormat.RGBA], TextureFormat.Depth24);
            }
            if (_ssaoResource != null) {
                _ssaoResource.target = ctx.targetPool.acquire(width, height);
            }
            for (i in 0..._postResources.length) {
                _postResources[i].target = ctx.targetPool.acquire(width, height, postProcess.stages[i].format);
            }
            return _graph;
        }

        if (_graph != null) {
            _graph.releaseTransients(ctx.targetPool);
            _graph.dispose();
            _graph = null;
        }

        var graph = new RenderGraph();

        var gbuffer:GBuffer;
        var gbufferResources:Array<RenderGraphResource> = [];
        var depth = depthFormat >= 0 ? (depthFormat : TextureFormat) : null;

        if (mrt) {
            var gbufferTarget = ctx.targetPool.acquireMRT(width, height, [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], depth);
            var gbufferResource = graph.createResource("GBuffer", gbufferTarget);
            gbufferResources.push(gbufferResource);
            gbuffer = GBuffer.fromMRT(gbufferTarget);
        }
        else {
            var albedo = graph.createResource("GBufferAlbedo", ctx.targetPool.acquireMRT(width, height, [TextureFormat.RGBA], depth));
            var normal = graph.createResource("GBufferNormal", ctx.targetPool.acquire(width, height));
            var emissive = graph.createResource("GBufferEmissive", ctx.targetPool.acquire(width, height));
            gbufferResources.push(albedo);
            gbufferResources.push(normal);
            gbufferResources.push(emissive);
            gbuffer = new GBuffer(albedo.target, normal.target, emissive.target, width, height);
        }
        this.gbuffer = gbuffer;

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
            spotShadowResource = graph.createResource("SpotShadowAtlas",
                ctx.targetPool.acquireMRT(spotShadowSize * 2, spotShadowSize, [TextureFormat.RGBA], TextureFormat.Depth24));
            pointShadowResource = graph.createResource("PointShadowAtlas",
                ctx.targetPool.acquireMRT(pointShadowSize * 4, pointShadowSize * 3, [TextureFormat.RGBA], TextureFormat.Depth24));
        }

        var ssaoResource:RenderGraphResource = null;
        if (hasSSAO) {
            ssaoResource = graph.createResource("SSAO", ctx.targetPool.acquire(width, height));
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

        var sceneColor = graph.createResource("SceneColorHDR", ctx.targetPool.acquire(width, height, sceneFormat));
        // Keep the opaque-lit color in HDR: transparent blending and the post
        // chain (tonemap/bloom) must operate before any LDR clamp.
        var finalColor = graph.createResource("FinalColor", ctx.targetPool.acquire(width, height, sceneFormat));

        var gbufferPass = new CallbackPass("GBufferPass", function(frame:FrameContext) {
            if (mrt) {
                gbuffer.bindGBuffer(frame.context);
            }
            if (renderGBuffer != null) {
                renderGBuffer(_activeQueue, frame, gbuffer);
            }
            frame.context.setRenderToBackBuffer();
        });
        for (resource in gbufferResources) {
            gbufferPass.write(resource);
        }
        graph.addPass(gbufferPass);

        if (ssaoResource != null) {
            var ssaoPass = new CallbackPass("SSAOPass", function(frame:FrameContext) {
                frame.aoMap = ssaoResource.target;
                ssaoRenderer.render(gbuffer, ssaoResource.target, frame);
            });
            for (resource in gbufferResources) {
                ssaoPass.read(resource);
            }
            ssaoPass.write(ssaoResource);
            graph.addPass(ssaoPass);
        }

        var lightingPass = new CallbackPass("DeferredLightingPass", function(frame:FrameContext) {
            sceneColor.target.bind(frame.context, false);
            if (renderLighting != null) {
                renderLighting(frame, gbuffer, sceneColor.target);
            }
            sceneColor.target.unbind(frame.context);
        });
        for (resource in gbufferResources) {
            lightingPass.read(resource);
        }
        if (shadowResources.length > 0) {
            for (resource in shadowResources) {
                lightingPass.read(resource);
            }
        }
        if (spotShadowResource != null) {
            lightingPass.read(spotShadowResource);
        }
        if (pointShadowResource != null) {
            lightingPass.read(pointShadowResource);
        }
        if (ssaoResource != null) {
            lightingPass.read(ssaoResource);
        }
        lightingPass.write(sceneColor);
        graph.addPass(lightingPass);

        var transparentPass = new CallbackPass("ForwardTransparentPass", function(frame:FrameContext) {
            finalColor.target.bind(frame.context, true);
            frame.context.clear(0.0, 0.0, 0.0, 1.0, 1.0, 0);
            if (renderTransparent != null) {
                renderTransparent(_activeQueue, frame, sceneColor.target, finalColor.target);
            }
            else {
                if (_copier == null) {
                    _copier = new FullscreenEffect(frame.context, "DeferredSceneCopy", PBRShaderLibrary.presentFragment());
                }
                _copier.render(finalColor.target, function(effect:FullscreenEffect) {
                    effect.setTexture("uColorMap", sceneColor.target.color);
                });
            }
            finalColor.target.unbind(frame.context);
        });
        transparentPass.read(sceneColor).write(finalColor);
        graph.addPass(transparentPass);

        _postResources = [];
        if (postStages > 0) {
            var postOutput = postProcess.build(graph, finalColor, ctx, _postResources);
            graph.setOutput(postOutput);
        }
        else {
            graph.setOutput(finalColor);
        }

        _graph = graph;
        _gbufferResources = gbufferResources;
        _sceneColor = sceneColor;
        _finalColor = finalColor;
        _shadowResources = shadowResources;
        _spotShadowResource = spotShadowResource;
        _pointShadowResource = pointShadowResource;
        _ssaoResource = ssaoResource;
        _shadowResource = shadowResources.length > 0 ? shadowResources[0] : null;
        _activeQueue = queue;
        _cachedWidth = width;
        _cachedHeight = height;
        _cachedSceneFormat = sceneFormat;
        _cachedMrt = mrt;
        _cachedDepthFormat = depthFormat;
        _cachedShadow = hasShadow;
        _cachedShadowSize = shadowMapSize;
        _cachedShadowCount = cascadeCount;
        _cachedLocalShadows = hasLocal;
        _cachedSpotShadowSize = spotShadowSize;
        _cachedPointShadowSize = pointShadowSize;
        _cachedSSAO = hasSSAO;
        _cachedPost = postProcess;
        _cachedPostStages = postStages;
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
        if (_graph != null) {
            _graph.dispose();
            _graph = null;
        }
        if (_copier != null) {
            _copier.dispose();
            _copier = null;
        }
        gbuffer = null;
        _gbufferResources = null;
        _sceneColor = null;
        _finalColor = null;
        _shadowResource = null;
        _shadowResources = null;
        _spotShadowResource = null;
        _pointShadowResource = null;
        _pointCubes = [];
        _ssaoResource = null;
        _postResources = null;
        _activeQueue = null;
        renderGBuffer = null;
        renderLighting = null;
        renderTransparent = null;
        postProcess = null;
        shadowRenderer = null;
        super.dispose();
    }
}
