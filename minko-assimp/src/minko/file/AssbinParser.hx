package minko.file;
import assimp.format.assbin.AssbinLoader;
import assimp.Importer;
class AssbinParser extends ASSIMPParser {
    public function new() {
    }
    static public function create()
    {
        return new AssbinParser();
    }
    override public function provideLoaders( importer:Importer)
    {
        importer.registerLoader(new  AssbinLoader());
    }

}
