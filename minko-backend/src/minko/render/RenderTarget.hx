package minko.render;

/**
 * Native framebuffer target.
 *
 * Color attachments are texture IDs owned by the caller. The context owns the
 * framebuffer/depth attachment and the RenderTarget object only carries the
 * metadata needed to bind and dispose it.
 */
class RenderTarget {
    public var id:Int;
    public var colors:Array<Int>;
    public var depth:Int;
    public var width:Int;
    public var height:Int;

    public function new(id:Int, colors:Array<Int>, depth:Int, width:Int, height:Int) {
        this.id = id;
        this.colors = colors;
        this.depth = depth;
        this.width = width;
        this.height = height;
    }

    public var colorCount(get, null):Int;

    function get_colorCount():Int {
        return colors != null ? colors.length : 0;
    }
}
