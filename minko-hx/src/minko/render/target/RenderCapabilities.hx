package minko.render.target;

import minko.render.AbstractContext;

/**
 * Backend capability summary used by RenderPipeline to select a render path.
 *
 * Values are conservative until the backend exposes native extension queries.
 * HL/OpenGL is expected to expose MRT/HDR/depth; WebGL falls back to Forward.
 */
class RenderCapabilities {
    public var maxColorAttachments:Int;
    public var maxTextureUnits:Int;
    public var supportsMRT:Bool;
    public var supportsDepthTexture:Bool;
    public var supportsFloatRenderTarget:Bool;
    public var glslVersion:Int;

    public function new() {
        maxColorAttachments = 1;
        maxTextureUnits = 8;
        supportsMRT = false;
        supportsDepthTexture = false;
        supportsFloatRenderTarget = false;
        glslVersion = 100;
    }

    public static function detect(context:AbstractContext):RenderCapabilities {
        var caps = new RenderCapabilities();

#if hl
        caps.maxColorAttachments = 4;
        caps.maxTextureUnits = 16;
        caps.supportsMRT = true;
        caps.supportsDepthTexture = true;
        caps.supportsFloatRenderTarget = true;
        caps.glslVersion = 120;
#else
        // WebGL1 is the safe default. WebGL2/extension detection can tighten
        // these values later without changing RenderPath callers.
        caps.maxColorAttachments = 1;
        caps.maxTextureUnits = 8;
        caps.supportsMRT = false;
        caps.supportsDepthTexture = false;
        caps.supportsFloatRenderTarget = false;
        caps.glslVersion = 100;
#end

        return caps;
    }

    public function canUseDeferred():Bool {
        return supportsMRT && supportsDepthTexture;
    }

    public function canUseHDR():Bool {
        return supportsFloatRenderTarget;
    }
}
