package minko.render.pipeline;

import minko.render.TextureFormat;
import minko.render.target.RenderTarget;

typedef PostProcessFunc = FrameContext -> RenderTarget -> RenderTarget -> Void;

class PostProcessStage {
    public var name:String;
    public var execute:PostProcessFunc;
    public var format:TextureFormat;

    public function new(name:String, execute:PostProcessFunc, format:TextureFormat = TextureFormat.RGBA) {
        this.name = name;
        this.execute = execute;
        this.format = format;
    }
}

/**
 * A chain of fullscreen post-process stages. Each stage reads one RenderTarget
 * and writes the next. The chain does not know about shader compilation; the
 * PipelineRenderer supplies the execute() callback for each stage.
 */
class PostProcessChain {
    public var stages:Array<PostProcessStage>;

    public function new() {
        stages = [];
    }

    public function add(name:String, execute:PostProcessFunc, format:TextureFormat = TextureFormat.RGBA):PostProcessChain {
        stages.push(new PostProcessStage(name, execute, format));
        return this;
    }

    public function build(graph:RenderGraph, source:RenderGraphResource, ctx:FrameContext, ?resources:Array<RenderGraphResource>):RenderGraphResource {
        var current = source;

        for (stage in stages) {
            var output = graph.createResource(stage.name, ctx.targetPool.acquire(ctx.width, ctx.height, stage.format));
            var pass = new CallbackPass(stage.name, createCallback(stage, current, output));
            pass.read(current).write(output);
            graph.addPass(pass);
            current = output;
            if (resources != null) {
                resources.push(output);
            }
        }

        return current;
    }

    private function createCallback(stage:PostProcessStage, input:RenderGraphResource, output:RenderGraphResource):FrameContext->Void {
        return function(frame:FrameContext) {
            output.target.bind(frame.context, false);
            if (stage.execute != null) {
                stage.execute(frame, input.target, output.target);
            }
            output.target.unbind(frame.context);
        };
    }
}
