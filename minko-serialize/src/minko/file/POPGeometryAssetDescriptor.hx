package minko.file;

//access
class LodDescriptor {
    public var level:Int;
    public var numIndices:Int;
    public var numVertices:Int;
    public var dataOffset:Int;
    public var dataLength:Int;
    public function new(level:Int, numIndices:Int,numVertices:Int, dataOffset:Int,dataLength:Int){

    }
}

class POPGeometryAssetDescriptor extends AbstractAssetDescriptor {

    private var _location:AssetLocation; //buffview

    private var _lodDescriptors:Array<LodDescriptor>;

    public static function create() {
        return new POPGeometryAssetDescriptor();
    }
//public var location(get,set):AssetLocation;
    override function set_location(l) {
        _location = l;

        return l;
    }

    override function get_location() {
        return _location;
    }
    public var numLodDescriptors(get, null):Int;

    function get_numLodDescriptors() {
        return _lodDescriptors.length;
    }

    public function addLodDescriptor(descriptor:LodDescriptor) {
        _lodDescriptors.push(descriptor);

        return (this);
    }

    public function lodDescriptor(index) {
        return _lodDescriptors[index];
    }

    public function new() {
        _lodDescriptors=[];
    }
}
