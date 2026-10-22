# minko-core

Low-level runtime foundation shared by `minko-backend` and `minko-hx`. It depends
only on `minko-glm`; it does not know about canvases, components, scenes,
materials or the file loader.

## Contents

```text
src/minko/
  signal/       Signal, Signal2..Signal5
  data/         Binding, BindingMap, Collection, Provider, ResolvedBinding,
                Store, UnsafePointer
  math/         Random, Rect
  utils/        MathUtil
  file/         File, AssetLocation, AbstractAssetDescriptor, PixelData
  Timer.hx
  Tuple.hx
  Uuid.hx
```

`minko.data.AbstractFilter` stays in `minko-hx` because it depends on components
and the scene graph.

## Dependency direction

```text
minko-glm
  ↑
minko-core
  ↑
minko-backend
  ↑
minko-hx
```

## Usage

As a source root:

```hxml
-cp ../minko-glm/src
-cp ../minko-core/src
```

`minko-core` is intentionally not a haxelib dependency of `minko-backend` or
`minko-hx` in this repository; all builds use local source roots.

## Standalone check

A program that only imports `minko-core` types can be compiled with:

```powershell
haxe -cp minko-core/src -cp minko-glm/src -main CoreCheck -js CoreCheck.js
```
