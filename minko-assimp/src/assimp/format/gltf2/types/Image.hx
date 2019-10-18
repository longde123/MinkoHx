package assimp.format.gltf2.types;

import assimp.format.gltf2.schema.GLTF.TGlTf;
import assimp.format.gltf2.schema.GLTF.TImage;
import assimp.format.gltf2.schema.GLTF.TImageMimeType;
import haxe.ds.Vector;

@:allow(assimp.format.gltf2.GLTF2)
class Image extends Ref {
    public var name(default, null):String = null;
    public var uri(default, null):Null<String> = null;
    public var mimeType(default, null):TImageMimeType = TImageMimeType.PNG;
    public var bufferView(default, null):Null<BufferView> = null;

    function new() {
        super();
    }

    function load(gltf:GLTF2, image:TImage):Void {
        this.name = image.name;
        this.uri = image.uri; //DataURI  // Local file
        this.mimeType = image.mimeType;
        if (image.bufferView != null) this.bufferView = gltf.bufferViews[image.bufferView];
    }

    static function loadFromRaw(gltf:GLTF2, raw:TGlTf):Vector<Image> {
        var images:Vector<Image> = new Vector<Image>(raw.images.length);
        for (i in 0...raw.images.length) {
            images[i] = new Image();
            images[i].index = i;
        }
        for (i in 0...raw.images.length) {
            images[i].load(gltf, raw.images[i]);
        }
        return images;
    }
}