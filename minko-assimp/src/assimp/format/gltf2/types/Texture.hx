package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TTexture;
import assimp.format.gltf2.types.Image;
import assimp.format.gltf2.types.Sampler;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Texture {
    public var name(default, null):String = null;
    public var image(default, null):Image = null;
    public var sampler(default, null):Sampler = null;

    function new() {}

    function load(gltf:GLTF2, texture:TTexture):Void {
        this.name = texture.name;
        if (texture.source != null) this.image = gltf.images[texture.source];
        if (texture.sampler != null) this.sampler = gltf.samplers[texture.sampler];
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Texture> {
        var textures:Vector<Texture> = new Vector<Texture>(raw.textures.length);
        for (i in 0...raw.textures.length) {
            textures[i] = new Texture();
        }
        for (i in 0...raw.textures.length) {
            textures[i].load(gltf, raw.textures[i]);
        }
        return textures;
    }
}