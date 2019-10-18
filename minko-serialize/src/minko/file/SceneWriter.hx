package minko.file;
import minko.file.AbstractStream.SceneStream;
import minko.file.AbstractStream.SerializedNode;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import haxe.io.BytesOutput;
import minko.component.AbstractComponent;
import minko.component.AmbientLight;
import minko.component.Animation;
import minko.component.BoundingBox;
import minko.component.DirectionalLight;
import minko.component.ImageBasedLight;
import minko.component.MasterAnimation;
import minko.component.Metadata;
import minko.component.PerspectiveCamera;
import minko.component.PointLight;
import minko.component.Renderer;
import minko.component.Skinning;
import minko.component.SpotLight;
import minko.component.Surface;
import minko.component.Transform;
import minko.scene.Node;
import minko.serialize.ComponentSerializer;
import minko.StreamingCommon;
import minko.Tuple.Tuple5;
typedef NodeWriterFunc = Node -> AbstractComponent -> AssetLibrary -> Dependency -> AbstractStream;


class SceneWriter extends AbstractWriter {

    private var _componentIdToWriteFunction:ObjectMap<Class<Dynamic>, NodeWriterFunc> = new ObjectMap<Class<Dynamic>, NodeWriterFunc>();

    public static function create(writerOptions:WriterOptions) {
        return new SceneWriter(writerOptions);
    }

    private function getNode() {
        return _data;
    }

    public function new(writerOptions:WriterOptions) {

        _magicNumber = StreamingCommon.MINKO_SCENE_MAGIC_NUMBER;
        registerComponent(PerspectiveCamera, ComponentSerializer.serializePerspectiveCamera);
        registerComponent(Transform, ComponentSerializer.serializeTransform);
        registerComponent(ImageBasedLight, ComponentSerializer.serializeImageBasedLight);
        registerComponent(AmbientLight, ComponentSerializer.serializeAmbientLight);
        registerComponent(DirectionalLight, ComponentSerializer.serializeDirectionalLight);
        registerComponent(SpotLight, ComponentSerializer.serializeSpotLight);
        registerComponent(PointLight, ComponentSerializer.serializePointLight);
        registerComponent(Surface, ComponentSerializer.serializeSurface);
        // var materialId:Int = dependencies.registerDependencyMaterial(surface.material);
        // var geometryId:Int = dependencies.registerDependencyGeometry(surface.geometry);
        // var effectId:Int = surface.effect != null ? dependencies.registerDependencyEffect(surface.effect) : 0;

        registerComponent(Renderer, ComponentSerializer.serializeRenderer);
        if (writerOptions.writeAnimations) {
            registerComponent(MasterAnimation, ComponentSerializer.serializeMasterAnimation);
            registerComponent(Animation, ComponentSerializer.serializeAnimation);
            registerComponent(Skinning, ComponentSerializer.serializeSkinning);
        }
        registerComponent(BoundingBox, ComponentSerializer.serializeBoundingBox);
        registerComponent(Metadata, ComponentSerializer.serializeMetadata);
    }

    public function registerComponent(componentType:Class<Any>, readFunction:NodeWriterFunc) {
        _componentIdToWriteFunction.set(componentType, readFunction);
    }

    override public function embed(assetLibrary:AssetLibrary, options:Options, writerOptions:WriterOptions, dependency:Dependency):AbstractStream {
        var sbuf = new SceneStream();
        var queue = new Array<Node>();
        var nodePack = sbuf.nodePack;
        var serializedControllerList = sbuf.serializedControllerList;
        var controllerMap:ObjectMap<AbstractComponent, Int> = new ObjectMap<AbstractComponent, Int>();
        queue.push(data);
        while (queue.length > 0) {
            var currentNode:Node = queue.pop();
            nodePack.push(writeNode(currentNode, serializedControllerList, controllerMap, assetLibrary, dependency, writerOptions));
            for (i in 0...currentNode.children.length) {
                queue.push(currentNode.children[i]);
            }
        }
        return sbuf;
    }

    public function writeNode(node:Node, serializedControllerList:Array<AbstractStream>, controllerMap:ObjectMap<AbstractComponent, Int>, assetLibrary:AssetLibrary, dependency:Dependency, writerOptions:WriterOptions) {
        if (writerOptions.addBoundingBoxes && node.hasComponent(Surface) && !node.hasComponent(BoundingBox)) {
            node.addComponent(BoundingBox.create());
        }
        var componentsId = new Array<Int>();
        var componentIndex = 0;
        var components:Array<AbstractComponent> = node.getComponents(AbstractComponent);
        var currentComponent:AbstractComponent = components[0];

        while (currentComponent != null) {
            var index = -1;
            if (controllerMap.exists(currentComponent)) {
                index = controllerMap.get(currentComponent);
            }
            else {
                var currentComponentType = currentComponent;
                if (_componentIdToWriteFunction.exists(currentComponentType)) {
                    index = serializedControllerList.length;
                    serializedControllerList.push(_componentIdToWriteFunction.get(currentComponentType)(node, currentComponent, assetLibrary, dependency));
                }
            }
            if (index != -1) {
                componentsId.push(index);
            }
            currentComponent = components[++componentIndex];
        }
        var res:SerializedNode = new SerializedNode(node.name, node.layout, node.children.length, componentsId, node.uuid);
        return res;
    }

}
