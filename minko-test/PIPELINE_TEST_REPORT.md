# Render pipeline acceptance report

Target: `minko-hx/docs/render-pipeline-design.md` §15 acceptance criteria.
Date: 2026-10-24. Platform: Windows, HashLink + SDL3/OpenGL (desktop GL).

## How to reproduce

```powershell
cd minko-test
haxe build_hl.hxml
hl bin/TestsHL.hl     # exit code 0 iff all checks pass
```

Latest run: **256 passed, 0 failed, exit code 0**.

## Fixed product bugs

### 1. Shadows had zero effect (`ShadowRenderer`)

`ShadowRenderer.render()` bound the shadow target and cleared it, but never
enabled depth test/depth writes, so the depth texture stayed at its cleared
value 1.0 and `shadowFactor()` always returned 1.0. This was a regression
against an earlier ad-hoc `SHADOW_OK` check: previously leaked global GL state
masked it.

Fix (`ShadowRenderer.hx`): explicit `setDepthTest(true, LESS)` plus blending
and culling defaults before the clear and draw.

### 2. Shadows could never be disabled (`PBRForwardRenderer`)

`render()` updated the shadow state only when `frame.shadowMap != null`, so a
frame without a shadow map kept sampling the previous frame's depth texture.
Fix: always update per frame (`setShadowMap(null, null)` when absent).

### 3. G-buffer pass inherited render state (`GBufferRenderer`, `GBufferFallbackRenderer`)

The G-buffer never set its own blending/depth/culling state. In a frame that
followed a forward render, it inherited `Blending.Mode.ALPHA`, so every
attachment whose fragment alpha is not 1 was written pre-multiplied:

- normal attachment alpha stores roughness → normals were scaled by roughness:
  measured centre pixel `(76,76,153) = 0.6 × (127,127,255)`;
- emissive attachment alpha stores metallic → emissive was scaled by metallic.

The corrupted normals decoded to `ndl ≈ 0`, which collapsed the deferred
lighting to its ambient term. That was the real cause of the "deferred preview
is dim" symptom (whole-frame average 0.023 instead of ~0.09), not the N·L
formula. A probe that replayed one forward render before the G-buffer pass
reproduced it exactly, and a CPU reference implementation matched the lighting
shader bit-for-bit (maxDiff 0.001), isolating the fault to the attachments.

Fix: both G-buffer renderers now set colour mask, depth test (`LESS`), blending
(`DEFAULT`) and culling (`BACK`) and clear colour+depth before drawing.

### 4. Deferred path could not composite transparency (`DeferredPBRPath`)

`TransparentDraw` had signature `(queue, frame, output)` — the pass had no
access to the lit scene, so transparent geometry had nothing to blend against
and `FinalColor` kept stale pool content when no callback was installed.

Fix:

- `TransparentDraw` is now `(queue, frame, sceneColor, output)`;
- when no callback is installed the path copies `SceneColorHDR` into
  `FinalColor` itself (lazy `FullscreenEffect`, disposed by the new
  `RenderPath.dispose()` which `RenderPipeline.dispose()` calls);
- `FinalColor` uses the same format as `SceneColorHDR` (RGBA16F when the
  backend supports float targets), so blending and tonemapping stay in HDR;
- `DeferredPBRPath.gbuffer` is exposed for debug views and tools.

### 5. G-buffer debug views did not exist (§15 requirement)

New `GBufferDebugRenderer` + `GBufferDebugMode` (albedo, normal, depth,
lighting, emissive). Depth linearises the depth texture sampled from the MRT
G-buffer; without a depth texture it shows a magenta placeholder and warns once
instead of failing.

### 6. `normalMatrix` was the world matrix (`PBRForwardRenderer`, both G-buffer renderers)

Correct for uniform scale only; under non-uniform scale it skews normals so
lighting picks the wrong hemisphere. New `PBRMath.normalMatrix()` computes
`transpose(inverse(world))` with a determinant guard (singular matrices — e.g.
zero scale — fall back to the world matrix instead of throwing). The renderers
reuse a scratch matrix, so there is no per-item allocation.

### 7. Render target pool ignored texture formats (`RenderTargetPool`)

