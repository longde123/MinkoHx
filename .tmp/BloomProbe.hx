import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.io.Bytes;
import minko.AbstractCanvas.Flags;
import minko.Canvas.CanvasManager;
import minko.geometry.CubeGeometry;
import minko.render.TextureFormat;
import minko.render.light.Light;
import minko.render.light.LightSet;
import minko.render.pbr.BloomRenderer;
import minko.render.pbr.FullscreenEffect;
import minko.render.pbr.PBRForwardRenderer;
import minko.render.pbr.PBRMaterial;
import minko.render.pbr.PBRShaderLibrary;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.RenderTarget;
import minko.render.target.RenderTargetPool;

// Probe bloom stage by stage: HDR scene -> bright -> blur H -> blur V -> composite.
class BloomProbe {
    static function avg(b:Bytes):Float {
        var sum = 0.0;
        var n = Std.int(b.length / 4);
        for (i in 0...n) {
            var o = i * 4;
            sum += (0.299 * b.get(o) + 0.587 * b.get(o + 1) + 0.114 * b.get(o + 2)) / 255.0;
        }
        return sum / n;
    }

    static function grab(t:RenderTarget, ctx):Bytes {
        t.bind(ctx, false);
        var b = Bytes.alloc(t.width * t.height * 4);
        ctx.readPixels(b);
        t.unbind(ctx);
        return b;
    }

    static function main() {
        var canvas = CanvasManager.create("BloomProbe", 64, 64, Flags.RESIZABLE);
        var context = canvas.context;
        var pool = new RenderTargetPool(context);
        var geometry = CubeGeometry.create(context);
        var pbr = new PBRForwardRenderer(context);

        var mat = PBRMaterial.create();
        mat.setBaseColor(new Vec4(0.02, 0.02, 0.02, 1.0));
        mat.setEmissive(new Vec3(4.0, 4.0, 4.0));
        var q = new RenderQueue();
        q.add(new RenderItem(geometry, mat, null, Mat4.identity(new Mat4())));
        var frame = new FrameContext(context, 256, 256);
        frame.viewMatrix = GLM.lookAt(new Vec3(0.0, 0.0, 3.0), new Vec3(), new Vec3(0.0, 1.0, 0.0), new Mat4());
        frame.projectionMatrix = GLM.perspective(0.785, 1.0, 0.1, 100.0, new Mat4());
        frame.cameraPosition = new Vec3(0.0, 0.0, 3.0);
        frame.lights = new LightSet();

        var hdr = pool.acquire(256, 256, TextureFormat.RGBA16F);
        hdr.bind(context, true);
        context.clear(0.0, 0.0, 0.0, 1.0);
        pbr.render(q, frame, hdr);
        trace("hdr avg(byte-readback)=" + Math.round(avg(grab(hdr, context)) * 1000) / 1000);

        var bright = new FullscreenEffect(context, "bright", PBRShaderLibrary.brightPassFragment());
        var blur = new FullscreenEffect(context, "blur", PBRShaderLibrary.blurFragment());
        var comp = new FullscreenEffect(context, "comp", PBRShaderLibrary.bloomCompositeFragment());

        var brightT = pool.acquire(128, 128, TextureFormat.RGBA);
        var blurT = pool.acquire(128, 128, TextureFormat.RGBA);
        var outT = pool.acquire(256, 256, TextureFormat.RGBA);

        bright.render(brightT, function(e) {
            e.setTexture("uColorMap", 0, hdr.color);
            e.setFloat("uThreshold", 1.0);
        });
        trace("bright avg=" + Math.round(avg(grab(brightT, context)) * 1000) / 1000);

        blur.render(blurT, function(e) {
            e.setTexture("uColorMap", 0, brightT.color);
            e.setVec2("uTexelSize", 1.0 / 128, 1.0 / 128);
            e.setVec2("uDirection", 1.0, 0.0);
        });
        trace("blurH avg=" + Math.round(avg(grab(blurT, context)) * 1000) / 1000);

        blur.render(brightT, function(e) {
            e.setTexture("uColorMap", 0, blurT.color);
            e.setVec2("uTexelSize", 1.0 / 128, 1.0 / 128);
            e.setVec2("uDirection", 0.0, 1.0);
        });
        trace("blurV avg=" + Math.round(avg(grab(brightT, context)) * 1000) / 1000);

        comp.render(outT, function(e) {
            e.setTexture("uSceneMap", 0, hdr.color);
            e.setTexture("uBloomMap", 1, brightT.color);
            e.setFloat("uBloomIntensity", 0.8);
        });
        trace("composite avg=" + Math.round(avg(grab(outT, context)) * 1000) / 1000);

        // reference: composite without bloom texture
        comp.render(outT, function(e) {
            e.setTexture("uSceneMap", 0, hdr.color);
            e.setTexture("uBloomMap", 1, blurT.color); // blurT was source of blurV; now stale/zero-ish
            e.setFloat("uBloomIntensity", 0.0);
        });
        trace("composite(intensity=0) avg=" + Math.round(avg(grab(outT, context)) * 1000) / 1000);

        bright.dispose();
        blur.dispose();
        comp.dispose();
        pbr.dispose();
        pool.dispose();
        Sys.exit(0);
    }
}
