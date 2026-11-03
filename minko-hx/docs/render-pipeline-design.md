# minko 新渲染管线设计

> 目标：在现有 minko Haxe 架构上，新增一套可同时支持 **Forward PBR**、**G-Buffer 延迟光照** 和 **后处理链** 的渲染管线。
>
> 本文是架构与实现设计，不是当前代码的现状说明。旧 `Renderer` / `DrawCallPool` 路径已删除，当前实现只保留新管线。

## 1. 设计范围

### 1.1 目标

- **Forward PBR**
  - metallic/roughness PBR；
  - 方向光、点光、聚光灯；
  - 阴影；
  - 透明物体排序；
  - IBL 作为可选能力。

- **G-Buffer Deferred**
  - opaque G-Buffer pass；
  - 延迟 PBR 光照 pass；
  - 透明物体走 forward pass；
  - 无 MRT 时自动降级为多 pass G-Buffer。

- **后处理**
  - HDR scene color；
  - Bloom；
  - Tone mapping；
  - Color grading；
  - FXAA；
  - 可选 SSAO。

- **RenderGraph**
  - pass 资源依赖；
  - transient RenderTarget 分配和复用；
  - pass 裁剪和排序；
  - 每帧执行计划缓存。

- **跨后端**
  - HashLink/OpenGL；
  - WebGL1/WebGL2；
  - 基于 `Capabilities` 自动选择路径和 fallback。

### 1.2 非目标

- 不在本轮实现 compute shader / GPU 光源剔除。
- 不要求 Forward+ 作为首版必需能力。
- 不实现旧 `Effect` / `Pass` / `BindingMap` / `ProgramSignature` 兼容层。
- 不实现 Vulkan/Metal/D3D12 后端。
- MSAA 暂缓，先用 FXAA。

## 2. 现有约束

当前 `minko-backend`：

- `AbstractContext.setRenderToTexture(texture)` 只支持单颜色附件；
- 没有 RenderTarget 资源抽象；
- 没有 MRT；
- 没有 depth texture 采样 API；
- `TextureFormat` 只有 RGB/RGBA 和压缩格式；
- 没有浮点 RenderTarget 格式；
- Shader 固定 `#version 100`（JS）或 `#version 120`（HL）；
- 没有 compute shader；
- `Effect` 是 technique/pass 模型，不表达 pass 间资源依赖。

因此新管线必须：

1. 先扩展 backend 的 RenderTarget/MRT/Depth/HDR 能力；
2. 在 `minko-hx` 新增 RenderGraph，而不是继续把所有逻辑堆进 `Renderer`；
3. 在不支持高级能力的平台上提供明确的 fallback。

## 3. 总体架构

```text
Scene / Node / Surface / Material
              │
              ▼
      RenderCollector
              │  RenderItem[]
              ▼
        RenderQueue
   ┌──────────┼───────────┬──────────────┐
   │          │           │              │
shadow     opaque     alphaTest      transparent
   │          │           │              │
   └──────────┴─────┬─────┴──────────────┘
                    ▼
             RenderPipeline
                    │
          ┌─────────┴─────────┐
          │                   │
   ForwardPBRPath      DeferredPBRPath
          │                   │
          └─────────┬─────────┘
                    ▼
               RenderGraph
     ┌──────────────┼────────────────┐
     │              │                │
 ShadowPass     GBufferPass     PostProcess
     │              │                │
     └──────────────┴────────────────┘
                    ▼
              FrameContext
                    ▼
             minko-backend
```

### 3.1 模块划分

