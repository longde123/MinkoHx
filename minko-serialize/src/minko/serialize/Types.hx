package minko.serialize;
import haxe.ds.IntMap;
class Types {
    public static var imageFormatToExtensionMap:IntMap<ImageFormat> = initSortedDictionary();

    static function initSortedDictionary() {
        var tmp = new IntMap<ImageFormat>();
        tmp.set(ImageFormat.PNG, "png");
        tmp.set(ImageFormat.JPEG, "jpg");
        tmp.set(ImageFormat.TGA, "tga");
        return tmp;
    }

    public static var defaultImageFormat = ImageFormat.PNG;

    public static function extensionFromImageFormat(format:ImageFormat) {
        var imageFormatToExtensionPairIt = imageFormatToExtensionMap.exists(format);

        if (imageFormatToExtensionPairIt == false) {
            return imageFormatToExtensionMap.get(defaultImageFormat);
        }

        return imageFormatToExtensionMap.get(format);
    }

    public static function imageFormatFromExtension(extension:String) {

        var imageFormatToExtensionPairIt = Lambda.find(imageFormatToExtensionMap.keys(), function(imageFormatToExtensionPair) {
            return imageFormatToExtensionMap.get(imageFormatToExtensionPair) == extension;
        });

        if (imageFormatToExtensionPairIt == null) {
            return ImageFormat.SOURCE;
        }

        return imageFormatToExtensionPairIt;
    }
}
@:enum abstract StreamedAssetType(Int) from Int to Int {

    var STREAMED_TEXTURE_ASSET = 5;
    var STREAMED_GEOMETRY_ASSET = 6;
}

@:enum abstract Version(Int) from Int to Int {

    var GEOMETRY_STREAM_VERSION = 0x10111213;
    var TEXTURE_STREAM_VERSION = 0;
}
@:enum abstract ComponentId(Int) from Int to Int {

    var IMAGE_BASED_LIGHT = 30;
    var _COMPONENT_ID_RESERVED_0 = 31;
    var _COMPONENT_ID_RESERVED_1 = 32;
    var _COMPONENT_ID_RESERVED_2 = 33;
    var _COMPONENT_ID_RESERVED_3 = 34;
    var _COMPONENT_ID_RESERVED_4 = 35;
    var _COMPONENT_ID_RESERVED_5 = 36;
    var _COMPONENT_ID_RESERVED_6 = 37;
    var _COMPONENT_ID_RESERVED_7 = 38;
    var _COMPONENT_ID_RESERVED_8 = 39;
    var _COMPONENT_ID_RESERVED_9 = 40;
    var _COMPONENT_ID_RESERVED_10 = 41;
    var _COMPONENT_ID_RESERVED_11 = 42;
    var _COMPONENT_ID_RESERVED_12 = 43;
    var _COMPONENT_ID_RESERVED_13 = 44;
    var _COMPONENT_ID_RESERVED_14 = 45;
    var _COMPONENT_ID_RESERVED_15 = 46;
    var _COMPONENT_ID_RESERVED_16 = 47;
    var _COMPONENT_ID_RESERVED_17 = 48;
    var _COMPONENT_ID_RESERVED_18 = 49;
    var TRANSFORM = 100;
    var PROJECTION_CAMERA = 101;
    var AMBIENT_LIGHT = 102;
    var DIRECTIONAL_LIGHT = 103;
    var POINT_LIGHT = 104;
    var SPOT_LIGHT = 105;
    var SURFACE = 106;
    var RENDERER = 107;
    var BOUNDINGBOX = 108;
    var ANIMATION = 109;
    var SKINNING = 110;
    var COLLIDER = 50;
    var PARTICLES = 60;
    var METADATA = 70;
    var MASTER_ANIMATION = 90;
    var COMPONENT_ID_EXTENSION = 111;
}
@:enum abstract MinkoTypes(Int) from Int to Int {

    var MATRIX4X4 = 0;
    var VECTOR4 = 3;
    var VECTOR3 = 1;
    var VECTOR2 = 2;
    var INT = 4;
    var TEXTURE = 5;
    var FLOAT = 6;
    var BOOL = 7;
    var BLENDING = 8;
    var TRIANGLECULLING = 9;
    var ENVMAPTYPE = 10;
    var STRING = 11;
}
@:enum abstract StreamingComponentId(Int) from Int to Int {
    var POP_GEOMETRY_LOD_SCHEDULER = ComponentId.COMPONENT_ID_EXTENSION + 1;
    var TEXTURE_LOD_SCHEDULER = POP_GEOMETRY_LOD_SCHEDULER + 1;
}
@:enum abstract AssetType(Int) from Int to Int {

    var GEOMETRY_ASSET = 0;
    var EMBED_GEOMETRY_ASSET = 10;
    var MATERIAL_ASSET = 1;
    var EMBED_MATERIAL_ASSET = 11;
    var TEXTURE_ASSET = 2;
    var EMBED_TEXTURE_ASSET = 120;
    var EFFECT_ASSET = 3;
    var EMBED_EFFECT_ASSET = 13;
    var TEXTURE_PACK_ASSET = 4;
    var EMBED_TEXTURE_PACK_ASSET = 14;
    var EMBED_LINKED_ASSET = 15;
    var LINKED_ASSET = 16;

}
@:enum abstract ImageFormat(Int) from Int to Int {

    var SOURCE = 1;
    var PNG = 2;
    var JPEG = 3;
    var TGA = 4;
}