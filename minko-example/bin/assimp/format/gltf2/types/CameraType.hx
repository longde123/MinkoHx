package assimp.format.gltf2.types;

enum CameraType {
    Orthographic(xmag:Float, ymag:Float);
    Perspective(aspectRatio:Float, yFov:Float);
}