```text
minko-hx/src/minko/render/pipeline/
  RenderPipeline.hx
  RenderPath.hx
  RenderGraph.hx
  RenderGraphResource.hx
  RenderPass.hx
  FrameContext.hx
  RenderQueue.hx
  RenderItem.hx
  ForwardPath.hx
  ForwardPBRPath.hx
  ForwardEffectRenderer.hx
  DeferredPBRPath.hx
  PostProcessChain.hx
  EffectStage.hx
  PipelineEffect.hx
  PipelineTechnique.hx
  PipelineUniform.hx
  UniformSource.hx
  PipelineState.hx
  PipelineEffectRenderer.hx

minko-hx/src/minko/material/
  Material.hx
  PhongMaterial.hx
  PBRMaterial.hx

minko-hx/src/minko/render/pbr/
  PBRShaderLibrary.hx
  PBRUniforms.hx
  BRDF.hx

minko-hx/src/minko/render/light/
  Light.hx
  LightType.hx
  LightSet.hx

minko-hx/src/minko/render/target/
  RenderTargetPool.hx
  GBuffer.hx
  FullscreenPass.hx
```

## 4. Backend 扩展

### 4.1 RenderTarget

新增低层资源：

```haxe
enum TextureFormat {
    RGBA8;
    RGBA16F;
    RGBA32F;
    R8;
    RG16F;
    Depth24;
    Depth32F;
}

enum DepthAttachment {
    None;
    Renderbuffer;
    Texture;
}

class RenderTargetDesc {
    public var width:Int;
    public var height:Int;
    public var colors:Array<TextureFormat>;
    public var depth:DepthAttachment;
    public var mipmaps:Bool;
    public var samples:Int;
}

class RenderTarget {
    public var id:Int;
    public var colors:Array<AbstractTexture>;
    public var depth:AbstractTexture;
    public var width:Int;
    public var height:Int;
}
```

`AbstractContext` 新增：

```haxe
createRenderTarget(desc:RenderTargetDesc):RenderTarget;
deleteRenderTarget(target:RenderTarget):Void;
setRenderTarget(target:RenderTarget):Void;
setRenderTargets(targets:Array<RenderTarget>):Void;
```

兼容：

- `setRenderToTexture(texture)` 保留，内部包装为单颜色 RenderTarget。

### 4.2 MRT

优先级：

1. **WebGL2 / OpenGL 3.2+**
   - 多颜色附件；
   - `glDrawBuffers`；
   - fragment shader 使用 `layout(location = N) out`。

2. **WebGL1 + WEBGL_draw_buffers**
   - `gl_FragData[N]`；
   - 扩展检测失败则不启用 MRT。

3. **无 MRT**
   - 优先 Forward PBR；
   - 如果用户强制 Deferred，则使用多 pass G-Buffer：

```text
Pass A → albedo/AO
Pass B → normal/roughness/metallic
Pass C → emissive/material id/depth
```

每个 pass 都需要重新绘制 geometry，性能较低，但功能可用。

### 4.3 Depth Texture

用于：

- 从 G-Buffer 重建 world position；
- SSAO；
- 软粒子/深度雾；
- Shadow map 采样。

不支持 depth texture 时：

- G-Buffer 增加一个线性深度颜色附件；
- 或使用 GBuffer2.a 存线性深度。

### 4.4 HDR

- PBR 光照、Bloom 需要 `RGBA16F`；
- 无浮点 RTT 时：
  - 使用 `RGBA8`；
  - 将曝光/tonemap 前置；
  - 限制 Bloom 强度。

### 4.5 Capabilities

```haxe
class RenderCapabilities {
    public var maxColorAttachments:Int;
    public var maxTextureUnits:Int;
    public var supportsMRT:Bool;
    public var supportsDepthTexture:Bool;
    public var supportsFloatRenderTarget:Bool;
    public var glslVersion:Int;
}
```

由 `AbstractContext` 暴露，Pipeline 在初始化时选择：

| 能力 | 选择 |
|---|---|
| MRT + depth + float | Deferred HDR |
| MRT + depth | Deferred LDR |
| 无 MRT | Forward PBR 或 multipass Deferred |
| 无 depth texture | 写线性深度颜色附件 |

## 5. RenderGraph

### 5.1 Resource

```haxe
class RenderGraphResource {
    public var name:String;
    public var desc:RenderTargetDesc;
    public var target:RenderTarget;
    public var transient:Bool;
}
```

