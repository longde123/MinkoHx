package minko.deserialize;
import glm.Mat4;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.io.BytesInput;
import minko.render.Blending.Mode;
import minko.render.TriangleCulling;
class TypeDeserializer {
    private static function readInt32(stream:BytesInput) {
        return stream.readInt32();
    }

    public static function deserializeVectorInt32(serializedValue:BytesInput):Array<Int> {
        var result = new Array<Int>();
        var resultCount = serializedValue.readInt32();
        var i = 0;

        while (i < resultCount) {
            result.push(serializedValue.readInt32());
            i++;
        }

        return result;
    }


    public static function deserializeFloat(serializedValue:BytesInput) {
        return deserializeVectorFloat(serializedValue)[0];
    }

    public static function deserializeVectorFloat(serializedValue:BytesInput) {
        var result = new Array<Float>();
        var resultCount = serializedValue.readInt32();
        var i = 0;

        while (i < resultCount) {
            result.push(serializedValue.readFloat());
            i++;
        }

        return result;
    }

    public function deserializeVector4(serializedVector:Tuple<Int, BytesInput>) {
        var defaultValues = new Array<Float>();//4
        var serializedIndex = 0;
        var stream = serializedVector.second;;

        defaultValues[3] = 1 ;


        for (i in 0... 4) {
            if ((serializedVector.first & (1 << serializedIndex++)) != 0) {
                defaultValues[i] = stream.readFloat();
            }
            //defaultValues[i] = serializedVector.get<1>()[serializedIndex++];
        }

        return Vec4.fromFloatArray(defaultValues);
    }

    public function deserializeVector3(serializedVector:Tuple<Int, BytesInput>) {
        var defaultValues = new Array<Float>();//3
        var serializedIndex = 0;
        var stream = serializedVector.second;


        for (i in 0...3) {
            if ((serializedVector.first & (1 << serializedIndex++)) != 0) {
                defaultValues[i] = (stream.readFloat());
            }
            //            defaultValues[i] = serializedVector.get<1>()[serializedIndex++];
        }

        return Vec3.fromFloatArray(defaultValues);
    }

    public function deserializeVector2(serializedVector:Tuple<Int, BytesInput>) {
        var defaultValues = new Array<Float>();//2
        var serializedIndex = 0;
        var stream = serializedVector.second;

        for (i in 0...2) {

            if ((serializedVector.first & (1 << serializedIndex++)) != 0) {
                defaultValues[i] = (stream.readFloat());
            }
            //defaultValues[i] = serializedVector.get<1>()[serializedIndex++];
        }

        return Vec2.fromFloatArray(defaultValues);;
    }

    public function deserializeMatrix4x4(serializeMatrix:Tuple<Int, BytesInput>) {
        var matrixValues = new Array<Float>();//16
        var stream = serializeMatrix.second;
        //(&*serializeMatrix.a1.begin(), serializeMatrix.a1.size());
        matrixValues[0] = 1;
        matrixValues[5] = 1;
        matrixValues[10] = 1;
        matrixValues[15] = 1;

        for (i in 0...16) {
            if ((serializeMatrix.first & (1 << i)) != 0) {
                matrixValues[i] = (stream.readFloat());
            }
            //matrixValues[i] = serializeMatrix.a1[serializedIndex++];
        }

        return Mat4.fromFloatArray(matrixValues);
    }

    public function deserializeBlending(seriliazedBlending:Tuple<Int, BytesInput>) {
        var seriliazedBlending_second = seriliazedBlending.second.readString(seriliazedBlending.second.length);
        if (seriliazedBlending_second == "+") {
            return Mode.ADDITIVE;
        }

        if (seriliazedBlending_second == "a") {
            return Mode.ALPHA;
        }

        return Mode.DEFAULT ;
    }

    public function deserializeTriangleCulling(seriliazedTriangleCulling:Tuple<Int, BytesInput>) {
        var seriliazedTriangleCulling_second = seriliazedTriangleCulling.second.readString(seriliazedTriangleCulling.second.length);
        if (seriliazedTriangleCulling_second == "b") {
            return TriangleCulling.BACK ;
        }
        if (seriliazedTriangleCulling_second == "u") {
            return TriangleCulling.BOTH;
        }
        if (seriliazedTriangleCulling_second == "f") {
            return TriangleCulling.FRONT ;
        }
        return TriangleCulling.NONE ;
    }

    public function deserializeTextureId(seriliazedTextureId:Tuple<Int, BytesInput>) {
        return (seriliazedTextureId.first & 0x00FFFFFF);
    }

    public function deserializeString(serialized:Tuple<Int, BytesInput>) {
        return (serialized.second.readString(serialized.second.length));
    }

    public function new() {
    }
}
