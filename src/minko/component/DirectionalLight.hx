package minko.component;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.component.ShadowMappingTechnique.Technique;
import minko.file.Loader;
import minko.render.Priority;
import minko.render.Texture;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.utils.MathUtil;
class DirectionalLight extends AbstractDiscreteLight {
    public static inline var MAX_NUM_SHADOW_CASCADES = 4;
    public static inline var DEFAULT_NUM_SHADOW_CASCADES = 4;
    public static inline var MIN_SHADOWMAP_SIZE = 32;
    public static inline var MAX_SHADOWMAP_SIZE = 1024;
    public static inline var DEFAULT_SHADOWMAP_SIZE = 512;

    private var _worldDirection:Vec3;
    private var _shadowMappingEnabled:Bool;
    private var _shadowMapSize:Int;
    private var _shadowMap:Texture;
    private var _numShadowCascades:Int;
    private var _shadowRenderers:Array<Renderer>;// Renderer[4];
    private var _shadowProjections:Array<Mat4>;//mat4[4];
    private var _view:Mat4;

    public static function create(diffuse = 1.0, specular = 1.0):DirectionalLight {
        return new DirectionalLight(diffuse, specular);
    }

    override public function clone(option:CloneOption) {
        return create(diffuse, specular);
    }

    public var shadowMap(get, null):Texture;

    function get_shadowMap() {
        return _shadowMap;
    }
    public var shadowSpread(null, set):Float;

    function set_shadowSpread(spread) {
        data.set("shadowSpread", spread);
        return spread;
    }
    public var shadowProjections(get, null):Array<Mat4>;

    function get_shadowProjections() {
        return _shadowProjections;
    }

    public var shadowMappingEnabled(get, null):Bool;

    function get_shadowMappingEnabled() {
        return _shadowMappingEnabled;
    }

    public var numShadowCascades(get, null):Int;

    function get_numShadowCascades() {
        return _numShadowCascades;
    }
//Math.POSITIVE_INFINITY
    public function computeShadowProjection(view:Mat4, projection:Mat4, zFar = 100000.0, fitToCascade = false) {
        if (!_shadowMappingEnabled) {
            return;
        }

        var invProjection:Mat4 = Mat4.invert(projection, new Mat4());
        var v:Array<Vec4> = [invProjection * (new Vec4(-1.0, 1.0, -1.0, 1.0)),
        invProjection * (new Vec4(1.0, 1.0, -1.0, 1.0)),
        invProjection * (new Vec4(1.0, -1.0, -1.0, 1.0)),
        invProjection * (new Vec4(-1.0, -1.0, -1.0, 1.0)),
        invProjection * (new Vec4(-1.0, 1.0, 1.0, 1.0)),
        invProjection * (new Vec4(1.0, 1.0, 1.0, 1.0)),
        invProjection * (new Vec4(1.0, -1.0, 1.0, 1.0)),
        invProjection * (new Vec4(-1.0, -1.0, 1.0, 1.0))];

        zFar = Math.floor(Math.min(zFar, -(v[4].z / v[4].w)));

        var zNear = -(v[0] / v[0].w).z;
        var fov = Math.atan(1.0 / projection.r1c1) * 2.0 ;
        var ratio = projection.r1c1 / projection.r0c0;

        // http://developer.download.nvidia.com/SDK/10.5/opengl/src/cascaded_shadow_maps/doc/cascaded_shadow_maps.pdf
        // page 7
        var splitFar:Array<Float> = [zFar, zFar, zFar, zFar];
        var splitNear:Array<Float> = [zNear, zNear, zNear, zNear];
        var lambda = .5;
        var j = 1.0;
        for (i in 0..._numShadowCascades - 1) {
            splitFar[i] = ( MathUtil.mix(zNear + (j / _numShadowCascades) * (zFar - zNear), zNear * Math.pow(zFar / zNear, j / _numShadowCascades), lambda));
            splitNear[i + 1] = splitFar[i];
            j += 1.0;
        }

        for (i in 0..._numShadowCascades) {
            var cameraViewProjection:Mat4 = GLM.perspective(fov, ratio, zNear, splitFar[i], new Mat4()) * (view);
            var box = computeBox(cameraViewProjection);

            _shadowProjections[i] = GLM.orthographic(box.first.x, box.second.x, box.first.y, box.second.y, -box.second.z, -box.first.z, new Mat4());

            if (fitToCascade) {
                zNear = splitFar[i];
            }
        }

        for (i in _numShadowCascades...MAX_NUM_SHADOW_CASCADES) {
            splitFar[i] = Math.NEGATIVE_INFINITY;
            splitNear[i] = Math.POSITIVE_INFINITY;
        }

        data.set("shadowSplitFar", new Vec4(splitFar[0], splitFar[1], splitFar[2], splitFar[3]));
        data.set("shadowSplitNear", new Vec4(splitNear[0], splitNear[1], splitNear[2], splitNear[3]));

        updateWorldToScreenMatrix();
    }

