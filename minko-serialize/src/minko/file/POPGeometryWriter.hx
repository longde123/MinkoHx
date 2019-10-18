package minko.file;
import minko.file.AbstractStream.POPGeometryLODHeader;
import minko.file.AbstractStream.POPGeometryHeader;
import minko.file.AbstractStream.GeometryStreamVertexBufferData;
import minko.file.AbstractStream.GeometryStreamVertexBuffer;
import minko.file.AbstractStream.POPGeometryLOD;
import minko.file.AbstractStream.POPGeometryHeader;
import minko.file.AbstractStream.GeometryStreamVertexBufferAttributes;
import minko.file.AbstractStream.POPGeometryHeaderStream;
import minko.file.AbstractStream.POPGeometryStream;
import minko.Tuple.Tuple4;
import minko.Tuple.Tuple6;
import glm.Vec3;
import haxe.ds.IntMap;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import Lambda;
import minko.component.BoundingBox;
import minko.component.Surface;
import minko.component.Transform;
import minko.geometry.Geometry;
import minko.render.VertexBuffer;
import minko.scene.Node;
import minko.StreamingCommon;
import minko.Tuple.Tuple3;
import minko.utils.MathUtil;
using minko.utils.BytesTool;

typedef RangeFunction = Geometry -> BoundingBox -> Int -> Int -> Void;
typedef QuantizationIndex = Tuple3<Int, Int, Int> ;
class LodData {
    public var precisionLevel:Int;

    public var indices:Array<Int>;
    public var vertices:Array<Array<Float>>;
    public var vertexSizes:Array<Int>;

    public function new(precisionLevel) {
        this.precisionLevel = precisionLevel;
        this.indices = [];
        this.vertices = [[]];
    }
}
class POPGeometryWriter extends AbstractWriter {


    public static var _fullPrecisionLevel:Int = 32;

    private static var _keepSplitVertexPattern:Bool = false;

    private static var _defaultMinPrecisionLevel:Int = 0;
    private static var _defaultMaxPrecisionLevel:Int = 12;

    private static var _smallFeatureTriangleCountThreshold:Int;

    private var _assetLibrary:AssetLibrary;
    private var _options:Options;
    private var _streamingOptions:StreamingOptions;

    private var _geometry:Geometry;

    private var _linkedAsset:LinkedAsset;
    private var _linkedAssetId:Int;

    private var _minLevel:Int;
    private var _maxLevel:Int;

    private var _minBound:Vec3;
    private var _maxBound:Vec3;

    private var _rangeFunction:RangeFunction;

    public static function create() {
        var instance = (new POPGeometryWriter());

        return instance;
    }
    public var streamingOptions(null, set):StreamingOptions;

    function set_streamingOptions(value) {
        _streamingOptions = value;
    }

    public function linkedAsset(linkedAsset:LinkedAsset, linkedAssetId:Int) {
        _linkedAsset = linkedAsset;

        _linkedAssetId = linkedAssetId;
    }

    public function new() {

        super();
        //   this._assetLibrary = new AssetLibrary();
        //this._geometry = new Geometry();
        this._rangeFunction = POPGeometryWriter.defaultRangeFunction;
        _magicNumber = 0x00000056 | StreamingCommon.MINKO_SCENE_MAGIC_NUMBER;
    }

    override public function embedAll(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Array<SerializedAsset>):Bytes {

    }

    override public function write(filename:String, assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency, userDefinedDependency:Array<SerializedAsset>):Void {

    }


    override public function embed(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency):AbstractStream {


        var geometry:Geometry = cast data;

        _assetLibrary = assetLibrary;
        _options = options;
        _geometry = geometry;

        var rangeFunction = _streamingOptions.popGeometryWriterLodRangeFunction != null ? _streamingOptions.popGeometryWriterLodRangeFunction : _rangeFunction;

        rangeFunction(geometry, null, _minLevel, _maxLevel);

        var lodData = new IntMap<LodData>();

        buildLodData(lodData, _minLevel, _maxLevel);

        updateBoundaryLevels(lodData);

        var blobData = new POPGeometryStream();

        serializeGeometry(dependency, writerOptions, lodData, blobData);
        var linkedAsset = _linkedAsset;


        if (linkedAsset != null && linkedAsset.linkType == LinkedAsset.LinkType.Internal) {
//            linkedAsset.length = (blobBuffer.length);
//            linkedAsset.data = blobBuffer.getBytes();
        }
        else {

        }
        return (blobData );
    }

