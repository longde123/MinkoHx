# Pipeline Effect 接线

新渲染管线使用 `minko.render.pipeline.PipelineEffect`。旧 `Effect` / `Pass` /
`ProgramSignature` / `BindingMap` / `DrawCall` 路径已删除；通用 `Store` /
`Provider` 数据模型也已移除，场景状态由 `Transform` / `PerspectiveCamera` /
`Geometry` / `Material` 直接持有。

## 1. 模型

```haxe
enum EffectStage {
    Forward;
    Transparent;
    GBuffer;
    Shadow;
    GBufferAlbedo;    // no-MRT fallback, single gl_FragColor
    GBufferNormal;
    GBufferEmissive;
}

class PipelineTechnique {
    public var stage:EffectStage;
    public var vertexSource:String;
    public var fragmentSource:String;
    public var uniforms:Array<PipelineUniform>;
    public var state:PipelineState;
}

class PipelineEffect {
    public var name:String;
    public var techniques:Array<PipelineTechnique>;
    public function addTechnique(technique:PipelineTechnique):PipelineTechnique;
    public function techniqueFor(stage:EffectStage):PipelineTechnique;
}

class PipelineUniform {
    public var name:String;
    public var source:UniformSource;
}

class PipelineState {
    public var depthTest:Bool;
    public var depthWrite:Bool;
    public var colorMask:Bool;
    public var triangleCulling:TriangleCulling;
    public var blendingSource:Blending.Source;
    public var blendingDestination:Blending.Destination;
    public static function opaque():PipelineState;
    public static function transparent():PipelineState;
}
```

一个 technique 对应 **一个 stage + 一个 program**，没有 pass 概念。同一
`PipelineEffect` 最多为一个 stage 保留一个 technique（取第一个匹配项）。

`GBuffer` stage 用于原生 MRT：一个 shader 写 `gl_FragData[0..2]`。无 MRT 的
fallback 使用三个单输出 stage：

```text
gbuffer-albedo   -> gl_FragColor 写 albedo target
gbuffer-normal   -> gl_FragColor 写 normal target
gbuffer-emissive -> gl_FragColor 写 emissive target
```

fallback 对缺少的 stage 继续走 PBR fallback；这样同一个 effect 在 MRT 后端
可以只提供 `gbuffer`，在 fallback 后端可以按需提供三个单输出 technique。

如果只提供 MRT `gbuffer` technique，`PipelineEffectFallbackCompiler` 会把
简单的顶层 `gl_FragData[N] = expr;` 自动拆成三个 `gl_FragColor` variant；
控制流内写入或无法安全拆分的 shader 会回退到 PBR G-buffer。

shader 源不要写 `#version`；`Shader` 会按后端追加（HL 为 120，WebGL 为 100）。

## 2. 使用

```haxe
var effect = PipelineEffect.create("tint");

var uniforms = [
    new PipelineUniform("modelMatrix", UniformSource.ModelMatrix),
    new PipelineUniform("viewMatrix", UniformSource.ViewMatrix),
    new PipelineUniform("projectionMatrix", UniformSource.ProjectionMatrix),
    PipelineUniform.material("uTint", "tint")
];

effect.addTechnique(new PipelineTechnique(
    EffectStage.Forward,
    vertexSource,
    fragmentSource,
    uniforms,
    PipelineState.opaque()
));

surface.pipelineEffect = effect;
```

`Surface.pipelineEffect` 是新管线读取的 effect 字段。直接构造 `RenderItem` 时也可手动赋值：

```haxe
var item = new RenderItem(geometry, material, null, world);
item.pipelineEffect = effect;
```

### 2.1 从 `.peffect` 文件加载

`PipelineEffectParser` 默认注册在 `.peffect` 扩展名上。文件格式：