    public function enableShadowMapping(shadowMapSize = DEFAULT_SHADOWMAP_SIZE, numCascades = DEFAULT_NUM_SHADOW_CASCADES) {
        if (!_shadowMappingEnabled || shadowMapSize != _shadowMapSize || numCascades != _numShadowCascades) {
            if (_shadowMap == null || shadowMapSize != _shadowMapSize || numCascades != _numShadowCascades) {
                _numShadowCascades = numCascades;
                // FIXME: do not completely re-init shadow mapping when just the shadow map size changes
                _shadowMapSize = shadowMapSize;
                initializeShadowMapping();
            }
            else {
                for (renderer in _shadowRenderers) {
                    if (renderer != null) {
                        renderer.enabled = (true);
                    }
                }

                data.set("shadowMap", _shadowMap);
            }

            _shadowMappingEnabled = true;
        }
    }

    public function disableShadowMapping(disposeResources = false) {
        if (_shadowMappingEnabled) {
            for (renderer in _shadowRenderers) {
                if (renderer != null) {
                    renderer.enabled = (false);
                }
            }
            data.unset("shadowMap");

            if (disposeResources) {
                _shadowMap = null;

                for (renderer in _shadowRenderers) {
                    if (renderer != null && target.existsComponent(renderer)) {
                        target.removeComponent(renderer);
                        renderer = null;
                    }
                }
            }

            _shadowMappingEnabled = false;
        }
    }

    override public function updateModelToWorldMatrix(modelToWorld:Mat4) {
        var tmp:Vec4 = modelToWorld * (new Vec4(0.0, 0.0, -1.0, 0));
        _worldDirection = MathUtil.vec4_vec3(tmp);
        _worldDirection = Vec3.normalize(_worldDirection, new Vec3()) ;
        data.set("direction", _worldDirection);

        updateWorldToScreenMatrix();
    }

    override public function updateRoot(root:Node) {
        super.updateRoot(root);

        if (root != null && _shadowMappingEnabled && _shadowMap == null) {
            initializeShadowMapping();
        }
    }


    override public function targetRemoved(target:Node) {
        super.targetRemoved(target);
        for (renderer in _shadowRenderers)
            if (renderer != null && target.existsComponent(renderer))
                target.removeComponent(renderer);
    }

    public function new(diffuse, specular) {
        super("directionalLight", diffuse, specular);
        this._shadowMappingEnabled = false;
        this._numShadowCascades = 0;
        this._shadowMap = null;
        this._shadowMapSize = 0;
        this._shadowRenderers = [for (i in 0...4) null];
        this._shadowProjections = [for (i in 0...4) Mat4.identity(new Mat4())];//mat4[4];
        updateModelToWorldMatrix(Mat4.identity(new Mat4()));
    }

    public function copyFrom(directionalLight:DirectionalLight, option:CloneOption) {
        // : base("directionalLight", directionalLight.diffuse(), directionalLight.specular())
        updateModelToWorldMatrix(Mat4.identity(new Mat4()));
    }

    private function initializeShadowMapping() {
        if (target == null || !target.root.hasComponent(SceneManager)) {
            return false;
        }
        var sm:SceneManager = cast target.root.getComponent(SceneManager);
        var assets = sm.assets;
        var effectName = "effect/ShadowMap.effect";
        var fx = assets.effect(effectName);

        var smTechnique = target.root.hasComponent(ShadowMappingTechnique) ? target.root.data.get("shadowMappingTechnique") : ShadowMappingTechnique.Technique.DEFAULT;

        if (fx == null) {
            var texture:Texture = assets.texture("shadow-map-tmp");

            if (texture == null) {
                // This texture is used only for ESM, but loading ShadowMap.effect will throw if the asset does not exist.
                // Thus, we create a dummy texture that we simply don't upload on the GPU.
                texture = Texture.create(assets.context, _shadowMapSize, _shadowMapSize, false, true);
                if (smTechnique == Technique.ESM) {
                    texture.upload();
                }
                assets.setTexture("shadow-map-tmp", texture);
            }

            texture = assets.texture("shadow-map-tmp-2");
            if (texture == null) {
                texture = Texture.create(assets.context, _shadowMapSize, _shadowMapSize, false, true);
                if (smTechnique == Technique.ESM) {
                    texture.upload();
                }
                assets.setTexture("shadow-map-tmp-2", texture);
            }

            var loader:Loader = Loader.createbyLoader(assets.loader);
            // FIXME: support async loading of the ShadowMapping.effect file
            loader.options.loadAsynchronously = (false);
            loader.queue(effectName);
            loader.load();
            fx = assets.effect(effectName);
        }

        _shadowMap = Texture.create(assets.context, _shadowMapSize * 2, _shadowMapSize * 2, false, true);
        _shadowMap.upload();
        data.set("shadowMap", _shadowMap)
        .set("shadowMaxDistance", 0.9)
        .set("shadowSpread", 1.0)
        .set("shadowBias", -0.001)
        .set("shadowMapSize", _shadowMapSize * 2.0);

        var viewports:Array<Vec4> = [new Vec4(0, _shadowMapSize, _shadowMapSize, _shadowMapSize),
        new Vec4(_shadowMapSize, _shadowMapSize, _shadowMapSize, _shadowMapSize),
        new Vec4(0, 0, _shadowMapSize, _shadowMapSize),
        new Vec4(_shadowMapSize, 0, _shadowMapSize, _shadowMapSize)];

        for (i in 0... _numShadowCascades) {
            var techniqueName = "shadow-map-cascade" + i;
            if (smTechnique == ShadowMappingTechnique.Technique.ESM) {
                techniqueName += "-esm";
            }

            var renderer:Renderer = Renderer.create(0xffffffff, _shadowMap, fx, techniqueName, Priority.FIRST - i);

            renderer.clearBeforeRender = (i == 0);
            renderer.viewport = (viewports[i]);
            renderer.effectVariables.push(new Tuple<String, String>("lightUuid", data.uuid));
            // renderer->effectVariables()["shadowProjectionId"] = std::to_string(i);
            renderer.layoutMask = (BuiltinLayout.CAST_SHADOW);
            target.addComponent(renderer);

            _shadowRenderers[i] = renderer;
        }

        computeShadowProjection(Mat4.identity(new Mat4()), GLM.perspective(0.785, 1.0, 0.1, 1000.0, new Mat4()));

        return true;
    }

