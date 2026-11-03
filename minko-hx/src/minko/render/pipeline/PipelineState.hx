package minko.render.pipeline;

import minko.render.Blending;
import minko.render.TriangleCulling;

/**
 * Render state applied by a PipelineTechnique.
 *
 * The defaults match the legacy opaque PBR state. Transparent techniques
 * should use PipelineState.transparent().
 */
class PipelineState {
    public var depthTest:Bool;
    public var depthWrite:Bool;
    public var colorMask:Bool;
    public var triangleCulling:TriangleCulling;
    public var blendingSource:Blending.Source;
    public var blendingDestination:Blending.Destination;

    public function new() {
        depthTest = true;
        depthWrite = true;
        colorMask = true;
        triangleCulling = TriangleCulling.BACK;
        blendingSource = Blending.Source.ONE;
        blendingDestination = Blending.Destination.ZERO;
    }

    public static function opaque():PipelineState {
        return new PipelineState();
    }

    public static function transparent():PipelineState {
        var state = new PipelineState();
        state.blendingSource = Blending.Source.SRC_ALPHA;
        state.blendingDestination = Blending.Destination.ONE_MINUS_SRC_ALPHA;
        return state;
    }
}
