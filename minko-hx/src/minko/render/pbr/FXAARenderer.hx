package minko.render.pbr;

import minko.render.AbstractContext;
import minko.render.target.RenderTarget;

/**
 * Lightweight FXAA pass built on FullscreenEffect.
 */
class FXAARenderer {
    private var _effect:FullscreenEffect;

    public function new(context:AbstractContext) {
        _effect = new FullscreenEffect(context, "FXAA", PBRShaderLibrary.fxaaFragment());
    }

    public function render(input:RenderTarget, output:RenderTarget):Void {
        if (input == null || output == null) {
            return;
        }
        _effect.render(output, function(effect:FullscreenEffect) {
            effect.setTexture("uColorMap", input.color);
            effect.setVec2("uTexelSize", 1.0 / Math.max(1, input.width), 1.0 / Math.max(1, input.height));
        });
    }

    public function dispose():Void {
        if (_effect != null) {
            _effect.dispose();
            _effect = null;
        }
    }
}