    public function quantize(position:Vec3, level:Int, maxLevel:Int, minBound:Vec3, maxBound:Vec3, boxSize:Vec3, outputQuantizedPosition:Bool, quantizedPosition:Vec3) {
        var segmentCount = Math.pow(2, level);

        var offset = position - minBound;

        var index = new QuantizationIndex(Math.floor(offset[0] * segmentCount / boxSize.x), Math.floor(offset[1] * segmentCount / boxSize.y), Math.floor(offset[2] * segmentCount / boxSize.z));

        if (outputQuantizedPosition) {
            var quantizedPositionData:Array<Float> = [((index.first + 0.5 ) * boxSize.x / segmentCount) + minBound.x,
            ((index.second + 0.5) * boxSize.y / segmentCount + minBound.y),
            ((index.thiree + 0.5) * boxSize.z / segmentCount + minBound.z)];

            quantizedPosition = new Vec3(quantizedPositionData[0], quantizedPositionData[1], quantizedPositionData[2]);
        }

        return index;
    }

    public function defaultRangeFunction(geometry:Geometry, boundingBox:BoundingBox, minLevel, maxLevel) {
        //ref
        minLevel = _defaultMinPrecisionLevel;
        maxLevel = _defaultMaxPrecisionLevel;
    }

    public function buildLodData(lodData:IntMap<LodData>, minLevel, maxLevel) {
        var assetLibrary = _assetLibrary;

        var geometry = _geometry;

        var hasProtectedFlagVertexAttribute = geometry.hasVertexAttribute("popProtected");
        var protectedFlagVertexBuffer = new VertexBuffer();
        var protectedFlagVertexAttributeSize = 0;
        var protectedFlagVertexAttributeOffset = 0;

        if (hasProtectedFlagVertexAttribute) {
            protectedFlagVertexBuffer = geometry.vertexBuffer("popProtected");

            var protectedFlagVertexAttribute = geometry.getVertexAttribute("popProtected");

            protectedFlagVertexAttributeSize = protectedFlagVertexAttribute.vertexSize;
            protectedFlagVertexAttributeOffset = protectedFlagVertexAttribute.offset;
        }

        var positionVertexBuffer = geometry.vertexBuffer("position");

        var positionAttribute = positionVertexBuffer.attribute("position");
        var positionAttributeSize = positionAttribute.size;
        var positionAttributeOffset = positionAttribute.offset;

        var vertexSize = positionVertexBuffer.vertexSize;

        var vertices = positionVertexBuffer.data;
        var indices = geometry.indices.data;

        var minBound = new Vec3();
        var maxBound = new Vec3();

        var precisionLevelBias = 0;

        var partitioningIsActive = geometry.data.hasProperty("partitioningMaxDepth");
        var isSharedPartition = geometry.data.hasProperty("isSharedPartition") && geometry.data.get("isSharedPartition");

        var partitioningDepth = 0;
        var partitioningMaxDepth = 0;

        var hasLodInfo = geometry.data.hasProperty("availableLods");
        var hasBoundInfo = geometry.data.hasProperty("minBound") && geometry.data.hasProperty("maxBound");

        if (partitioningIsActive) {
            partitioningMaxDepth = geometry.data.get("partitioningMaxDepth");
            partitioningDepth = geometry.data.get("partitioningDepth");

            minBound = geometry.data.get("partitioningMinBound");
            maxBound = geometry.data.get("partitioningMaxBound");
        }
        else if (hasBoundInfo) {
            minBound = geometry.data.get("minBound");
            maxBound = geometry.data.get("maxBound");
        }
        else {
            var node = Node.create()
            .addComponent(Transform.create())
            .addComponent(Surface.create(geometry, _options.material, _options.effect))
            .addComponent(BoundingBox.create());
            var boundingBox:BoundingBox = cast node.getComponent(BoundingBox);
            var box = boundingBox.box;

            minBound = box.bottomLeft;
            maxBound = box.topRight;
        }

        var orderedBufferMap = new IntMap<Array<Int>>();

        var levelToPrecisionLevelMap = new Array<Tuple<Int, Int>>();

        if (!hasLodInfo) {
            levelToPrecisionLevelMap.push(new Tuple(_fullPrecisionLevel, _fullPrecisionLevel));
        }
        else {
            var availableLods:IntMap< ProgressiveOrderedMeshLodInfo> = geometry.data.get("availableLods");

            for (availableLod in availableLods) {
                levelToPrecisionLevelMap.push(new Tuple(availableLod._level, availableLod._precisionLevel));
            }
        }

        _minBound = minBound;
        _maxBound = maxBound;

        var boxSize = maxBound - minBound;

        var minBoxSize = 1.0E-7;
        boxSize = MathUtil.vec3_max(new Vec3(minBoxSize, minBoxSize, minBoxSize), boxSize);
        var level = maxLevel;
        while (level >= minLevel - 1) {
            var mi:Int=level == maxLevel != 0 ? _fullPrecisionLevel : level + 1;
            if(!orderedBufferMap.exists(mi)){
                orderedBufferMap.set(mi,[]);
            }
            var currentOrderedBuffer:Array<Int> = orderedBufferMap.get(mi);

            var remainingIndices = new Array<Int>();

            var precisionLevel = Math.max(level - partitioningDepth + partitioningMaxDepth + precisionLevelBias, minLevel);

            if (!hasLodInfo) {
                levelToPrecisionLevelMap.push(new Tuple(level, precisionLevel));
            }
            var i = 0;

            while (i < indices.length) {
                var triangle = [indices[i], indices[i + 1], indices[i + 2]];
                var quantizedTriangle:Array<QuantizationIndex > = [for (k in 0...3) new QuantizationIndex()];
                var vertexIsProtected = [false, false, false];

                for (j in 0... 3) {
                    var vertexIndex = triangle[j];

                    var vertexPositionOffset = vertexIndex * vertexSize + positionAttributeOffset;

                    var vertexPosition = new Vec3(vertices[vertexPositionOffset + 0], vertices[vertexPositionOffset + 1], vertices[vertexPositionOffset + 2]);

                    if (hasProtectedFlagVertexAttribute) {
                        vertexIsProtected[j] = protectedFlagVertexBuffer.data[vertexIndex * protectedFlagVertexAttributeSize + protectedFlagVertexAttributeOffset] != 0.0;
                    }

                    var actualLevel = precisionLevel;

                    var quantizedPosition = new Vec3();
                    var quantizationIndex = quantize(vertexPosition, actualLevel, maxLevel, minBound, maxBound, boxSize, false, quantizedPosition);

                    quantizedTriangle[j] = quantizationIndex;
                }

                var triangleIsDegenerate =
                (!vertexIsProtected[0] && !vertexIsProtected[1] && quantizedTriangle[0] == quantizedTriangle[1])
                || (!vertexIsProtected[0] && !vertexIsProtected[2] && quantizedTriangle[0] == quantizedTriangle[2])
                || (!vertexIsProtected[1] && !vertexIsProtected[2] && quantizedTriangle[1] == quantizedTriangle[2]);

                var targetTriangleContainer:Array<Int> = triangleIsDegenerate ? currentOrderedBuffer : remainingIndices;

                for (j in 0... 3) {
                    var index = triangle[j];

                    targetTriangleContainer.push(index);
                }
                i += 3;
            }

            indices = remainingIndices;
            --level;
        }

        if (indices.length > 0) {
            var level = minLevel;

            var orderedBuffer = orderedBufferMap.get(level);

            orderedBuffer = orderedBuffer.concat(indices);
            orderedBufferMap.set(level, orderedBuffer);
        }

        var currentOrderedIndex = 0;

        var indexToOrderedIndexMap = new IntMap<Int>();

        for (orderedBufferEntry in orderedBufferMap.keys()) {
            var level = orderedBufferEntry;
            var orderedBuffer = orderedBufferMap.get(orderedBufferEntry);

            if (orderedBuffer.length == 0) {
                continue;
            }

            //LodData
            var lodDataIt = new LodData(levelToPrecisionLevelMap[level]);
            lodData.set(level, lodDataIt);

            var orderedIndexBuffer = lodDataIt.indices;
            var orderedVertexBuffers = lodDataIt.vertices;

            // orderedVertexBuffers.resize(geometry.vertexBuffers().size());
            //todo
            // lodDataIt.first.second.vertexSizes.resize(geometry.vertexBuffers().size());

            var vertexBufferIndex = 0;
            for (vertexBuffer in geometry.vertexBuffers) {
                lodDataIt.vertexSizes[vertexBufferIndex] = vertexBuffer.vertexSize;

                ++vertexBufferIndex;
            }

            for (index in orderedBuffer) {
                var indexToOrderedIndexIt = indexToOrderedIndexMap.exists(index);

                if (indexToOrderedIndexIt == false) {
                    var orderedIndex = currentOrderedIndex++;

                    indexToOrderedIndexMap.set(index, orderedIndex);

                    orderedIndexBuffer.push(orderedIndex);

                    var vertexBufferIndex = 0;
                    for (vertexBuffer in geometry.vertexBuffers) {
                        var localVertexSize = vertexBuffer.vertexSize ;
                        var localVertices = vertexBuffer.data ;

                        var vertexBegin = (index * localVertexSize);
                        var vertexEnd = vertexBegin + localVertexSize;

                        var orderedVertexBuffer = orderedVertexBuffers[vertexBufferIndex];
                        //todo
                        orderedVertexBuffer = orderedVertexBuffer.concat(localVertices) ;

                        ++vertexBufferIndex;
                    }
                }
                else {
                    var orderedIndex = indexToOrderedIndexIt;

                    orderedIndexBuffer.push(orderedIndex);
                }
            }
        }
    }

