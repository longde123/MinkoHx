package minko.serialize;
import glm.Mat4;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.io.BytesOutput;
import haxe.io.Output;
import minko.render.Blending.Mode;
import minko.render.TriangleCulling;
import minko.serialize.Types.MinkoTypes;
class TypeSerializer {
    private static function writeInt8(stream:Output, value:Int) {
        stream.writeInt8(value);
    }

    public static function serializeVectorInt8(vect:Array<Int>) {
        var stream:BytesOutput = new BytesOutput();

        for (value in vect) {
            writeInt8(stream, value);
        }

        return stream;
    }

    private static function writeInt32(stream:Output, value:Int) {
        stream.writeInt32(value);
    }

    public static function serializeVectorInt32(vect:Array<Int>):BytesOutput {
        var stream:BytesOutput = new BytesOutput();

        for (value in vect) {
            writeInt32(stream, value);
        }

        return stream;
    }

    private static function writeFloat(stream:Output, value:Float) {
        stream.writeFloat(value);
    }

    public static function serializeVectorFloat(vect:Array<Float>):BytesOutput {
        var stream:BytesOutput = new BytesOutput();

        for (value in vect) {
            writeFloat(stream, value);
        }

        return stream;
    }

    static public function serializeVector4(value:Vec4) {
        var type = 0x00000000;
        var stream:BytesOutput = new BytesOutput();
        type += MinkoTypes.VECTOR4 << 24;
        var values:Array<Float> = value.toFloatArray();
        for (i in 0...4) {
            var compareValue = 0;
            if (i == 3) {
                compareValue = 1;
            }
            if (values[i] != compareValue) {
                writeFloat(stream, values[i]);
                type += 1 << i;
            }
        }
        return new Tuple<Int, BytesOutput>(type, stream);
    }

    static public function serializeVector3(value:Vec3) {
        var type = 0x00000000;
        var stream:BytesOutput = new BytesOutput();
        var values:Array<Float> = value.toFloatArray();
        type += MinkoTypes.VECTOR3 << 24;

        for (i in 0... 3) {
            if (values[i] != 0) {
                writeFloat(stream, values[i]);
                type += 1 << i;
            }
        }

        return new Tuple<Int, BytesOutput>(type, stream);
    }

    static public function serializeVector2(value:Vec2) {

        var type = 0x00000000;
        var values = value.toFloatArray();
        var stream:BytesOutput = new BytesOutput();

        type += MinkoTypes.VECTOR2 << 24;

        for (i in 0... 2) {
            if (values[i] != 0) {
                //res.push_back(values[i]);
                writeFloat(stream, values[i]);
                type += 1 << i;
            }
        }

        return new Tuple<Int, BytesOutput>(type, stream);
    }

    static public function serializeMatrix4x4(value:Mat4):Tuple<Int, BytesOutput> {
        var type = 0x00000000;
        var values = value.toFloatArray();
        var stream:BytesOutput = new BytesOutput();
        type += MinkoTypes.MATRIX4X4 << 24;
        for (i in 0... 16) {
            var compareValue = 0;
            if (i == 0 || i == 5 || i == 10 || i == 15) {
                compareValue = 1;
            }
            if (values[i] != compareValue) {
                type += 1 << i;
                //res.push_back(values[i]);
                writeFloat(stream, values[i]);
            }
        }
        return new Tuple<Int, BytesOutput>(type, stream);
    }

    static public function serializeBlending(mode:Mode) {
        var res = "";
        if (mode == Mode.ADDITIVE) {
            res = "+";
        }
        else if (mode == Mode.ALPHA) {
            res = "a";
        }
        else {
            res = "d";
        }
        var type = 0x00000000;

        type += MinkoTypes.BLENDING << 24;
        var stream:BytesOutput = new BytesOutput();
        stream.writeString(res)
        return new Tuple<Int, BytesOutput>(type, stream);
    }

    static public function serializeCulling(tc:TriangleCulling) {

        var res = "";

        if (tc == TriangleCulling.BACK) {
            res = "b";
        }
        else if (tc == TriangleCulling.BOTH) {
            res = "u";
        }
        else if (tc == TriangleCulling.FRONT) {
            res = "f";
        }
        else if (tc == TriangleCulling.NONE) {
            res = "n";
        }
        else {
            res = "b";
        }
        var type = 0x00000000;
        type += MinkoTypes.TRIANGLECULLING << 24;
        var stream:BytesOutput = new BytesOutput();
        stream.writeString(res)
        return new Tuple<Int, BytesOutput>(type, stream);
    }

    static public function serializeTexture(textureId:Int) {
        var type = 0x00000000;
        type += MinkoTypes.TEXTURE << 24;
        type += textureId;
        var stream:BytesOutput = new BytesOutput();
        return new Tuple<Int, BytesOutput>(type, stream);

    }

    static public function serializeString(str:String) {
        var type = MinkoTypes.STRING << 24;
        var stream:BytesOutput = new BytesOutput();
        stream.writeString(str)
        return new Tuple<Int, BytesOutput>(type, stream);
    }

}