尺寸策略：

```haxe
enum SizePolicy {
    Screen;
    ScreenScale(scale:Float);
    Fixed(width:Int, height:Int);
}
```

### 5.2 RenderPass

```haxe
class RenderPass {
    public var name:String;
    public var inputs:Array<RenderGraphResource>;
    public var outputs:Array<RenderGraphResource>;

    public function execute(ctx:FrameContext):Void;
}
```

### 5.3 Graph 编译

```text
RenderGraph.compile(finalOutput)
  1. 从 finalOutput 反向遍历 pass
  2. 删除无贡献 pass
  3. 拓扑排序
  4. 分配 transient RenderTarget
  5. 按尺寸/格式复用资源
  6. 生成不可变执行列表
```

`RenderTargetPool` 跨帧复用：

- key = (width, height, formats, depth)；
- resize 时重建；
- 一帧结束归还，而非立即 destroy。

### 5.4 FrameContext

```haxe
class FrameContext {
    public var context:AbstractContext;
    public var camera:CameraData;
    public var lights:LightSet;
    public var queue:RenderQueue;
    public var graph:RenderGraph;
    public var time:Float;
    public var frameId:Int;
}
```

## 6. RenderQueue

### 6.1 RenderItem

```haxe
class RenderItem {
    public var geometry:Geometry;
    public var material:Material;
    public var effect:Effect;
    public var worldMatrix:Mat4;
    public var bounds:Bounds;
    public var layerMask:Int;
    public var renderPathMask:Int;
    public var castShadow:Bool;
    public var receiveShadow:Bool;
}
```

### 6.2 分组

```text
RenderQueue
  shadowCasters
  depthOpaque
  gbufferOpaque
  forwardOpaque
  forwardAlphaTest
  transparent
```

排序规则：

- opaque：按 material/program 分组，降低状态切换；
- transparent：按 view-space depth 从远到近；
- shadow：按 shadow map / light 分组。

### 6.3 与现有 Effect / Pass 的关系

新管线不再使用 `Effect` / `Pass` / `ProgramSignature` / `BindingMap` /
`DrawCall`。它使用独立的 pipeline effect 抽象：

- `EffectStage`：`Forward` / `Transparent` / `GBuffer` / `Shadow`；
- `PipelineTechnique`：一个 stage + 一对 vertex/fragment source + uniform 列表 + state；
- `PipelineEffect`：technique 集合，按 stage 选择；
- `PipelineEffectRenderer`：编译缓存、uniform 解析、state、geometry 属性绑定和 draw。

`Surface` 只保留 `pipelineEffect`，旧 `effect` 字段已随旧 Renderer 删除。

详见 `docs/effect-pipeline-wiring.md`。新管线不再由 `DrawCallPool` 决定帧顺序。

## 7. Forward PBR 路径

### 7.1 资源

```text
SceneColorHDR : RGBA16F (fallback RGBA8)
SceneDepth    : Depth24 / depth texture
ShadowMaps    : depth texture 或 R32F color
```

### 7.2 Pass 顺序

```text
1. ShadowPass
2. DepthPrepass（可选）
3. ForwardOpaquePass
4. ForwardAlphaTestPass
5. TransparentPass
6. PostProcessChain
```

### 7.3 光照

首版支持：

- DirectionalLight：1~4；
- PointLight：最多 N 个；
- SpotLight：最多 N 个；
- ambient / IBL 可选。

PBR 参数：

```text
baseColor
metallic
roughness
emissive
normal
occlusion
alphaMode
doubleSided
```

### 7.4 阴影

- 方向光：CSM 可选；首版单张 shadow map；
- 聚光灯：单张 shadow map；
- 点光：首版用 forward 无阴影，后续 cubemap shadow。

### 7.5 Forward+ 扩展

无 compute shader，Forward+ 采用：

- CPU 端 tile 光源剔除；
- 每 tile 生成 light index；
- 通过 uniform 数组或小纹理传 shader。

Forward+ 不阻塞 Forward PBR 首版。

