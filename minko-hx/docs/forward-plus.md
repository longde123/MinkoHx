# Forward+ tile light culling

PBR forward 路径已启用 tile light culling。

## 1. 布局

- tile size：16 px。
- tile map：按 viewport 动态计算，纹理尺寸向上取 2 次幂。
- 每个 tile 一个 RGBA texel，共 32 bit 光源 mask。
- 最多 32 盏 point/spot light。

```text
tileMask.r → lights 0..7
tileMask.g → lights 8..15
tileMask.b → lights 16..23
tileMask.a → lights 24..31
```

## 2. CPU 侧

[LightTileCuller.hx](../src/minko/render/pbr/LightTileCuller.hx)：

- 投影每个 point/spot light 的位置和 `range` 到屏幕 AABB。
- 将覆盖到的 tile 对应 bit 置 1。
- 输出 `textureWidth × textureHeight` RGBA `Bytes`；逻辑 tile 数为 `ceil(width/16) × ceil(height/16)`，上限 128×128。

## 3. GPU 侧

`PBRForwardRenderer`：

- 每帧 cull 一次。
- viewport 变化时重建纹理，否则只上传新 mask。
- 每个 draw item 在材质绑定之后重新绑定 tile map，固定使用 texture unit 7，避免被材质贴图覆盖。

PBR shader：

- 每个 fragment 只采样一次所属 tile 的 mask。
- 点光循环仍然遍历 32 个槽位，但用 mask 跳过未覆盖的光源。
- 没有 tile map 时回退到全局 `uPointLightCount` 循环。

## 4. 验证

```text
light tiles: active=3 coveredBytes=256 texture=16x16
PASS light tiles: all point lights active
PASS light tiles: tile mask written
PASS light tiles: 16x16 mask texture`nPASS light tiles: 1280x720 texture 128x64
```

现有 spot/point 局部阴影测试继续通过。

## 5. 限制

- 逻辑 tile 数上限 128×128；超过后按 128×128 截断。
- 每 tile 最多 32 盏光，超过部分忽略。
- 不做屏幕空间 light list 压缩/排序。

## 6. Deferred 接入

deferred lighting 同样使用 tile mask（`DeferredLightingRenderer.bindLightTiles`）。修复过程中定位到三个真实缺陷，均已修复：

1. **tile mask bit 解码的浮点精度 bug**
   `floor(packed * 255.0 / exp2(bitIndex))` 在 packed=1/255 时因浮点误差得 0，导致 bit 0 光源被误剔除；且除法后加 `+0.5` 会让相邻 bit 误判。正确写法是先在**乘法后**取整，再做整数位提取：
   ```glsl
   float packed255 = floor(packed * 255.0 + 0.5);
   float bitValue = mod(floor(packed255 / exp2(float(bitIndex))), 2.0);
   ```
2. **纹理单元硬编码冲突**
   `setTextureAt(7, ...)` 与 `uShadowMap1` 的稠密 sampler slot 相撞（deferred 共 13 个 sampler，position 0..12）。sampler 必须绑定到 `UniformInput.position`。
3. **后端裸 `GL.bindTexture` 污染活跃 texture unit**（根因）
   后端（SDL `SDLGLContext` 与 WebGL `GlContext`）的 `createTexture` / `uploadTexture2dData` / `uploadCubeTextureData` / `uploadCompressedTexture2dData` / `generateMipmaps` 直接把纹理绑到"当前活跃 unit"，而该 unit 可能正是 `uAlbedoMap`（unit 0）等 live sampler。由于 per-unit 缓存未同步、且 draw 前没有重新绑定，G-buffer 输入被换成了 tile mask，整个 deferred 光照退化为 ambient。修复：后端跟踪 `_activeTextureUnit`，上传/创建/生成 mipmap 统一走 `beginTextureUpload` / `endTextureUpload` —— 在上传前后**保存并恢复该 unit 原有绑定**，并置 `_currentBoundTexture = -1` 使缓存失效。不使用固定 unit，因此任意 sampler 数量、任意 `MAX_TEXTURE_IMAGE_UNITS` 下都正确。

验证：

```text
deferred point light: near=0.164 far=0.056
deferred spot light:  lit=0.168 away=0.056
```

## 7. 回归防护

- `testBackendUploadQuirks`：同帧上传、隔帧上传、FBO 会话内上传、无关纹理上传。
- `testManySamplerThreshold`：1/2/4/8/12/13/16 个全部活跃的 sampler 均能正确采样各自的纹理。
