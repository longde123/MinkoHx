package minko.render.pipeline;

import minko.render.target.RenderTarget;

class RenderGraphResource {
    public var name:String;
    public var target:RenderTarget;
    public var transient:Bool;
    public var producer:RenderPass;
    public var version:Int;

    public function new(name:String, target:RenderTarget = null, transient:Bool = true) {
        this.name = name;
        this.target = target;
        this.transient = transient;
        this.producer = null;
        this.version = 0;
    }

    public function resize(width:Int, height:Int):Void {
        if (target != null) {
            target.width = width;
            target.height = height;
        }
        version++;
    }
}