### 7.6 非 PBR Forward

`ForwardPath` 是与 PBR 无关的通用 forward path：它只负责 scene color、可选
shadow 和 post chain，场景绘制由 callback 提供。`ForwardPBRPath` 是它保留
历史名称/pass 名的薄子类。

非 PBR 绘制使用 `ForwardEffectRenderer`：

```haxe
var forwardFx = new ForwardEffectRenderer(context);
var path = new ForwardPath(function(q, f, t) forwardFx.render(q, f, t), null, "forward-effect");
```

- `ForwardEffectRenderer` 只使用 `RenderItem.pipelineEffect`，不做 PBR fallback。- `opaque` / `alphaTest` 使用 `EffectStage.Forward`，`transparent` 使用
  `EffectStage.Transparent`。
- 没有 effect 的 item 默认跳过，可通过 `defaultEffect` 提供统一默认效果。
- 缺对应 stage technique 时静默跳过。

## 8. Deferred G-Buffer 路径

### 8.1 G-Buffer 布局

首版 3 颜色附件：

| Attachment | 格式 | 内容 |
|---|---|---|
| GBuffer0 | RGBA8 | albedo.rgb + AO |
| GBuffer1 | RGBA8 | octahedral normal.xy + roughness + metallic |
| GBuffer2 | RGBA8 | emissive.rgb + material/shading model |
| Depth | Depth24/Depth32F | 深度 |

没有 depth texture 时：

- GBuffer2.a 存线性深度；或
- 增加 GBuffer3 `R32F` 线性深度。

### 8.2 Pass 顺序

```text
1. ShadowPass
2. DepthPrepass（可选）
3. GBufferPass
4. SSAO（可选）
5. DeferredLightingPass
6. ForwardTransparentPass
7. PostProcessChain
```

### 8.3 Lighting

- 从 depth 重建 world position；
- 从 G-Buffer 读取 PBR 参数；
- 方向光/点光/聚光灯；
- 输出 HDR SceneColor；
- 透明物体随后走 forward PBR。

## 9. 后处理

### 9.1 链

```text
SceneColorHDR
  → Bloom
  → ToneMapping
  → ColorGrading
  → FXAA
  → FinalLDR
```

### 9.2 FullscreenPass

```haxe
class FullscreenPass extends RenderPass {
    public var effect:Effect;
    public var material:Material;
}
```

复用现有 fullscreen quad 几何；  
每个后处理是一个 RenderGraph pass，输入/输出纹理由 graph 管理。

### 9.3 Bloom

- 多级 downsample；
- 每级尺寸为上一级 1/2；
- RenderTargetPool 复用；
- 上采样合成；
- 支持阈值/强度/半径。

### 9.4 MSAA

暂不实现；先使用 FXAA。  
后续给 `RenderTargetDesc.samples` 增加 MSAA resolve。

## 10. 材质与 Shader

### 10.1 EffectStage

新管线使用 `EffectStage`：

```haxe
enum abstract EffectStage(Int) {
    var Forward;
    var Transparent;
    var GBuffer;
    var Shadow;
}
```

一个 `PipelineTechnique` 直接携带 stage，不通过 technique 名或 Pass 选择：

```haxe
class PipelineTechnique {
    public var stage:EffectStage;
    public var vertexSource:String;
    public var fragmentSource:String;
    public var uniforms:Array<PipelineUniform>;
    public var state:PipelineState;
}
```

后续可扩展 `Lighting` / `PostProcess`，但本轮不接。

### 10.2 Shader source

内置 PBR shader 仍由 `PBRShaderLibrary` 提供源码。自定义 `PipelineEffect`
可以直接在代码中构造，也可以从 `.peffect` JSON 文件加载：

```haxe
var technique = new PipelineTechnique(
    EffectStage.Forward,
    vertexSource,
    fragmentSource,
    uniforms,
    PipelineState.opaque()
);
```

