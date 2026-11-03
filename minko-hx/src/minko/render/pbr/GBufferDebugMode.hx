package minko.render.pbr;

/**
 * G-buffer debug views exposed by GBufferDebugRenderer (design §15).
 */
@:enum abstract GBufferDebugMode(Int) from Int to Int {
    var Albedo = 0;
    var Normal = 1;
    var Depth = 2;
    var Lighting = 3;
    var Emissive = 4;
}