    public function serializeGeometry(dependency:Dependency, writerOptions:WriterOptions, lodData:IntMap<LodData>, blobBuffer:POPGeometryStream) {


        var geometry:Geometry = _geometry;

        var vertexSize = geometry.vertexSize;

        var minLevel = _minLevel;
        var maxLevel = _maxLevel;

        var fullPrecisionLevel = _fullPrecisionLevel;

        var minBound = _minBound;
        var maxBound = _maxBound;

        var levelCount = Lambda.count(lodData);

        var numVertexBuffers = geometry.vertexBuffers.length;

        var vertexAttributes:Array<Array<GeometryStreamVertexBufferAttributes>> = new Array<Array<GeometryStreamVertexBufferAttributes>>();

        for (vertexBuffer in geometry.vertexBuffers) {
            var attributes:Array<GeometryStreamVertexBufferAttributes> = [];
            for (attribute in vertexBuffer.attributes) {
                var tmp:GeometryStreamVertexBufferAttributes = new GeometryStreamVertexBufferAttributes();
                tmp.name = (attribute.name);
                tmp.size = (attribute.size);
                tmp.offset = (attribute.offset);
                attributes.push(tmp);
            }
            vertexAttributes.push(attributes);
        }

        var bounds = [minBound.x, minBound.y, minBound.z, maxBound.x, maxBound.y, maxBound.z];

        var isSharedPartition = false;
        var borderMinPrecision = 0;
        var borderMaxDeltaPrecision = 0;

        if (geometry.data.hasProperty("isSharedPartition") && geometry.data.get("isSharedPartition")) {
            isSharedPartition = true;
        }

        //
        var headerData:POPGeometryHeader = blobBuffer.header;
        headerData.vertexAttributes = vertexAttributes;
        headerData.linkedAssetId = (_linkedAssetId);
        headerData.levelCount = (levelCount);
        headerData.minLevel = (minLevel);
        headerData.maxLevel = (maxLevel);
        headerData.fullPrecisionLevel = (fullPrecisionLevel);

        headerData.bounds = bounds;

        headerData.vertexSize = (vertexSize);
        headerData.numVertexBuffers = (numVertexBuffers);


        headerData.isSharedPartition = (isSharedPartition);
        if (isSharedPartition) {
            headerData.borderMinPrecision = (borderMinPrecision);
            headerData.borderMaxDeltaPrecision = (borderMaxDeltaPrecision);
        }


        var levels = new Array<Int>();

        for (lod in lodData.keys()) {
            levels.push(lod);
        }

        levels.sort();

        for (level in levels) {
            serializeLod(blobBuffer, level, lodData[level]);
        }

    }

