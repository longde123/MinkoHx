package minko.file;

import minko.component.MasterLodScheduler;
import minko.component.Surface;
import minko.data.Store;
import minko.file.MeshPartitioner.Options;
import minko.file.POPGeometryWriter.RangeFunction;
import minko.geometry.Geometry;
import minko.render.AbstractTexture;
import minko.utils.MathUtil;
typedef LodFunction = Int -> Int -> Int -> Float -> Surface -> Int;
typedef LodPriorityFunction = Int -> Int -> Surface -> Store -> Store -> Store -> Float;
typedef PopGeometryErrorFunction = Float -> Surface -> Float;
typedef POPGeometryFunction = String -> Geometry -> Geometry;
typedef StreamedTextureFunction = String -> AbstractTexture -> AbstractTexture;


class StreamingOptions {

    static public var MAX_LOD = 32;
    static public var MAX_LOD_RANGE = 32;

    private var _disableProgressiveLodFetching:Bool;

    private var _textureStreamingIsActive:Bool;
    private var _geometryStreamingIsActive:Bool;

    private var _masterLodScheduler:MasterLodScheduler;

    private var _popGeometryWriterLodRangeFunction:RangeFunction;

    private var _popGeometryErrorToleranceThreshold:Int;

    private var _popGeometryLodFunction:LodFunction;
    private var _streamedTextureLodFunction:LodFunction;

    private var _popGeometryLodPriorityFunction:LodPriorityFunction;
    private var _streamedTextureLodPriorityFunction:LodPriorityFunction;

    private var _popGeometryErrorFunction:PopGeometryErrorFunction;

    private var _meshPartitionerOptions:Options;

    private var _popGeometryPriorityFactor:Float;
    private var _streamedTexturePriorityFactor:Float;

    private var _popGeometryMaxPrecisionLevel:Int;
    private var _streamedTextureMaxMipLevel;

    private var _popGeometryLodRangeFetchingBoundFunction:Int -> Int -> Int -> Int -> Int -> Int -> Void;
    private var _streamedTextureLodRangeFetchingBoundFunction:Int -> Int -> Int -> Int -> Int -> Int -> Void;

    private var _createStreamedTextureOnTheFly:Bool;

    private var _popGeometryBlendingRange:Float;

    private var _maxNumActiveParsers:Int;

    private var _requestAbortingEnabled:Bool;
    private var _abortableRequestProgressThreshold:Float;

    private var _popGeometryFunction:POPGeometryFunction;
    private var _streamedTextureFunction:StreamedTextureFunction;

    private var _popGeometryLodDependencyProperties:Array<String>;
    private var _streamedTextureLodDependencyProperties:Array<String>;

    private var _surfaceOperator:SurfaceOperator;

    public static function create() {
        var streamingOptions = new StreamingOptions();

        return streamingOptions;
    }

    public var disableProgressiveLodFetching(get, set):Bool;

    function get_disableProgressiveLodFetching() {
        return _disableProgressiveLodFetching;
    }

    function set_disableProgressiveLodFetching(value) {
        _disableProgressiveLodFetching = value;

        return value;
    }

    public var textureStreamingIsActive(get, set):Bool;

    function get_textureStreamingIsActive() {
        return _textureStreamingIsActive;
    }

    function set_textureStreamingIsActive(value) {
        _textureStreamingIsActive = value;

        return value;
    }

    public var geometryStreamingIsActive(get, set):Bool;

    function get_geometryStreamingIsActive() {
        return _geometryStreamingIsActive;
    }

    function set_geometryStreamingIsActive(value) {
        _geometryStreamingIsActive = value;

        return value;
    }
    public var masterLodScheduler(get, set):MasterLodScheduler;

    function get_masterLodScheduler() {
        return _masterLodScheduler;
    }

    function set_masterLodScheduler(value) {
        _masterLodScheduler = value;

        return value;
    }

    public var popGeometryWriterLodRangeFunction(get, set):RangeFunction;

    function get_popGeometryWriterLodRangeFunction() {
        return _popGeometryWriterLodRangeFunction;
    }

    function set_popGeometryWriterLodRangeFunction(v) {
        _popGeometryWriterLodRangeFunction = v;

        return v;
    }
    public var popGeometryErrorToleranceThreshold(get, set):Int;

    function get_popGeometryErrorToleranceThreshold() {
        return _popGeometryErrorToleranceThreshold;
    }

    function set_popGeometryErrorToleranceThreshold(value) {
        _popGeometryErrorToleranceThreshold = value;

        return value;
    }

    public var popGeometryLodFunction(get, set):LodFunction;

    function get_popGeometryLodFunction() {
        return _popGeometryLodFunction;
    }

    function set_popGeometryLodFunction(f) {
        _popGeometryLodFunction = f;

        return f;
    }
    public var streamedTextureLodFunction(get, set):LodFunction;

    function get_streamedTextureLodFunction() {
        return _streamedTextureLodFunction;
    }

    function set_streamedTextureLodFunction(f) {
        _streamedTextureLodFunction = f;

        return f;
    }

    public var popGeometryLodPriorityFunction:LodPriorityFunction;

    function get_popGeometryLodPriorityFunction() {
        return _popGeometryLodPriorityFunction;
    }

    function set_popGeometryLodPriorityFunction(f) {
        _popGeometryLodPriorityFunction = f;

        return f;
    }
    public var streamedTextureLodPriorityFunction(get, set):LodPriorityFunction;

