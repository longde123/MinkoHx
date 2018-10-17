package minko.file;
import minko.geometry.Geometry;
import haxe.io.BytesInput;
import minko.deserialize.TypeDeserializer;
import minko.Tuple;
import haxe.io.Bytes;
using minko.utils.BytesTool;
import minko.render.VertexBuffer;
import minko.render.IndexBuffer;
import minko.render.AbstractContext;
import haxe.ds.IntMap;
typedef SerializeAttribute = Tuple3<Bytes, Int, Int> ;
typedef SerializedGeometry = Tuple4<Int, String, Bytes, Array<Bytes>>;
class GeometryParser extends AbstractSerializerParser {

    private static var indexBufferParserFunctions:IntMap<Bytes -> AbstractContext -> IndexBuffer> = new IntMap<Bytes -> AbstractContext -> IndexBuffer>();
    private static var vertexBufferParserFunctions:IntMap<Bytes -> AbstractContext -> VertexBuffer> = new IntMap<Bytes -> AbstractContext -> VertexBuffer>();

    public static function create() {
        return new GeometryParser();
    }

    public static function registerIndexBufferParserFunction(f:String -> AbstractContext -> IndexBuffer, functionId:Int) {
        indexBufferParserFunctions.set(functionId, f);
    }

    public static function registerVertexBufferParserFunction(f:String -> AbstractContext -> VertexBuffer, functionId:Int) {
        vertexBufferParserFunctions.set(functionId, f);
    }


    public function new() {
        initialize();
    }

    public function initialize() {
        registerIndexBufferParserFunction(GeometryParser.deserializeIndexBuffer, 0);
        registerVertexBufferParserFunction(GeometryParser.deserializeVertexBuffer, 0);
    }

    public function deserializeVertexBuffer(serializedVertexBuffer:BytesInput, context:AbstractContext) {
        var deserializedVertex = new Tuple<String, Array<SerializeAttribute>>();

        deserializedVertex.first = serializedVertexBuffer.readUTF();
        deserializedVertex.second = new Array<SerializeAttribute>();
        var len = serializedVertexBuffer.readInt32();
        for (i in 0...len) {
            var sa:SerializeAttribute = new SerializeAttribute();
            sa.first = serializedVertexBuffer.readBytes();
            sa.second = serializedVertexBuffer.readInt32();
            sa.thiree = serializedVertexBuffer.readInt32();
            deserializedVertex.second.push(sa);
        }

        var vector = TypeDeserializer.deserializeVectorFloat(new BytesInput(deserializedVertex.first));
        var vertexBuffer:VertexBuffer = VertexBuffer.create(context, vector);

        var numAttributes = deserializedVertex.second.length;

        for (attributesIndex in 0... numAttributes) {
            vertexBuffer.addAttribute(deserializedVertex.second[attributesIndex].first, deserializedVertex.second[attributesIndex].second, deserializedVertex.second[attributesIndex].thiree);
        }

        return vertexBuffer;
    }

    public function deserializeIndexBuffer(serializedIndexBuffer:BytesInput, context:AbstractContext) {
        var vector = TypeDeserializer.deserializeVectorInt32(serializedIndexBuffer);

        return IndexBuffer.createbyData(context, vector);
    }

    override public function parse(filename, resolvedFilename, options:Options, __data:Bytes, assetLibrary:AssetLibrary) {
        var data:BytesInput = new BytesInput(__data);
        if (!readHeader(filename, data, 0x47)) {
            return;
        }

        var folderPathName = extractFolderPath(resolvedFilename);
        var geom:Geometry = Geometry.create(filename);
        var serializedGeometry:SerializedGeometry = new SerializedGeometry();

        extractDependencies(assetLibrary, data, _headerSize, _dependencySize, options, folderPathName);

        data.position = _headerSize + _dependencySize;

        serializedGeometry.first = data.readInt32();
        serializedGeometry.second = data.readUTF();
        serializedGeometry.thiree = data.readOneBytes();
        serializedGeometry.four = [];
        var len = data.readInt32();
        for (i in 0...len) {
            serializedGeometry.four.push(data.readOneBytes());
        }

        var indexBufferFunction = 0;
        var vertexBufferFunction = 0;

        computeMetaData(serializedGeometry.first, indexBufferFunction, vertexBufferFunction);

        geom.indices = (indexBufferParserFunctions.get(indexBufferFunction)(serializedGeometry.thiree, options.context));

        for (serializedVertexBuffer in serializedGeometry.four) {
            geom.addVertexBuffer(vertexBufferParserFunctions.get(vertexBufferFunction)(serializedVertexBuffer, options.context));
        }

        geom = options.geometryFunction(serializedGeometry.second, geom);

        if (options.disposeIndexBufferAfterLoading) {
            geom.disposeIndexBufferData();
        }

        if (options.disposeVertexBufferAfterLoading) {
            geom.disposeVertexBufferData();
        }

        var uniqueName = serializedGeometry.second;
        var parse_nameId = 0;
        while (assetLibrary.geometry(uniqueName) != null) {
            uniqueName = "geometry" + (parse_nameId++);
        }

        assetLibrary.setGeometry(uniqueName, geom);
        _lastParsedAssetName = uniqueName;
    }

    inline function computeMetaData(metaData, indexBufferFunctionId, vertexBufferFunctionId) {
        indexBufferFunctionId = 0x00000000 + ((metaData >> 4) & 0x0F);
        vertexBufferFunctionId = 0x00000000 + (metaData & 0x0F);
    }

}
