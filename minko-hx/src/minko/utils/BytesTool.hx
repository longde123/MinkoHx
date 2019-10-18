package minko.utils;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
class BytesTool {
    public static function readUTF(b:BytesInput):String {
        var len = b.readInt32();
        return b.readString(len);
    }

    public static function readOneBytes(b:BytesInput):Bytes {
        var len = b.readInt32();
        return b.read(len);
    }

    public static function writeUTF(b:BytesOutput, bt:String) :Void{
        b.writeInt32(bt.length);
        b.writeString(bt);


    }

    public static function writeOneBytes(b:BytesOutput, bt:Bytes) :Void {
        b.writeInt32(bt.length);
        b.writeFullBytes(bt,0,bt.length);
    }
}