`.peffect` 由 `minko.file.PipelineEffectParser` 解析，默认注册在 `.peffect`
扩展名上，结果通过 `AssetLibrary.pipelineEffect(filename)` 取得。vertex/fragment
可以是内联字符串或 `{ "file": "..." }` 外部文件；source 支持递归
`#pragma include "..."`；顶层/technique `macros` 会在编译时生成 `#define`。
格式说明见 `docs/effect-pipeline-wiring.md`。

共享 GLSL：

```text
BRDF
OctahedralEncode/Decode
DepthReconstruct
Tonemap
Gamma
```

### 10.3 兼容 GLSL 100/120

- 使用 `texture2D`；
- 不使用 UBO；
- MRT 在 GLSL 120 用 `gl_FragData`；
- WebGL2 使用 `layout`；
- 浮点纹理通过扩展/能力判断。

## 11. Renderer 集成

新增：

```haxe
@:expose("minko.component.PipelineRenderer")
class PipelineRenderer extends AbstractComponent {
    public var pipeline:RenderPipeline;
    public var camera:PerspectiveCamera;
}
```

职责：

1. 收集 Surface / RenderItem；
2. 构建 RenderQueue；
3. 选择 RenderPath；
4. 构建 RenderGraph；
5. 执行；
6. 输出 backbuffer / final target。

场景图入口：

- `minko.component.PBRRenderer` 负责 SceneManager 接线、相机与 Surface 收集；
- `PipelineRenderer` 负责构建队列、选择路径、构建并执行 RenderGraph。

## 12. 帧工作流

```text
SceneManager.render
  → PipelineRenderer.render
      → RenderCollector.collect()
      → RenderQueue.build()
      → RenderPipeline.selectPath()
      → RenderGraph.build()
      → graph.execute(FrameContext)
          → ShadowPass
          → GBufferPass / ForwardOpaquePass
          → LightingPass
          → ForwardTransparentPass
          → PostProcessChain
      → context.present()
```

## 13. 资源生命周期

- RenderTarget 由 RenderTargetPool 持有；
- RenderGraph 只持有 transient 引用；
- Program 由 Pass/PassPrograms 持有；
- RenderItem 不拥有 Geometry/Material；
- 每帧结束重置 transient 状态，不 destroy；
- resize 时统一重建尺寸相关资源。

## 14. 分阶段实施

### Phase 0：Backend

- TextureFormat 扩展；
- RenderTarget / RenderTargetDesc；
- Capabilities；
- Depth texture；
- MRT；
- GL/WebGL 实现；
- 单颜色 + depth 测试。

### Phase 1：Graph + Queue + Fullscreen

- RenderGraph；
- RenderTargetPool；
- RenderQueue / RenderItem；
- FullscreenPass；
- 用现有 forward shader 跑通“场景 → HDR target → 后处理 → backbuffer”。

### Phase 2：Forward PBR

- PBRMaterial；
- 方向光/点光/聚光灯；
- PBR forward shader；
- 透明排序；
- shadow map；
- IBL 可选。

### Phase 3：Deferred

- GBuffer；
- GBufferPass；
- DeferredLightingPass；
- 无 MRT fallback；
- transparent forward。

### Phase 4：Post

- Bloom；
- ToneMapping；
- ColorGrading；
- FXAA；
- SSAO 可选。

### Phase 5：Forward+（可选）

- CPU tile light culling；
- light index 数据上传；
- 大规模点光源。

## 15. 验收标准

### 功能

- Forward PBR 场景可运行；
- Deferred 场景可运行；
- 透明物体在两种路径下都正确；
- Bloom/Tonemap/FXAA 可开关；
- G-Buffer 调试视图（albedo/normal/depth/lighting）。

### 兼容

- HL 运行；
- WebGL1 无扩展时自动 forward；
- WebGL2 使用 MRT；
- `PBRRenderer` 覆盖 SceneManager 驱动的 PBR forward 场景。

### 性能

- RenderGraph 编译结果缓存；
- RenderTargetPool 稳态零分配；
- update 无每帧全量扫描；
- 1000+ RenderItem 可运行；
- 提供基准场景。