```json
{
  "name": "pipeline-tint",
  "macros": {
    "USE_GREEN": true,
    "MAX_LIGHTS": 4
  },
  "techniques": [
    {
      "stage": "forward",
      "vertexShader": { "file": "shaders/tint.vert" },
      "fragmentShader": { "file": "shaders/tint.frag" },
      "macros": {
        "MODE": "PBR"
      },
      "uniforms": {
        "modelMatrix": { "source": "modelMatrix" },
        "viewMatrix": { "source": "viewMatrix" },
        "projectionMatrix": { "source": "projectionMatrix" },
        "uTint": { "material": "tint" },
        "uScale": { "value": 2.0 },
        "uColor": { "value": [1.0, 0.5, 0.2] }
      },
      "states": {
        "blending": "alpha",
        "triangleCulling": "none",
        "depthTest": true,
        "depthWrite": true,
        "colorMask": true
      }
    }
  ]
}
```

- `techniques` 非空；`stage` 为 `forward` / `transparent` / `gbuffer` / `shadow`。
  同一 stage 不能重复。
- `vertexShader` / `fragmentShader` 可以是：
  - 内联 source 字符串；
  - `{ "file": "shaders/tint.vert" }` 外部文件，路径相对 `.peffect` 所在目录。
- 外部文件与内联 source 都支持 `#pragma include "common.glsl"`；递归展开，
  相对当前 shader 目录解析，找不到时回退 `Options.includePaths`。
- `macros` 可在顶层和 technique 上出现；顶层宏应用到所有 technique，technique
  同名宏覆盖顶层。`false` / `null` 表示不生成 define。
- `uniforms` 每个值必须且只能是以下之一：
  - `{ "source": "<name>" }`，name 见下一节；
  - `{ "material": "<property>" }`；
  - `{ "value": <JSON scalar/array> }`。
- `states` 可选，缺省为 opaque；`blending` 支持 `default` / `alpha` / `additive`，
  `triangleCulling` 支持 `none` / `front` / `back` / `both`。

外部 fragment 示例：

```glsl
#pragma include "common.glsl"

uniform vec4 uTint;

void main() {
    gl_FragColor = uTint * luminance(uTint.rgb);
}
```

macro 编译时会生成：

```glsl
#define USE_GREEN
#define MAX_LIGHTS 4
#define MODE PBR
```

支持 `#ifdef` / `#if`；macro 是编译期静态配置，不支持运行时切换。

加载：

```haxe
var loader = Loader.createbyOptions(options);
loader.queue("effect/tint.peffect").load();

// 加载完成后：
var loaded = options.assetLibrary.pipelineEffect("effect/tint.peffect");
surface.pipelineEffect = loaded;
```

`AssetLibrary` 也提供 `numPipelineEffects`、`setPipelineEffect()` 和
`pipelineEffectName()`。解析失败（缺文件、缺失 include、循环 include、非法
macro）时 parser 通过 `_error` 上报，不会存入 library。

## 3. UniformSource

| 值 | 来源 |
| --- | --- |
| `MaterialProperty("tint")` | `item.material.get("tint")`，数值或纹理 |
| `Constant(value)` | 固定值 |
| `ModelMatrix` | `item.worldMatrix` |
| `NormalMatrix` | `transpose(inverse(world))` |
| `ViewMatrix` / `ProjectionMatrix` | `FrameContext` |
| `CameraPosition` | `FrameContext.cameraPosition` |
| `Time` | `FrameContext.time` |
| `LightDirection` / `LightColor` / `LightIntensity` | 第一盏 directional light |
| `LightViewProjection` | `FrameContext.lightViewProjection` |
| `ShadowMap` | `FrameContext.shadowMap.depth` |
| `HasShadowMap` | 0 或 1 |

支持的 uniform 类型：`float/int/bool` 的 1~4 分量、`mat4`、`sampler2D` /
`samplerCube`。`mat3` 暂不支持；数组 uniform 也不在首版范围内。

## 4. 绘制与状态

`PipelineEffectRenderer` 在第一次遇到 technique 时编译并缓存 program：

