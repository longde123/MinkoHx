import test.component.AmbientLightTest;
import test.component.DirectionalLightTest;
import test.component.PointLightTest;
import test.component.RendererTest;
import test.component.SpotLightTest;
import test.component.SurfaceTest;
import test.component.TransformTest;
import test.data.CollectionTest;
import test.data.ProviderTest;
import test.data.StoreTest;
import test.file.EffectParserTest;
import test.file.EffectParserTestPass;
import test.file.FileTest;
import test.geometry.GeometryTest;
import test.scene.NodeSetTest;
import test.scene.NodeTest;
import test.MinkoTests;
import minko.WebCanvas;

class TestMain {
    static public function main() {
        var canvas = WebCanvas.create("Minko Tests", 640, 480);
        MinkoTests.canvas = canvas;

        var r = new haxe.unit.TestRunner();

        r.add(new DirectionalLightTest());
        r.add(new TransformTest());
        r.add(new RendererTest());
        r.add(new CollectionTest());
        r.add(new ProviderTest());
        r.add(new StoreTest());
        r.add(new FileTest());
        r.add(new EffectParserTest());
        r.add(new EffectParserTestPass());
        r.add(new NodeTest());
        r.add(new NodeSetTest());
        r.add(new GeometryTest());
        r.add(new SurfaceTest());
        r.add(new SpotLightTest());
        r.add(new PointLightTest());
        r.add(new AmbientLightTest());

        r.run();
    }
}
