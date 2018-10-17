package minko.file;
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

    override public function parse(filename:String, resolvedFilename:String, options:Options, _data:Bytes, assetLibrary:AssetLibrary) {
        super.parse(filename, resolvedFilename, options, _data, assetLibrary);

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
        var data = new BytesInput(_data);
        parseHeader(filename, resolvedFilename, options, data, assetLibrary);
    }

    public function parseHeader(filename:String, resolvedFilename:String, options:Options, data:BytesInput, assetLibrary:AssetLibrary) {
        if (!readHeader(filename, data)) {
            _error.execute(this, ("SceneParsingError" + "Failed to parse header: " + filename));
            return;
        }

        var embedContentOffset = this.embedContentOffset;
        var embedContentLength = this.embedContentLength;

        if (data.length >= embedContentOffset + embedContentLength) {
            var embedContentDataBegin = data.position + embedContentOffset;
            var embedContentDataEnd = embedContentDataBegin + embedContentLength;
            parseEmbedContent(filename, resolvedFilename, options, data.readOneBytes(embedContentDataBegin, embedContentDataEnd), assetLibrary);

            return;
        }

        var embedContentLoader = Loader.create();
        var embedContentOptions = options.clone();

        embedContentLoader.options = (embedContentOptions);
        embedContentOptions.seekingOffset = (embedContentOffset);
        embedContentOptions.seekedLength(embedContentLength);
        embedContentOptions.storeDataIfNotParsed = (false);
        embedContentOptions.parserFunction = (function(extension) {
            return null;
        });

        _embedContentLoaderCompleteSlot = embedContentLoader.complete.connect(function(embedContentLoaderThis:Loader) {
            _embedContentLoaderCompleteSlot = null;
            parseEmbedContent(filename, resolvedFilename, embedContentOptions, embedContentLoaderThis.files.get(filename).data, assetLibrary);
        });

        embedContentLoader.queue(filename).load();
    }

    public function parseEmbedContent(filename:String, resolvedFilename:String, options:Options, data:BytesInput, assetLibrary:AssetLibrary) {
        var folderPath = extractFolderPath(resolvedFilename);

        var dst:Tuple<Array<String>, Array<SerializedNode>> = new Tuple<Array<String>, Array<SerializedNode>> ();
        extractDependencies(assetLibrary, data, 0, _dependencySize, options, folderPath);

//unpack(dst, data, _sceneDataSize, _dependencySize);
        //todo

        assetLibrary.symbol(filename, parseNode(dst.second, dst.first, assetLibrary, options));
        if (_jobList.length > 0) {
            var jobManager:JobManager = JobManager.create(30);
            for (it in _jobList) {
                jobManager.pushJob(it);
            }
            assetLibrary.symbol(filename).addComponent(jobManager);
        }
        complete.execute(this);
    }

    public function parseNode(nodePack:Array<SerializedNode>, componentPack:Array<String>, assetLibrary:AssetLibrary, options:Options) {
        var root = new Node();
        var nodeStack = new Array<Tuple<Node, Int>>();
        var componentIdToNodes:IntMap<Array<Node>> = new IntMap<Array<Node>>();
        var nodeToParentMap:ObjectMap<Node, Node> = new ObjectMap<Node, Node>();

        for (i in 0... nodePack.length) {
            var layouts = nodePack[i].second;
            var numChildren = nodePack[i].thiree;
            var componentsId = nodePack[i].four;
            var uuid = nodePack[i].five;
            var newNode:Node = Node.create(uuid, "");
            newNode.layout = (layouts);
            newNode.name = (nodePack[i].first);

            for (componentId in componentsId) {
                componentIdToNodes.get(componentId).push(newNode);
            }

            if (nodeStack.length == 0) {
                root = newNode;
                nodeToParentMap.set(root, null);
            }
            else {
                var parent:Node = nodeStack[0].first;
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

        var markedComponent = new Array<Int>();
        for (componentIndex in 0...componentPack.length) {
            var dst = componentPack[componentIndex].charAt(componentPack[componentIndex].lengthength - 1);
            if (dst == ComponentId.SKINNING || dst == ComponentId.MASTER_ANIMATION) {
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
            var dst = componentPack[componentIndex].charAt(componentPack[componentIndex].length - 1);
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
                n.addComponent(component.BoundingBox.create());
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
