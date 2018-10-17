package ;

import example.ExampleWater;
import example.ExampleBenchmarkCube;
import tutorial.ApplyingAntialiasingEffect;
import example.ExamplePicking;
import tutorial.WorkingPointlights;
import tutorial.WorkingDirectionallights;
import tutorial.WorkingAmbientlights;
import tutorial.WorkingSpotlights;
import example.ExampleLightScattering;
import example.ExampleStencil;
import example.ExampleShadowMapping;
import tutorial.PostProcessingEffect;
import example.ExampleCube;
import example.ExampleSkybox;
import example.ExamplePbr;
import tutorial.WorkingSpecularMaps;
import tutorial.WorkingEnvironmentMaps;
import tutorial.WorkingNormalMaps;
import tutorial.WorkingPhongMaterial;
import test.component.DirectionalLightTest;
import test.component.AmbientLightTest;
import test.component.PointLightTest;
import test.component.SpotLightTest;
import test.component.SurfaceTest;
import test.component.RendererTest;
import test.render.DrawCallPoolTest;
import test.render.DrawCallTest;
import test.geometry.GeometryTest;
import test.component.TransformTest;
import test.scene.NodeSetTest;
import test.scene.NodeTest;
import test.file.EffectParserTestPass;
import test.file.FileTest;
import test.data.StoreTest;
import test.data.ProviderTest;
import test.data.CollectionTest;
import test.file.EffectParserTest;
import test.MinkoTests;
import minko.WebCanvas;
import minko.component.Surface;
import minko.material.BasicMaterial;
import minko.file.Loader;
import minko.AbstractCanvas;
import minko.component.PerspectiveCamera;
import minko.component.Renderer;
import minko.component.SceneManager;
import minko.component.Transform;
import minko.file.PNGParser;
import minko.geometry.CubeGeometry;
import glm.Mat4;
import glm.Vec3;
import minko.scene.Node;
import minko.WebCanvas;
import minko.component.ParticleSystem;
import minko.particle.modifier.ColorBySpeed;

class Main {
    static public function main() {
      //   new ExampleWater();
         // new WorkingSpecularMaps();
     //   new WorkingEnvironmentMaps();
      // new WorkingPhongMaterial();
     //  new WorkingNormalMaps();
    //  new ExamplePbr();
     //  new ExampleShadowMapping();
    ///          new ExampleCube();
           new ExampleBenchmarkCube();

   //    new ExamplePicking();
   //  new ExampleSkybox();
  // new ExampleCube();
     //  new PostProcessingEffect();
      //  new ExampleStencil();
      //  new ApplyingAntialiasingEffect();
      //  new ExampleLightScattering();
      //  new WorkingSpotlights();
     //   new WorkingAmbientlights();
       // new WorkingDirectionallights();
      //  new WorkingPointlights();
        return;

        var canvas = WebCanvas.create("Minko Tests", 640, 480);



        MinkoTests.canvas=(canvas);

        var r = new haxe.unit.TestRunner();

        r.add(new DirectionalLightTest());
/*
        r.add(new RendererTest());
       r.add(new CollectionTest());
       r.add(new ProviderTest());
       r.add(new StoreTest());
       r.add(new FileTest());
       r.add(new EffectParserTest());
    r.add(new EffectParserTestPass());
       r.add(new NodeTest());
       r.add(new NodeSetTest());
         r.add(new TransformTest());
       r.add(new GeometryTest());


       r.add(new SurfaceTest());
       // add other TestCases here
       r.add(new SpotLightTest());
       r.add(new PointLightTest());
       r.add(new AmbientLightTest());

*/
       // finally, run the tests
        r.run();

    }
}
