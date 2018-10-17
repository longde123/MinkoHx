package minko.file;
import glm.Vec3;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.deserialize.TypeDeserializer;
import minko.file.POPGeometryAssetDescriptor.LodDescriptor;
import minko.geometry.Geometry;
import minko.render.IndexBuffer;
import minko.render.VertexBuffer;
import minko.StreamingCommon.ProgressiveOrderedMeshLodInfo;
import minko.Tuple.Tuple4;
import minko.utils.MathUtil;
import minko.utils.VectorHelper;
using minko.utils.BytesTool;
class LodInfo {
    public var level:Int;
    public var precisionLevel:Int;

    public var indexCount:Int;
    public var vertexCount:Int;

    public var blobOffset:Int;
    public var blobSize:Int;

    public var isRead:Bool;

    public function new(level, precisionLevel, indexCount, vertexCount, blobOffset, blobSize) {
        this.level = level;
        this.precisionLevel = precisionLevel;
        this.indexCount = indexCount;
        this.vertexCount = vertexCount;
        this.blobOffset = blobOffset;
        this.blobSize = blobSize;
        this.isRead = false;
    }
}

class POPGeometryParser extends AbstractStreamedAssetParser {
    private var _lodCount:Int;
    private var _minLod:Int;
    private var _maxLod:Int;
    private var _fullPrecisionLod:Int;

    private var _minBound:Vec3;
    private var _maxBound:Vec3;

    private var _isSharedPartition:Bool;
    private var _minBorderPrecision:Int;
    private var _maxDeltaBorderPrecision:Int;

    private var _vertexSize:Int;
    private var _numVertexBuffers:Int;
    private var _vertexAttributes:Array<Tuple4< Int, String, Int, Int >>;

    private var _lods:IntMap< LodInfo>;

    private var _geometryIndexOffset:Int;
    private var _geometryVertexOffset:Int;

    private var _geometry:Geometry;

    public static function create() {
        return new POPGeometryParser();
    }

    public function new() {
        super();
        this._lodCount = 0;
        this._minLod = 0;
        this._maxLod = 0;
        this._minBound = new Vec3();
        this._maxBound = new Vec3();
        this._vertexSize = 0;
        this._vertexAttributes = new Array<Tuple4< Int, String, Int, Int >>();
        this._lods = new IntMap< LodInfo>();
        this._geometryIndexOffset = 0;
        this._geometryVertexOffset = 0;
        assetExtension = (0x00000056);
    }

    public function useDescriptor(filename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        var descriptor:POPGeometryAssetDescriptor = assetLibrary.assetDescriptor(filename);

        if (!descriptor) {
            return false;
        }

        _geometry = assetLibrary.geometry(filename);

        var lowerLod = StreamingOptions.MAX_LOD;
        var upperLod = 0;

        for (i in 0...descriptor.numLodDescriptors) {
            var lodDescriptor:LodDescriptor = descriptor.lodDescriptor(i);

            lowerLod = Math.min(lodDescriptor.level, lowerLod);
            upperLod = Math.max(lodDescriptor.level, upperLod);

            var lodInfo = new LodInfo(lodDescriptor.level, lodDescriptor.level, lodDescriptor.numIndices, lodDescriptor.numVertices, lodDescriptor.dataOffset, lodDescriptor.dataLength);

            _lods.set(lodInfo.level, lodInfo);
        }

        lodParsed(lowerLod - 1, upperLod, data, options, options.disposeIndexBufferAfterLoading, options.disposeVertexBufferAfterLoading);

        return true;
    }

