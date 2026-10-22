package minko.native;

typedef OggFile = hl.Abstract<"fmt_ogg">;

/**
 * Minimal HashLink `fmt.hdll` OGG Vorbis bindings.
 * These are the same native entry points used by heaps' OggData.
 */
@:hlNative("fmt", "ogg_")
class Ogg {
    public static function open(bytes:hl.Bytes, size:Int):OggFile {
        return null;
    }

    public static function info(file:OggFile, bitrate:hl.Ref<Int>, frequency:hl.Ref<Int>, samples:hl.Ref<Int>, channels:hl.Ref<Int>):Void {
    }

    public static function read(file:OggFile, output:hl.Bytes, size:Int, format:Int):Int {
        return -1;
    }

    public static function seek(file:OggFile, sample:Int):Bool {
        return false;
    }
}
