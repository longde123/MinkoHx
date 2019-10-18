package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TBuffer;
import haxe.io.Bytes;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Buffer {
    public var uri(default, null):String = "";
    public var name(default, null):String = "";
    public var data(default, null):Bytes = null;

    function new() {}

    function load(gltf:GLTF2, buffer:TBuffer, data:Bytes):Void {
        this.uri = buffer.uri;//DataURI  // Local file
        this.name = buffer.name;
        this.data = data;
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf, loadedBuffers:Array<Bytes>):Vector<Buffer> {
        var buffers:Vector<Buffer> = new Vector<Buffer>(raw.buffers.length);
        for (i in 0...raw.buffers.length) {
            buffers[i] = new Buffer();
        }
        for (i in 0...raw.buffers.length) {
            buffers[i].load(gltf, raw.buffers[i], loadedBuffers[i]);
        }
        return buffers;
    }
}
