package minko.file;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import minko.render.TextureFormat;
import minko.render.AbstractTexture;
class PNGWriter {
    static public function create():PNGWriter {
        return new PNGWriter();
    }
    public function new() {
    }
    public function writeToStream(destination:BytesOutput,  source:Array<Bytes>,   width,   height){

    }

}