`acquireMRT` reused free targets by size, attachment count and "has depth"
only, so an RGBA target could be served to an RGBA16F request (and Depth24 to
Depth32F). The reuse key now includes the colour format and the depth format.

## Deferred lighting quality

`DeferredLightingRenderer` now evaluates the same GGX/Smith/Fresnel BRDF as the
forward renderer (`PBRShaderLibrary.brdfFunctions()` is shared by both, so they
cannot drift), driving albedo, encoded normal, roughness (`normal.a`), metallic
(`emissive.a`) and emissive from the G-buffer.

- The light is configurable (`lightDirection`, `lightColor`, `lightIntensity`,
  `ambient`) and is overridden by the first directional light of the
  `FrameContext` when one is passed.
- The per-pixel view direction is rebuilt from the camera basis and UV
  (right/up/forward, tan(fov/2), aspect); when a depth texture is available,
  world position is reconstructed from depth and used for point/spot lights and
  directional shadows. Without depth the renderer keeps the camera-basis path
  and directional-only lighting.
- Measured parity with the forward path on the same scene and light:
  deferred 0.214 vs forward 0.213 whole-frame average.
- Deferred point-light and shadow checks: near 0.164 vs far 0.056; shadowed
  band 0.531 vs lit 0.703 (shadows off 0.708).

The three-target fallback now allocates a depth texture on the albedo target, so
deferred point lights work on both MRT and fallback backends when the backend
supports depth textures. Spot lights evaluate the inner/outer cone cosines.
Fallback `PipelineEffect` items use the new `gbuffer-albedo` /
`gbuffer-normal` / `gbuffer-emissive` stages. `ForwardPath` and
`DeferredPBRPath` now reuse their `RenderGraph`/passes across frames and only
reacquire transient targets from the pool.

## §15 acceptance checklist

### 功能 (functional)

| Criterion | Status | Evidence |
| --- | --- | --- |
| Forward PBR 场景可运行 | PASS | `forward: lit=0.194 unlit=0.006`; PipelineRenderer E2E; `PipelineMain` demo runs |
| Deferred 场景可运行 | PASS | MRT lighting 0.056, fallback 0.056, deferred path 0.159, deferred PipelineRenderer E2E 0.15 (stable across frames) |
| Deferred 点光 | PASS | depth reconstruction: near 0.164 vs far 0.056 |
| Deferred 方向光阴影 | PASS | shadow on left 0.531 / right 0.703; off 0.708 |
| Spot 光锥 | PASS | forward lit 0.223 vs cone-away 0.006; deferred lit 0.168 vs 0.056 |
| CSM 级联阴影 | PASS | 2 cascades built; shadowed band 0.304 vs 0.398 unshadowed |
| Spot 局部阴影 | PASS | on.left 0.071 vs off.left 0.110 |
| Point 局部阴影 | PASS | on.avg 0.382 vs off.avg 0.393; 6 face resources built |
| Phong 局部阴影 | PASS | spot on.left 0.333 vs off.left 0.511 |
| Multiple point shadows | PASS | 2 lights; baseCell 0/6; count=2 |
| Multiple spot shadows | PASS | 2 lights; cells 0/1; count=2 |
| Shadow PCF | PASS | 3×3 PCF；方向/spot/point shadow 测试保持通过 |
| Deferred SSAO | PASS | AO avg 0.983；pass order GBufferPass,SSAOPass,DeferredLightingPass；3×3 depth-aware blur |
| Forward+ tile culling | PASS | active=3；动态 tile map；1280x720 纹理 128x64 |
| Dynamic tile map | PASS | 256 逻辑 16x16；1280x720 逻辑 80x45、纹理 128x64 |
| PCSS soft shadows | PASS | ShadowRenderer.softShadows/lightSize；5×5 blocker search + 可变半径 PCF |
| Deferred tile map | PASS | near 0.164 vs far 0.056；lit 0.168 vs away 0.056 |
| Backend upload quirks | PASS | 同帧/隔帧/FBO 内/无关纹理上传均正常 |
| Many live samplers | PASS | 1..16 个活跃 sampler 全部正确采样 |
| Sampler units survive upload | PASS | 16 live sampler + draw 前上传新纹理，绑定不被顶掉 |
| Forward 双点阴影像素 | PASS | base 0.646 / onlyA 0.512 / onlyB 0.512 / both 0.288；两槽各自生效 |`n| Forward 双 spot 阴影像素 | PASS | base 0.351 / onlyA 0.346 / onlyB 0.346；两槽各自生效 |`n| Deferred 双点阴影像素 | PASS | path 与 direct 两种路径：base 0.722 / onlyA 0.67 / onlyB 0.671 |`n| 点阴影 atlas grid | PASS | 单槽 grid 3x2 → 4x3，与多光 atlas 布局一致 |`n| fallback effect 自动拆分 | PASS | MRT gl_FragData[0..2] split; albedo [0,255,0], normal [0,0,255], emissive [255,0,0] |
| 硬件 cubemap 点阴影 | PASS | PBR forward on.left 0.095 vs off 0.21；deferred 0.722→0.706；Phong 0.386 vs 0.875 |`n| Cube-face 渲染后端 | PASS | SDL/WebGL `beginCubeFaceRender` 均编译并参与渲染 |`n| 材质类 | PASS | `PhongMaterial`/`PBRMaterial` 均在 `minko.material`，setter 版本递增 |
| Skinning 快照存储 | PASS | 未变形快照存 Geometry；软件蒙皮经 Surface 解析；移除时清空 |
| 场景灯光组件 | PASS | PointLight 收集、Transform 位置同步、手动/场景灯光合并与清空 |
| Phong 渲染路径 | PASS | lit 0.235 vs ambient 0.011；alpha 材质进入 transparent；ForwardPhongPath 输出 0.187 |
| Phong Normal Map | PASS | tangent vec4 正交/ handedness ±1；normal map 中心从 20 变为 255 |
| PhongRenderer 组件 | PASS | pipeline/path 创建、Surface 收集、灯光组件收集、detach 释放 |
| 透明物体在两种路径下都正确 | PASS | Forward: `transparent center r=250 g=131 b=131`. Deferred: 4-arg transparent callback receives the HDR scene colour, glass tints it (`r=255 g=118`); with no callback the path copies the scene by itself |
| Bloom/Tonemap/FXAA 可开关 | PASS | `Tonemap+FXAA` = 0.146 vs `Bloom+Tonemap+FXAA` = 0.180 |
| G-Buffer 调试视图 | PASS | albedo 0.151, normal 0.130, depth 0.824 (cube centre 64), lighting 0.151, emissive 0.079; views verified distinct |

