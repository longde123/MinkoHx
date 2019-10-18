package minko.geometry;
import minko.render.AbstractContext;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
@:expose("minko.geometry.SphereGeometry")
class SphereGeometry extends Geometry {
    public static function create(context:AbstractContext, numParallels = 10, numMeridians = 0, withNormals = true) {
        numMeridians = numMeridians != 0 ? numMeridians : numParallels;

        var geom = new SphereGeometry();

        geom.initializeVertices(context, numParallels, numMeridians, withNormals);
        geom.initializeIndices(context, numParallels, numMeridians);

        return geom;
    }


    private function initializeVertices(context:AbstractContext, numParallels, numMeridians, withNormals) {
        var numVertices = (numParallels - 2) * (numMeridians + 1) + 2;
        var c = 0;
        var k = 0;
        var data:Array<Float> = [];

        for (j in 1... numParallels - 1) {
            var i = 0;
            while (i < numMeridians + 1) {
                var theta = j / (numParallels - 1.0) * Math.PI;
                var phi = i / numMeridians * 2.0 * Math.PI;
                var x = Math.sin(theta) * Math.cos(phi) * .5;
                var y = Math.cos(theta) * .5;
                var z = -Math.sin(theta) * Math.sin(phi) * .5;

                // x, y, z
                data.push(x);
                data.push(y);
                data.push(z);

                // u, v
                data.push(1.0 - i / numMeridians);
                data.push(j / (numParallels - 1.0));

                // normal
                if (withNormals) {
                    data.push(x * 2.0);
                    data.push(y * 2.0);
                    data.push(z * 2.0);
                }

                i++;
                c += 3;
                k += 2;
            }
        }

        // north pole
        data.push(0.0);
        data.push(.5);
        data.push(0.0);

        data.push(.5);
        data.push(0.0);

        if (withNormals) {
            data.push(0.0);
            data.push(1.0);
            data.push(0.0);
        }

        // south pole
        data.push(0.0);
        data.push(-.5);
        data.push(0.0);

        data.push(.5);
        data.push(1.0);

        if (withNormals) {
            data.push(0.0);
            data.push(-1.0);
            data.push(0.0);
        }

        var stream:VertexBuffer = VertexBuffer.createbyData(context, data);

        stream.addAttribute("position", 3, 0);
        stream.addAttribute("uv", 2, 3);
        if (withNormals) {
            stream.addAttribute("normal", 3, 5);
        }

        addVertexBuffer(stream);

        computeCenterPosition();
    }

    private function initializeIndices(context:AbstractContext, numParallels, numMeridians) {
        //std::vector<unsigned short>    data(numParallels * numMeridians * 6);
        var data:Array<Int> = [];//((numParallels - 2) * numMeridians * 6);
        var c = 0;

        numMeridians++;
        for (j in 0...numParallels - 3) {
            for (i in 0...numMeridians - 1) {
                data[c++] = j * numMeridians + i;
                data[c++] = (j + 1) * numMeridians + i + 1;
                data[c++] = j * numMeridians + i + 1;

                data[c++] = j * numMeridians + i;
                data[c++] = (j + 1) * numMeridians + i;
                data[c++] = (j + 1) * numMeridians + i + 1;
            }
        }

        for (i in 0... numMeridians - 1) {
            data[c++] = (numParallels - 2) * numMeridians;
            data[c++] = i;
            data[c++] = i + 1;


            data[c++] = (numParallels - 2) * numMeridians + 1;
            data[c++] = (numParallels - 3) * numMeridians + i + 1;
            data[c++] = (numParallels - 3) * numMeridians + i;
        }

        indices = (IndexBuffer.createbyData(context, data));
    }

    public function new() {
        super("sphere");
    }
}
