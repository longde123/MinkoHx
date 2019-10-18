package minko;
class StreamingCommon{
    public static var   MINKO_SCENE_MAGIC_NUMBER   = 0x4D4B0300; // MK30 last byte reserved for extensions (material, geometry...)
    public static var   MINKO_SCENE_HEADER_SIZE    = 56;
    public static var   MINKO_SCENE_VERSION_MAJOR  = 0;
    public static var   MINKO_SCENE_VERSION_MINOR	=3;
    public static var   MINKO_SCENE_VERSION_PATCH  = 1;

}
class ProgressiveOrderedMeshLodInfo {

    private var _level:Int;
    private var _precisionLevel:Int;
    private var _indexOffset:Int;
    private var _indexCount:Int;

    private var _isValid:Bool;

    public var isValid(get, null):Bool;

    function get_isValid() {
        return _isValid;
    }

    public function new(level,
                        precisionLevel,
                        indexOffset,
                        indexCount) {
        _level = (level);
        _precisionLevel = (precisionLevel);
        _indexOffset = (indexOffset);
        _indexCount = (indexCount);
        _isValid = (true);
    }

    public function equals(left:ProgressiveOrderedMeshLodInfo, right:ProgressiveOrderedMeshLodInfo) {
        return left._level == right._level &&
        left._precisionLevel == right._precisionLevel &&
        left._indexOffset == right._indexOffset &&
        left._indexCount == right._indexCount &&
        left.isValid == right.isValid;
    }
}
