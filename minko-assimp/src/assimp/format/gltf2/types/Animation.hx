package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TAnimation;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Animation {
    public var name(default, null):String = null;
    public var channels(default, null):Vector<AnimationChannel> = null;

    function new() {}

    function load(gltf:GLTF2, animation:TAnimation):Void {
        this.name = animation.name;
        this.channels = new Vector<AnimationChannel>(animation.channels.length);

        for (i in 0...animation.channels.length) {
            var channel:AnimationChannel = new AnimationChannel();
            channel.node = gltf.nodes[animation.channels[i].target.node];
            channel.loadSampler(gltf, animation.samplers[animation.channels[i].sampler]);
            channel.path = animation.channels[i].target.path;
            channels[i] = channel;
        }
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Animation> {
        var animations:Vector<Animation> = new Vector<Animation>(raw.animations.length);
        for (i in 0...raw.animations.length) {
            animations[i] = new Animation();
        }
        for (i in 0...raw.animations.length) {
            animations[i].load(gltf, raw.animations[i]);
        }
        return animations;
    }
}