### 兼容 (compatibility)

| Criterion | Status | Evidence |
| --- | --- | --- |
| HL 运行 | PASS | 256-check suite + demos on HashLink + SDL3/OpenGL |
| WebGL1 无扩展时自动 forward | NOT VERIFIED LOCALLY | Needs a browser. The same capability branch is exercised on HL by forcing `RenderCapabilities` all-false (deferred three-target fallback, LDR forward scene) |
| WebGL2 使用 MRT | NOT VERIFIED LOCALLY | Needs a browser. Native MRT verified on desktop GL (HL) |
| PBRRenderer 场景图入口 | PASS | SceneManager attachment, camera/surface collection, light forwarding, post-process configuration, forward/deferred switching, transparent deferred compositing, detach cleanup |

### 性能 (performance)

| Criterion | Status | Evidence |
| --- | --- | --- |
| RenderGraph 编译结果缓存 | PASS | cache hit + invalidation checks |
| RenderGraph/Pass 跨帧复用 | PASS | forward and deferred paths return the same graph across builds; targets reacquired from the pool |
| RenderTargetPool 稳态零分配 | PASS | 10 consecutive acquires return the same reference; POT rounding, MRT, format-aware reuse, eviction |
| update 无每帧全量扫描 | NOT INSTRUMENTED | no per-frame scan counter exists to assert |
| 1000+ DrawCall 可运行 | PASS | `BENCH drawCalls=1000 frames=30 avgMs=0.77–1.02` (median 0.80; baseline 8.12) |
| 提供基准场景 | PASS | benchmark case in the HL suite |

### 性能修复结果

The benchmark improved from a median of **8.12 ms** to **0.80 ms** per frame
(about **90.1%**) on the same 1000-draw-call scene. Caveat: the benchmark uses
one geometry for all 1000 items, so the geometry-binding cache removes almost
all per-item attribute binds. Scenes with predominantly unique geometry will
land between the old and new numbers; the material cache/sort and the other
fixes still apply to those scenes.

