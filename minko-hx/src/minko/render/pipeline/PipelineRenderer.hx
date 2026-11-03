package minko.render.pipeline;

import glm.Vec3;
import minko.component.PerspectiveCamera;
import minko.render.AbstractContext;
import minko.scene.Node;

/**
 * Entry point for the new render pipeline.
 *
 * It collects Surfaces from a scene graph, updates camera data and delegates
 * execution to RenderPipeline.
 */
class PipelineRenderer {
    public var pipeline:RenderPipeline;
    public var root:Node;
    public var width:Int;
    public var height:Int;
    public var camera:PerspectiveCamera;
    public var time:Float;

    public function new(context:AbstractContext, root:Node, path:RenderPath, width:Int, height:Int) {
        this.root = root;
        this.width = width;
        this.height = height;
        this.pipeline = new RenderPipeline(context, path);
        this.camera = null;
        this.time = 0.0;
    }

    public function render(deltaTime:Float = 0.0):Void {
        time += deltaTime;
        camera = SceneCollector.collect(root, pipeline.queue);

        if (camera != null) {
            pipeline.viewMatrix = camera.viewMatrix;
            pipeline.projectionMatrix = camera.projectionMatrix;
            pipeline.cameraPosition = camera.position;
        }

        pipeline.render(width, height, time);
    }

    public function dispose():Void {
        if (pipeline != null) {
            pipeline.dispose();
            pipeline = null;
        }
        root = null;
        camera = null;
    }
}
