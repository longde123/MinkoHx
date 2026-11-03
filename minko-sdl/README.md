# minko-sdl

HashLink / SDL3 demo and build shell for `minko-hx`.

The shared canvas/input/audio/context implementation lives in
`../minko-backend`; this folder contains the new-pipeline demos
(`src/PipelineMain.hx`, `src/PBRRendererMain.hx`) and their build/run files.
The legacy `Renderer`/`DrawCall` demo was removed with the old pipeline.

## Requirements

- Windows x64 (the included run script assumes `D:\hashlink-2.0.0-win`).
- Haxe 4.3+ (tested with the installed Haxe 5 preview).
- HashLink 2.0 with `sdl.hdll`/`SDL3.dll`, `openal.hdll`/`OpenAL32.dll` and
  `fmt.hdll` (OGG decoding).
- Haxelibs: `hlsdl` 1.16+, `hlopenal` 1.5+, `format` 3.8+.

## Build

From this directory:

```powershell
haxe build_pbr_renderer.hxml     # -> bin/PBRRendererMain.hl
haxe build_pipeline.hxml         # -> bin/PipelineMain.hl
haxe build_phong_light_test.hxml # -> bin/PhongLightTestMain.hl
haxe build_pbr_light_test.hxml     # -> bin/PBRLightTestMain.hl
```

## Run

```powershell
.\run.ps1                        # runs bin/PBRRendererMain.hl
.\run.ps1 bin/PipelineMain.hl    # runs the pipeline demo
.\\run.ps1 bin/PhongLightTestMain.hl  # runs the Phong light test
.\\run.ps1 bin/PBRLightTestMain.hl    # runs the PBR light test
```

`run.ps1` sets `HL_PATH` to `bin` + the HashLink installation, changes the working
directory to this folder, and starts `hl.exe`. If HashLink is not at
`D:\hashlink-2.0.0-win`, set `HASHLINK_HOME` to its directory.

Both demos generate their own geometry/textures; no external asset tree is
required.

## Pipeline demo (`src/PipelineMain.hx`)

The new render pipeline has its own demo and build file:

```powershell
haxe build_pipeline.hxml     # -> bin/PipelineMain.hl
hl bin/PipelineMain.hl
```

It renders a PBR cube through `PipelineRenderer` with shadows, bloom, tonemap
and FXAA, and lets you switch the render path at runtime:

| Key | Action |
| --- | --- |
| `1`/`2` | metallic -/+ |
| `3`/`4` | roughness -/+ |
| `5` | cycle base color |
| `6`/`7` | light intensity -/+ |
| arrows | light direction |
| `SPACE` | toggle spin / light auto-rotate |
| `0` | reset |
| `D` | toggle forward / deferred path |
| `G` | cycle G-buffer debug views (off, albedo, normal, depth, lighting, emissive) |

Debug views force the deferred path (they need the G-buffer). The deferred path
evaluates the same GGX/Lambert BRDF as the forward path for the directional
light; point lights are forward-only for now.

For headless smoke tests the startup mode can be forced with an environment
variable:

```powershell
$env:MINKO_DEMO_MODE = "deferred"     # or "debug=2" (depth view)
hl bin/PipelineMain.hl
```

## PBRRenderer demo (`src/PBRRendererMain.hx`)

A minimal scene-graph demo for the new pipeline's `PBRRenderer` component:

```powershell
haxe build_pbr_renderer.hxml     # -> bin/PBRRendererMain.hl
hl bin/PBRRendererMain.hl
```

It renders a rotating PBR cube through `minko.component.PBRRenderer` +
`SceneManager`, with a checker base-color map, directional/point lights, and a
Bloom → Tonemap → FXAA post chain. Camera and Surface collection are handled by
the component; lights and post-processing are configured through its public
API.

| Key | Action |
| --- | --- |
| `1`/`2` | metallic -/+ |
| `3`/`4` | roughness -/+ |
| `5` | cycle base color |
| `6`/`7` | light intensity -/+ |
| arrows | light direction |
| `SPACE` | toggle spin / light auto-rotate |
| `0` | reset |

Unlike `PipelineMain`, this demo does not own a `PipelineRenderer` or switch to
the deferred path; it demonstrates the `SceneManager`-driven component wiring.

## Phong light test (`src/PhongLightTestMain.hx`)

Scene-graph light test for `PhongRenderer` and `LightComponent`:

```powershell
haxe build_phong_light_test.hxml
hl bin/PhongLightTestMain.hl
```

It renders three Phong cubes and a ground plane lit by:

- `DirectionalLight`
- orbiting `PointLight`
- moving `SpotLight`

All three are `LightComponent` instances collected by `PhongRenderer`.

| Key | Action |
| --- | --- |
| `1` | directional intensity + |
| `2` | point intensity + |
| `3` | spot intensity + |
| `SPACE` | toggle animation |
| `0` | reset |

## PBR light test (`src/PBRLightTestMain.hx`)

Scene-graph light test for `PBRRenderer` and `LightComponent`:

```powershell
haxe build_pbr_light_test.hxml
hl bin/PBRLightTestMain.hl
```

It renders three PBR cubes and a ground plane with directional, orbiting point
and moving spot lights. All lights are `LightComponent` instances collected by
`PBRRenderer`.

| Key | Action |
| --- | --- |
| `1` | directional intensity + |
| `2` | point intensity + |
| `3` | spot intensity + |
| `SPACE` | toggle animation |
| `0` | reset |

## Implementation notes

- `SDLCanvas` extends `AbstractCanvas`; `SDLBackend` owns the blocking SDL event loop.
  Both now live in `../minko-backend`.
- `SDLGLContext` is a native port of the WebGL `GlContext` using `sdl.GL`.
  The new pipeline's `PipelineEffectRenderer` and PBR renderers share it.
- hlsdl only exposes `uniform1i`, `uniform4fv` and `uniformMatrix4fv`. `HLShaderTools`
  rewrites scalar/vec2/vec3/int/bool uniforms to `vec4` and `SDLGLContext` pads their
  values before upload. Original GLSL is kept for uniform reflection.
- GLSL is compiled as `#version 120` in a compatibility profile. `attribute`,
  `varying`, `gl_FragColor` and `texture2D` are therefore valid.
- Active uniforms/attributes are recovered by parsing the original GLSL source,
  because hlsdl does not expose `glGetActiveUniform`/`glGetActiveAttrib`. Sampler
  uniforms also get a `position` (their texture unit), assigned densely in
  declaration order, so renderers no longer hardcode texture units.
- Texture binding is no longer limited to a fixed 8-slot table: WebGL uses the
  driver's `MAX_TEXTURE_IMAGE_UNITS`, HashLink uses 16 (the GL spec minimum,
  since hlsdl does not expose the query).
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
- `mat3` uniforms are not uploaded (the pipeline program upload path has no
  `float9` path).
- Compressed textures are not supported.
- `glCheckFramebufferStatus` is unavailable through hlsdl; RTT setup is checked with
  `glGetError` instead.
- The shader uniform normalization targets the uniform types used by this repository;
  unusual GLSL constructs (struct uniforms, nested array indexing) are not guaranteed.