The measured fixes are:

- `SDLGLContext.setVertexBufferAt` no longer rebinds an already-bound vertex
  buffer for every enabled attribute.
- `SDLGLContext` reuses scratch `Bytes` for `uniform4fv` / `uniformMatrix4fv`.
- PBR/GBuffer/Shadow renderers upload from reusable scratch float arrays.
- `RenderItem` caches its normal matrix until `worldMatrix` is reassigned.
- `GBufferRenderer` uploads view/projection once per pass instead of per item.
- `NodeSet.descendants` uses an index queue/stack instead of `shift()` +
  `concat()` (O(n²)).
- `SceneCollector` avoids per-node `getComponents(Surface)` arrays and hoists
  the `RootTransform` lookup.
- `PipelineEffectRenderer` skips macro-prefix construction while its cached
  program is still valid.
- `RenderPipeline` reuses one `FrameContext` across frames.
- `PBRForwardRenderer` sorts opaque/alpha-test items by material, caches PBR
  material parameters by `Material.version`, and skips repeated material
  uniform uploads.
- `PBRForwardRenderer` caches the currently bound geometry and skips per-item
  attribute binding when consecutive items share it.
- `PBRForwardRenderer` skips program/state reapplication until a
  `PipelineEffect` item actually changes them.

Follow-up candidates not in this batch: persistent RenderGraph/RenderPath
objects, per-geometry attribute-layout cache, material batching across
renderers, and instancing.

## Test-design notes

- `readPixels` rows are stored top-to-bottom (probe-verified); the shadow bands
  depend on it.
- Byte readback of `RGBA16F` saturates at 1.0 — HDR pixels are indistinguishable
  in bytes, so bloom is tested on an LDR scene with emissive 0.4.
- Roughness is invisible on a dielectric in byte space (F0 = 0.04 → specular
  < 1% of the pixel on a flat face); the roughness check compares metals.
- Head-on light hides GGX lobe width → material tests use an oblique light.
- A forward render before the G-buffer pass is the regression trigger for the
  blending-state bug, and the suite keeps that ordering on purpose.
- The non-uniform normal test uses `scale(world) * rotate(45°)`: the correct
  inverse-transpose normal is `(0.243, 0, 0.970)` while the old world-matrix
  behaviour gives `(0.970, 0, 0.243)`.

## Pipeline effect wiring (new)

The new pipeline now consumes a pipeline-native effect model that does not use
the legacy `Effect` / `Pass` / `DrawCall` path:

- `minko-hx/src/minko/render/pipeline/PipelineEffect.hx`
- `minko-hx/src/minko/render/pipeline/PipelineTechnique.hx`
- `minko-hx/src/minko/render/pipeline/PipelineUniform.hx`
- `minko-hx/src/minko/render/pipeline/UniformSource.hx`
- `minko-hx/src/minko/render/pipeline/PipelineState.hx`
- `minko-hx/src/minko/render/pipeline/EffectStage.hx`
- `minko-hx/src/minko/render/pipeline/PipelineEffectRenderer.hx`
- `minko-hx/docs/effect-pipeline-wiring.md`

`Surface.pipelineEffect` / `RenderItem.pipelineEffect` attach an effect; the
forward, MRT G-Buffer and shadow renderers use it when the matching stage
technique exists and otherwise fall back to the existing PBR draw.
`GBufferFallbackRenderer` intentionally stays on the built-in path.

New checks cover custom fragment output, material uniform updates, transparent
blending, MRT G-Buffer technique, shadow technique, missing-stage fallback, and
state isolation between effect and PBR draws.

### `.peffect` parser

`minko.file.PipelineEffectParser` loads JSON files with the `.peffect` extension
and stores the result through `AssetLibrary.pipelineEffect(filename)`. It
supports one stage technique per entry, inline or external shader sources,
recursive `#pragma include`, top-level/technique macros, `source` / `material` /
`value` uniform entries, and the `PipelineState` fields. Multi-pass techniques
remain out of scope.

