package example;
import minko.geometry.Geometry;
import minko.render.AbstractContext;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
import minko.utils.VectorHelper;
class StarGeometry extends Geometry {
    inline static public function create(context:AbstractContext, numBranches:Int, outerRadius:Float, innerRadius:Float) {
        var ptr = new StarGeometry() ;
        ptr.initialize(context, numBranches, outerRadius, innerRadius);

        return ptr;
    }

    public function new() {
        super("star");
    }

    public function initialize(context:AbstractContext, numBranches:Int, outerRadius:Float, innerRadius:Float) {
        if (context == null) {
            throw ("context");
        }

        if (numBranches < 2) {
            throw ("numBranches");
        }

        var outRadius = Math.abs(outerRadius);
        var inRadius = Math.min(outRadius, Math.abs(innerRadius));

        // vertex buffer initialization
        var vertexSize = 3; // (x y z nx ny nz)
        var numVertices = 1 + 2 * numBranches;
        var vertexData:Array<Float> = VectorHelper.initializedList(numVertices * vertexSize, 0.0);

        var step = Math.PI / numBranches;
        var cStep = Math.cos(step);
        var sStep = Math.sin(step);

        var idx = vertexSize;
        var cAng = 1.0;
        var sAng = 0.0;

        for (i in 0...numBranches) {
            vertexData[idx] = outRadius * cAng;
            vertexData[idx + 1] = outRadius * sAng;
            idx += vertexSize;

            var c = cAng * cStep - sAng * sStep;
            var s = sAng * cStep + cAng * sStep;
            cAng = c;
            sAng = s;

            vertexData[idx] = inRadius * cAng;
            vertexData[idx + 1] = inRadius * sAng;
            idx += vertexSize;

            c = cAng * cStep - sAng * sStep;
            s = sAng * cStep + cAng * sStep;
            cAng = c;
            sAng = s;
        }

        var vertexBuffer = VertexBuffer.createbyData(context, vertexData);

        vertexBuffer.addAttribute("position", 3, 0);
        addVertexBuffer(vertexBuffer);

        // index buffer initialization
        var numTriangles = 2 * numBranches;

        var indexData:Array<Int> = [];// new List<ushort>(3 * numTriangles);

        idx = 0;

        for (i in 0... numTriangles) {
            indexData[idx++] = 0;
            indexData[idx++] = i + 1;
            indexData[idx++] = (i + 2 < numVertices)   ? i + 2 : 1;
        }

        indices = (IndexBuffer.createbyData(context, indexData));
    }
}

