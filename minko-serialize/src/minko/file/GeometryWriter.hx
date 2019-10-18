package minko.file;
import minko.serialize.Types.ComponentId;
import minko.file.AbstractStream.GeometryStreamIndexBuffer;
import minko.file.AbstractStream.GeometryStreamVertexBufferAttributes;
import minko.file.AbstractStream.GeometryStreamVertexBuffer;
import minko.file.AbstractStream.GeometryStream;
import minko.file.Dependency.GeometryTestFunc;
import haxe.ds.IntMap;
import minko.geometry.Geometry;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
import minko.StreamingCommon;
using minko.utils.BytesTool;
typedef IndexBufferWriteFunc = IndexBuffer -> GeometryStreamIndexBuffer;
typedef VertexBufferWriteFunc = VertexBuffer -> GeometryStreamVertexBuffer;
class GeometryWriter extends AbstractWriter {


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

    override public function embed(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency):AbstractStream {
        var geometry:Geometry = data ;
        var geometryStream:GeometryStream = new GeometryStream();
        computeMetaData(geometry, writerOptions, geometryStream);
        var indexBufferFunctionId = geometryStream.indexBufferFunctionId;
        var vertexBufferFunctionId = geometryStream.vertexBufferFunctionId;
        var metaData = geometryStream.metaData;
        geometryStream.indices = indexBufferWriterFunctions.get(indexBufferFunctionId)(geometry.indices);
        geometryStream.vertexBuffers = [];
        for (vertexBuffer in geometry.vertexBuffers) {
            var buff:GeometryStreamVertexBuffer = vertexBufferWriterFunctions.get(vertexBufferFunctionId)(vertexBuffer);
            geometryStream.vertexBuffers.push(buff);
        }
        geometryStream.name = assetLibrary.geometryName(geometry);
        return geometryStream ;
    }

    public function serializeIndexStream(indexBuffer:IndexBuffer):Array<Int> {
        return (indexBuffer.data);
    }

    public function serializeVertexStream(vertexBuffer:VertexBuffer):GeometryStreamVertexBuffer {
        var sbuf:GeometryStreamVertexBuffer = new GeometryStreamVertexBuffer();
        sbuf.attributes = new Array<GeometryStreamVertexBufferAttributes>();
        for (attribute in vertexBuffer.attributes) {
            var tmp:GeometryStreamVertexBufferAttributes = new GeometryStreamVertexBufferAttributes();
            tmp.name = (attribute.name);
            tmp.size = (attribute.size);
            tmp.offset = (attribute.offset);
            sbuf.attributes.push(tmp);
        }
        sbuf.data = vertexBuffer.data;
        return sbuf ;
    }

    public function computeMetaData(geometry:Geometry, writerOptions:WriterOptions, geometryStream:GeometryStream):Void {
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
        geometryStream.metaData = metaData;
        geometryStream.indexBufferFunctionId = indexBufferFunctionId;
        geometryStream.vertexBufferFunctionId = vertexBufferFunctionId;
    }

}
