# Phong 前向渲染路径

Phong 路径与 PBR 前向路径并列，使用 `PhongMaterial` 和相同的
`FrameContext` 灯光。

## 1. 使用

```haxe
import minko.material.PhongMaterial;
import minko.render.phong.PhongForwardRenderer;
import minko.render.pipeline.ForwardPhongPath;
import minko.render.pipeline.PipelineRenderer;

var material = PhongMaterial.create()
    .setDiffuse(new Vec3(0.8, 0.3, 0.2))
    .setSpecular(new Vec3(0.6, 0.6, 0.6))
    .setShininess(64.0);

var phongRenderer = new PhongForwardRenderer(context);
var path = new ForwardPhongPath(
    function(queue, frame, target) phongRenderer.render(queue, frame, target),
    postProcess
);
var pipeline = new PipelineRenderer(context, root, path, width, height);
pipeline.pipeline.lights.add(Light.directional());
```

## 2. 支持范围

- 方向光、点光、聚光；
- 单张方向光 shadow map（`frame.shadowMap`）；
- `diffuse` / `specular` / `shininess` / `ambient` / `emissive`；
- `diffuseMap` / `specularMap` / `normalMap`；
- `alpha` 透明混合；
- `doubleSided` 关闭背面剔除；
- `PipelineEffect` Forward / Transparent stage 覆盖；
- `ForwardPath` 的 graph/pass 跨帧复用、shadow pass、post-process。

## 3. Normal Map

`PhongMaterial.NORMAL_MAP` 使用 tangent-space normal map：

- `Geometry.computeTangents()` 生成 `tangent` vec4（xyz + handedness）。
- `CubeGeometry` 自动生成。
- Phong vertex shader 传递 tangent 和 handedness。
- fragment shader 用 TBN 采样 normal map。
- 没有 tangent 的 Geometry 自动回退到几何 normal。

## 4. 限制

- 不支持 CSM 或 point/spot shadow。
- 没有 built-in Phong deferred 路径。
- `PhongRenderer` 场景组件不包含 deferred 切换。
