package minko.render.pipeline;

class RenderQueue {
    public var opaque:Array<RenderItem>;
    public var alphaTest:Array<RenderItem>;
    public var transparent:Array<RenderItem>;
    public var shadowCasters:Array<RenderItem>;
    private var _opaqueSorted:Bool;

    public function new() {
        opaque = [];
        alphaTest = [];
        transparent = [];
        shadowCasters = [];
        _opaqueSorted = false;
    }

    public function add(item:RenderItem, transparent:Bool = false, alphaTest:Bool = false):RenderItem {
        _opaqueSorted = false;
        if (transparent) {
            this.transparent.push(item);
        }
        else if (alphaTest) {
            this.alphaTest.push(item);
        }
        else {
            this.opaque.push(item);
        }

        if (item.castShadow) {
            shadowCasters.push(item);
        }
        return item;
    }

    public function clear():Void {
        opaque.resize(0);
        alphaTest.resize(0);
        transparent.resize(0);
        shadowCasters.resize(0);
        _opaqueSorted = false;
    }

    public function sortOpaque():Void {
        if (_opaqueSorted) {
            return;
        }
        opaque.sort(compareByMaterial);
        alphaTest.sort(compareByMaterial);
        _opaqueSorted = true;
    }

    public function sortTransparent():Void {
        transparent.sort(function(a:RenderItem, b:RenderItem) {
            if (a.depth > b.depth) return -1;
            if (a.depth < b.depth) return 1;
            return 0;
        });
    }

    private static function compareByMaterial(a:RenderItem, b:RenderItem):Int {
        var aKey = a.material != null ? a.material.uuid : "";
        var bKey = b.material != null ? b.material.uuid : "";
        if (aKey < bKey) return -1;
        if (aKey > bKey) return 1;
        return 0;
    }

    public var count(get, null):Int;

    function get_count():Int {
        return opaque.length + alphaTest.length + transparent.length;
    }
}
