package minko.serialize;
import minko.file.AbstractStream;
import haxe.io.BytesOutput;
import minko.component.AbstractComponent;
import minko.file.AssetLibrary;
import minko.file.Dependency;
import minko.scene.Node;
import minko.serialize.Types.StreamingComponentId;
class LodSchedulerSerializer {
    public function new() {
    }

    public function serializePOPGeometryLodScheduler(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependency:Dependency) {
        var type = StreamingComponentId.POP_GEOMETRY_LOD_SCHEDULER;

        var buffer = new AbstractStream();

        buffer.type=(type);
        return buffer ;
    }

    public function serializeTextureLodScheduler(node:Node, component:AbstractComponent, assetLibrary:AssetLibrary, dependency:Dependency) {
        var type = StreamingComponentId.TEXTURE_LOD_SCHEDULER;
        var buffer = new AbstractStream();

        buffer.type=(type);

        return buffer ;
    }

}
