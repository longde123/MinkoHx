package minko.render;
@:enum abstract TextureFormat(Int) from Int to Int{
    var RGB = 0;
    var RGBA = 1;

    var RGB_DXT1 = 2;
    var RGBA_DXT1 = 3;
    var RGBA_DXT3 = 4;
    var RGBA_DXT5 = 5;

    var RGB_ETC1 = 6;
    var RGBA_ETC1 = 7;

    var RGB_PVRTC1_2BPP = 8;
    var RGB_PVRTC1_4BPP = 9;
    var RGBA_PVRTC1_2BPP = 10;
    var RGBA_PVRTC1_4BPP = 11;

    var RGBA_PVRTC2_2BPP = 12;
    var RGBA_PVRTC2_4BPP = 13;

    var RGB_ATITC = 14;
    var RGBA_ATITC = 15;

    // supported from OES 3.0
    var RGB_ETC2 = 16;
    var RGBA_ETC2 = 7;

}
