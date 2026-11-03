package minko.file;
@:expose("minko.file.AssetLocation")
class AssetLocation {
    public var filename:String;
    public var offset:Int;
    public var length:Int;

    public function new(filename, offset, length) {
        this.filename = (filename);
        this.offset = offset;
        this.length = length;
    }

}
