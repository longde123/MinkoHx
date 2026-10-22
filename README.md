# minko-hx

GLM math is provided by `minko-glm` (derived from
https://github.com/hamaluik/haxe-glm).

Modules:

- `minko-glm`: standalone GLM math library (`glm.*`, Apache-2.0, derived from
  haxe-glm).
- `minko-core`: low-level foundation (signals, data, math, basic file types,
  Timer, Tuple, Uuid). Depends only on `minko-glm`.
- `minko-backend`: shared canvas/input/audio/context/render-resource layer plus
  the HTML5 and HashLink implementations, and the async worker runtime. Depends
  on `minko-core` + `minko-glm`.
- `minko-hx`: platform-independent engine (scene, data, geometry, material,
  file loader/parsers, high-level render pipeline). Depends on
  `minko-backend` + `minko-core` + `minko-glm`.
- `minko-example`: all `example.*` and `tutorial.*` sources, assets and the
  example launcher.
- `minko-test`: engine tests, test runner and host page.
- `minko-sdl`: HashLink/SDL3 demo and build shell (PNG/JPEG textures, OpenAL
  WAV/OGG audio).

Typical source-root order:

```hxml
-cp ../minko-glm/src
-cp ../minko-core/src
-cp ../minko-backend/src
-cp ../minko-hx/src
```