    public function serializeLod(blobBuffer:POPGeometryStream, level:Int, lod:LodData) {
        var lodIndices = lod.indices;
        var lodVertices = lod.vertices;

        var lodData:POPGeometryLOD = new POPGeometryLOD();
        lodData.indices = lodIndices;
        lodData.vertexBuffers = lodVertices;
        lodData.vertexSizes = lod.vertexSizes;
        var  lodHeadData:POPGeometryLODHeader = new POPGeometryLODHeader();
        lodHeadData.indexCount= lodIndices.length;
        lodHeadData.vertexCount= lodVertices.length/ lod.vertexSizes;
        lodHeadData.level=level;
        lodHeadData.precisionLevel=lod.precisionLevel;

        blobBuffer.header.lods.push(lodHeadData);
        blobBuffer.lodDatas.push(lodData)
    }

    public function updateBoundaryLevels(lodData:IntMap<LodData>) {
        var minLevel = Math.POSITIVE_INFINITY;
        var maxLevel = 0;

        for (levelToLodData in lodData.keys()) {
            if (levelToLodData < minLevel) {
                minLevel = levelToLodData;
            }

            if (levelToLodData > maxLevel) {
                maxLevel = levelToLodData;
            }
        }

        _minLevel = minLevel;
        _maxLevel = maxLevel;
    }
}
