package minko.geometry;
import glm.Mat4;
import minko.scene.Node;
class Bone {

    private var _node:Node;
    private var _offsetMatrix:Mat4;
    private var _vertexIds:Array<Int>;
    private var _vertexWeights:Array<Float>;

    public static function create(node, offsetMatrix, vertexIds, vertexWeights) {
        return new Bone(node, offsetMatrix, vertexIds, vertexWeights);
    }
    public var node(get, null):Node;

    function get_node() {
        return _node;
    }

    public var offsetMatrix(get, null):Mat4;

    function get_offsetMatrix() {
        return _offsetMatrix;
    }

    public var vertexIds(get, null):Array<Int>;

    function get_vertexIds() {
        return _vertexIds;
    }

    public var vertexWeights(get, null):Array<Float>;

    function get_vertexWeights() {
        return _vertexWeights;
    }

    public function new(node:Node, offsetMatrix:Mat4, vertexIds:Array<Int>, vertexWeights:Array<Float>) {
        this._node = node;
        this._offsetMatrix = offsetMatrix;
        this._vertexIds = (vertexIds);
        this._vertexWeights = (vertexWeights);
        if (_vertexIds.length != _vertexWeights.length) {
            throw ("A bone's arrays of vertex indices and vertex weights must have the same size.");
        }
    }

}