    public function parsed(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        _geometry = createPOPGeometry(assetLibrary, options, filename);

        if (_geometry == null) {
            trace("failed to create geometry from " + filename);

            _error.execute(this, ("POPGeometryParsingError" + "geometry parsing error"));
        }

        if (!options.trackAssetDescriptor) {
            return;
        }

        var assetDescriptor:POPGeometryAssetDescriptor = assetLibrary.assetDescriptor(filename);

        if (!assetDescriptor) {
            assetDescriptor = POPGeometryAssetDescriptor.create();
            assetDescriptor.location = (new AssetLocation(linkedAsset.filename, linkedAsset.offset, linkedAsset.length));

            for (lodKey in _lods.keys()) {
                var lod = _lods.get(lodKey);
                assetDescriptor.addLodDescriptor(new LodDescriptor (lodKey, lod.indexCount, lod.vertexCount, lod.blobOffset, lod.blobSize));
            }

            assetLibrary.assetDescriptor(filename, assetDescriptor);
        }
    }

    public function createPOPGeometry(assetLibrary:AssetLibrary, options:Options, fileName:String) {
        var existingGeometry = assetLibrary.geometry(fileName);

        if (existingGeometry != null) {
            return existingGeometry;
        }

        if (_lodCount <= 0) {
            return Geometry.create(fileName);
        }

        var popGeometry = Geometry.create(fileName);

        popGeometry.data().set("type", "pop");

        var indexCount = 0;
        var vertexCount = 0;

        for (lod in _lods) {
            indexCount += lod.indexCount;
            vertexCount += lod.vertexCount;
        }

        var indexBuffer = IndexBuffer.create(options.context);

        if (options.disposeIndexBufferAfterLoading) {
            indexBuffer.upload(0, indexCount, VectorHelper.initializedList(indexCount, 0));

            indexBuffer.disposeData();
        }
        else {
            indexBuffer.data.resize(indexCount, 0);

            indexBuffer.upload();
        }

        popGeometry.indices = (indexBuffer);

        var vertexBuffers = new Array<VertexBuffer>();//_numVertexBuffers);

        for (i in 0... _numVertexBuffers) {
            vertexBuffers[i] = VertexBuffer.create(options.context);
        }

        for (attribute in _vertexAttributes) {
            var vertexBufferIndex = attribute.first;

            var attributeName = attribute.second;
            var attributeSize = attribute.thiree;
            var attributeOffset = attribute.four;

            vertexBuffers[vertexBufferIndex].addAttribute(attributeName, attributeSize, attributeOffset);
        }

        for (vertexBuffer in vertexBuffers) {
            if (options.disposeVertexBufferAfterLoading) {
                vertexBuffer.upload(0, vertexCount, [for (i in 0...vertexCount * vertexBuffer.vertexSize) 0.0]);

                vertexBuffer.disposeData();
            }
            else {
                vertexBuffer.data.resize(vertexCount * vertexBuffer.vertexSize, 0.0);

                vertexBuffer.upload();
            }

            popGeometry.addVertexBuffer(vertexBuffer);
        }

        popGeometry.data.set("popMinBound", _minBound);
        popGeometry.data.set("popMaxBound", _maxBound);

        if (_isSharedPartition) {
            popGeometry.data.set("isSharedPartition", true);

            popGeometry.data.set("borderMinPrecision", _minBorderPrecision);
            popGeometry.data.set("borderMaxDeltaPrecision", _maxDeltaBorderPrecision);
        }

        var availableLods = new IntMap<ProgressiveOrderedMeshLodInfo>();

        for (levelToLodPair in _lods) {
            var lod = levelToLodPair;

            availableLods.set(lod.level, new ProgressiveOrderedMeshLodInfo(lod.level, lod.precisionLevel));
        }

        if (availableLods.exists(_fullPrecisionLod) == false) {
            availableLods.set(_fullPrecisionLod, new ProgressiveOrderedMeshLodInfo(_fullPrecisionLod, _fullPrecisionLod));
        }

        if (data != null) {
            data.set("availableLods", availableLods);
            data.set("maxAvailableLod", 0);
        }

        popGeometry.data.set("popFullPrecisionLod", _fullPrecisionLod);

        if (streamingOptions.popGeometryFunction) {
            popGeometry = streamingOptions.popGeometryFunction(fileName, popGeometry);
        }

        assetLibrary.geometry(fileName, popGeometry);

        return popGeometry;
    }

