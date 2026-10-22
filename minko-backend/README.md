# minko-backend

Platform backend layer for the Minko Haxe port. It keeps the platform and
rendering responsibilities:

- canvas/backend: `AbstractCanvas`, `Canvas`, `CanvasEvent`, `WebCanvas`,
  `WebBackend`, `SDLCanvas`, `SDLBackend`
- async: `IWorker`, `Worker`, `WorkerImpl` (canvas worker polling)
- input: keyboard/mouse/touch/joystick bases and SDL implementations
- audio: `Sound`/`SoundChannel`/`SoundTransform` and OpenAL WAV/OGG playback
  (`SDLAudio`, `SDLSound`, `SDLSoundChannel`)
- render: `AbstractContext`, resource/texture/buffer/shader/program bases,
  `GlContext` (WebGL), `SDLGLContext` (HashLink/OpenGL), `HLShaderTools`
- native: `fmt.hdll` OGG bindings

The high-level rendering pipeline (`DrawCall`, `DrawCallPool`, `Effect`, `Pass`)
stays in `minko-hx`. The audio loader integration (`SDLSoundParser`) and
`PositionalSound` also live in `minko-hx`, since they depend on the file loader
and the component/scene layer.

## Dependency direction

```text
minko-glm
  ↑
minko-core      (signals, data, math, basic file types, Timer, Tuple, Uuid)
  ↑
minko-backend   (this module)
  ↑
minko-hx
```

`minko-backend` depends only on `minko-core` and `minko-glm`. It no longer
imports `minko-hx`, so the previous source-level cycle is gone. Consumers still
compile the source roots together:

```hxml
-cp ../minko-glm/src
-cp ../minko-core/src
-cp ../minko-backend/src
```

## Standalone compile check

A small program that imports only backend/core types can be compiled without
`minko-hx/src`:

```powershell
haxe -cp minko-core/src -cp minko-backend/src -cp minko-glm/src -main BackendCheck -js BackendCheck.js
```

## Building

For the HashLink demo:

```powershell
cd ../minko-sdl
haxe build.hxml
```

For the HTML5 module list:

```powershell
cd ../minko-hx
haxe completion2.hxml
```

## Layout

```text
src/minko/
  AbstractBackend.hx
  AbstractCanvas.hx
  Canvas.hx
  CanvasEvent.hx
  WebBackend.hx
  WebCanvas.hx
  SDLBackend.hx
  SDLCanvas.hx
  input/       (bases + SDL)
  async/       (IWorker, Worker, WorkerImpl)
  audio/       (bases + SDL/OpenAL, no file loader integration)
  render/      (context/resources + GlContext/SDLGLContext)
  native/      (Ogg.hx)
```

Platform selection is done by the existing `#if js` / `#elseif hl` branches in
`Canvas.hx`; the unused side is not reached by that target.
