package minko.render.pipeline;

typedef FramePassFunc = FrameContext -> Void;

class CallbackPass extends RenderPass {
    private var _execute:FramePassFunc;

    public function new(name:String, execute:FramePassFunc) {
        super(name);
        _execute = execute;
    }

    override public function execute(ctx:FrameContext):Void {
        if (_execute != null) {
            _execute(ctx);
        }
    }
}
