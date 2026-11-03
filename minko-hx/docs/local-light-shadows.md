# 局部光源阴影

新管线在方向光 CSM 之外支持：

- Spot light：单张 2D shadow map。
- Point light：6 面 cube shadow（4×3 face atlas，最多 2 盏点光共 12 格）。

首版每帧最多一盏 shadow-casting spot 和一盏 shadow-casting point。

## 1. Spot

- `FrameContext.spotShadow:SpotShadow`
- `SpotShadow`：
  - `target`
  - `lightViewProjection`
  - `lightIndex`
- `ShadowRenderer.renderSpot(...)`：
  - 由 `position` / `direction` / `outerCone` / `range` 构造 view/projection。
  - 投影到 2D depth target。

## 2. Point

- `FrameContext.pointShadow:PointShadow`
- `PointShadow`：
  - `atlas`（4×3 face atlas）
  - `matrices[6]`
  - `lightIndex`
  - `position`
  - `range`
- `ShadowRenderer.renderPointAtlas(...)`：
  - +X/-X/+Y/-Y/+Z/-Z 六个方向各渲染一次。
  - shader 根据 `worldPosition - lightPosition` 的最大分量选择 face。

## 3. Path 配置

`ForwardPath` / `DeferredPBRPath`：

```haxe
spotShadowSize:Int = 512
pointShadowSize:Int = 512
enableLocalShadows:Bool = true
```

- ShadowPass 顺序：方向光 → spot → point。
- shadow resources 作为 scene/lighting pass 的依赖。
- graph cache 跨帧复用，重新 acquire 局部 shadow targets。

`PBRRenderer` / `PhongRenderer` 暴露同名配置。PBR forward/deferred 和 Phong
forward 都采样局部阴影；Phong 只支持单张方向光 + 局部阴影，不支持 CSM。

## 4. Shader

PBR forward / deferred：

- `uSpotShadowMap` / `uSpotShadowMatrix` / `uSpotShadowLightIndex` / `uHasSpotShadow`
- `uPointShadowAtlas` / `uPointShadowMatrix0..5` / `uPointShadowPosition` /
  `uPointShadowRange` / `uPointShadowLightIndex` / `uHasPointShadow`

点光循环中：

```glsl
if (uHasSpotShadow > 0.5 && i == int(uSpotShadowLightIndex)) attenuation *= spotShadowFactor(worldPosition);
if (uHasPointShadow > 0.5 && i == int(uPointShadowLightIndex)) attenuation *= pointShadowFactor(worldPosition);
```

## 5. 限制

- 每帧只支持一盏 point shadow 和一盏 spot shadow。
- point shadow 默认使用**硬件 cube map**（`samplerCube`）：每盏点光渲染 6 个面到 `CubeTexture`，fragment 写入线性距离/range；采样时 `textureCube(cube, worldPosition - lightPosition)` 与 `length(...)/range` 比较，**不需要逐面矩阵与 cell 选择**。
- 旧 4×3 2D atlas 作为回退保留（`uPointShadowAtlas`）；`shadowAtAtlas(..., grid)` 必须传 `vec2(4.0, 3.0)`，单槽若误用 3×2 会导致 UV 子区域错位。
- 渲染到 cube 面由后端 `beginCubeFaceRender/endCubeFaceRender` 提供（SDL 与 WebGL 均实现），每面独立 depth renderbuffer。
- shadow 采样使用 3×3 PCF；`uShadowTexelSize` 由 path 的 `shadowMapSize` 计算。`ShadowRenderer.softShadows` 打开后执行 PCSS：5×5 blocker search + 可变半径 PCF。
- 不做 CSM 与局部阴影的级联融合。