Parser checks cover valid parsing, uniform source forms, blending/culling,
AssetLibrary storage, external vertex/fragment files, recursive
`#pragma include`, top-level/technique macros, and the invalid JSON / unknown
stage / unknown source / duplicate stage / missing shader / missing include /
recursive include error paths. A render check verifies that a macro actually
selects an `#ifdef` branch.

### Non-PBR forward

`ForwardPath` owns the generic forward graph; `ForwardPBRPath` is a compatibility
subclass preserving the `forward-pbr` name and `ForwardPBRPass` pass name.
`ForwardEffectRenderer` draws only `PipelineEffect` items (no PBR fallback), with
an optional `defaultEffect` for items that do not define one. New checks cover
opaque and transparent effects, skipping items without effects, default-effect
fallback, and the absence of PBR fallback.

### PBRRenderer component

`minko.component.PBRRenderer` connects the new pipeline to `SceneManager`: it
finds the scene's SceneManager, subscribes to its render signal, lazily creates
`PBRForwardRenderer` + `ForwardPBRPath` + `PipelineRenderer`, and releases them
on detach. `useDeferred` switches the same component to `DeferredPBRPath`
(GBuffer + deferred lighting) and back; deferred transparent items are composited
through `PBRForwardRenderer.renderTransparent`. Tests cover SceneManager
attachment, surface collection, forward/deferred path selection, transparent
deferred compositing, light forwarding, disabling, and pipeline release.

## Legacy pipeline removal

The legacy `Renderer` / `DrawCallPool` / `DrawCall` / `Effect` / `Pass` /
`ProgramSignature` / `States` / `EffectParser` path, its bindings and legacy
materials were deleted. `Surface` now carries only geometry/material/
`pipelineEffect`; `RenderItem` no longer has an `effect` field. The old
examples, old SDL `Main` demo, legacy-only serialization/particle/assimp modules
and legacy tests were removed.

The generic `minko.data` model (`Store` / `Provider` / `Collection` /
`UnsafePointer`) was also removed. `Node` no longer owns a property store;
`Transform` and `PerspectiveCamera` expose typed matrix state and change
signals, `Geometry`/`Material` keep their own typed/map state, and `Culling` /
`OctTree` were removed. The remaining browser suite covers
Transform/file/geometry/scene; the HashLink suite remains at 256 checks.

## Files changed

