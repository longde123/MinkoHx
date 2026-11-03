# 场景灯光组件

灯光组件位于 `minko-hx/src/minko/component/`。它们把 `minko.render.light.Light`
挂到 scene graph，并由 `PBRRenderer` 每帧收集。

## 1. 使用

```haxe
var lightNode = Node.create("key-light")
    .addComponent(Transform.create())
    .addComponent(DirectionalLight.create(new Vec3(1.0, 0.95, 0.9), 2.0));

root.addChild(lightNode);
```

点光：

```haxe
var pointNode = Node.create("fill-light")
    .addComponent(Transform.create())
    .addComponent(PointLight.create(new Vec3(0.3, 0.5, 1.0), 4.0, 12.0));
```

聚光：

```haxe
var spotNode = Node.create("spot-light")
    .addComponent(Transform.create())
    .addComponent(SpotLight.create(new Vec3(1.0, 1.0, 1.0), 6.0, 15.0, 0.9, 0.7));
```

## 2. Transform 约定

- 位置：`modelToWorldMatrix` 的平移分量。
- 方向：Transform 的 **-Z** 方向。
- 没有 Transform 时保留 light 默认值。
- Transform 在 `SceneManager.renderingBegin` 更新，`PBRRenderer` 在
  `renderingEnd` 收集，因此当帧看到的是最新矩阵。

## 3. API

```haxe
class LightComponent extends AbstractComponent {
    public var light(get, null):Light;
    public var type(get, null):LightType;

    public var color(get, set):Vec3;
    public var intensity(get, set):Float;
    public var range(get, set):Float;
    public var innerCone(get, set):Float;
    public var outerCone(get, set):Float;
    public var castShadow(get, set):Bool;

    public function syncFromTransform():Void;
}
```

链式 setter：

```haxe
light.setColor(color)
     .setIntensity(2.0)
     .setRange(10.0)
     .setCone(0.9, 0.7)
     .setCastShadow(true);
```

子类：

- `DirectionalLight`
- `PointLight`
- `SpotLight`

## 4. 与 PBRRenderer 的关系

`PBRRenderer` 每帧：

1. 清空合并灯光集；
2. 加入 `addLight()` 手动添加的灯；
3. 遍历场景中的 `LightComponent`，`syncFromTransform()` 后加入；
4. 把合并结果设置给 `pipeline.lights`。

手动添加与组件灯光可以共存：

```haxe
renderer.addLight(Light.point());   // 手动
// 场景中另有 LightComponent
```

同一盏灯不要既 `addLight()` 又挂组件，否则会重复。
