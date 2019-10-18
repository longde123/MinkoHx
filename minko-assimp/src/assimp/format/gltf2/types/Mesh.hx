package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TMesh;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Mesh extends Ref {
    public var name(default, null):Null<String> = null;
    public var primitives(default, null):Vector<MeshPrimitive> = new Vector<MeshPrimitive>(0);
    public var weights(default, null):Vector<Float> = new Vector<Float>(0);

    function new() {
        super();
    }

    function load(gltf:GLTF2, mesh:TMesh):Void {
        name = mesh.name;
        primitives = new Vector<MeshPrimitive>(mesh.primitives.length);
        for (i in 0...mesh.primitives.length) {
            primitives[i] = new MeshPrimitive();
            primitives[i].load(gltf, mesh.primitives[i]);
        }

        if (mesh.weights != null) weights = Vector.fromArrayCopy(mesh.weights);
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Mesh> {
        var meshes:Vector<Mesh> = new Vector<Mesh>(raw.meshes.length);
        for (i in 0...raw.meshes.length) {
            meshes[i] = new Mesh();
            meshes[i].index = i;
        }
        for (i in 0...raw.meshes.length) {
            meshes[i].load(gltf, raw.meshes[i]);

        }
        return meshes;
    }
}
