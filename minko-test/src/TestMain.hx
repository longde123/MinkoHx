import test.component.BoundingBoxTest;
import test.component.MousePickingTest;
import test.component.TransformTest;
import test.file.FileTest;
import test.geometry.GeometryRayTest;
import test.geometry.GeometryTest;
import test.math.BoxTest;
import test.scene.NodeLifecycleTest;
import test.scene.NodeSetTest;
import test.scene.NodeTest;
import test.MinkoTests;
import minko.WebCanvas;

class TestMain {
    static public function main() {
        var canvas = WebCanvas.create("Minko Tests", 640, 480);
        MinkoTests.canvas = canvas;

        var r = new haxe.unit.TestRunner();

        r.add(new TransformTest());
        r.add(new BoundingBoxTest());
        r.add(new MousePickingTest());
        r.add(new FileTest());
        r.add(new GeometryTest());
        r.add(new GeometryRayTest());
        r.add(new BoxTest());
        r.add(new NodeTest());
        r.add(new NodeLifecycleTest());
        r.add(new NodeSetTest());

        r.run();
    }
}
