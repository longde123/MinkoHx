package minko.render.target;

import minko.render.AbstractContext;
import minko.render.AbstractTexture;

/**
 * Deferred G-Buffer resource.
 *
 * Supports both native MRT (one RenderTarget with three color attachments) and
 * the legacy multipass fallback (three independent RenderTargets).
 */
class GBuffer {
    public var target:RenderTarget;
    public var albedo:RenderTarget;
    public var normal:RenderTarget;
    public var emissive:RenderTarget;
    public var width:Int;
    public var height:Int;

    public function new(albedo:RenderTarget, normal:RenderTarget, emissive:RenderTarget, width:Int, height:Int, target:RenderTarget = null) {
        this.albedo = albedo;
        this.normal = normal;
        this.emissive = emissive;
        this.target = target;
        this.width = width;
        this.height = height;
    }

    public static function fromMRT(target:RenderTarget):GBuffer {
        return new GBuffer(null, null, null, target.width, target.height, target);
    }

    public var albedoTexture(get, null):AbstractTexture;

    function get_albedoTexture():AbstractTexture {
        return target != null ? target.colors[0] : (albedo != null ? albedo.color : null);
    }

    public var normalTexture(get, null):AbstractTexture;

    function get_normalTexture():AbstractTexture {
        return target != null ? target.colors[1] : (normal != null ? normal.color : null);
    }

    public var emissiveTexture(get, null):AbstractTexture;

    function get_emissiveTexture():AbstractTexture {
        return target != null ? target.colors[2] : (emissive != null ? emissive.color : null);
    }

    public var depthTexture(get, null):AbstractTexture;

    function get_depthTexture():AbstractTexture {
        if (target != null) {
            return target.depth;
        }
        return albedo != null ? albedo.depth : null;
    }

    public function bindGBuffer(context:AbstractContext):Void {
        if (target != null) {
            target.bind(context, true);
        }
        else {
            albedo.bind(context, true);
        }
    }

    public function bindAlbedo(context:AbstractContext):Void {
        if (albedo != null) albedo.bind(context, true);
    }

    public function bindNormal(context:AbstractContext):Void {
        if (normal != null) normal.bind(context, true);
    }

    public function bindEmissive(context:AbstractContext):Void {
        if (emissive != null) emissive.bind(context, true);
    }

    public function unbind(context:AbstractContext):Void {
        context.setRenderToBackBuffer();
    }
}
