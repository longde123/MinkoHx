package minko.file;
import minko.file.VertexWelder.NodePredicateFunction;
import glm.Mat4;
import minko.component.BoundingBox;
import minko.component.Metadata;
import minko.component.Surface;
import minko.component.Transform;
import minko.scene.Node;
import minko.signal.Signal2;
class RetargetedSurface {
    public var surface:Surface;
    public var matrix:Mat4;

    public function new(surface:Surface, matrix:Mat4) {
        this.surface = surface;
        this.matrix = matrix;
    }
}
//typedef NodePredicateFunction = Node -> Bool;

class SceneTreeFlattener extends AbstractWriterPreprocessor  {


    private var _protectedNodePredicateFunction:NodePredicateFunction;

    private var _progressRate:Float;
    private var _statusChanged:Signal2<AbstractWriterPreprocessor , String>;
    override public function get_statusChanged() {
        return _statusChanged;
    }

    public static function create() {
        var instance = (new SceneTreeFlattener());

        return instance;
    }

    public function protectedNodePredicateFunction(func:NodePredicateFunction) {
        _protectedNodePredicateFunction = func;
    }

  //  public var progressRate(get, null):Float;

    function get_progressRate() {
        return _progressRate;
    }



    public function new() {

        super();
        this._protectedNodePredicateFunction = new NodePredicateFunction();
        this._progressRate = 0.0;
        this._statusChanged = new Signal2<AbstractWriterPreprocessor<Node>, String>();
    }

    override public function process(node:Dynamic, assetLibrary:AssetLibrary) {
        if (statusChanged != null && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "SceneTreeFlattener: start");
        }

        var retargetedSurfaces = new Array<RetargetedSurface>();

        collapseNode(node, null, node, retargetedSurfaces);

        patchNode(node, retargetedSurfaces);

        _progressRate = 1.0 ;

        if (statusChanged != null && statusChanged.numCallbacks > 0) {
            statusChanged.execute(this, "SceneTreeFlattener: stop");
        }
    }

    public function collapseNode(node:Node, parent:Node, root:Node, retargetedSurfaces:Array<RetargetedSurface>) {
        var protectedDescendant = false;

        var childrenToRemove = new Array<Node>();

        for (child in node.children) {
            var childRetargetedSurfaces = new Array<RetargetedSurface>();

            var childProtectedDescendant = collapseNode(child, node, root, childRetargetedSurfaces);

            if (!childProtectedDescendant) {
                childrenToRemove.push(child);
            }

            protectedDescendant |= childProtectedDescendant;

            retargetedSurfaces = retargetedSurfaces.concat(childRetargetedSurfaces);
            //todo
        }

        for (child in childrenToRemove) {
            node.removeChild(child);
        }

        var surfaces:Array<Surface> = node.getComponents(Surface);
        var transforms:Array<Transform> = node.getComponents(Transform);

        var nodeIsProtected = node == root || protectedDescendant || (_protectedNodePredicateFunction ? _protectedNodePredicateFunction(node) : defaultProtectedNodePredicateFunction(node));

        if (!nodeIsProtected) {
            var localTransformMatrix = transforms.length == 0 ? new Mat4() : transforms[0].matrix;

            var nodeTransform = transforms[0];

            for (retargetedSurface in retargetedSurfaces) {
                retargetedSurface.matrix = localTransformMatrix * retargetedSurface.matrix;
            }

            for (surface in surfaces) {
                retargetedSurfaces.push(new RetargetedSurface(surface, localTransformMatrix));
            }
        }
        else {
            patchNode(node, retargetedSurfaces);

            retargetedSurfaces = [];
        }

        return nodeIsProtected;
    }

    public function patchNode(node:Node, retargetedSurfaces:Array<RetargetedSurface>) {
        for (retargetedSurface in retargetedSurfaces) {
            var target = retargetedSurface.surface.target ;

            var surfaceNode = Node.create(target.name);
            surfaceNode.layout = (target.layout);
            surfaceNode.addComponent(Transform.create(retargetedSurface.matrix));
            surfaceNode.addComponent(BoundingBox.create());
            surfaceNode.addComponent(retargetedSurface.surface);

            node.addChild(surfaceNode);
        }
    }

    public function defaultProtectedNodePredicateFunction(node:Node) {
        return node.components.length > (node.getComponents(Transform).length + node.getComponents(BoundingBox).length + node.getComponents(Surface).length + node.getComponents(Metadata).length)
        || (node.data.hasProperty("animated") && node.data.get("animated"));
    }

}