    function get_streamedTextureLodPriorityFunction() {
        return _streamedTextureLodPriorityFunction;
    }

    function set_streamedTextureLodPriorityFunction(f) {
        _streamedTextureLodPriorityFunction = f;

        return f;
    }

    public var popGeometryErrorFunction(get, set):PopGeometryErrorFunction;

    function get_popGeometryErrorFunction() {
        return _popGeometryErrorFunction;
    }

    function set_popGeometryErrorFunction(f) {
        _popGeometryErrorFunction = f;

        return f;
    }

    public var meshPartitionerOptions(get, set):Options;

    function get_meshPartitionerOptions() {
        return _meshPartitionerOptions;
    }

    function set_meshPartitionerOptions(value) {
        _meshPartitionerOptions.copyFrom(value);

        return _meshPartitionerOptions;
    }

    public var popGeometryPriorityFactor(get, set):Float;

    function get_popGeometryPriorityFactor() {
        return _popGeometryPriorityFactor;
    }

    function set_popGeometryPriorityFactor(value) {
        _popGeometryPriorityFactor = value;

        return value;
    }

    public var streamedTexturePriorityFactor(get, set):Float;

    function get_streamedTexturePriorityFactor() {
        return _streamedTexturePriorityFactor;
    }

    function set_streamedTexturePriorityFactor(value) {
        _streamedTexturePriorityFactor = value;

        return value;
    }
    public var popGeometryMaxPrecisionLevel(get, set):Int;

    function get_popGeometryMaxPrecisionLevel() {
        return _popGeometryMaxPrecisionLevel;
    }

    function set_popGeometryMaxPrecisionLevel(value) {
        _popGeometryMaxPrecisionLevel = value;

        return value;
    }

    public var streamedTextureMaxMipLevel(get, set):Int;

    function get_streamedTextureMaxMipLevel() {
        return _streamedTextureMaxMipLevel;
    }

    function set_streamedTextureMaxMipLevel(value) {
        _streamedTextureMaxMipLevel = value;

        return value;
    }

    public var popGeometryLodRangeFetchingBoundFunction(get, set):Int -> Int -> Int -> Int -> Int -> Int -> Void;

    function get_popGeometryLodRangeFetchingBoundFunction() {
        return _popGeometryLodRangeFetchingBoundFunction;
    }

    function set_popGeometryLodRangeFetchingBoundFunction(f) {
        _popGeometryLodRangeFetchingBoundFunction = f;

        return f;
    }

    public var streamedTextureLodRangeFetchingBoundFunction(get, set):Int -> Int -> Int -> Int -> Int -> Int -> Void;

    function get_streamedTextureLodRangeFetchingBoundFunction() {
        return _streamedTextureLodRangeFetchingBoundFunction;
    }

    function set_streamedTextureLodRangeFetchingBoundFunction(f) {
        _streamedTextureLodRangeFetchingBoundFunction = f;

        return f;
    }

    public var createStreamedTextureOnTheFly(get, set):Bool;

    function get_createStreamedTextureOnTheFly() {
        return _createStreamedTextureOnTheFly;
    }

    function set_createStreamedTextureOnTheFly(value) {
        _createStreamedTextureOnTheFly = value;

        return value;
    }

    public var popGeometryBlendingRange(get, set):Float;

    function get_popGeometryBlendingRange() {
        return _popGeometryBlendingRange;
    }

    function set_popGeometryBlendingRange(value) {
        _popGeometryBlendingRange = MathUtil.clamp(value, 0.0, 1.0);

        return _popGeometryBlendingRange;
    }
    public var maxNumActiveParsers(get, set):Int;

    function get_maxNumActiveParsers() {
        return _maxNumActiveParsers;
    }

    function set_maxNumActiveParsers(value) {
        _maxNumActiveParsers = value;

        return value;
    }

    public var requestAbortingEnabled(get, set):Bool;

    function get_requestAbortingEnabled() {
        return _requestAbortingEnabled;
    }

    function set_requestAbortingEnabled(value) {
        _requestAbortingEnabled = value;

        return value;
    }
    public var abortableRequestProgressThreshold(get, set):Float;

    function get_abortableRequestProgressThreshold() {
        return _abortableRequestProgressThreshold;
    }

    function set_abortableRequestProgressThreshold(value) {
        _abortableRequestProgressThreshold = value;

        return value;
    }

    public var popGeometryFunction(get, set):POPGeometryFunction;

    function get_popGeometryFunction() {
        return _popGeometryFunction;
    }

    function set_popGeometryFunction(func) {
        _popGeometryFunction = func;

        return func;
    }

    public var streamedTextureFunction(get, set):StreamedTextureFunction;

    function get_streamedTextureFunction() {
        return _streamedTextureFunction;
    }

    function set_streamedTextureFunction(func) {
        _streamedTextureFunction = func;

        return func;
    }
    public var popGeometryLodDependencyProperties(get, null):Array<String>;

    function get_popGeometryLodDependencyProperties() {
        return _popGeometryLodDependencyProperties;
    }
    public var streamedTextureLodDependencyProperties(get, null):Array<String>;

    function get_streamedTextureLodDependencyProperties() {
        return _streamedTextureLodDependencyProperties;
    }
    public var surfaceOperator(get, set):SurfaceOperator;

    function get_surfaceOperator() {
        return _surfaceOperator;
    }

    function set_surfaceOperator(value) {
        _surfaceOperator.copyFrom(value);

        return _surfaceOperator;
    }

    public function new() {
    }
}
