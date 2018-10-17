package minko.file;
import haxe.ds.IntMap;
import haxe.io.BytesOutput;
import minko.geometry.Geometry;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
import minko.serialize.TypeSerializer;
import minko.StreamingCommon;
import minko.Tuple.Tuple3;
using minko.utils.BytesTool;
typedef IndexBufferWriteFunc = IndexBuffer -> BytesOutput;
typedef VertexBufferWriteFunc = VertexBuffer -> BytesOutput;
typedef GeometryTestFunc = Geometry -> Bool;
class GeometryWriter extends AbstractWriter<Geometry> {


    private static var indexBufferWriterFunctions:IntMap<IndexBufferWriteFunc> = new IntMap<IndexBufferWriteFunc>();
    private static var vertexBufferWriterFunctions:IntMap<VertexBufferWriteFunc> = new IntMap<VertexBufferWriteFunc>() ;

    private static var indexBufferTestFunctions:IntMap< GeometryTestFunc> = new IntMap< GeometryTestFunc>();
    private static var vertexBufferTestFunctions:IntMap<GeometryTestFunc> = new IntMap<GeometryTestFunc>();

    public static function create() {
        return new GeometryWriter();
    }

    public static function registerIndexBufferWriterFunction(f:IndexBufferWriteFunc, testFunc:GeometryTestFunc, functionId:Int) {
        indexBufferWriterFunctions.set(functionId, f);
        indexBufferTestFunctions.set(functionId, testFunc);
    }

    public static function registerVertexBufferWriterFunction(f:VertexBufferWriteFunc, testFunc:GeometryTestFunc, functionId:Int) {
        vertexBufferWriterFunctions.set(functionId, f);
        vertexBufferTestFunctions.set(functionId, testFunc);
    }


    public function new() {
        initialize();
    }

    public function initialize() {
        _magicNumber = 0x00000047 | StreamingCommon.MINKO_SCENE_MAGIC_NUMBER;
        registerIndexBufferWriterFunction(GeometryWriter.serializeIndexStream, function(geometry) {
            return true;
        }, 0);
        registerVertexBufferWriterFunction(GeometryWriter.serializeVertexStream, function(geometry) {
            return true;
        }, 0);
    }

    override public function embed(assetLibrary:AssetLibrary, options:Options, dependency:Dependency, writerOptions:WriterOptions, embeddedHeaderData:BytesOutput) {
        var geometry:Geometry = data ;
        var __metaData:Tuple3<Int, Int, Int> = computeMetaData(geometry, writerOptions);
        var indexBufferFunctionId = __metaData.second;
        var vertexBufferFunctionId = __metaData.thiree;
        var metaData = __metaData.first;
        var serializedIndexBuffer:BytesOutput = indexBufferWriterFunctions.get(indexBufferFunctionId)(geometry.indices);
        var serializedVertexBuffers = new BytesOutput();
        serializedVertexBuffers.writeInt32(geometry.vertexBuffers.length);
        for (vertexBuffer in geometry.vertexBuffers) {
            var buff:BytesOutput = vertexBufferWriterFunctions.get(vertexBufferFunctionId)(vertexBuffer);
            serializedVertexBuffers.writeOneBytes(buff.getBytes());
        }
        var sbuf = new BytesOutput();
        sbuf.writeInt16(metaData);
        sbuf.writeUTF(assetLibrary.geometryName(geometry));
        sbuf.writeOneBytes(serializedIndexBuffer.getBytes());
        sbuf.writeOneBytes(serializedVertexBuffers.getBytes());

        return sbuf ;
    }

    public function serializeIndexStream(indexBuffer:IndexBuffer) {
        return TypeSerializer.serializeVectorInt32(indexBuffer.data);
    }

    public function serializeVertexStream(vertexBuffer:VertexBuffer) {
        var serializedAttributes = new BytesOutput();

        serializedAttributes.writeInt32(vertexBuffer.attributes.length);
        for (attribute in vertexBuffer.attributes) {
            serializedAttributes.writeUTF(attribute.name);
            serializedAttributes.writeInt8(attribute.size);
            serializedAttributes.writeInt8(attribute.offset);

        }

        var serializedVector = TypeSerializer.serializeVectorFloat(vertexBuffer.data);
        var sbuf = new BytesOutput();
        sbuf.writeOneBytes(serializedVector);
        sbuf.writeOneBytes(serializedAttributes);


        return sbuf ;
    }

    public function computeMetaData(geometry:Geometry, writerOptions:WriterOptions) {
        var metaData = 0x0000;
        var indexBufferFunctionId = 0;
        var vertexBufferFunctionId = 0;
        for (functionIdTestFuncKey in indexBufferTestFunctions.keys()) {
            var functionIdTestFunc = indexBufferTestFunctions.get(functionIdTestFuncKey);
            if (functionIdTestFunc(geometry) && functionIdTestFuncKey >= indexBufferFunctionId) {
                indexBufferFunctionId = functionIdTestFuncKey;
            }
        }

        for (functionIdTestFuncKey in vertexBufferTestFunctions.keys()) {
            var functionIdTestFunc = vertexBufferTestFunctions.get(functionIdTestFuncKey);
            if (functionIdTestFunc(geometry) && functionIdTestFunc >= vertexBufferFunctionId) {
                vertexBufferFunctionId = functionIdTestFunc;
            }
        }

        metaData = ((indexBufferFunctionId << 4) & 0xF0) + (vertexBufferFunctionId & 0x0F);

        return new Tuple3<Int, Int, Int>(metaData, indexBufferFunctionId, vertexBufferFunctionId);
    }

}
