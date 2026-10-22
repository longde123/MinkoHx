# minko-glm

GLM math library for the Minko Haxe port, derived from
[haxe-glm](https://github.com/hamaluik/haxe-glm) by Kenton Hamaluik and
distributed under the Apache License 2.0 (the original headers are preserved in
each source file).

The package name stays `glm`, so existing imports such as `glm.Vec3`,
`glm.Mat4` and `using glm.Mat4` do not change.

## Usage

As a source root:

```hxml
-cp ../minko-glm/src
```

Or as a dev haxelib:

```powershell
haxelib dev minko-glm D:\MinkoHx\minko-glm
haxe ... -lib minko-glm
```

## Contents

- `GLM.hx` — matrix/vector helpers, look-at, perspective, transforms
- `Vec2/3/4.hx`, `Mat2/3/4.hx`, `Quat.hx`

The optional `#if kha` implementations use `kha.math.Fast*` types; when compiling
with `-D kha`, Kha must also be on the classpath. The default Haxe/HL/JS path
uses the portable `Vec*Base`/`Mat*Base` classes.

## Relationship to the rest of the repository

`minko-core`, `minko-backend`, `minko-hx`, `minko-example`, `minko-test` and
`minko-sdl` all import `glm.*` and must include this module's `src` in their
classpath.
