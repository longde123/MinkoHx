package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TSampler;
import assimp.format.gltf2.schema.GLTF.TWrapMode;
import assimp.format.gltf2.schema.GLTF.TMinFilter;
import assimp.format.gltf2.schema.GLTF.TMagFilter;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Sampler extends Ref {
    public var name(default, null):String;
    public var magFilter(default, null):TMagFilter;
    public var minFilter(default, null):TMinFilter;
    public var wrapS(default, null):TWrapMode;
    public var wrapT(default, null):TWrapMode;

    function new() {
        super();
    }

    function load(gltf:GLTF2, sampler:TSampler):Void {
        this.name = sampler.name;
        this.magFilter = sampler.magFilter;
        this.minFilter = sampler.minFilter;
        this.wrapS = sampler.wrapS;
        this.wrapT = sampler.wrapT;
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Sampler> {
        var samplers:Vector<Sampler> = new Vector<Sampler>(raw.samplers.length);
        for (i in 0...raw.samplers.length) {
            samplers[i] = new Sampler();
            samplers[i].index = i;
        }
        for (i in 0...raw.samplers.length) {
            samplers[i].load(gltf, raw.samplers[i]);
        }
        return samplers;
    }
}