# minko-test

Test sources for the Minko Haxe port. This is now the only source home for the
`test.*` package; `minko-hx` keeps the engine core and `minko-example` keeps the
examples/tutorials.

## Layout

```text
src/
  TestMain.hx    WebGL test runner
  test/          21 test modules
    MinkoTests.hx
    component/...
    data/...
    file/...
    geometry/...
    render/...
    scene/...
bin/Tests.js     build output
index.html       test host page
build.hxml
```

## Build

From this directory:

```powershell
haxe build.hxml
```

`build.hxml`:

```hxml
-cp src
-cp ../minko-glm/src
-cp ../minko-core/src
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

The tests create a `WebCanvas` and exercise the WebGL renderer, so they need a
browser.

1. Make the example assets available as `minko-test/asset` (the loader looks for
   `asset/...` relative to the page):

   ```powershell
   New-Item -ItemType Junction -Path asset -Target (Resolve-Path ..\minko-example\asset)
   ```

   Or copy/mount `../minko-example/asset` to `asset/`.

2. Serve the repository root (for example with a local static server) and open:

   ```text
   http://localhost:<port>/minko-test/index.html
   ```

3. Test results are written to the browser console by `haxe.unit.TestRunner`.

Compilation does not require the `asset` directory; only tests that load effects
(`effect/*.effect`) need it at runtime.

## Coverage

`TestMain` registers:

- component: DirectionalLight, Transform, Renderer, Surface, SpotLight,
  PointLight, AmbientLight
- data: Collection, Provider, Store
- file: File, EffectParser, EffectParserPass
- geometry: Geometry
- scene: Node, NodeSet

Additional test modules such as `test.render.DrawCallTest`,
`test.render.DrawCallPoolTest`, `test.render.ProgramSignatureTest` and
`test.render.TextureTest` live in `src/test` but are not registered by default;
add them to `TestMain` when needed.
