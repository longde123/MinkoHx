package minko.render.target;

import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.RenderTarget as BackendRenderTarget;

/**
 * A logical render target.
 *
 * The current backend only exposes single-color render-to-texture through
 * AbstractContext.setRenderToTexture(). This class is the high-level resource
 * container that the new pipeline uses; color attachments and depth attachments
 * can be added without changing the public pipeline API once the backend grows
 * MRT/depth texture support.
 */
class RenderTarget {
    public var colors:Array<AbstractTexture>;
    public var width:Int;
    public var height:Int;
    public var nativeTarget:BackendRenderTarget;
    public var depth:AbstractTexture;

    private var _context:AbstractContext;

    public function new(colors:Array<AbstractTexture>, width:Int, height:Int, context:AbstractContext = null, nativeTarget:BackendRenderTarget = null, depth:AbstractTexture = null) {
        this.colors = colors;
        this.width = width;
        this.height = height;
        this._context = context;
        this.nativeTarget = nativeTarget;
        this.depth = depth;
    }

    /**
     * Bind the current single-color attachment.
     *
     * This is the compatibility path until AbstractContext grows a native
     * multi-attachment RenderTarget API.
     */
    public function bind(context:AbstractContext, enableDepthAndStencil:Bool = true):Void {
        if (nativeTarget != null) {
            context.setRenderTarget(nativeTarget);
            return;
        }
        if (colors.length == 0 || colors[0] == null) {
            context.setRenderToBackBuffer();
            return;
        }
        context.setRenderToTexture(colors[0].id, enableDepthAndStencil);
    }

    public function unbind(context:AbstractContext):Void {
        context.setRenderToBackBuffer();
    }

    /**
     * Detach color attachments from the native FBO.
     *
     * Some drivers return black when a texture still attached to an FBO is
     * sampled while rendering to the default framebuffer. Call this after the
     * last render into the target for the frame, before using it as a source.
     */
    public function detach(context:AbstractContext):Void {
        if (nativeTarget != null) {
            context.detachRenderTarget(nativeTarget);
        }
    }

    public var color(get, null):AbstractTexture;

    function get_color():AbstractTexture {
        return colors.length > 0 ? colors[0] : null;
    }

    public var colorCount(get, null):Int;

    function get_colorCount():Int {
        return colors.length;
    }

    public function dispose():Void {
        if (nativeTarget != null) {
            if (_context != null) {
                _context.deleteRenderTarget(nativeTarget);
            }
            nativeTarget = null;
        }
        if (colors != null) {
            for (color in colors) {
                if (color != null) {
                    color.dispose();
                }
            }
            colors = [];
        }
        if (depth != null) {
            depth.dispose();
            depth = null;
        }
        _context = null;
    }
}
