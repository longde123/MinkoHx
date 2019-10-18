package minko.file;
import minko.file.AbstractStream.GeometryStreamVertexBuffer;
import minko.file.AbstractStream.GeometryStreamIndexBuffer;
import minko.file.AbstractStream.GeometryStream;
import minko.geometry.Geometry;
import haxe.io.Bytes;
using minko.utils.BytesTool;
import minko.render.VertexBuffer;
import minko.render.IndexBuffer;
import minko.render.AbstractContext;
import haxe.ds.IntMap;
class GeometryParser extends AbstractSerializerParser {
    private static var indexBufferParserFunctions:IntMap<GeometryStreamIndexBuffer -> AbstractContext -> IndexBuffer> = new IntMap<GeometryStreamIndexBuffer -> AbstractContext -> IndexBuffer>();
    private static var vertexBufferParserFunctions:IntMap<GeometryStreamVertexBuffer -> AbstractContext -> VertexBuffer> = new IntMap<GeometryStreamVertexBuffer -> AbstractContext -> VertexBuffer>();

    public static function create() {
        return new GeometryParser();
    }

    public static function registerIndexBufferParserFunction(f:GeometryStreamIndexBuffer -> AbstractContext -> IndexBuffer, functionId:Int) {
        indexBufferParserFunctions.set(functionId, f);
    }

    public static function registerVertexBufferParserFunction(f:GeometryStreamVertexBuffer -> AbstractContext -> VertexBuffer, functionId:Int) {
        vertexBufferParserFunctions.set(functionId, f);
    }


    public function new() {
        initialize();
    }

    public function initialize() {
        registerIndexBufferParserFunction(GeometryParser.deserializeIndexBuffer, 0);
        registerVertexBufferParserFunction(GeometryParser.deserializeVertexBuffer, 0);
    }

    public function deserializeVertexBuffer(serializedVertexBuffer:GeometryStreamVertexBuffer, context:AbstractContext) {
        var vertexBuffer:VertexBuffer = VertexBuffer.create(context, serializedVertexBuffer.data);
        for (attributes in serializedVertexBuffer.attributes) {
            vertexBuffer.addAttribute(attributes.name, attributes.size, attributes.offset);
        }
        return vertexBuffer;
    }

    public function deserializeIndexBuffer(serializedIndexBuffer:GeometryStreamIndexBuffer, context:AbstractContext) {

        return IndexBuffer.createbyData(context, serializedIndexBuffer);
    }

    override public function parse(filename, resolvedFilename, options:Options, __data:Bytes, assetLibrary:AssetLibrary) {

    }

    override public function parseStream(filename:String, resolvedFilename:String, options:Options, _data:AbstractStream, assetLibrary:AssetLibrary) {
        var serializedGeometry:GeometryStream = cast _data;
        computeMetaData(serializedGeometry);
        var folderPathName = extractFolderPath(resolvedFilename);
        var geom:Geometry = Geometry.create(filename);
        geom.indices = (indexBufferParserFunctions.get(serializedGeometry.indexBufferFunctionId)(serializedGeometry.indices, options.context));

        for (serializedVertexBuffer in serializedGeometry.vertexBuffers) {
            geom.addVertexBuffer(vertexBufferParserFunctions.get(serializedGeometry.vertexBufferFunctionId)(serializedVertexBuffer, options.context));
        }

        geom = options.geometryFunction(serializedGeometry.name, geom);

        if (options.disposeIndexBufferAfterLoading) {
            geom.disposeIndexBufferData();
        }

        if (options.disposeVertexBufferAfterLoading) {
            geom.disposeVertexBufferData();
        }

        var uniqueName = serializedGeometry.name;
        var parse_nameId = 0;
        while (assetLibrary.geometry(uniqueName) != null) {
            uniqueName = "geometry" + (parse_nameId++);
        }

        assetLibrary.setGeometry(uniqueName, geom);
        _lastParsedAssetName = uniqueName;
    }

    inline function computeMetaData(geometryStream:GeometryStream) {
        geometryStream.indexBufferFunctionId = 0x00000000 + ((geometryStream.metaData >> 4) & 0x0F);
        geometryStream.vertexBufferFunctionId = 0x00000000 + (geometryStream.metaData & 0x0F);
    }

}
