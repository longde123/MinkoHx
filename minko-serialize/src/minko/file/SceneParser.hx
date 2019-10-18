package minko.file;
import minko.file.AbstractStream.SceneStream;
import minko.file.AbstractStream.SerializedNode;
import minko.file.AbstractStream.SceneStream;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.component.AbstractComponent;
import minko.component.BoundingBox;
import minko.component.JobManager;
import minko.component.MasterAnimation;
import minko.component.Surface;
import minko.deserialize.ComponentDeserializer;
import minko.file.AbstractSerializerParser.SceneVersion;
import minko.file.SceneWriter.SerializedNode;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.serialize.Types.ComponentId;
import minko.signal.Signal.SignalSlot;
using minko.utils.BytesTool;

typedef ComponentReadFunction = SceneVersion -> String -> AssetLibrary -> Dependency -> AbstractComponent;
class SceneParser extends AbstractSerializerParser {
    private static var _componentIdToReadFunction:IntMap<ComponentReadFunction> = new IntMap<ComponentReadFunction>();
    private var _embedContentLoaderCompleteSlot:SignalSlot<Loader> ;

    public static function create() {
        return new SceneParser();
    }

    public function new() {

        _dependency = Dependency.create();
        _geometryParser = GeometryParser.create();
        _materialParser = MaterialParser.create();
        _textureParser = TextureParser.create();

        registerComponent(ComponentId.PROJECTION_CAMERA, ComponentDeserializer.deserializeProjectionCamera);
        registerComponent(ComponentId.TRANSFORM, ComponentDeserializer.deserializeTransform);
        registerComponent(ComponentId.IMAGE_BASED_LIGHT, ComponentDeserializer.deserializeImageBasedLight);
        registerComponent(ComponentId.AMBIENT_LIGHT, ComponentDeserializer.deserializeAmbientLight);
        registerComponent(ComponentId.DIRECTIONAL_LIGHT, ComponentDeserializer.deserializeDirectionalLight);
        registerComponent(ComponentId.SPOT_LIGHT, ComponentDeserializer.deserializeSpotLight);
        registerComponent(ComponentId.POINT_LIGHT, ComponentDeserializer.deserializePointLight);
        registerComponent(ComponentId.SURFACE, ComponentDeserializer.deserializeSurface);
        registerComponent(ComponentId.RENDERER, ComponentDeserializer.deserializeRenderer);
        registerComponent(ComponentId.MASTER_ANIMATION, ComponentDeserializer.deserializeMasterAnimation);
        registerComponent(ComponentId.ANIMATION, ComponentDeserializer.deserializeAnimation);
        registerComponent(ComponentId.SKINNING, ComponentDeserializer.deserializeSkinning);
        registerComponent(ComponentId.BOUNDINGBOX, ComponentDeserializer.deserializeBoundingBox);
        registerComponent(ComponentId.METADATA, ComponentDeserializer.deserializeMetadata);
    }

    public function registerComponent(componentId:Int, readFunction:ComponentReadFunction) {
        _componentIdToReadFunction.set(componentId, readFunction);
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary):Void {


        var scenePath = File.extractPrefixPathFromFilename(resolvedFilename);
        var includePaths = options.includePaths;

        var includePathIt = Lambda.find(includePaths, function(includePath) {
            return includePath == scenePath;
        });

        if (includePathIt == null) {
            includePaths.push(scenePath);
        }

        _dependency = Dependency.create();
        _dependency.options = (options);

    }

    override public function parseStream(filename:String, resolvedFilename:String, options:Options, _data:AbstractStream, assetLibrary:AssetLibrary) {
        var data:SceneStream = cast _data;
        var folderPath = extractFolderPath(resolvedFilename);
        assetLibrary.symbol(filename, parseNode(data.nodePack, data.serializedControllerList, assetLibrary, options));
        if (_jobList.length > 0) {
            var jobManager:JobManager = JobManager.create(30);
            for (it in _jobList) {
                jobManager.pushJob(it);
            }
            assetLibrary.symbol(filename).addComponent(jobManager);
        }
        complete.execute(this);
    }

