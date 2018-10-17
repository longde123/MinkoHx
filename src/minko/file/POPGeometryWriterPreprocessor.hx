package minko.file;
import Lambda;
import minko.component.AbstractAnimation;
import minko.component.POPGeometryLodScheduler;
import minko.component.Skinning;
import minko.component.Surface;
import minko.data.Provider;
import minko.geometry.Bone;
import minko.geometry.Geometry;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
class Options {
    private static var InstanceFieldsInitialized:Bool = false;

    private static function InitializeInstanceFields() {
        all = computeVertexColor | smoothVertexColor;
    }

    private static var none = 0;

    private static var computeVertexColor = 1 << 0;
    private static var smoothVertexColor = 1 << 1;

    private static var all;

    private var flags:Int;

    public function new() {
        if (!InstanceFieldsInitialized) {
            InitializeInstanceFields();
            InstanceFieldsInitialized = true;
        }
        this.flags = none;
    }
}

class POPGeometryWriterPreprocessor extends AbstractWriterPreprocessor<Node > {


    private var _options:Options;


    private var _statusChanged:Signal2<AbstractWriterPreprocessor<Node>, String>;

    override public function get_statusChanged() {
        return _statusChanged;
    }
    public var progressRate(get, null):Float;

    function get_progressRate() {
        return 1.0;
    }


    public static function create() {
        var instance = (new StreamedTextureWriterPreprocessor());

        return instance;
    }
    public var options(null, set):Options;

    function set_options(op) {
        _options.copyFrom(op);
    }


    public function new() {
        super();
        this._statusChanged = new Signal2<AbstractWriterPreprocessor<Node>, String>();
    }

    public function process(node:Node, assetLibrary:AssetLibrary) {
        // TODO
        // introduce heuristics based on scene layout
        // * find object instances within scene hierarchy
        //   to dispatch lod scheduling components at correspondings object roots, used as
        //   scene object descriptors specifying type of technique to apply

        // by default whole scene is streamed as a progressive ordered mesh

        if (!node.hasComponent(POPGeometryLodScheduler)) {
            node.addComponent(POPGeometryLodScheduler.create());
        }

        var animatedNodes = collectAnimatedNodes(node);

        markPOPGeometries(node, animatedNodes);
    }

    public function markPOPGeometries(root:Node, ignoredNodes:Array<Node>) {
        var surfaceNodes:NodeSet = NodeSet.create(root).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Surface);
        });

        for (surfaceNode in surfaceNodes.nodes()) {
            if (Lambda.has(ignoredNodes, surfaceNode)) {
                continue;
            }
            var surfaces:Array<Surface> = surfaceNode.getComponents(Surface);
            for (surface in surfaces) {
                var geometry = surface.geometry;

                markPOPGeometry(surfaceNode, surface, geometry);
            }
        }
    }

    public function markPOPGeometry(node:Node, surface:Surface, geometry:Geometry) {
        geometry.data.set("type", "pop");
    }

    public function collectAnimatedNodes(root:Node) {
        var animatedNodes = new Array<Node>();

        var abstractAnimationNodes:NodeSet = NodeSet.create(root).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(AbstractAnimation);
        });

        for (animatedNode in abstractAnimationNodes.nodes()) {
            var animatedNodeDescendants = NodeSet.create(animatedNode).descendants(true);

            animatedNodes = animatedNodes.concat(animatedNodeDescendants.nodes());
        }
        var skinningNodes:NodeSet = NodeSet.create(root).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Skinning);
        });

        for (skinningNode in skinningNodes.nodes) {
            var skinning:Skinning = cast skinningNode.getComponent(Skinning);
            var skin = skinning.skin;

            for (i in 0...skin.numBones) {
                var bone:Bone = skin.getBone(i);

                var boneDescendants = NodeSet.create(bone.node).descendants(true);

                animatedNodes = animatedNodes.concat(boneDescendants.nodes());
            }

            for (node in animatedNodes) {
                var provider = Provider.create();

                provider.set("animated", true);

                node.data.addProvider(provider);
            }
        }

        return animatedNodes;
    }

}
