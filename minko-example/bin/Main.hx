package ;
import example.ExamplePbr;
import example.ExampleWater;
import example.ExampleStencil;
import example.ExamplePicking;
import tutorial.WorkingNormalMaps;
import tutorial.ApplyingAntialiasingEffect;
import example.ExampleSkybox;
import example.ExampleLightScattering;
import tutorial.WorkingSpotlights;
import tutorial.WorkingSpecularMaps;
import tutorial.WorkingPointlights;
import tutorial.WorkingEnvironmentMaps;
import minko.file.Gltf2Parser;
import minko.Canvas.CanvasManager;
import glm.Quat;
import minko.input.Mouse;
import minko.file.JPEGParser;
import minko.file.PNGParser;
import glm.Mat4;
import glm.Vec3;
import glm.GLM;
import minko.component.Transform;
import minko.component.Renderer;
import minko.input.Keyboard;
import minko.component.PerspectiveCamera;
import minko.component.MasterAnimation;
import minko.component.DirectionalLight;
import minko.component.AmbientLight;
import minko.component.Surface;
import minko.scene.NodeSet;
import minko.scene.Node;
import minko.file.Loader;
import minko.file.ASSIMPParser;
import minko.component.Skinning.SkinningMethod;
import minko.component.SceneManager;
import minko.WebCanvas;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal.SignalSlot;
import minko.component.AbstractAnimation;
import assimp.format.Defs;
import assimp.format.Camera.AiCamera;
import assimp.format.Anim;
import assimp.format.Light;
import assimp.format.Material;
import assimp.format.Mesh;
import assimp.format.MetaData;
import assimp.format.Scene;
import assimp.format.Version;
import assimp.Types;
import assimp.StringUtil;
import assimp.ScenePreprocessor;
import assimp.ProgressHandler;
import assimp.ProcessHelper;
import assimp.IOSystem;

import assimp.AiPostProcessStep;
import assimp.Assimp;
import assimp.DefaultIOSystem;
import assimp.DefaultProgressHandler;
import assimp.Hash;
import assimp.ImporterDesc;
import assimp.ImporterPimpl;
import assimp.BaseImporter;
import assimp.postProcess.ValidateDSProcess;
import assimp.Importer;
import assimp.format.assbin.AssbinLoader;
import assimp.Config;
import minko.file.IOHandler;
import minko.file.AbstractASSIMPParser;
import assimp.format.gltf2.GLTF2;
//import gltf.GLTF;
import assimp.format.gltf2.GlTF2Importer;
class Main {
    //3k 40 fps
    //3.5k 30fps
    //2k 60fps
    static public function main() {
        new ExampleAssimp();
    }
}

class ExampleAssimp {
    private static var WINDOW_WIDTH = 800;
    private static var WINDOW_HEIGHT = 600;
    //private static var MODEL_FILENAME = "pg_stand.gltf";
     private static var MODEL_FILENAME = "Sample_005339_08932_25_14.gltf";
   // private static var MODEL_FILENAME = "leg-with-control-bones.gltf";
    private static var LABEL_RUN_START = "run_start";
    private static var LABEL_RUN_STOP = "run_stop";
    private static var LABEL_IDLE = "idle";
    private static var LABEL_WALK_START = "walk_start";
    private static var LABEL_WALK_STOP = "walk_stop";
    private static var LABEL_PUNCH_START = "punch_start";
    private static var LABEL_PUNCH_HIT = "punch_hit";
    private static var LABEL_PUNCH_STOP = "punch_stop";
    private static var LABEL_KICK_START = "kick_start";
    private static var LABEL_KICK_HIT = "kick_hit";
    private static var LABEL_KICK_STOP = "kick_stop";
    private static var LABEL_STUN_START = "stun_start";
    private static var LABEL_STUN_STOP = "stun_stop";

    private function run(anim:AbstractAnimation):Void {
        if (anim == null) {
            return ;
        }

        anim.isLooping = (true);

        anim.setPlaybackWindowbyName(LABEL_RUN_START, LABEL_RUN_STOP);
        anim.play();
    }

    private function walk(anim:AbstractAnimation):Void {
        if (anim == null) {
            return  ;
        }

        anim.isLooping = (true);

        anim.setPlaybackWindowbyName(LABEL_WALK_START, LABEL_WALK_STOP);
        anim.play();
    }

