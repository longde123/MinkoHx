# minko-hx

GLM math is provided by `minko-glm` (derived from
https://github.com/hamaluik/haxe-glm).

Modules:

- `minko-glm`: standalone GLM math library (`glm.*`, Apache-2.0, derived from
  haxe-glm).
- `minko-backend`: shared canvas/input/audio/context/render-resource layer plus
  the HTML5 and HashLink implementations, the async worker runtime, and the
  low-level foundation (`Timer`, `Tuple`, `Uuid`, signals). Depends only on
  `minko-glm`.
- `minko-hx`: platform-independent engine (data model, scene, geometry,
  material, file loader/parsers, new high-level render pipeline). Depends on
  `minko-backend` + `minko-glm`.
- `minko-test`: engine tests, test runner and host page.
- `minko-sdl`: HashLink/SDL3 PBR demos and build shell.

The legacy renderer (`Renderer` / `DrawCallPool` / `Effect` / `Pass`), its
examples and the legacy-only serialization/particle/assimp modules have been
removed; use `minko.render.pipeline` and `minko.component.PBRRenderer`.

Typical source-root order:

```hxml
-cp ../minko-glm/src
-cp ../minko-backend/src
-cp ../minko-hx/src
```
