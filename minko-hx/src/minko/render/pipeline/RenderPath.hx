package minko.render.pipeline;

class RenderPath {
    public var name:String;

    public function new(name:String) {
        this.name = name;
    }

    public function build(queue:RenderQueue, ctx:FrameContext):RenderGraph {
        throw "RenderPath.build() must be overridden: " + name;
    }

    /**
     * Releases resources the path itself created (not resources handed in by
     * the caller, such as user-owned renderers).
     */
    public function dispose():Void {
    }
}
