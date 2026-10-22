# minko-sdl

HashLink / SDL3 demo and build shell for `minko-hx`.

The shared canvas/input/audio/context implementation now lives in
`../minko-backend`; this folder only contains the native demo (`src/Main.hx`) and
its build/run files. Build by adding both source roots:

```hxml
-cp ../minko-glm/src
-cp ../minko-core/src
-cp ../minko-backend/src
-cp ../minko-hx/src
-cp src
-lib hlsdl
-lib hlopenal
-lib format
-main Main
-hl bin/Main.hl
```

## Requirements

- Windows x64 (the included run script assumes `D:\hashlink-2.0.0-win`).
- Haxe 4.3+ (tested with the installed Haxe 5 preview).
- HashLink 2.0 with `sdl.hdll`/`SDL3.dll`, `openal.hdll`/`OpenAL32.dll` and
  `fmt.hdll` (OGG decoding).
- Haxelibs: `hlsdl` 1.16+, `hlopenal` 1.5+, `format` 3.8+.

## Build

From this directory:

```powershell
haxe build.hxml
```

The output is `bin/Main.hl`.

## Run

```powershell
.\run.ps1
```

`run.ps1` sets `HL_PATH` to `bin` + the HashLink installation, changes the working
directory to this folder, and starts `hl.exe bin\Main.hl`. If HashLink is not at
`D:\hashlink-2.0.0-win`, set `HASHLINK_HOME` to its directory.

The demo resolves assets through `../minko-example/asset`, so keep the repository
layout intact or edit the `assetRoot` in `src/Main.hx`.

## What the demo does

- Creates an 800x600 SDL window with an OpenGL 3.2 compatibility context.
- Loads `texture/diffuseMap.jpg` (NanoJPEG decoder) and `effect/Basic.effect`.
- Renders a rotating textured cube through `SceneManager`/`Renderer`/`Surface`.
- Loads `sound/beep.wav`; press **Space** to play it through OpenAL.
- Handles resize, mouse, keyboard, text input, touch and window close.

## Implementation notes

- `SDLCanvas` extends `AbstractCanvas`; `SDLBackend` owns the blocking SDL event loop.
  Both now live in `../minko-backend`.
- `SDLGLContext` is a native port of the WebGL `GlContext` using `sdl.GL`.
  `DrawCall`/`Effect`/`Pass` remain in `minko-hx`.
- hlsdl only exposes `uniform1i`, `uniform4fv` and `uniformMatrix4fv`. `HLShaderTools`
  rewrites scalar/vec2/vec3/int/bool uniforms to `vec4` and `SDLGLContext` pads their
  values before upload. Original GLSL is kept for uniform reflection.
- GLSL is compiled as `#version 120` in a compatibility profile. `attribute`,
  `varying`, `gl_FragColor` and `texture2D` are therefore valid.
- Active uniforms/attributes are recovered by parsing the original GLSL source,
  because hlsdl does not expose `glGetActiveUniform`/`glGetActiveAttrib`.
- PNG textures are decoded with `format.png`; JPEG textures use the bundled
  NanoJPEG baseline decoder. Both are converted BGRA -> RGBA and resized to
  power-of-two dimensions like the browser path.
- Audio uses OpenAL (`hlopenal`). `SDLSoundParser` decodes PCM WAV with
  `format.wav` and OGG Vorbis through the native `fmt.hdll` bindings, uploads a
  buffer and plays it from `SDLSound`/`SDLSoundChannel`.
- `FileProtocol` now implements `fileExists` and reads the whole file when
  `seekedLength == 0`, which is required for native asset loading.

## Known limitations

- JPEG: baseline only (NanoJPEG); progressive JPEG and CMYK are not supported.
  Chroma upsampling uses the fast path to avoid a buffer-size bug in the Haxe port.
- Audio: WAV PCM (8/16-bit, mono/stereo) and OGG Vorbis; MP3 is not decoded.
  Panning/left-right balance is currently reduced to master gain, and
  `PositionalSound` is not wired to OpenAL 3D positioning.
- `mat3` uniforms are not uploaded (the engine's `DrawCall` has no `float9` path).
- Compressed textures are not supported.
- `glCheckFramebufferStatus` is unavailable through hlsdl; RTT setup is checked with
  `glGetError` instead.
- The shader uniform normalization targets the uniform types used by this repository;
  unusual GLSL constructs (struct uniforms, nested array indexing) are not guaranteed.
