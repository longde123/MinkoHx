
package minko.file;
import assimp.format.gltf2.GlTF2Importer;
import haxe.io.Bytes;
import assimp.Importer;
class Gltf2Parser extends ASSIMPParser {
    public function new() {
        super();
    }
    static public function create()
    {
        return new Gltf2Parser();
    }
    override public function provideLoaders( importer:Importer)
    {
        importer.registerLoader(new  GlTF2Importer());
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {

            //loadin gltf  bin file
            var assetName=filename.substr(0,filename.indexOf("gltf"))+"bin";
            var textureParentPrefixPath = File.extractPrefixPathFromFilename(resolvedFilename);
            var texturePrefixPath = File.extractPrefixPathFromFilename(assetName);
            var loader = Loader.create();
            loader.options = (options.clone());
            loader.options.includePaths.push(textureParentPrefixPath + "/" + texturePrefixPath);
            _loaderCompleteSlots.set(loader, loader.complete.connect(function(l:Loader) {
                nextParse(filename, resolvedFilename, options, data, assetLibrary,[ options.assetLibrary.blob(assetName)]);
            }));
            _loaderErrorSlots.set(loader, loader.error.connect(function(textureLoader, error) {
                LOG_DEBUG("Unable to find glb with filename '" + assetName + "'");
                _error.execute(this, ("MissingDependency" + assetName));
            }));
            loader.queue(assetName).load();

    }


}
