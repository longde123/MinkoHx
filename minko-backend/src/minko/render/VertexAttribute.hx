package minko.render;
@:expose("minko.render.VertexAttribute")
class VertexAttribute {
    public var resourceId:Int;
    public var vertexSize:Int;
    public var name:String;
    public var size:Int;
    public var offset:Int;


    public function equals(rhs:VertexAttribute) {
        return this.resourceId == rhs.resourceId && this.vertexSize == rhs.vertexSize && this.name == rhs.name && this.size == rhs.size && this.offset == rhs.offset;
    }

    public function new(_id, _vertexSize, name, size, actualOffset) {
        resourceId = _id;
        vertexSize = _vertexSize;
        this.name = name;
        this.size = size;
        this.offset = actualOffset;
    }
}