## 16. 风险

1. Backend MRT/depth/HDR 改动大，需要双后端实现。
2. GLSL 100/120 能力有限，shader 需要多版本。
3. 无 compute shader，Forward+ 只能 CPU tile。
4. Deferred 与 transparent/forward 混合需要材质双 variant。
5. RenderGraph 与现有 Effect/Pass 的职责边界需要严格控制。
6. 需要真实场景和帧时间数据，不能只以构建通过作为性能验收。

## 17. 推荐落地顺序

1. Backend RenderTarget + Capabilities；
2. RenderGraph + RenderTargetPool + Fullscreen post；
3. Forward PBR；
4. Deferred G-Buffer；
5. Forward+ 与高级后处理。

## 18. Implementation status

The following pieces are present in the tree:

- backend `RenderTarget` with multi-color attachments and depth attachment:
  - `minko-backend/src/minko/render/RenderTarget.hx`
  - `AbstractContext.createRenderTarget/deleteRenderTarget/setRenderTarget`
  - SDL/OpenGL implementation in `SDLGLContext.hx`
  - single-target WebGL fallback in `GlContext.hx`
- `RGBA16F`, `RGBA32F`, `R8`, `RG16F`, `Depth24`, `Depth32F` texture formats.
- `RenderTargetPool` with `acquire`, `acquireMRT`, depth attachment support and reuse.
- `GBuffer` supporting native MRT and three-target fallback.
- `RenderGraph`, `RenderPass`, `RenderPath`, `RenderPipeline`, `RenderQueue`, `PostProcessChain`.
- `ForwardPath` and `ForwardPBRPath` (PBR path is a compatibility subclass);
  the path caches its graph/passes across frames and reacquires transient
  targets from the pool.
- `DeferredPBRPath` caches its G-buffer/shadow/color/post passes and reacquires
  per-frame targets; it also exposes `depthTexture` for point/spot lighting.
- `ForwardEffectRenderer`: non-PBR forward renderer that draws only
  `PipelineEffect` items (optional `defaultEffect`, no PBR fallback).
- `PBRMaterial`, `Light`, `LightSet`, `RenderCapabilities`.
- `PBRForwardRenderer`: actual forward PBR draw using `PBRShaderLibrary` shaders.
- `PhongForwardRenderer`: forward Blinn-Phong draw using `PhongMaterial` and
  `PhongShaderLibrary`; supports the same lights, single shadow map and
  tangent-space normal maps.
- `ForwardPhongPath`: `ForwardPath` specialization for the Phong pass.
- `minko.component.PhongRenderer`: SceneManager-driven Phong component.
- `GBufferRenderer`: writes albedo/normal/emissive G-Buffer via `gl_FragData`.
- `DeferredLightingRenderer`: fullscreen deferred lighting with directional,
  point/spot lights, optional directional shadows from reconstructed depth, and
  optional SSAO ambient occlusion.
- `FullscreenRenderer`: tonemap post-process.
- `FullscreenEffect`: generic fullscreen shader pass.
- `BloomRenderer`: bright pass + separable blur + composite.
- `FXAARenderer`: lightweight FXAA pass.
- `ShadowRenderer`: directional shadow-map pass using a depth texture; supports
  1–4 CSM cascades through `renderCascades`, plus spot 2D and point 6-face
  shadow maps.
- `SSAORenderer`: deferred screen-space ambient occlusion from depth/normal.
- `LightTileCuller`: forward+ 64×64 tile light mask for up to 32 point/spot
  lights; `PBRForwardRenderer` samples it per fragment.
- `PBRForwardRenderer` supports optional shadow map sampling, cascade sampling,
  spot/point local shadows, and a transparent-only entry point for deferred
  scene-color compositing.
- `GBufferFallbackRenderer`: multipass G-Buffer for backends without MRT;
  supports per-attachment `PipelineEffect` stages
  (`gbuffer-albedo` / `gbuffer-normal` / `gbuffer-emissive`) and automatic
  splitting of simple MRT `gl_FragData` techniques.
