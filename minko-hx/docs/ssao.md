# Deferred SSAO

`SSAORenderer` 为 deferred 路径提供屏幕空间环境光遮蔽。

## 1. 使用

```haxe
var ssao = new SSAORenderer(context);
ssao.radius = 0.8;
ssao.bias = 0.025;
ssao.power = 1.4;
ssao.intensity = 1.0;

renderer.useDeferred = true;
renderer.ssaoRenderer = ssao;
```

`PBRRenderer` 只把 SSAO 接到 `DeferredPBRPath`；forward 路径不执行 SSAO。

## 2. 管线位置

```text
GBufferPass
  → SSAOPass
    → DeferredLightingPass
      → ForwardTransparentPass
```

- SSAO 读取 G-buffer depth + normal。
- 输出单张 RGBA target（rgb = AO）。
- 默认使用 3×3 depth-aware box blur 平滑 AO；`ssao.blur = false` 可关闭。
- `FrameContext.aoMap` 在 SSAOPass 中写入。
- `DeferredLightingRenderer` 用 `uAOMap` / `uHasAOMap` 只调制 ambient 项。

## 3. 参数

| 参数 | 默认 | 作用 |
| --- | --- | --- |
| `radius` | 0.6 | 采样半径 |
| `bias` | 0.025 | 深度比较偏移 |
| `power` | 1.4 | AO 曲线 |
| `intensity` | 1.0 | 遮蔽强度 |

## 4. 限制

- 仅 deferred。
- 固定 16 样本 kernel。
- 3×3 depth-aware blur，按深度差拒绝跨边缘样本。
- 只影响 ambient/间接光，不调制 direct light。
