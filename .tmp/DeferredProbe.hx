import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.io.Bytes;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.geometry.CubeGeometry;
import minko.render.TextureFormat;
import minko.render.pbr.DeferredLightingRenderer;
import minko.render.pbr.FullscreenEffect;
import minko.render.pbr.GBufferRenderer;
import minko.render.pbr.PBRForwardRenderer;
import minko.render.pbr.PBRMaterial;
import minko.render.pbr.PBRShaderLibrary;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.GBuffer;
import minko.render.target.RenderTarget;
import minko.render.target.RenderTargetPool;

// Compare DeferredLightingRenderer output against a CPU reference computed from
// the G-buffer bytes, to find where the dimness comes from.
class DeferredProbe {
    static function main() {
        var canvas = CanvasManager.create("DeferredProbe", 64, 64, Flags.RESIZABLE);
        var context = canvas.context;
        var pool = new RenderTargetPool(context);
        var geometry = CubeGeometry.create(context);

        var gbufferRenderer = new GBufferRenderer(context);
        var lighting = new DeferredLightingRenderer(context);
        var pbr = new PBRForwardRenderer(context);
        var copier = new FullscreenEffect(context, "Copy", PBRShaderLibrary.presentFragment());

        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.9, 0.6, 0.2, 1.0));
        mat.setRoughness(0.6);
        var q = new RenderQueue();
        q.add(new RenderItem(geometry, mat, null, Mat4.identity(new Mat4())));

        var frame = new FrameContext(context, 256, 256);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.0);

        var gTarget = pool.acquireMRT(256, 256, [TextureFormat.RGBA, TextureFormat.RGBA, TextureFormat.RGBA], TextureFormat.Depth24);
        var gbuffer = GBuffer.fromMRT(gTarget);

        // Simulate the suite: a forward PBR render immediately before the
        // G-buffer pass (leaves depth LESS, culling BACK, blending ALPHA).
        var sceneTarget = pool.acquire(256, 256);
        sceneTarget.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        frame.lights = new minko.render.light.LightSet();
        frame.lights.add(minko.render.light.Light.directional());
        pbr.render(q, frame, sceneTarget);
        sceneTarget.unbind(context);
        pool.release(sceneTarget);
        gTarget.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        gbufferRenderer.render(q, frame, gbuffer);
        gbuffer.unbind(context);

        function grab(t:RenderTarget):Bytes {
            t.bind(context, false);
            var b = Bytes.alloc(t.width * t.height * 4);
            context.readPixels(b);
            t.unbind(context);
            return b;
        }

        function copyAvg(tex:minko.render.AbstractTexture):Bytes {
            var t = pool.acquire(256, 256);
            copier.render(t, function(e) e.setTexture("uColorMap", 0, tex));
            var b = grab(t);
            pool.release(t);
            return b;
        }

        var albedoB = copyAvg(gbuffer.albedoTexture);
        var normalB = copyAvg(gbuffer.normalTexture);
        var emissiveB = copyAvg(gbuffer.emissiveTexture);

        var out = pool.acquire(256, 256);
        lighting.render(gbuffer, out);
        var litB = grab(out);
        pool.release(out);

        function luma(r:Int, g:Int, b:Int):Float {
            return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
        }

        // CPU reference: same formula as deferredLightingFragment
        var Lx = -0.4, Ly = 0.8, Lz = 0.6;
        var Llen = Math.sqrt(Lx * Lx + Ly * Ly + Lz * Lz);
        Lx /= Llen; Ly /= Llen; Lz /= Llen;
        var refSum = 0.0; var shSum = 0.0; var n = 0;
        var maxDiff = 0.0;
        for (i in 0...256 * 256) {
            var o = i * 4;
            var ar = albedoB.get(o) / 255.0, ag = albedoB.get(o + 1) / 255.0, ab = albedoB.get(o + 2) / 255.0;
            var nx = normalB.get(o) / 255.0 * 2.0 - 1.0;
            var ny = normalB.get(o + 1) / 255.0 * 2.0 - 1.0;
            var nz = normalB.get(o + 2) / 255.0 * 2.0 - 1.0;
            var nl = Math.sqrt(nx * nx + ny * ny + nz * nz);
            if (nl > 1e-6) { nx /= nl; ny /= nl; nz /= nl; }
            var ndl = nx * Lx + ny * Ly + nz * Lz;
            if (ndl < 0.0) ndl = 0.0;
            var er = emissiveB.get(o) / 255.0, eg = emissiveB.get(o + 1) / 255.0, eb = emissiveB.get(o + 2) / 255.0;
            var rr = ar * (0.15 + ndl * 0.85) + er;
            var rg = ag * (0.15 + ndl * 0.85) + eg;
            var rb = ab * (0.15 + ndl * 0.85) + eb;
            var rl = 0.299 * rr + 0.587 * rg + 0.114 * rb;
            var sl = luma(litB.get(o), litB.get(o + 1), litB.get(o + 2));
            refSum += rl; shSum += sl; n++;
            var d = Math.abs(rl - sl);
            if (d > maxDiff) maxDiff = d;
        }
        trace("deferred probe: cpuRefAvg=" + Math.round(refSum / n * 1000) / 1000
            + " shaderAvg=" + Math.round(shSum / n * 1000) / 1000
            + " maxDiff=" + Math.round(maxDiff * 1000) / 1000
            + " albedoAvg=" + Math.round(avgOf(albedoB) * 1000) / 1000
            + " normalAvg=" + Math.round(avgOf(normalB) * 1000) / 1000);

        trace("center albedo=" + px(albedoB, 128, 128) + " normal=" + px(normalB, 128, 128)
            + " lit=" + px(litB, 128, 128));

        gbufferRenderer.dispose();
        lighting.dispose();
        pbr.dispose();
        copier.dispose();
        pool.dispose();
        Sys.exit(0);
    }

    static function avgOf(b:Bytes):Float {
        var s = 0.0;
        for (i in 0...Std.int(b.length / 4)) {
            var o = i * 4;
            s += (0.299 * b.get(o) + 0.587 * b.get(o + 1) + 0.114 * b.get(o + 2)) / 255.0;
        }
        return s / Std.int(b.length / 4);
    }

    static function px(b:Bytes, x:Int, y:Int):String {
        var o = (y * 256 + x) * 4;
        return '(${b.get(o)},${b.get(o + 1)},${b.get(o + 2)})';
    }
}
