# minko-hx

GLM math lives in `../minko-glm` (derived from
https://github.com/hamaluik/haxe-glm). Low-level signals, data, math, Timer,
Tuple, Uuid and basic file value types live in `../minko-core`.

`minko-hx` is the platform-independent engine: scene graph, components,
geometry, materials, file loader/parsers and the high-level render pipeline
(`DrawCall`/`Effect`/`Pass`).

The canvas, input, audio playback and render resource layer live in
`../minko-backend`. Source roots are compiled together:

```hxml
-cp src
-cp ../minko-glm/src
-cp ../minko-core/src
-cp ../minko-backend/src
```

`minko-backend` no longer depends on this package; the direction is
`minko-hx → minko-backend → minko-core → minko-glm`.

`example.*` and `tutorial.*` have moved to `../minko-example`, and `test.*` has
moved to `../minko-test`; this package keeps the engine only.

HashLink demo/build shell: `../minko-sdl` (see its README).
