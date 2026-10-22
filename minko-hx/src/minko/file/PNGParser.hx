package minko.file;
import minko.math.Rect;
import minko.utils.MathUtil;
import minko.file.MaxRectPacker.AtlasBuilder;
import haxe.io.Bytes;
import minko.render.AbstractTexture;
import minko.render.TextureFormat;
#if js
import minko.utils.WebNodeTools;
#end
@:expose("minko.file.PNGParser")
class PNGParser extends AbstractParser {

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {

#if js
        WebNodeTools.loadFromBytes("png", data, function(pd:PixelData) {
            pd.bytesPerPixel =  4 ;
            __parse(filename, resolvedFilename, options, pd, assetLibrary);
        });
#else
        try {
            var png = new format.png.Reader(new haxe.io.BytesInput(data)).read();
            var header = format.png.Tools.getHeader(png);
            var bgra = format.png.Tools.extract32(png);
            var rgba = Bytes.alloc(header.width * header.height * 4);
            var numPixels = header.width * header.height;
            for (i in 0...numPixels) {
                var o = i * 4;
                rgba.set(o, bgra.get(o + 2));
                rgba.set(o + 1, bgra.get(o + 1));
                rgba.set(o + 2, bgra.get(o));
                rgba.set(o + 3, bgra.get(o + 3));
            }

            var width = Math.floor(Math.min(MathUtil.clp2(header.width), 4096));
            var height = Math.floor(Math.min(MathUtil.clp2(header.height), 4096));
            if (width != header.width || height != header.height) {
                rgba = AbstractTexture.resizeData(header.width, header.height, rgba, width, height, true);
            }

            var pd = new PixelData(width, height, rgba);
            pd.bytesPerPixel = 4;
            __parse(filename, resolvedFilename, options, pd, assetLibrary);
        }
        catch (e:Dynamic) {
            _error.execute(this, Std.string(e));
        }
#end
    }

    public function __parse(filename:String, resolvedFilename:String, options:Options, data:PixelData, assetLibrary:AssetLibrary) {
        var bmpData:Bytes = data.pixels;
        var width = data.width;
        var height = data.height;

        var texture:AbstractTexture = null;

        if (options.isCubeTexture) {
            var parser:MipMapChainParser = new MipMapChainParser();
//parseMipMaps has some error
            var cubeTexture = parser.parseCubeTexture(
                options.context,
                width,
                height,
                bmpData,
                options.parseMipMaps,
                (options.parseMipMaps || options.generateMipmaps)&& !options.fixMipMaps,
                options.resizeSmoothly,
                TextureFormat.RGBA,
                filename
            );

            cubeTexture = cast(options.textureFunction(filename, cubeTexture));

            assetLibrary.setCubeTexture(filename, cubeTexture);
            texture = cubeTexture;
        }
        else if (options.isRectangleTexture) {
            // FIXME: handle rectangle textures
        }
        else {
            var parser:MipMapChainParser = new MipMapChainParser();

            var texture2d = parser.parseTexture(
                options.context,
                width,
                height,
                bmpData,
                options.parseMipMaps,
                (options.parseMipMaps || options.generateMipmaps)&& !options.fixMipMaps,
                options.resizeSmoothly,
                TextureFormat.RGBA,
                filename
            );

            texture2d = cast(options.textureFunction(filename, texture2d));

            texture = texture2d;
            assetLibrary.setTexture(filename, texture2d);
        }
        trace("PNGParser" + filename);
        texture.upload();

        if (options.disposeTextureAfterLoading)
            texture.disposeData();

        complete.execute(this);
    }
}