    public function headerParsed(data:Bytes, options:Options, linkedAssetId:Int) {
        //ref
        var headerData:BytesInput = new BytesInput(data);
        var size = data.length;

        linkedAssetId = headerData.readInt32();

        _lodCount = headerData.readInt32();
        _minLod = headerData.readInt32();
        _maxLod = headerData.readInt32();
        _fullPrecisionLod = headerData.readInt32();

        var rawBounds = headerData.readOneBytes();
        var bounds = TypeDeserializer.deserializeVectorFloat(rawBounds);

        _minBound = MathUtil.make_vec3(bounds, 0);
        _maxBound = MathUtil.make_vec3(bounds, 3);

        _vertexSize = headerData.readInt32();

        _numVertexBuffers = headerData.readInt32();

        var vertexAttributes_length = headerData.readInt32();
        for (v in 0...vertexAttributes_length) {
            var va = new Tuple4< Int, String, Int, Int >(
            headerData.readInt32(),
            headerData.readUTF(),
            headerData.readInt32(),
            headerData.readInt32()
            );
            _vertexAttributes.push(va);
        }


        _isSharedPartition = headerData.readInt8();

        if (_isSharedPartition) {
            _minBorderPrecision = headerData.readInt32();
            _maxDeltaBorderPrecision = headerData.readInt32();
        }

        var lodInfo_length = headerData.readInt32();
        for (i in 0... _lodCount) {
            var level = headerData.readInt32();
            var precisionLevel = headerData.readInt32();
            var indexCount = headerData.readInt32();
            var vertexCount = headerData.readInt32();
            var blobOffset = headerData.readInt32();
            var blobSize = headerData.readInt32();
            _lods.set(level, new LodInfo(level, precisionLevel, indexCount, vertexCount, blobOffset, blobSize));
        }
    }

    public function lodParsed(previousLod, currentLod, data:Bytes, options:Options) {
        lodParsed(previousLod, currentLod, data, options, options.disposeIndexBufferAfterLoading, options.disposeVertexBufferAfterLoading);
    }

    public function complete(currentLod) {
        return currentLod == _maxLod;
    }

    public function completed() {
        if (!data()) {
            return;
        }

        var availableLods:IntMap<ProgressiveOrderedMeshLodInfo> = data.get("availableLods");

        var fullPrecisionLodInfo = availableLods.get(_fullPrecisionLod);

        if (!fullPrecisionLodInfo.isValid) {
            var maxLodInfo = availableLods.get(_maxLod);

            fullPrecisionLodInfo = new ProgressiveOrderedMeshLodInfo(fullPrecisionLodInfo._level, fullPrecisionLodInfo._precisionLevel, maxLodInfo._indexOffset + maxLodInfo._indexCount, 0);

            data.set("availableLods", availableLods);
            data.set("maxAvailableLod", fullPrecisionLodInfo._level);
        }
    }

