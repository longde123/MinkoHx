# PBRRenderer 组件

`minko.component.PBRRenderer` 把新渲染管线接到 scene graph / `SceneManager`
帧循环。旧 `minko.component.Renderer` 及其 `DrawCallPool` / `Effect` / `Pass`
路径已删除，这是唯一场景图渲染入口。

## 1. 使用

```haxe
var renderer = PBRRenderer.create();
root.addComponent(renderer);

renderer.addLight(Light.directional());
```

`PBRRenderer` 从 `target.root` 查找 `SceneManager`，订阅
`SceneManager.renderingEnd`（按 `priority` 排序），每帧：

```text
SceneManager.nextFrame
  → SceneManager.renderingEnd
    → PBRRenderer._renderFrame
      → SceneCollector.collect(root, queue)
      → PBRForwardRenderer.render(...)
      → ForwardPBRPath / RenderGraph
      → present
```

相机 view/projection / camera position 由 `PipelineRenderer` 内部的
`SceneCollector` 自动更新；`PerspectiveCamera` 放在 root 的子树即可。

## 2. API

```haxe
class PBRRenderer extends AbstractComponent {
    public static function create(priority:Float = 0.0, name:String = ""):PBRRenderer;

    public var pipeline(get, null):RenderPipeline;
    public var renderer(get, null):PipelineRenderer;
    public var forwardPath(get, null):ForwardPBRPath;
    public var forwardRenderer(get, null):PBRForwardRenderer;
    public var deferredPath(get, null):DeferredPBRPath;
    public var useDeferred(get, set):Bool;

    public var postProcess:PostProcessChain;
    public var shadowRenderer:ShadowRenderer;
    public var lightViewProjection:Mat4;
    public var shadowMapSize:Int;
    public var shadowCascadeCount:Int;
    public var shadowSplitLambda:Float;
    public var shadowLightDirection:Vec3;
    public var shadowMaxDistance:Float;
    public var spotShadowSize:Int;
    public var pointShadowSize:Int;
    public var enableLocalShadows:Bool;
    public var ssaoRenderer:SSAORenderer;

    public var lights(get, null):LightSet;
    public var enabled:Bool;
    public var priority:Float;

    public var renderingBegin(get, null):Signal<PBRRenderer>;
    public var renderingEnd(get, null):Signal<PBRRenderer>;

    public function addLight(light:Light):PBRRenderer;
    public function clearLights():Void;
}
```

- `pipeline` / `renderer` / `forwardPath` / `forwardRenderer` 在首次渲染后可用。
- `postProcess` / `shadowRenderer` / `lightViewProjection` / `shadowMapSize`
  在每帧 render 前同步到 `forwardPath`，挂载前后赋值都有效。
- `lights` 是组件持有的合并 `LightSet`；`addLight` / `clearLights` 操作手动灯光，
  场景中的 `LightComponent` 每帧自动合并进来。
- `priority` 修改后会重新连接 SceneManager 信号，更新多个 Renderer 的顺序。
- `renderingBegin` / `renderingEnd` 在 `PipelineRenderer.render()` 前后触发。

## 3. 默认路径

组件默认创建：

```text
PBRForwardRenderer
  → ForwardPBRPath(renderScene = forwardRenderer.render)
    → PipelineRenderer
```

- 默认没有 shadow / post-process；设置 `shadowRenderer` / `postProcess`
  后下一帧生效。
- 阴影需要同时提供 `shadowRenderer` 和 `lightViewProjection`；路径会在
  支持 depth texture 时启用 `ShadowPass`。
- `shadowCascadeCount > 1` 时使用 CSM；此时 `shadowLightDirection` 和
  `shadowMaxDistance` 生效，`lightViewProjection` 只用于单级兼容路径。
- `enableLocalShadows` 打开后，每帧第一盏 `castShadow` spot / point light
  会生成局部 shadow map；`spotShadowSize` / `pointShadowSize` 控制尺寸。
- `ssaoRenderer` 只在 `useDeferred = true` 时接入 `DeferredPBRPath`；
  forward 路径忽略它。
- forward 路径自动构建 64×64 tile light mask，最多 32 盏 point/spot light；
  无需额外配置。

## 4. Forward / Deferred 切换

```haxe
renderer.useDeferred = true;   // 下一帧走 DeferredPBRPath
renderer.useDeferred = false;  // 下一帧回到 ForwardPBRPath
```

- 两种路径共享 `lights`、`postProcess`、`shadowRenderer`、
  `lightViewProjection` 和 `shadowMapSize`。
- Deferred 路径使用 `GBufferRenderer`（有 MRT）或
  `GBufferFallbackRenderer`（无 MRT），然后由 `DeferredLightingRenderer`
  做光照。
- 透明队列通过 `PBRForwardRenderer.renderTransparent()` 绘制：先复制
  deferred scene color，再以 alpha blending 画透明物体。
- `deferredPath` 在首次创建后可用，可直接设置 shadow 等高级选项。
- 点光/聚光与方向光阴影依赖 depth texture；无 depth 时 Deferred 自动退化
  为方向光、无阴影。
- 相机矩阵由 `PipelineRenderer` 每帧从场景收集，不需要手动同步。

## 4. 光照

新管线使用 `minko.render.light.Light`；旧 light 组件已随旧管线删除：

```haxe
var light = Light.directional();
light.direction = new Vec3(0.0, 0.0, -1.0);
light.intensity = 3.0;
renderer.addLight(light);
```

- 光照通过 `addLight()` 或场景中的 `LightComponent`
  （`DirectionalLight` / `PointLight` / `SpotLight`）管理；两种来源每帧合并。

## 5. 生命周期

- `targetAdded`：连接 root 的 `componentAdded/componentRemoved`，查找
  `SceneManager`；SceneManager 后添加也能接上。
- SceneManager 变化/移除：断开渲染信号，dispose 当前管线。
- `targetRemoved` / `dispose`：
  - 断开 SceneManager 与 root 信号；
  - dispose `PipelineRenderer`；
  - dispose `PBRForwardRenderer`；
  - 清空 pipeline / path / renderer 引用。
- `postProcess` / `shadowRenderer` 由调用方持有，组件不 dispose 它们。

## 6. 限制

- 只提供 Forward PBR；Deferred 继续使用 `PipelineRenderer` +
  `DeferredPBRPath` 手动接线。
- 忽略 `SceneManager` 传入的 renderTarget；输出到当前 canvas/backbuffer。
- 一个根场景只允许一个 SceneManager。
- `PBRRenderer` 是新管线唯一的场景图入口，旧 `Renderer` 已删除。
