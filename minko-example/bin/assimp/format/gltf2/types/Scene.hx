package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TScene;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Scene {
    public var name(default, null):Null<String> = null;
    public var nodes(default, null):Vector<Node> = new Vector<Node>(0);

    function new() {}

    function load(gltf:GLTF2, scene:TScene):Void {
        name = scene.name;
        nodes = new Vector<Node>(scene.nodes.length);
        for (i in 0...scene.nodes.length) {
            nodes[i] = gltf.nodes[scene.nodes[i]];
        }
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Scene> {
        var scenes:Vector<Scene> = new Vector<Scene>(raw.scenes.length);
        for (i in 0...raw.scenes.length) {
            scenes[i] = new Scene();
        }
        for (i in 0...raw.scenes.length) {
            scenes[i].load(gltf, raw.scenes[i]);
        }
        return scenes;
    }
}
