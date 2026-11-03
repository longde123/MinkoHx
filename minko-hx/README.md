# minko-hx

GLM math lives in `../minko-glm` (derived from
https://github.com/hamaluik/haxe-glm). Low-level signals, Timer, Tuple and Uuid
live in `../minko-backend` (`minko.signal`, `minko.Timer`, `minko.Tuple`,
`minko.Uuid`).

`minko-hx` is the platform-independent engine: scene graph with typed component
state (`Node`, `Transform`, `PerspectiveCamera`, `BoundingBox`, `Geometry`,
`Material`), file value types (`minko.file`: File, AssetLocation,
AbstractAssetDescriptor, PixelData, ...), `Random`, `MathUtil`, `Rect`, file
loader/parsers and the new render pipeline
(`RenderPipeline`/`RenderGraph`/`PipelineEffect`).

The canvas, input, audio playback and render resource layer live in
`../minko-backend`. Source roots are compiled together:

```hxml
-cp src
-cp ../minko-glm/src
-cp ../minko-backend/src
```

`minko-backend` no longer depends on this package; the direction is
`minko-hx → minko-backend → minko-glm`.

`test.*` lives in `../minko-test`; this package keeps the engine only. The old
`example.*` / `tutorial.*` tree and the legacy renderer were removed.

HashLink demo/build shell: `../minko-sdl` (see its README).

## Rendering pipeline design

The design for the next-generation renderer is in
[`docs/render-pipeline-design.md`](docs/render-pipeline-design.md). It covers:

- Forward PBR;
- G-Buffer deferred lighting;
- post-processing (bloom, tone mapping, FXAA);
- RenderGraph / RenderQueue and transient RenderTarget reuse;
- pipeline-native `PipelineEffect` / `PipelineTechnique` (stage-based, independent
  from the legacy `Effect`/`Pass` path) and the `.peffect` parser with external
  shader files, `#pragma include` and compile-time macros;
- generic `ForwardPath` + `ForwardEffectRenderer` for non-PBR forward rendering;
- `minko.component.PBRRenderer` for SceneManager-driven PBR forward rendering;
- required backend extensions (RenderTarget, MRT, depth texture, HDR formats);
- capability-based fallback for OpenGL/WebGL1/WebGL2.

See [`docs/effect-pipeline-wiring.md`](docs/effect-pipeline-wiring.md) for the
pipeline effect contract and [`docs/pbr-renderer-component.md`](docs/pbr-renderer-component.md)
for the scene-graph component.