    private function updateWorldToScreenMatrix() {
        if (target != null && target.data.hasProperty("modelToWorldMatrix")) {
            _view = Mat4.invert(cast target.data.get("modelToWorldMatrix"), new Mat4());
        }
        else {
            _view = Mat4.identity(new Mat4());
        }

        var zFar:Array<Float> = [0.0, 0.0, 0.0, 0.0];
        var zNear:Array<Float> = [0.0, 0.0, 0.0, 0.0];
        var viewProjections:Array<Mat4> = new Array<Mat4>();

        for (i in 0... _numShadowCascades) {
            var projection:Mat4 = _shadowProjections[i];
            var istr = Std.string(i);
            var farMinusNear = 2.0 / projection.r2c2;
            var farPlusNear = projection.r2c3 * farMinusNear;

            zNear[i] = (farMinusNear + farPlusNear) / 2.0 ;
            zFar[i] = farPlusNear - zNear[i];
            var mat4 = projection * _view;
            viewProjections.push(mat4);
        }

        data.set("viewProjection", viewProjections).set("zNear", zNear).set("zFar", zFar);
    }

    private function computeBox(viewProjection:Mat4):Tuple<Vec3, Vec3> {
        var t:Mat4 = _view * Mat4.invert(viewProjection, new Mat4());
        var v:Array<Vec4> = [t * (new Vec4(-1.0, 1.0, -1.0, 1.0)),
        t * (new Vec4(1.0, 1.0, -1.0, 1.0)),
        t * (new Vec4(1.0, -1.0, -1.0, 1.0)),
        t * (new Vec4( -1.0, -1.0, -1.0, 1.0)),
        t * (new Vec4( -1.0, 1.0, 1.0, 1.0)),
        t * (new Vec4(1.0, 1.0, 1.0, 1.0)),
        t * (new Vec4(1.0, -1.0, 1.0, 1.0)),
        t * (new Vec4( -1.0, -1.0, 1.0, 1.0))];

        for (i in 0...v.length) {
            var p = v[i];
            v[i] = p / p.w ;
        }

        var bottomLeft:Vec3 = new Vec3(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY);
        var topRight:Vec3 = new Vec3( Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

        for (p in v) {
            if (p.x < bottomLeft.x) {
                bottomLeft.x = p.x;
            }
            if (p.x > topRight.x) {
                topRight.x = p.x;
            }
            if (p.y < bottomLeft.y) {
                bottomLeft.y = p.y;
            }
            if (p.y > topRight.y) {
                topRight.y = p.y;
            }
            if (p.z < bottomLeft.z) {
                bottomLeft.z = p.z;
            }
            if (p.z > topRight.z) {
                topRight.z = p.z;
            }
        }

        return new Tuple<Vec3, Vec3>(bottomLeft, topRight);
    }

    private function computeBoundingSphere(view:Mat4, projection:Mat4) {
        var invProj = _view * (Mat4.invert(projection * view, new Mat4()));

        var center:Vec4 = invProj * (new Vec4(0.0, 0.0, 0.0, 1.0));
        center = center * (1 / center.w);

        var max:Vec4 = invProj * (new Vec4(1.0, 1.0, 1.0, 1.0));
        var min:Vec4 = invProj * (new Vec4( -1.0, -1.0, -1.0, 1.0));
        max = max * (1 / max.w);
        min = min * (1 / min.w);

        var radius = Math.max(Vec4.distanceSquared(max, center), Vec4.distanceSquared(min, center));

        // center = _view * center;

        return {
            first:new Vec3(center.x, center.y, center.z), second:radius
        };
    }

    public function minSphere(pt:Array<Vec3>, np:Int, bnd:Array<Vec3>, nb:Int) {

    }

}
