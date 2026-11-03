package minko.render.pipeline;

class RenderPass {
    public var name:String;
    public var inputs:Array<RenderGraphResource>;
    public var outputs:Array<RenderGraphResource>;

    public function new(name:String) {
        this.name = name;
        this.inputs = [];
        this.outputs = [];
    }

    public function read(resource:RenderGraphResource):RenderPass {
        if (resource != null && inputs.indexOf(resource) == -1) {
            inputs.push(resource);
        }
        return this;
    }

    public function write(resource:RenderGraphResource):RenderPass {
        if (resource != null && outputs.indexOf(resource) == -1) {
            outputs.push(resource);
        }
        return this;
    }

    public function execute(ctx:FrameContext):Void {
        throw "RenderPass.execute() must be overridden: " + name;
    }
}