- minko-hx/src/minko/render/phong/PhongForwardRenderer.hx, PhongShaderLibrary.hx — forward Blinn-Phong path
- minko-hx/src/minko/render/pipeline/ForwardPhongPath.hx — Phong ForwardPath specialization
- minko-hx/src/minko/material/Material.hx — shared material store/version
- `minko-hx/src/minko/material/PhongMaterial.hx` — Phong material data
- `minko-hx/src/minko/material/PBRMaterial.hx` — canonical PBR material (moved from render.pbr)
- `minko-hx/src/minko/component/LightComponent.hx`, `DirectionalLight.hx`, `PointLight.hx`, `SpotLight.hx` — scene-graph lights
- minko-hx/src/minko/render/pbr/SpotShadow.hx, PointShadow.hx — local shadow resources
- minko-hx/src/minko/render/pbr/ShadowRenderer.hx — directional CSM + spot/point shadow maps
- `minko-hx/src/minko/render/pbr/PBRForwardRenderer.hx` — per-frame shadow state, normal matrix
- `minko-hx/src/minko/render/pbr/GBufferRenderer.hx` — state isolation + clear, normal matrix
- `minko-hx/src/minko/render/pbr/GBufferFallbackRenderer.hx` — state isolation + clear, normal matrix
- `minko-hx/src/minko/render/pbr/PBRMath.hx` — new normal-matrix helper
- `minko-hx/src/minko/render/pbr/PBRShaderLibrary.hx` — shared BRDF chunk, PBR deferred lighting, G-buffer debug shader
- `minko-hx/src/minko/render/pbr/DeferredLightingRenderer.hx` — configurable light, depth-reconstructed point/spot lights, directional shadows
- `minko-hx/src/minko/render/pbr/GBufferDebugRenderer.hx`, `GBufferDebugMode.hx` — new debug views
- `minko-hx/src/minko/render/target/GBuffer.hx` — depth texture exposure
- `minko-hx/src/minko/render/pipeline/DeferredPBRPath.hx` — depth allocation, optional shadow pass, transparent compositing, HDR final color, graph reuse, `gbuffer`, `dispose`
- `minko-hx/src/minko/render/pipeline/EffectStage.hx` — fallback per-attachment stages
- `minko-hx/src/minko/render/pbr/GBufferFallbackRenderer.hx` — per-attachment PipelineEffect support
- `minko-hx/src/minko/render/pipeline/RenderPath.hx`, `RenderPipeline.hx` — dispose chain
- `minko-hx/src/minko/render/target/RenderTargetPool.hx` — format-aware reuse
- `minko-hx/src/minko/component/Surface.hx` — new `pipelineEffect` field
- `minko-hx/src/minko/render/pipeline/RenderItem.hx`, `SceneCollector.hx` — carry the pipeline effect
- `minko-hx/src/minko/file/PipelineEffectParser.hx` — `.peffect` JSON parser
- `minko-hx/src/minko/file/PipelineShaderResolver.hx` — external shader/include resolver
- `minko-hx/src/minko/file/AssetLibrary.hx` — `pipelineEffect` storage API
- `minko-hx/src/minko/file/Options.hx` — register the `.peffect` parser
- `minko-hx/src/minko/render/pipeline/ForwardPath.hx` — generic forward path with graph/pass reuse
- `minko-hx/src/minko/render/pipeline/ForwardEffectRenderer.hx` — non-PBR forward renderer
- `minko-hx/src/minko/render/pipeline/ForwardPBRPath.hx` — compatibility subclass
- `minko-hx/src/minko/component/PBRRenderer.hx` — SceneManager-driven PBR component
- `minko-backend/src/minko/render/SDLGLContext.hx` — vertex binding cache + uniform scratch bytes
- `minko-hx/src/minko/render/pbr/PBRMath.hx` — reusable vec/matrix array writers
- `minko-hx/src/minko/render/pbr/PBRForwardRenderer.hx`, `GBufferRenderer.hx`, `GBufferFallbackRenderer.hx`, `ShadowRenderer.hx` — scratch uniforms, normal-matrix cache, G-buffer constant hoist
- `minko-hx/src/minko/render/pipeline/RenderItem.hx` — world/normal matrix cache
- `minko-hx/src/minko/scene/NodeSet.hx` — O(n²) descendants traversal fix
- `minko-hx/src/minko/render/pipeline/SceneCollector.hx` — per-node allocation reduction
- `minko-hx/src/minko/render/pipeline/RenderPipeline.hx` — FrameContext reuse
- `minko-hx/src/minko/render/pipeline/PipelineTechnique.hx`, `PipelineEffectRenderer.hx` — macro-version compile cache
- `minko-hx/src/minko/data/*` — removed (Store/Provider/Collection/UnsafePointer)
- `minko-hx/src/minko/component/Transform.hx`, `scene/Node.hx` — typed transform state, no Node.data
- `minko-hx/src/minko/component/PerspectiveCamera.hx` — typed camera state, Transform signal
- `minko-hx/src/minko/geometry/Geometry.hx`, `material/Material.hx` — self-contained state
- `minko-hx/src/minko/component/Culling.hx`, `math/OctTree.hx` — removed
- `minko-extension` — removed (depended on deleted serializer/data APIs)
- `minko-test/src/test/data/*` — removed
- `minko-hx/src/minko/component/Surface.hx` — simplified geometry/material/pipelineEffect surface
- `minko-hx/src/minko/file/Options.hx` — `.peffect`-only parser registration, legacy effect options removed
- `minko-hx/src/minko/render/pipeline/RenderItem.hx`, `SceneCollector.hx` — pipelineEffect-only items
- `minko-test/src/TestHLMain.hx` — 233 checks
- `minko-test/src/TestMain.hx`, `test/MinkoTests.hx` — legacy tests removed
- `minko-test/build_hl.hxml`, `minko-test/README.md`, `minko-sdl/README.md`
- `minko-sdl/src/PipelineMain.hx` — forward/deferred toggle (`D`), debug views (`G`), `MINKO_DEMO_MODE`
- `minko-sdl/src/PBRRendererMain.hx`, `minko-sdl/build_pbr_renderer.hxml` — component demo
