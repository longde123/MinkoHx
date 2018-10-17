package minko.component;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import minko.file.Loader;
import minko.geometry.Geometry;
import minko.geometry.LineGeometry;
import minko.material.BasicMaterial;
import minko.render.AbstractContext;
import minko.render.Blending.Mode;
import minko.render.IndexBuffer;
import minko.render.Priority;
import minko.render.VertexBuffer;
import minko.scene.Layout.BuiltinLayout;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.utils.MathUtil;
class FrustumDisplay extends AbstractComponent {
    private var _projection:Mat4;
    private var _surface:Surface;
    private var _lines:Surface;
    private var _material:BasicMaterial;
    private var _addedSlot:SignalSlot3<Node, Node, Node>;

    public static function create(projection:Mat4) {
        return new FrustumDisplay(projection);
    }
    public var material(get, null):BasicMaterial;

    function get_material() {
        return _material;
    }

    public function new(projection:Mat4) {
        super();
        this._projection = projection;
        this._surface = null;
        this._addedSlot = null;
        this._material = BasicMaterial.create();
        _material.diffuseColor = (new Vec4(1.0, 1.0, 1.0, .1));
        _material.priority = (Priority.LAST);
        _material.depthMask = (false);
        _material.zSorted = (true);

        _material.blendingMode = (Mode.ADDITIVE);
        // ->depthFunction(render::CompareMode::ALWAYS)
        // ->triangleCulling(render::TriangleCulling::NONE)
    }

    override public function targetAdded(target:Node) {
        if (target.root.hasComponent(SceneManager)) {
            addedHandler(null, target, null);
        }
        else {
            _addedSlot = target.added.connect(addedHandler);
        }
    }

    override public function targetRemoved(target:Node) {
        _addedSlot = null;

        if (target.existsComponent(_surface)) {
            target.removeComponent(_surface);
        }
        _surface = null;

        if (target.existsComponent(_lines)) {
            target.removeComponent(_lines);
        }
        _lines = null;
    }

    public function addedHandler(node:Node, target:Node, added:Node) {
        if (_surface == null && target.root.hasComponent(SceneManager)) {
            initialize();
        }
    }

    public function initialize() {
        var vertices = getVertices();

        initializePlanes(vertices);
        initializeLines(vertices);
    }

    public function initializePlanes(vertices:Array<Vec3>) {
        var sceneManager:SceneManager = cast target.root.getComponent(SceneManager);
        var assets = sceneManager.assets;

        var effect = assets.effect("effect/Basic.effect");
        if (effect == null) {
            var loader = Loader.createbyLoader(assets.loader);

            loader.options.loadAsynchronously = (false);
            loader.queue("effect/Basic.effect");
            loader.load();

            effect = assets.effect("effect/Basic.effect");
        }

        var geom = initializeFrustumGeometry(vertices, assets.context);

        _surface = Surface.create(geom, _material, effect, "transparent");
        _surface.layoutMask = (BuiltinLayout.DEBUG_ONLY);
        target.addComponent(_surface);
    }

    public function initializeLines(vertices:Array<Vec3>) {
        var sceneManager:SceneManager = cast target.root.getComponent(SceneManager);
        var assets = sceneManager.assets;

        var effect = assets.effect("effect/Line.effect");
        if (effect == null) {
            var loader = Loader.createbyLoader(assets.loader);

            loader.options.loadAsynchronously = (false);
            loader.queue("effect/Line.effect");
            loader.load();

            effect = assets.effect("effect/Line.effect");
        }

        var lines:LineGeometry = LineGeometry.create(assets.context);

        lines.moveToVector3(vertices[0]);
        for (i in 1... 4) {
            lines.lineToVector3(vertices[i]);
        }
        lines.lineToVector3(vertices[0]);
        lines.moveToVector3(vertices[4]);
        for (i in 4... 8) {
            lines.lineToVector3(vertices[i]);
        }
        lines.lineToVector3(vertices[4]);
        for (i in 0... 4) {
            lines.moveToVector3(vertices[i]).lineToVector3(vertices[i + 4]);
        }
        lines.upload();

        _lines = Surface.create(lines, _material, effect);
        _lines.layoutMask = (BuiltinLayout.DEBUG_ONLY);
        target.addComponent(_lines);
    }

    public function initializeFrustumGeometry(vertices:Array<Vec3>, context:AbstractContext) {
        var vb = VertexBuffer.createbyVec3Data(context, (vertices ), vertices.length * 3);
        vb.addAttribute("position", 3);
        vb.upload();

        var ib = IndexBuffer.createbyData(context, [0, 3, 1, 1, 3, 2, 4, 5, 7, 5, 6, 7, 4, 0, 5, 5, 0, 1, 7, 6, 3, 6, 2, 3, 4, 3, 0, 4, 7, 3, 5, 1, 6, 1, 2, 6]); // right -  left -  bottom -  top -  far -  near
        ib.upload();

        var geom = Geometry.create();
        geom.addVertexBuffer(vb);
        geom.indices = (ib);

        return geom;
    }

    public function getVertices():Array<Vec3> {
        var invProj = Mat4.invert(_projection, new Mat4());
        var vv:Array<Vec4> = [invProj * new Vec4(-1.0, 1.0, -1.0, 1.0),
        invProj * new Vec4(1.0, 1.0, -1.0, 1.0),
        invProj * new Vec4(1.0, -1.0, -1.0, 1.0),
        invProj * new Vec4(-1.0, -1.0, -1.0, 1.0),
        invProj * new Vec4(-1.0, 1.0, 1.0, 1.0),
        invProj * new Vec4(1.0, 1.0, 1.0, 1.0),
        invProj * new Vec4(1.0, -1.0, 1.0, 1.0),
        invProj * new Vec4(-1.0, -1.0, 1.0, 1.0)];

        var vertices:Array<Vec3> = [];
        for (v in vv) {
            vertices.push(MathUtil.vec4_vec3(v / v.w));
        }

        return vertices;
    }

}
