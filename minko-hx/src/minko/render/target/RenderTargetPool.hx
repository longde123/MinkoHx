package minko.render.target;

import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.Texture;
import minko.render.TextureFormat;
import minko.render.target.RenderTarget;

/**
 * Reuses render-to-texture allocations across frames.
 *
 * The current backend creates a framebuffer from a single RTT Texture. MRT
 * support will extend acquire() with multiple color formats; the pool API is
 * already based on RenderTarget so the callers will not need to change.
 */
class RenderTargetPool {
    private var _context:AbstractContext;
    private var _free:Array<RenderTarget>;
    private var _active:Array<RenderTarget>;
    private var _maxFreePerSize:Int;

    public function new(context:AbstractContext, maxFreePerSize:Int = 4) {
        this._context = context;
        this._free = [];
        this._active = [];
        this._maxFreePerSize = maxFreePerSize;
    }

    public function acquire(width:Int, height:Int, format:TextureFormat = TextureFormat.RGBA):RenderTarget {
        return acquireMRT(width, height, [format]);
    }

    public function acquireMRT(width:Int, height:Int, formats:Array<TextureFormat>, depthFormat:Null<TextureFormat> = null):RenderTarget {
        // Texture GPU storage is always rounded up to power-of-two by the
        // Texture class. Request POT sizes here so the FBO attachment, the
        // viewport and the sampled UV 0..1 range all cover exactly the same
        // area; otherwise present samples mostly undefined texels (black).
        width = potSize(width);
        height = potSize(height);

        var colorCount = formats != null && formats.length > 0 ? formats.length : 1;
        var wantsDepth = depthFormat != null;
        var format0 = formats != null && formats.length > 0 ? formats[0] : TextureFormat.RGBA;

        for (i in 0..._free.length) {
            var entry = _free[i];
            if (entry.width != width || entry.height != height || entry.colors.length != colorCount) {
                continue;
            }
            if ((entry.depth != null) != wantsDepth) {
                continue;
            }
            // Formats must match too: handing an RGBA target to an RGBA16F
            // request (or a Depth24 buffer to a Depth32F request) silently
            // changes precision/content. Index 0 is representative because
            // acquireMRT always builds all color attachments from `formats`.
            if (!sameFormat(entry.colors[0], format0)) {
                continue;
            }
            if (wantsDepth && !sameFormat(entry.depth, depthFormat)) {
                continue;
            }
            _free.splice(i, 1);
            _active.push(entry);
            return entry;
        }

        var colors:Array<AbstractTexture> = [];
        var textureIds = [];
        for (i in 0...colorCount) {
            var format = formats != null && i < formats.length ? formats[i] : TextureFormat.RGBA;
            var texture = Texture.create(_context, width, height, false, false, true, format);
            texture.upload();
            colors.push(texture);
            textureIds.push(texture.id);
        }

        var depthTexture:Texture = null;
        var depthId = -1;
        if (wantsDepth) {
            depthTexture = Texture.create(_context, width, height, false, false, true, depthFormat);
            depthTexture.upload();
            depthId = depthTexture.id;
        }

        var nativeTarget = _context.createRenderTarget(textureIds, width, height, depthId);
        var target = new RenderTarget(colors, width, height, _context, nativeTarget, depthTexture);
        _active.push(target);
        return target;
    }

    public static function potSize(value:Int):Int {
        var size = 1;
        while (size < value) {
            size <<= 1;
        }
        return size;
    }

    private static function sameFormat(texture:AbstractTexture, format:TextureFormat):Bool {
        if (texture == null) {
            return false;
        }
        return texture.format == format;
    }

    public function release(target:RenderTarget):Void {
        if (target == null) {
            return;
        }
        _active.remove(target);

        var sameSize = 0;
        for (entry in _free) {
            if (entry.width == target.width && entry.height == target.height) {
                sameSize++;
            }
        }

        if (sameSize < _maxFreePerSize) {
            _free.push(target);
        }
        else {
            target.dispose();
        }
    }

    /**
     * Drops cached targets. Active targets are intentionally left alone:
     * releasing an in-flight frame target while the GPU may still read it is
     * invalid. Call this at frame boundaries.
     */
    public function trim():Void {
        for (target in _free) {
            target.dispose();
        }
        _free = [];
    }

    public function dispose():Void {
        for (target in _free) {
            target.dispose();
        }
        for (target in _active) {
            target.dispose();
        }
        _free = [];
        _active = [];
        _context = null;
    }

    public var activeCount(get, null):Int;

    function get_activeCount():Int {
        return _active.length;
    }

    public var freeCount(get, null):Int;

    function get_freeCount():Int {
        return _free.length;
    }
}