    private function kick(anim:AbstractAnimation):Void {
        if (anim == null) {
            return ;
        }

        anim.isLooping = (false);

        anim.setPlaybackWindowbyName(LABEL_KICK_START, LABEL_KICK_STOP, true);
        anim.play();
    }

    private function punch(anim:AbstractAnimation):Void {
        if (anim == null) {
            return ;
        }

        anim.isLooping = (false);

        anim.setPlaybackWindowbyName(LABEL_PUNCH_START, LABEL_PUNCH_STOP, true);
        anim.play();
    }

    private function idle(anim:AbstractAnimation):Void {
        if (anim == null) {
            return ;
        }

        anim.isLooping=(false);

        anim.resetPlaybackWindow();
        anim.seekLabel(LABEL_IDLE);
        anim.stop();
    }

    private function stun(anim:AbstractAnimation):Void {
        if (anim == null) {
            return ;
        }

        anim.isLooping = (true);

        anim.setPlaybackWindowbyName(LABEL_STUN_START, LABEL_STUN_STOP);
        anim.play();
    }


    private function printAnimationInfo(anim:AbstractAnimation):Void {
        if (anim == null) {
            return;
        }

        trace("Animation labels\n--------------");
        trace("\n");

        for (labelId in 0... anim.numLabels) {
            trace("\t'");
            trace(anim.labelName(labelId),"'\tat t = ",anim.labelTime(labelId));
            trace("\n");
        }

        trace("Animation controls\n--------------\n\t[up]\trun\n\t[down]\twalk\n\t[left]\tpunch\n\t[right]\tkick\n\t[space]\tstun\n\t[end]\tidle");
        trace("\n");
        trace("\t[r]\treverse animation\n\t[1]\tlow speed\n\t[2]\tnormal speed\n\t[3]\thigh speed\n");
        trace("\n");
    }

    private var anim:AbstractAnimation ;
    private var started:SignalSlot<AbstractAnimation>;
    private var stopped:SignalSlot<AbstractAnimation>;
    private var looped:SignalSlot<AbstractAnimation>;
    private var labelHit:SignalSlot3<AbstractAnimation, String, Int> ;

