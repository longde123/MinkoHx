# 材质类

材质类位于 `minko-hx/src/minko/material/`，都直接或间接继承
`minko.material.Material`。材质只保存参数；具体 shader 由渲染路径或
`PipelineEffect` 决定。

## 1. Material

```haxe
class Material {
    public var version:Int;
    public function hasProperty(name:String):Bool;
    public function get(name:String):Dynamic;
    public function set(name:String, value:Dynamic):Material;
    public function unset(name:String):Void;
}
```

`version` 在每次 `set` / `unset` / `setbyKeyObject` / `copyFrom` 后递增，
PBR 渲染器的材质缓存依赖这个版本号。

## 2. PhongMaterial

```haxe
var material = PhongMaterial.create()
    .setDiffuse(new Vec3(0.8, 0.2, 0.2))
    .setSpecular(new Vec3(0.3, 0.3, 0.3))
    .setShininess(48.0)
    .setAlpha(1.0);
```

字段：

| 常量 | 默认值 | 类型 |
| --- | --- | --- |
| `DIFFUSE` | `Vec3(1,1,1)` | `Vec3` |
| `SPECULAR` | `Vec3(0.2,0.2,0.2)` | `Vec3` |
| `SHININESS` | `32` | `Float` |
| `AMBIENT` | `Vec3(0.1,0.1,0.1)` | `Vec3` |
| `EMISSIVE` | `Vec3(0,0,0)` | `Vec3` |
| `DIFFUSE_MAP` | – | `AbstractTexture` |
| `SPECULAR_MAP` | – | `AbstractTexture` |
| `NORMAL_MAP` | – | `AbstractTexture` |
| `ALPHA` | `1` | `Float` |
| `DOUBLE_SIDED` | `false` | `Bool` |

Phong 渲染路径见 `phong-render-path.md`：`PhongForwardRenderer` +
`ForwardPhongPath` / `PhongRenderer` 会消费这些字段，`NORMAL_MAP` 使用
Geometry 生成的 tangent。

## 3. PBRMaterial

`PBRMaterial` 已从 `minko.render.pbr` 移到 `minko.material`：

```haxe
import minko.material.PBRMaterial;

var material = PBRMaterial.create()
    .setBaseColor(new Vec4(0.8, 0.2, 0.2, 1.0))
    .setMetallic(0.2)
    .setRoughness(0.35);
```

字段：

| 常量 | 默认值 |
| --- | --- |
| `BASE_COLOR` | `Vec4(1,1,1,1)` |
| `BASE_COLOR_MAP` | – |
| `METALLIC` | `0` |
| `ROUGHNESS` | `0.5` |
| `EMISSIVE` | `Vec3(0,0,0)` |
| `NORMAL_SCALE` | `1` |
| `OCCLUSION` | `1` |
| `ALPHA_MODE` | `0` |
| `DOUBLE_SIDED` | `false` |

旧 import `minko.render.pbr.PBRMaterial` 已删除。