- `SceneCollector` and `PipelineRenderer`: scene graph collection and pipeline entry point.
- `minko.component.PBRRenderer`: scene-graph component that drives the new
  pipeline through `SceneManager`; defaults to `ForwardPBRPath` and can switch
  to `DeferredPBRPath` with `useDeferred`, exposing `pipeline`, `forwardPath`,
  `deferredPath`, lights, post-process and optional shadow config.
- `PipelineEffect` / `PipelineTechnique` / `PipelineUniform` / `PipelineState`:
  pipeline-native effect model.
- `PipelineEffectRenderer`: per-technique program cache, uniform sources, state and
  geometry attribute binding; used by `PBRForwardRenderer`, `GBufferRenderer`
  (MRT) and `ShadowRenderer`.
- `Surface.pipelineEffect` and `RenderItem.pipelineEffect`: attach a
  `PipelineEffect` to a surface/item.
- `minko.file.PipelineEffectParser` (`.peffect`): parses JSON shader/uniform/state
  definitions into `PipelineEffect`; supports external shader files,
  `#pragma include` and compile-time macros. Stored through
  `AssetLibrary.pipelineEffect`.

Runtime checks performed with temporary HashLink programs:

```text
MRT_OK colors=2
TARGET_OK
PATH_OK
FORWARD_OK
PBR_RUNTIME_OK
FULLSCREEN_OK
DEFERRED_LIGHTING_OK
DEFERRED_PIPELINE_OK
SCENE_PIPELINE_OK
POSTFX_OK
PBR_POINT_OK
SHADOW_OK
SHADOW_PIPELINE_OK
GBUFFER_FALLBACK_OK
FULL_POST_OK
PRESENT_OK
BENCH_OK drawCalls=1000 frames=30 avgMs=7.25
WINDOW_CUBE_OK (PipelineMain demo: PBR cube visible on screen)
LIGHT_TEST PASS (directional front 0.22 vs back 0.007; point near 0.167 vs far 0.007; 4 point lights 0.099)
```

### Backend quirks discovered during debugging

- `AbstractTexture` rounds GPU sizes up to power-of-two (`clp2`); render target
  pools must request POT sizes or presented content samples undefined texels.
- The shader compiler rewrites scalar `float` uniforms into `vec4` and rewrites
  their usage sites with `.x`; `int` uniforms are left untouched and fail
  silently with the float upload path (`uniform4fv` type mismatch). All shader
  flags/counters therefore use `float` uniforms.
- Array uniforms are registered with a `[0]` suffix in the program input list;
  lookups must try `name` and `name + "[0]"`.
- `hlsdl` implements only a subset of `sdl.GL` (`blitFramebuffer` and several
  other functions are empty stubs); WebGL (`GlContext`) implements the same
  API surface correctly.

### Window presentation notes

- RTT textures allocated through `Texture` are always power-of-two on the GPU
  (`AbstractTexture` applies `clp2`). `RenderTargetPool` therefore rounds its
  targets up to POT so the FBO attachment, viewport and sampled UV 0..1 range
  cover exactly the same area; non-POT targets sampled as black when presented.
- `setRenderToBackBuffer` always rebinds the default framebuffer (the native
  render-target path leaves the FBO-bound state otherwise).
- `drawTriangles` resets the cached index buffer after unbinding the element
  array, otherwise the next indexed draw reuses a stale binding.
- Fullscreen passes disable depth test and culling; the scene target is
  cleared after bind in `ForwardPBRPath`.
- The demo renders at the canvas size and updates the projection on resize.

Still missing for a complete product pipeline:

- multi-pass / post-process PipelineEffect stages (Lighting, PostProcess);
- macros / program variants for PipelineEffect;
- point-light arrays and custom vertex attribute names for PipelineEffect;
- material/texture normal maps, IBL;
- WebGL2 MRT and HDR capability detection runtime verification;
- visual regression tests.

