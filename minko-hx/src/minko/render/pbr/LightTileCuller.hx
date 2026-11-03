package minko.render.pbr;

import glm.Mat4;
import glm.Vec4;
import haxe.io.Bytes;
import minko.render.light.Light;
import minko.render.light.Light.LightType;

class LightTileMap {
    public var bytes:Bytes;
    public var textureWidth:Int;
    public var textureHeight:Int;
    public var mapWidth:Int;
    public var mapHeight:Int;
    public var tileSize:Int;
    public var activeLights:Int;

    public function new(bytes:Bytes, textureWidth:Int, textureHeight:Int,
                        mapWidth:Int, mapHeight:Int, tileSize:Int, activeLights:Int) {
        this.bytes = bytes;
        this.textureWidth = textureWidth;
        this.textureHeight = textureHeight;
        this.mapWidth = mapWidth;
        this.mapHeight = mapHeight;
        this.tileSize = tileSize;
        this.activeLights = activeLights;
    }
}

/**
 * CPU tile light culling for forward+.
 *
 * One RGBA texel per tile stores a 32-bit light mask. A fragment reads its
 * tile mask once and skips light slots whose bit is not set. This avoids
 * dynamic uniform-array indexing in GLSL 120.
 */
class LightTileCuller {
    public var tileSize:Int;
    public var mapWidth:Int;
    public var mapHeight:Int;

    public function new() {
        tileSize = 16;
        mapWidth = 64;
        mapHeight = 64;
    }

    public function cull(lights:Array<Light>, view:Mat4, projection:Mat4, width:Int, height:Int):LightTileMap {
        var logicalWidth = Std.int(Math.max(1, Math.min(128, Math.ceil(width / tileSize))));
        var logicalHeight = Std.int(Math.max(1, Math.min(128, Math.ceil(height / tileSize))));
        var textureWidth = nextPowerOfTwo(logicalWidth);
        var textureHeight = nextPowerOfTwo(logicalHeight);
        var bytes = Bytes.alloc(textureWidth * textureHeight * 4);
        var active = 0;

        if (lights != null && width > 0 && height > 0) {
            for (i in 0...lights.length) {
                if (active >= 32) break;
                var light = lights[i];
                if (light.type != LightType.Point && light.type != LightType.Spot) {
                    continue;
                }
                var viewPosition = Mat4.multVec(view, new Vec4(light.position.x, light.position.y, light.position.z, 1.0), new Vec4());
                if (viewPosition.z >= -0.1) {
                    continue;
                }
                var clip = Mat4.multVec(projection, viewPosition, new Vec4());
                if (Math.abs(clip.w) < 0.0001) {
                    continue;
                }
                var screenX = (clip.x / clip.w * 0.5 + 0.5) * width;
                var screenY = (clip.y / clip.w * 0.5 + 0.5) * height;
                var radiusPixels = Math.abs(projection.r1c1 * light.range / viewPosition.z) * height * 0.5;
                radiusPixels = Math.max(4.0, Math.min(Math.max(width, height) * 2.0, radiusPixels));

                var minX = Std.int(Math.max(0, Std.int(Math.floor((screenX - radiusPixels) / tileSize))));
                var maxX = Std.int(Math.min(logicalWidth - 1, Std.int(Math.floor((screenX + radiusPixels) / tileSize))));
                var minY = Std.int(Math.max(0, Std.int(Math.floor((screenY - radiusPixels) / tileSize))));
                var maxY = Std.int(Math.min(logicalHeight - 1, Std.int(Math.floor((screenY + radiusPixels) / tileSize))));
                if (minX > maxX || minY > maxY) {
                    continue;
                }

                var channel = Std.int(i / 8);
                var bit = 1 << (i % 8);
                var stored = false;
                for (ty in minY...(maxY + 1)) {
                    for (tx in minX...(maxX + 1)) {
                        var offset = (ty * textureWidth + tx) * 4 + channel;
                        var value = bytes.get(offset);
                        bytes.set(offset, value | bit);
                        stored = true;
                    }
                }
                if (stored) {
                    active++;
                }
            }
        }

        return new LightTileMap(bytes, textureWidth, textureHeight, logicalWidth, logicalHeight, tileSize, active);
    }

    private function nextPowerOfTwo(value:Int):Int {
        var result = 1;
        while (result < value) {
            result <<= 1;
        }
        return result;
    }
}
