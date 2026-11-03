# PhongRenderer 组件

`minko.component.PhongRenderer` 把 Phong 前向路径接到 scene graph /
`SceneManager`，用法与 `PBRRenderer` 类似，但不包含 deferred。

## 1. 使用

```haxe
var root = Node.create("root");
root.addComponent(SceneManager.create(canvas));

var cameraNode = Node.create("camera")
    .addComponent(Transform.create())
    .addComponent(PerspectiveCamera.create(1.0));
root.addChild(cameraNode);

var mesh = Node.create("mesh")
    .addComponent(Transform.create())
    .addComponent(Surface.create(geometry, PhongMaterial.create(), null));
root.addChild(mesh);

var lightNode = Node.create("light")
    .addComponent(Transform.create())
    .addComponent(DirectionalLight.create());
root.addChild(lightNode);

var renderer = PhongRenderer.create();
root.addComponent(renderer);
```

## 2. API

```haxe
class PhongRenderer extends AbstractComponent {
    public static function create(priority:Float = 0.0, name:String = ""):PhongRenderer;

    public var pipeline(get, null):RenderPipeline;
    public var renderer(get, null):PipelineRenderer;
    public var forwardPath(get, null):ForwardPhongPath;
    public var forwardRenderer(get, null):PhongForwardRenderer;

    public var postProcess:PostProcessChain;
    public var shadowRenderer:ShadowRenderer;
    public var lightViewProjection:Mat4;
    public var shadowMapSize:Int;

    public var lights(get, null):LightSet;
    public var enabled:Bool;
    public var priority:Float;

    public var renderingBegin(get, null):Signal<PhongRenderer>;
    public var renderingEnd(get, null):Signal<PhongRenderer>;

    public function addLight(light:Light):PhongRenderer;
    public function clearLights():Void;
}
```

- `pipeline` / `renderer` / `forwardPath` 在首次渲染后可用。
- `postProcess` / `shadowRenderer` / `lightViewProjection` / `shadowMapSize`
  每帧同步到 `ForwardPhongPath`。
- `lights` 是合并结果：手动 `addLight()` + 场景中的 `LightComponent`。
- `renderingBegin` / `renderingEnd` 在 `pipeline.render()` 前后触发。

## 3. 与 PBRRenderer 的差异

| | PBRRenderer | PhongRenderer |
| --- | --- | --- |
| forward path | `ForwardPBRPath` | `ForwardPhongPath` |
| deferred | 支持 `useDeferred` | 不支持 |
| G-Buffer | 支持 | 不支持 |
| 材质 | `PBRMaterial` | `PhongMaterial` |
| 灯光组件 | 支持 | 支持 |

## 4. 生命周期

- `targetAdded` 查找最近的 `SceneManager` 并订阅 `renderingEnd`。
- `targetRemoved` / `dispose` 释放 pipeline、path、renderer、信号。
- 切换 SceneManager 或 canvas context 会重建 pipeline。
