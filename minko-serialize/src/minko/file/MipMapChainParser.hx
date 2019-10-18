package minko.file;
import glm.Vec2;
import haxe.io.Bytes;
import minko.render.AbstractContext;
import minko.render.CubeTexture;
import minko.render.Texture;
import minko.render.TextureFormat;
import minko.utils.MathUtil;
class MipMapChainParser {
    public function new() {
    }


    public function parseTexture(context:AbstractContext, width:Int, height:Int, data:Bytes, parseMipMaps:Bool, mipMapping = false, smooth = true, format = TextureFormat.RGBA, filename = "") {
        //todo

        var numLevels = mipMapping && parseMipMaps ? MathUtil.getp2(width) + 1 : 1;
        var actualHeight = height;

        if (mipMapping && parseMipMaps && width * 2 - 1 != height) {
            var diff = height - width * 2 - 1;

            actualHeight = height + Math.floor((diff + 1) / 2);
        }

        var bytesPerPixel = format == TextureFormat.RGB ? 3 : 4;
        var rgba:Bytes = Bytes.alloc(width * actualHeight * 4);
        var texture:Texture = Texture.create(context, width, actualHeight, mipMapping, false, smooth, TextureFormat.RGBA, filename);

        // FIXME: offset data to start parsing where width < MAX_SIZE

        parseMipMap(rgba, 0, data, 0, width, height, new Vec2(), width, actualHeight, bytesPerPixel);
        texture.data[0] = rgba;
        texture.upload();

        return texture;
        if (mipMapping && parseMipMaps) {
            var dataOffset = width * actualHeight * bytesPerPixel;
            //  var rgbaOffset = width * actualHeight * 4 ;

            for (level in 1... numLevels) {
                // incomplete mipmap chain
                if (dataOffset > width * height * bytesPerPixel) {
                    break;
                }

                var mipMapSize = Math.floor(Math.max(width >> level, 1) * Math.max(actualHeight >> level, 1) * 4);

                var textureRgbaData:Bytes = Bytes.alloc(mipMapSize);
                texture.data[level] = textureRgbaData;
                //textureRgbaData[rgbaOffset] todo
                parseMipMap(textureRgbaData, 0, data, dataOffset, width, height, new Vec2(), width >> level, actualHeight >> level, bytesPerPixel);

                dataOffset += width * (actualHeight >> level) * bytesPerPixel;
                texture.uploadMipLevel(level, textureRgbaData);

                // rgbaOffset += mipMapSize;
            }
        }

        return texture;
    }


    public function parseMipMap(_out:Bytes, rgbaOffset:Int, data:Bytes, dataOffset:Int, width:Int, height:Int, offset:Vec2, mipMapWidth, mipMapHeight, bytesPerPixel) {
        var endX = Math.floor(offset.x + mipMapWidth);
        var endY = Math.floor(offset.y + mipMapHeight);
        var idx = 0;
        for (y in Math.floor(offset.y)...endY) {
            for (x in Math.floor(offset.x) ... endX) {
                var xy = (x + y * width) * bytesPerPixel;
                for (i in 0... bytesPerPixel) {
                    _out.set(rgbaOffset + (idx++), data.get(dataOffset + (xy++)));
                }
                for (i in bytesPerPixel...4) {
                    _out.set(rgbaOffset + (idx++), 1);
                }
            }
        }
    }


    public function parseCubeTexture(context:AbstractContext, width:Int, height:Int, data:Bytes, parseMipMaps:Bool, mipMapping = false, smooth = true, format = TextureFormat.RGBA, filename = "") {
        var faceSize = Math.floor(width / 4);
        var texture:CubeTexture = CubeTexture.create(context, faceSize, faceSize, mipMapping, false, smooth, TextureFormat.RGBA, filename);
        var faces:Array<Face> = [Face.POSITIVE_X, Face.NEGATIVE_X, Face.POSITIVE_Y, Face.NEGATIVE_Y, Face.POSITIVE_Z, Face.NEGATIVE_Z];
        // horizontal cross layout
        var faceOffset:Array<Vec2> = [new Vec2(2, 1), new Vec2(0, 1), new Vec2(1, 0), new Vec2(1, 2), new Vec2(1, 1), new Vec2(3, 1)];
        var rgba:Bytes = Bytes.alloc(faceSize * faceSize * 4);
        var bytesPerPixel = format == TextureFormat.RGBA ? 4 : 3;

        for (i in 0... 6) {

            var offset = Vec2.multiplyScalar(faceOffset[i], faceSize, new Vec2());
            var face = faces[i];
            this.parseMipMap(rgba, 0, data, 0, width, height, offset, faceSize, faceSize, bytesPerPixel);
            texture.setData(rgba, face);
        }
        texture.upload();
        var eof = width * height * bytesPerPixel;
        if (mipMapping && parseMipMaps) {
            for (i in 0... 6) {
                var face = faces[i];
                var level = 1;
                var dataOffset = width * faceSize * 3 * bytesPerPixel;
                var size = faceSize / 2;
                while (size >= 1) {
                    var offset = Vec2.multiplyScalar(faceOffset[i], size, new Vec2());
                    // incomplete mipmap chain
                    if (dataOffset >= eof) {
                        break;
                    }
                    this.parseMipMap(rgba, 0, data, dataOffset, width, height, offset, size, size, bytesPerPixel);

                    // uint s = math::clp2(size);
                    //
                    // if (s != size)
                    // {
                    //     std::vector<unsigned char> resized(s * s * sizeof(int));
                    //
                    //     AbstractTexture::resizeData(size, size, &mipMapData[0], s, s, smooth, resized);
                    //     // mipMapData = std::move(resized);
                    //     mipMapData = resized;
                    // }

                    texture.uploadMipLevel(level, rgba, face);
                    dataOffset += Math.floor(width * size * 3 * bytesPerPixel);
                    size /= 2;
                    ++level;
                }
            }
        }

        return texture;
    }

    public function dispose() {
    }
}