    public function new():Void {

        var canvas =  CanvasManager.create("Minko Example - Assimp", WINDOW_WIDTH, WINDOW_HEIGHT);
        var sceneManager = SceneManager.create(canvas);
        var defaultOptions = sceneManager.assets.loader.options;

        // setup assets
        defaultOptions.generateMipmaps = (true);
        defaultOptions.skinningFramerate=(60);
        defaultOptions.skinningMethod=(SkinningMethod.HARDWARE);
        defaultOptions.startAnimation=(true);
        defaultOptions.registerParser("assbin", function()return new ASSIMPParser());
        defaultOptions.registerParser("gltf", function()return new Gltf2Parser());
        defaultOptions.registerParser("png", function()return new PNGParser());
        defaultOptions.registerParser("jpg", function()return new JPEGParser());

        var fxLoader = Loader.createbyLoader(sceneManager.assets.loader);
      //  fxLoader.options.loadAsynchronously=false;
        fxLoader.queue("effect/Basic.effect")
       .queue("effect/PBR.effect")
       .queue("effect/Phong.effect");


        var fxComplete = fxLoader.complete.connect(function(l) {
            sceneManager.assets.loader.options.effect=sceneManager.assets.effect("effect/Phong.effect");
            sceneManager.assets.loader.queue(MODEL_FILENAME);
            sceneManager.assets.loader.load();
        });
        var beIdle = true;
        var doPunch = false;
        var doKick = false;
        var doWalk = false;
        var doRun = false;
        var beStun = false;
        var reverseAnim = false;
        var speedId = 0;

        var root = Node.create("root");
        root.addComponent(sceneManager);

        var camera = Node.create("camera");
        camera.addComponent(Renderer.create(0x7f7f7fff));
        var mat4:Mat4=GLM.lookAt(new Vec3(0.25, 0.75, 2.5), new Vec3(0.0, 0.75, 0.0), new Vec3(0, 1, 0),new Mat4());
        camera.addComponent(Transform.createbyMatrix4(Mat4.invert(mat4,new Mat4())));
        camera.addComponent(PerspectiveCamera.create(canvas.aspectRatio));
        root.addChild(camera);

        var error = sceneManager.assets.loader.error.connect(function(loader, e) {
            trace("error");
            trace(e);
            trace("\n");
        });

        var _ = sceneManager.assets.loader.complete.connect(function(loader) {
            var model = sceneManager.assets.symbol(MODEL_FILENAME);

            var surfaceNodeSet = NodeSet.createbyNode(model).descendants(true).where(function(n:Node) {
                return n.hasComponent(Surface);
            });

            root.addComponent(AmbientLight.create());
            root.addComponent(DirectionalLight.create());

            root.addChild(model);

          //  var modelTransform:Transform = cast model.getComponent(Transform);
           // modelTransform.matrix = GLM.rotate(Quat.axisAngle(new Vec3(1,0,0),180 ,new Quat()),new Mat4());

            var skinnedNodes:NodeSet = NodeSet.createbyNode(model).descendants(true).where(function(n:Node) {
                return n.hasComponent(MasterAnimation);
            });

            var skinnedNode:Node = skinnedNodes.nodes.iterator().hasNext() ? skinnedNodes.nodes.iterator().next() : null;
/*
            anim = cast skinnedNode.getComponent(MasterAnimation);

            anim.addLabel(LABEL_RUN_START, 0);
            anim.addLabel(LABEL_RUN_STOP, 800);
            anim.addLabel(LABEL_IDLE, 900);
            anim.addLabel(LABEL_WALK_START, 1400);
            anim.addLabel(LABEL_WALK_STOP, 2300);
            anim.addLabel(LABEL_PUNCH_START, 2333);
            anim.addLabel(LABEL_PUNCH_HIT, 2600);
            anim.addLabel(LABEL_PUNCH_STOP, 3000);
            anim.addLabel(LABEL_KICK_START, 3033);
            anim.addLabel(LABEL_KICK_HIT, 3316);
            anim.addLabel(LABEL_KICK_STOP, 3600);
            anim.addLabel(LABEL_STUN_START, 3633);
            anim.addLabel(LABEL_STUN_STOP, 5033);

            started = anim.started.connect(function(UnnamedParameter1) {
                trace("\nanimation started");
                trace("\n");
            });
            stopped = anim.stopped.connect(function(UnnamedParameter1) {
                trace("animation stopped");
                trace("\n");
            });
            looped = anim.looped.connect(function(UnnamedParameter1) {
                trace("\nanimation looped");
                trace("\n");
            });
            labelHit = anim.labelHit.connect(function(UnnamedParameter1, name, time) {
                trace("label '");
                trace(name);
                trace("'\thit at t = ");
                trace(time);
                trace("\n");
            });

            printAnimationInfo(anim);
            idle(anim);
            */


        });

        var resized = canvas.resized.connect(function(canvas, w, h) {
            var perspectiveCamera:PerspectiveCamera = cast camera.getComponent(PerspectiveCamera);
            perspectiveCamera.aspectRatio = ( w / h);
        });

        var keyDown = canvas.keyboard.keyDown.connect(function(k:Keyboard) {
            if (anim == null) {
                return;
            }

            if (k.keyIsDown(Key.UP)) {
                beIdle = doPunch = doKick = doWalk = beStun = reverseAnim = false;
                speedId = 0;
                doRun = true;
            }
            else if (k.keyIsDown(Key.DOWN)) {
                beIdle = doPunch = doRun = doKick = beStun = reverseAnim = false;
                speedId = 0;
                doWalk = true;
            }
            else if (k.keyIsDown(Key.LEFT)) {
                beIdle = doRun = doKick = doWalk = beStun = reverseAnim = false;
                speedId = 0;
                doPunch = true;
            }
            else if (k.keyIsDown(Key.RIGHT)) {
                beIdle = doPunch = doRun = doWalk = beStun = reverseAnim = false;
                speedId = 0;
                doKick = true;
            }
            else if (k.keyIsDown(Key.SPACE)) {
                beIdle = doPunch = doRun = doKick = doWalk = reverseAnim = false;
                speedId = 0;
                beStun = true;
            }
            else if (k.keyIsDown(Key.END)) {
                doPunch = doRun = doKick = doWalk = beStun = reverseAnim = false;
                speedId = 0;
                beIdle = true;
            }
            else if (k.keyIsDown(Key._1)) {
                doPunch = doRun = doKick = doWalk = beStun = beIdle = reverseAnim = false;
                speedId = 1;
            }
            else if (k.keyIsDown(Key._2)) {
                doPunch = doRun = doKick = doWalk = beStun = beIdle = reverseAnim = false;
                speedId = 2;
            }
            else if (k.keyIsDown(Key._3)) {
                doPunch = doRun = doKick = doWalk = beStun = beIdle = reverseAnim = false;
                speedId = 3;
            }
            else if (k.keyIsDown(Key.R)) {
                doPunch = doRun = doKick = doWalk = beStun = beIdle = false;
                reverseAnim = true;
                speedId = 0;
            }
        });

        var keyUp = canvas.keyboard.keyUp.connect(function(k:Keyboard) {
            if (anim == null) {
                return;
            }

            if (doWalk) {
                walk(anim);
            }
            else if (doRun) {
                run(anim);
            }
            else if (doKick) {
                kick(anim);
            }
            else if (doPunch) {
                punch(anim);
            }
            else if (beIdle) {
                idle(anim);
            }
            else if (beStun) {
                stun(anim);
            }
            else if (reverseAnim) {
                anim.isReversed = (!anim.isReversed);
                trace("animation is ");
                trace((!anim.isReversed  ? "not " : ""));
                trace("reversed");
                trace("\n");
            }
            else if (speedId > 0) {
                if (speedId == 1) {
                    anim.timeFunction = function(t) {
                        return Math.floor(t / 2);
                    };
                    trace("animation's speed is decreased");
                    trace("\n");
                }
                else if (speedId == 2) {
                    anim.timeFunction = function(t) {
                        return t;
                    };
                    trace("animation is back to normal speed");
                    trace("\n");
                }
                else if (speedId == 3) {
                    anim.timeFunction = function(t) {
                        return t * 2;
                    };
                    trace("animation's speed is increased");
                    trace("\n");
                }

                speedId = 0;
            }




        });

//       var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {
//           sceneManager.nextFrame(time, deltaTime);
//      });


        var yaw = 0.3;
        // float pitch = 1.3f;//float(M_PI) * .5f;
        var pitch = Math.PI * .5;
        var minPitch = 0.0 + 0.1;
        // auto maxPitch = float(M_PI) * .5f - .1f;
        var maxPitch = Math.PI - .1;
        var lookAt = new Vec3(0.0, 2.0, 0.0);
        var distance = 3.0;
        var minDistance = 1.0;
        var zoomSpeed = 0.0;

        var mouseWheel = canvas.mouse.wheel.connect(function(m, h, v) {
            zoomSpeed -= v * .1;
        });

        var mouseMove:SignalSlot3<Mouse, Int, Int> = null;
        var cameraRotationXSpeed = 0.0;
        var cameraRotationYSpeed = 0.0;

        var mouseDown = canvas.mouse.leftButtonDown.connect(function(m) {
            mouseMove = canvas.mouse.move.connect(function(UnnamedParameter1, dx, dy) {
                cameraRotationYSpeed = dx * .01;
                cameraRotationXSpeed = dy * -.01;
            });
        });

        var mouseUp = canvas.mouse.leftButtonUp.connect(function(m) {
            mouseMove.disconnect();
           // mouseMove = null;
        });

        var enterFrame = canvas.enterFrame.connect(function(canvas, time, deltaTime) {
            distance += zoomSpeed;
            zoomSpeed *= 0.9;
            if (distance < minDistance) {
                distance = minDistance;
            }

            yaw += cameraRotationYSpeed;
            cameraRotationYSpeed *= 0.9;

            pitch += cameraRotationXSpeed;
            cameraRotationXSpeed *= 0.9;

            if (pitch > maxPitch) {
                pitch = maxPitch;
            }
            else if (pitch < minPitch) {
                pitch = minPitch;
            }
            var cameraTransform:Transform = cast camera.getComponent(Transform);
            cameraTransform.matrix = (Mat4.invert(GLM.lookAt(
                new Vec3(lookAt.x + distance * Math.cos(yaw) * Math.sin(pitch), lookAt.y + distance * Math.cos(pitch), lookAt.z + distance * Math.sin(yaw) * Math.sin(pitch)),
                lookAt, new Vec3(0.0, 1.0, 0.0), new Mat4()), new Mat4()));

            sceneManager.nextFrame(time, deltaTime);
        });


        fxLoader.load();
        canvas.run();

    }
}
