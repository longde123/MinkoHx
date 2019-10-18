package assimp.format.gltf2.types;
class Ref {
    static public var idCount:Int = 0;
    public var id:Int;
    public var index:Int;

    public function new() {
        id = idCount++;
    }
}
