package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TCamera;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Camera extends Ref {
    public var type(default, null):CameraType;
    public var znear(default, null):Float;
    public var zfar(default, null):Float;

    function new() {
        super();
    }

    function load(gltf:GLTF2, camera:TCamera):Void {
        if (camera.perspective != null) {
            type = CameraType.Perspective(camera.perspective.aspectRatio, camera.perspective.yfov);
            znear = camera.perspective.znear;
            zfar = camera.perspective.zfar;
        }
        else {
            type = CameraType.Orthographic(camera.orthographic.xmag, camera.orthographic.ymag);
            znear = camera.orthographic.znear;
            zfar = camera.orthographic.zfar;
        }
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Camera> {
        var cameras:Vector<Camera> = new Vector<Camera>(raw.cameras.length);
        for (i in 0...raw.cameras.length) {
            cameras[i] = new Camera();
            cameras[i].index = i;
        }
        for (i in 0...raw.cameras.length) {
            cameras[i].load(gltf, raw.cameras[i]);
        }
        return cameras;
    }
}
