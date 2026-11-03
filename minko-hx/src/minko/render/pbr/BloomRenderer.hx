package minko.render.pbr;

import minko.render.AbstractContext;
import minko.render.TextureFormat;
import minko.render.target.RenderTarget;
import minko.render.target.RenderTargetPool;

/**
 * Two-pass (bright + separable blur) bloom.
 *
 * Uses FullscreenEffect programs and transient half-resolution targets from
 * RenderTargetPool.
 */
class BloomRenderer {
    private var _bright:FullscreenEffect;
    private var _blur:FullscreenEffect;
    private var _composite:FullscreenEffect;

    public function new(context:AbstractContext) {
        _bright = new FullscreenEffect(context, "BloomBright", PBRShaderLibrary.brightPassFragment());
        _blur = new FullscreenEffect(context, "BloomBlur", PBRShaderLibrary.blurFragment());
        _composite = new FullscreenEffect(context, "BloomComposite", PBRShaderLibrary.bloomCompositeFragment());
    }

    public function render(pool:RenderTargetPool, input:RenderTarget, output:RenderTarget, threshold:Float = 1.0, intensity:Float = 0.6):Void {
        if (pool == null || input == null || output == null) {
            return;
        }

        var halfWidth = Math.floor(Math.max(1, input.width * 0.5));
        var halfHeight = Math.floor(Math.max(1, input.height * 0.5));
        var brightTarget = pool.acquire(halfWidth, halfHeight, TextureFormat.RGBA);
        var blurTarget = pool.acquire(halfWidth, halfHeight, TextureFormat.RGBA);

        _bright.render(brightTarget, function(effect:FullscreenEffect) {
            effect.setTexture("uColorMap", input.color);
            effect.setFloat("uThreshold", threshold);
        });

        _blur.render(blurTarget, function(effect:FullscreenEffect) {
            effect.setTexture("uColorMap", brightTarget.color);
            effect.setVec2("uTexelSize", 1.0 / halfWidth, 1.0 / halfHeight);
            effect.setVec2("uDirection", 1.0, 0.0);
        });

        _blur.render(brightTarget, function(effect:FullscreenEffect) {
            effect.setTexture("uColorMap", blurTarget.color);
            effect.setVec2("uTexelSize", 1.0 / halfWidth, 1.0 / halfHeight);
            effect.setVec2("uDirection", 0.0, 1.0);
        });

        _composite.render(output, function(effect:FullscreenEffect) {
            effect.setTexture("uSceneMap", input.color);
            effect.setTexture("uBloomMap", brightTarget.color);
            effect.setFloat("uBloomIntensity", intensity);
        });

        pool.release(brightTarget);
        pool.release(blurTarget);
    }

    public function dispose():Void {
        if (_bright != null) _bright.dispose();
        if (_blur != null) _blur.dispose();
        if (_composite != null) _composite.dispose();
        _bright = null;
        _blur = null;
        _composite = null;
    }
}
