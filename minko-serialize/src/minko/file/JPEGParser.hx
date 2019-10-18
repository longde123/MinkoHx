package minko.file;
import haxe.io.Bytes;
import minko.data.PixelData;
import minko.render.AbstractTexture;
import minko.render.TextureFormat;
import minko.utils.WebNodeTools;
class JPEGParser extends AbstractParser {


    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {

        WebNodeTools.loadFromBytes("jpg", data, function(pd:PixelData) {
            __parse(filename, resolvedFilename, options, pd, assetLibrary);
        });
    }

    public function __parse(filename:String, resolvedFilename:String, options:Options, data:PixelData, assetLibrary:AssetLibrary) {
        var bmpData:Bytes = data.pixels;
        var width = data.width;
        var height = data.height;

        var texture:AbstractTexture = null;

        if (options.isCubeTexture) {
            var parser:MipMapChainParser = new MipMapChainParser();

            var cubeTexture = parser.parseCubeTexture(
                options.context,
                width,
                height,
                bmpData,
                options.parseMipMaps,
                options.parseMipMaps || options.generateMipmaps,
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
                options.parseMipMaps || options.generateMipmaps,
                options.resizeSmoothly,
                TextureFormat.RGBA,
                filename
            );

            texture2d = cast(options.textureFunction(filename, texture2d));

            texture = texture2d;
            assetLibrary.setTexture(filename, texture2d);
        }
        trace("JPEGParser" + filename);
        texture.upload();

        if (options.disposeTextureAfterLoading)
            texture.disposeData();

        complete.execute(this);
    }
}