    public function parseNode(nodePack:Array<SerializedNode>, componentPack:Array<AbstractStream>, assetLibrary:AssetLibrary, options:Options) {
        var root = new Node();
        var nodeStack = new Array<Tuple<Node, Int>>();
        var componentIdToNodes:IntMap<Array<Node>> = new IntMap<Array<Node>>();
        var nodeToParentMap:ObjectMap<Node, Node> = new ObjectMap<Node, Node>();

        //done 1
        for (np in nodePack) {
            var numChildren = np.children;
            var componentsId = np.componentsId;
            var uuid = np.uuid;
            var newNode:Node = Node.create(uuid, "");
            newNode.layout = np.layout;
            newNode.name = np.name;
            for (componentId in componentsId) {
                if (!componentIdToNodes.exists(componentId)) {
                    componentIdToNodes.set(componentId, []);
                }
                componentIdToNodes.get(componentId).push(newNode);
            }
            if (nodeStack.length == 0) {
                root = newNode;
                nodeToParentMap.set(root, null);
            }
            else {
                var parent:Node = cast nodeStack[0].first;
                nodeStack[0].second--;
                if (nodeStack[0].second == 0) {
                    nodeStack.pop();
                }
                nodeToParentMap.set(newNode, parent);
            }

            if (numChildren > 0) {
                nodeStack.push(new Tuple<Node, Int>(newNode, numChildren));
            }
        }

        for (nodeToParentPair in nodeToParentMap.keys()) {
            var node = nodeToParentPair;
            var parent = nodeToParentMap.get(nodeToParentPair);
            if (parent != null) {
                parent.addChild(node);
            }
        }

        _dependency.loadedRoot = (root);

        //done 2
        var markedComponent = new Array<Int>();
        for (componentIndex in 0...componentPack.length) {
            var dst = componentPack[componentIndex] ;
            if (dst.type == ComponentId.SKINNING || dst.type == ComponentId.MASTER_ANIMATION) {
                markedComponent.push(componentIndex);
            }
            else {
                if (_componentIdToReadFunction.exists(dst)) {
                    var newComponent:AbstractComponent = _componentIdToReadFunction.get(dst)(_version, componentPack[componentIndex], assetLibrary, _dependency);
                    var nodes:Array<Node> = componentIdToNodes.get(componentIndex);
                    for (node in nodes) {
                        node.addComponent(newComponent);
                    }
                }
            }
        }

        var isSkinningFree = true; // FIXME
        for (componentIndex in markedComponent) {
            if (_version.major <= 0 && _version.minor < 3) {
                continue;
            }
            var dst = componentPack[componentIndex] ;
            isSkinningFree = false;
            var newComponent:AbstractComponent = _componentIdToReadFunction.get(dst)(_version, componentPack[componentIndex], assetLibrary, _dependency);
            var nodes:Array<Node> = componentIdToNodes.get(componentIndex);
            for (node in nodes) {
                node.addComponent(newComponent);
                if (!node.hasComponent(MasterAnimation)) {
                    node.addComponent(MasterAnimation.create());
                }
            }
        }

        if (isSkinningFree) {
            var nodeSet:NodeSet = NodeSet.create(root).descendants(true).where(function(n:Node) {
                return n.getComponents(Surface).length > 0 && n.getComponents(BoundingBox).length == 0;
            });
            for (n in nodeSet.nodes) {
                n.addComponent(BoundingBox.create());
            }
        }

        for (nodeToParentPair in nodeToParentMap.keys()) {
            var node = nodeToParentPair;
            var newNode = options.nodeFunction(node);
            if (newNode != node) {
                var parent = node.parent;
                parent.removeChild(node);
                parent.addChild(newNode);
            }
        }

        return root;
    }

}
