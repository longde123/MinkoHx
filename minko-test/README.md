# minko-test

Test sources for the Minko Haxe port. This is the only source home for the
`test.*` package; `minko-hx` keeps the engine core.

## Layout

```text
src/
  TestMain.hx    WebGL test runner
  test/
    MinkoTests.hx
    component/TransformTest.hx
    file/FileTest.hx
    geometry/GeometryTest.hx
    scene/...
  TestHLMain.hx  HashLink new-pipeline suite
bin/Tests.js     build output
index.html       test host page
build.hxml
build_hl.hxml
```

The legacy `Renderer`, `DrawCall`, `Effect`, `Pass`, `EffectParser`, light
component and Surface tests were removed with the old pipeline.

## Build

From this directory:

```powershell
haxe build.hxml
```

`build.hxml`:

```hxml
-cp src
-cp ../minko-glm/src
-cp ../minko-backend/src
-cp ../minko-hx/src
-lib hx3compat
-main TestMain
-js bin/Tests.js
```

Output: `bin/Tests.js`.

### Haxe 5 / haxe.unit

The tests use the classic `haxe.unit.TestCase` / `haxe.unit.TestRunner` API.
Haxe 5 preview no longer ships `haxe.unit`; the build therefore uses the
installed `hx3compat` haxelib, which provides the compatibility implementation.
`minko-test` is the only module that needs `hx3compat`.

## Run

The tests create a `WebCanvas`, so they need a browser:

1. Serve the repository root with any static server.
2. Open:

   ```text
   http://localhost:<port>/minko-test/index.html
   ```

3. Test results are shown on the page and written to the browser console by
   `haxe.unit.TestRunner`.

No external asset directory is required.

## Coverage

`TestMain` registers:

- component: Transform, BoundingBox, MousePicking
- file: File
- geometry: Geometry buffers/normals and ray intersection
- math: Box ray intersection and distance
- scene: Node hierarchy/disposal and NodeSet

The legacy `minko.data` Store/Provider/Collection tests were removed with the
data model.

## HashLink suite (new render pipeline)

`src/TestHLMain.hx` is a standalone HashLink suite for the new render pipeline
specified in `minko-hx/docs/render-pipeline-design.md`. It needs no browser: it
creates a hidden SDL canvas, renders into pool-acquired offscreen targets and
reads pixels back through `context.readPixels`.

### Build

From this directory:

```powershell
haxe build_hl.hxml
```

`build_hl.hxml`:

```hxml
-cp src
-cp ../minko-glm/src
-cp ../minko-backend/src
-cp ../minko-hx/src
-lib hlsdl
-lib hlopenal
-lib format
-main TestHLMain
-hl bin/TestsHL.hl
```

`hlsdl` links the SDL3/OpenGL backend; `hlopenal` and `format` satisfy the
backend's audio/image link-time dependencies. Output: `bin/TestsHL.hl`.

### Run

```powershell
hl bin/TestsHL.hl
```

Exit code `0` iff every check passed. Each check prints `PASS <name>` or
`FAIL <name> -- <detail>`, and the run ends with
`== RESULT: N passed, M failed ==`.

The pixel assertions compare relative values (lit band vs shadowed band,
in-range vs out-of-range light, chain with vs without bloom), never absolute
pixel values, so the suite is adapter/driver independent.

### Coverage

- graph: topological order from output, culling of unconnected passes,
  compile-result cache, cache invalidation, execute order, double-producer
  rejection, empty compile, transient release
- queue: bucket assignment, opaque sort by material uuid, transparent
  far-to-near, shadow casters honour `castShadow=false`, clear
- pool: POT rounding, release/reacquire identity, format-aware reuse
  (RGBA vs RGBA16F, Depth24 vs Depth32F), MRT with depth, max-free eviction,
  steady-state zero allocation
- capabilities: HL backend reports MRT/depth/HDR
- math: normal matrix is `transpose(inverse(world))` (non-uniform scale keeps
  rotated normals), singular matrices fall back without throwing
- scene math: Box/Geometry ray intersection, degenerate input, BoundingBox
  caching, manual update and clone options
- interaction: nearest mouse hit, move/over/rollOver/out and button dispatch
- lifecycle: invalid hierarchy rejection and idempotent subtree disposal
- forward PBR: lit vs ambient-only, roughness/metallic response (metals),
  point-light range attenuation, alpha-blended transparency, directional
  shadows on/off, pipeline renderer E2E
- deferred: native MRT G-buffer (lighting output, per-attachment albedo and
  normal readback), three-target fallback, G-buffer state isolation after a
  forward pass (blending/depth), deferred lighting parity with the forward
  path, `DeferredPBRPath` pass order and per-frame stability for both MRT and
  forced-fallback capabilities, transparent compositing over the lit scene,
  deferred pipeline renderer E2E
- debug views: albedo / normal / depth / lighting / emissive G-buffer views
- pipeline effects: custom forward fragment and material uniform, transparent
  blending, MRT G-Buffer technique, shadow technique, missing-stage fallback,
  and state isolation between effect and PBR draws
- non-PBR forward: `ForwardPath` + `ForwardEffectRenderer`, opaque/transparent
  effects, skip-without-effect, `defaultEffect`, and no PBR fallback
- PBRRenderer component: SceneManager attachment, default forward path, surface
  collection, light forwarding, and pipeline release on detach
- `.peffect` parser: valid technique/uniform/state parsing, AssetLibrary storage,
  external shader files, recursive `#pragma include`, compile-time macros,
  missing/recursive include errors, and invalid JSON / unknown stage / unknown
  uniform source / duplicate stage / missing shader errors
- post: tonemap + FXAA chain, bloom brightens the output
- pipeline: `PipelineRenderer` collection and alpha<1 transparent bucketing
- benchmark: 1000 draw calls x 30 frames
