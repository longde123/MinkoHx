package minko.render.pipeline;

import minko.render.target.RenderTarget;
import minko.render.target.RenderTargetPool;

class RenderGraph {
    public var resources:Array<RenderGraphResource>;
    public var passes:Array<RenderPass>;

    private var _output:RenderGraphResource;
    private var _compiledPasses:Array<RenderPass>;
    private var _visited:Array<RenderPass>;

    public function new() {
        resources = [];
        passes = [];
        _output = null;
        _compiledPasses = [];
        _visited = [];
    }

    public function createResource(name:String, target:RenderTarget = null, transient:Bool = true):RenderGraphResource {
        var resource = new RenderGraphResource(name, target, transient);
        resources.push(resource);
        return resource;
    }

    public function addResource(resource:RenderGraphResource):RenderGraphResource {
        if (resources.indexOf(resource) == -1) {
            resources.push(resource);
        }
        return resource;
    }

    public function addPass(pass:RenderPass):RenderPass {
        if (passes.indexOf(pass) == -1) {
            passes.push(pass);
        }
        for (output in pass.outputs) {
            if (output.producer != null && output.producer != pass) {
                throw "RenderGraph: resource '" + output.name + "' has more than one producer";
            }
            output.producer = pass;
        }
        _compiledPasses = [];
        return pass;
    }

    public function setOutput(resource:RenderGraphResource):Void {
        _output = resource;
        _compiledPasses = [];
    }

    public var output(get, null):RenderGraphResource;

    function get_output():RenderGraphResource {
        return _output;
    }

    public function compile():Array<RenderPass> {
        if (_compiledPasses.length > 0) {
            return _compiledPasses;
        }
        if (_output == null || _output.producer == null) {
            return _compiledPasses;
        }

        _visited = [];
        visit(_output.producer);
        _compiledPasses = _visited;
        return _compiledPasses;
    }

    private function visit(pass:RenderPass):Void {
        if (pass == null || _visited.indexOf(pass) != -1) {
            return;
        }

        for (input in pass.inputs) {
            if (input.producer != null) {
                visit(input.producer);
            }
        }

        _visited.push(pass);
    }

    public function execute(ctx:FrameContext):Void {
        for (pass in compile()) {
            pass.execute(ctx);
        }
    }

    /**
     * Return transient targets to the pool after the frame has been submitted.
     * Resources stay in the graph so the next frame can rebuild/reacquire them.
     */
    public function releaseTransients(pool:RenderTargetPool):Void {
        if (pool == null) {
            return;
        }
        for (resource in resources) {
            if (resource.transient && resource.target != null) {
                pool.release(resource.target);
                resource.target = null;
            }
        }
    }

    public function dispose():Void {
        for (resource in resources) {
            if (resource.target != null && resource.transient) {
                resource.target.dispose();
            }
            resource.target = null;
            resource.producer = null;
        }
        resources = [];
        passes = [];
        _compiledPasses = [];
        _visited = [];
        _output = null;
    }
}
