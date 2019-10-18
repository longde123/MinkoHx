package minko.geometry;
import minko.render.AbstractContext;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
@:expose("minko.geometry.QuadGeometry")
class QuadGeometry extends Geometry {
    private var _numColumns:Int;
    private var _numRows:Int;
    private var _width:Float;
    private var _height:Float;

    public static function create(context:AbstractContext, numColumns = 1, numRows = 1, width = 1.0, height = 1.0):QuadGeometry {
        var geom = new QuadGeometry(numColumns, numRows, width, height);

        geom.initialize(context);

        return geom;
    }

    public function new(numColumns = 1, numRows = 1, width = 1.0, height = 1.0) {
        super("quad_" + (numColumns) + "x" + (numRows));
        this._numColumns = numColumns;
        this._numRows = numRows;
        this._width = width;
        this._height = height;
    }

    private function initialize(context:AbstractContext) {
        var vertexData:Array<Float> = [];
        var indicesData:Array<Int> = [];

        var y = 0;
        while (y <= _numRows) {
            var x = 0;
            while (x <= _numColumns) {
                vertexData.push((x / _numColumns - 0.5) * _width);
                vertexData.push((y / _numRows - 0.5) * _height);
                vertexData.push(0.0);
                vertexData.push(0.0);
                vertexData.push(0.0);
                vertexData.push(1.0);
                vertexData.push(x / _numColumns);
                vertexData.push(1.0 - y / _numRows);
                x++;
            }
            y++;
        }

        for (y in 0..._numRows) {
            for (x in 0... _numColumns) {
                indicesData.push(x + (_numColumns + 1) * y);
                indicesData.push(x + 1 + y * (_numColumns + 1));
                indicesData.push((y + 1) * (_numColumns + 1) + x);
                indicesData.push(x + 1 + y * (_numColumns + 1));
                indicesData.push((y + 1) * (_numColumns + 1) + x + 1);
                indicesData.push((y + 1) * (_numColumns + 1) + x);
            }
        }

        var vertexBuffer:VertexBuffer = VertexBuffer.createbyData(context, vertexData);
        var indexBuffer:IndexBuffer = IndexBuffer.createbyData(context, indicesData);

        vertexBuffer.addAttribute("position", 3, 0);
        vertexBuffer.addAttribute("normal", 3, 3);
        vertexBuffer.addAttribute("uv", 2, 6);
        addVertexBuffer(vertexBuffer);

        indices = (indexBuffer);

        computeCenterPosition();
    }

}