- 顶点属性按 program input 名从 `Geometry.getVertexAttribute(name)` 绑定；
  自定义属性名必须与 Geometry 属性同名（`position`、`normal`、`uv` 等）。
- uniform 按 `PipelineUniform` 列表上传；找不到的 input 静默跳过。
- `PipelineState` 在每次 draw 前应用。
- 每次 draw 直接绑定索引缓冲并调用 `drawIndexBufferTriangles`，不管理
  render target / viewport / clear。

Renderer 在 effect 绘制后、下一个直绘 item 前恢复 stage 默认状态，避免
effect 的 culling/blending/color mask 泄漏到后续 PBR item。

## 5. Renderer 回退

| Renderer | Stage | 无 technique 时 |
| --- | --- | --- |
| `PBRForwardRenderer` opaque/alphaTest | `Forward` | 内置 PBR 直绘 |
| `PBRForwardRenderer` transparent | `Transparent` | 内置 PBR 直绘 |
| `GBufferRenderer`（仅 MRT） | `GBuffer` | 内置 G-Buffer 直绘 |
| `ShadowRenderer` | `Shadow` | 内置 shadow 直绘 |

- `GBufferFallbackRenderer`（无 MRT）不支持 `PipelineEffect`，继续使用内置 PBR。
- `castShadow=false` 的 item 不进入 `ShadowRenderer`。
- transparent 分桶仍由 material `baseColor.a < 1` 决定；`Transparent` technique
  只对进入 transparent bucket 的 item 生效。
- 内置 PBR 本身暂不改为 `PipelineEffect`。

### 5.1 非 PBR Forward

`ForwardPath` 是通用 forward path，不依赖 PBR；配合
`ForwardEffectRenderer` 可以只渲染 `PipelineEffect` item：

```haxe
var forwardFx = new ForwardEffectRenderer(context);
var path = new ForwardPath(
    function(q, f, t) forwardFx.render(q, f, t),
    null,
    "forward-effect"
);
```

- `ForwardEffectRenderer` 不 fallback 到 PBR，也不读取 `item.effect`。
- `opaque` / `alphaTest` 使用 `EffectStage.Forward`；
  transparent 使用 `EffectStage.Transparent`。
- 没有 `pipelineEffect` 的 item 默认跳过；可传入 `defaultEffect` 统一绘制。
- 缺对应 stage technique 时跳过，不报错。
- `ForwardPBRPath` 是 `ForwardPath` 的兼容子类，行为/名称/pass 名不变。

## 6. 限制

- 一个 stage 一个 program，不支持多 pass。
- macro 是编译期静态配置，不支持运行时 program variant 切换。
- 只支持 `#pragma include "..."`；不支持 `#include` 或尖括号形式。
- 不支持自定义顶点属性名。
- 只处理 directional light；点光源、多光源仍属内置 PBR。
- `PipelineEffectRenderer` 的编译缓存随 renderer 生命周期；不要在 renderer
  仍在使用时销毁其 effect/technique 对象。

## 7. 测试

`minko-test/src/TestHLMain.hx` 覆盖：

- forward 自定义 fragment；
- material uniform 更新；
- transparent blending；
- MRT G-Buffer technique；
- shadow technique；
- 缺 stage 时回退 PBR；
- effect 状态不泄漏到后续直绘 item；
- `.peffect` parser：合法文件、uniform 三种来源、blending/culling、
  AssetLibrary 存取，以及 invalid JSON / 未知 stage / 未知 source / 重复 stage /
  缺 shader 的错误路径；
- 外部 shader 文件 + `#pragma include` + macro；
- 缺失 include / 循环 include 的错误路径；
- `#define` 实际影响 shader 编译结果（`#ifdef` 分支渲染验证）；
- 非 PBR forward：opaque/transparent effect、无 effect 跳过、defaultEffect、
  无 PBR fallback。

```powershell
cd minko-test
haxe build_hl.hxml
hl bin/TestsHL.hl
```
