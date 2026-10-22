# minko-example

Example and tutorial sources for the Minko Haxe port. This is now the only
source home for `example.*` and `tutorial.*`; `minko-hx` keeps the engine core
and tests live in `../minko-test`.

## Layout

```text
src/
  ExampleMain.hx     default example launcher (ExampleCube)
  example/           12 examples
  tutorial/          10 tutorials
asset/               effects, textures, sounds, models
```

`bin/` contains older generated copies and is not used as a source root. Use the
root `completion.hxml`.

## Build

From this directory:

```powershell
haxe completion.hxml
```

The classpath is local; no installed `minko` haxelib is required:

```hxml
-cp src
-cp ../minko-glm/src
-cp ../minko-core/src
-cp ../minko-backend/src
-cp ../minko-hx/src
-main ExampleMain
-js bin/Main.js
```

Output: `bin/Main.js`.

## Run

Serve the repository/file system and open `bin/index.html` (or the host page that
loads `bin/Main.js`). The examples resolve effects/textures relative to the
working directory and the `asset/` folder.

## Switching examples

`src/ExampleMain.hx` currently starts the textured cube:

```haxe
import example.ExampleCube;

class ExampleMain {
    static function main() {
        new ExampleCube();
    }
}
```

Change the import and constructor to run any other class in `example/` or
`tutorial/`, for example `new example.ExamplePbr()` or
`new tutorial.WorkingPhongMaterial()`.

## Tests

The legacy test runner and test sources have moved to `../minko-test`. This
project now only builds and runs examples (`-main ExampleMain`); see
`../minko-test/README.md` for the test build and asset setup.