    public function lodParsed(previousLod:Int, currentLod:Int, data:Bytes, options:Options, disposeIndexBuffer:Bool, disposeVertexBuffer:Bool) {
        var lodInfoRangeBeginIt = previousLod + 1;// _lods.lower_bound(previousLod + 1);
        var lodInfoRangeEndIt = currentLod;//_lods.lower_bound(currentLod);
        var lodInfoRangeUpperBoundIt = currentLod;//_lods.upper_bound(currentLod);

        var availableLods:IntMap<ProgressiveOrderedMeshLodInfo> = this.data ? this.data.get("availableLods") : new IntMap<ProgressiveOrderedMeshLodInfo>();

        var dataOffset = 0 ;

        for (lodInfoIt in lodInfoRangeBeginIt...lodInfoRangeUpperBoundIt) {
            var lodInfo = _lods.get(lodInfoIt);

            var dataSize = lodInfo.blobSize;

            var lodData = new BytesInput(data.blit(dataOffset, dataSize));


            dataOffset += dataSize;

            var indices = TypeDeserializer.deserializeVectorInt32(lodData.readOneBytes());

            var indexBuffer = _geometry.indices;

            var geometryIndexOffset = _geometryIndexOffset;
            _geometryIndexOffset += lodInfo.indexCount;

            if (disposeIndexBuffer) {
                indexBuffer.upload(geometryIndexOffset, lodInfo.indexCount, indices);
            }
            else {
                var indexData = indexBuffer.data;

                if (indexData.length < geometryIndexOffset + indices.length) {
                    indexData.resize(geometryIndexOffset + indices.length);
                }

                MathUtil.std_copy(indices, 0, geometryIndexOffset + indices.length, indexData, geometryIndexOffset);

                indexBuffer.upload(geometryIndexOffset, lodInfo.indexCount);
            }

            var geometryVertexOffset = _geometryVertexOffset;

            _geometryVertexOffset += lodInfo.vertexCount;

            var vertexBufferIndex = 0 ;
            for (vertexBuffer in _geometry.vertexBuffers) {
                var vertices:Array<Float> = TypeDeserializer.deserializeVectorFloat(lodData.get < 1 > ().at(vertexBufferIndex));

                if (lodInfo.vertexCount > 0) {
                    var localVertexOffset = geometryVertexOffset * vertexBuffer.vertexSize();

                    if (disposeVertexBuffer) {
                        vertexBuffer.upload(geometryVertexOffset, lodInfo.vertexCount, vertices);
                    }
                    else {
                        var vertexData = vertexBuffer.data ;

                        if (vertexData.length < localVertexOffset + vertices.length) {
                            vertexData.resize(localVertexOffset + vertices.length);
                        }

                        MathUtil.std_copy(vertices, 0, localVertexOffset + vertices.length, vertexData, localVertexOffset);

                        vertexBuffer.upload(geometryVertexOffset, lodInfo.vertexCount);
                    }
                }

                ++vertexBufferIndex;
            }

            availableLods[lodInfo.level] = ProgressiveOrderedMeshLodInfo(lodInfo.level, lodInfo.precisionLevel, geometryIndexOffset, lodInfo.indexCount);
        }

        if (this.data != null) {
            this.data.set("availableLods", availableLods);
            this.data.set("maxAvailableLod", lodInfoRangeEndIt.second.level);
        }
    }

    public function lodRangeFetchingBound(currentLod, requiredLod, lodRangeMinSize, lodRangeMaxSize, lodRangeRequestMinSize, lodRangeRequestMaxSize) {

        //ref
        if (streamingOptions.popGeometryLodRangeFetchingBoundFunction != null) {
            streamingOptions.popGeometryLodRangeFetchingBoundFunction(currentLod, requiredLod, lodRangeMinSize, lodRangeMaxSize, lodRangeRequestMinSize, lodRangeRequestMaxSize);
        }
        else {
            lodRangeMinSize = StreamingOptions.MAX_LOD_RANGE;
        }
    }

    public function lodRangeRequestByteRange(lowerLod, upperLod, offset, size) {
        //ref
        var lowerLodIt = lowerLod;// _lods.lower_bound(lowerLod);
        var upperLodIt = upperLod;//_lods.lower_bound(upperLod);

        var lowerLodInfo = _lods.get(lowerLodIt);//.second;
        var upperLodInfo:LodInfo = null;

        if (upperLodIt != null) {
            upperLodInfo = upperLodIt;
        }
        else {
            upperLodInfo = _lods.iterator().next();
        }

        offset = lowerLodInfo.blobOffset;
        size = (upperLodInfo.blobOffset + upperLodInfo.blobSize) - offset;
    }

    public function lodLowerBound(lod) {
        var lodLowerIt = _lods.get(lod);//_lods.lower_bound(lod);

        var lodInfo:LodInfo = null;

        if (lodLowerIt != null) {
            lodInfo = lodLowerIt;
        }
        else {
            lodInfo = _lods.iterator().next();//.rbegin().second;
        }

        return lodInfo.level;
    }

    public function maxLod() {
        return _maxLod;
    }


}
