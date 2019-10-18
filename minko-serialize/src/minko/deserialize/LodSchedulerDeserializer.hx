package minko.deserialize;
import haxe.io.BytesInput;
import minko.component.POPGeometryLodScheduler;
import minko.component.TextureLodScheduler;
import minko.file.AbstractSerializerParser.SceneVersion;
import minko.file.AssetLibrary;
import minko.file.Dependency;
class LodSchedulerDeserializer {
    public function new() {
    }

    public function deserializePOPGeometryLodScheduler(version:SceneVersion, serializedData:BytesInput, assetLibrary:AssetLibrary, dependency:Dependency) {
        var lodScheduler = POPGeometryLodScheduler.create();

        return lodScheduler;
    }

    public function deserializeTextureLodScheduler(version:SceneVersion, serializedData:BytesInput, assetLibrary:AssetLibrary, dependency:Dependency) {
        var lodScheduler = TextureLodScheduler.create(assetLibrary);

        return lodScheduler;
    }


}
