package minko.component;
import glm.Mat4;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import minko.component.AbstractLodScheduler.ResourceInfo;
import minko.data.Provider;
import minko.data.Store;
import minko.file.AssetLibrary;
import minko.render.AbstractTexture;
import minko.render.TextureSampler;
import minko.scene.Node;
import minko.signal.Signal3.SignalSlot3;
import minko.signal.Signal5.SignalSlot5;
import minko.utils.MathUtil;
class TextureResourceInfo {
    public var base:ResourceInfo;

    public var texture:AbstractTexture;
    public var textureType:String;
    public var materialDataSet:Array<Provider>;
    public var activeLod:Int;

    public var maxAvailableLod:Int;
    public var maxLod:Int;
    public var propertyChangedSlots:ObjectMap<Node, SignalSlot3<Store, Provider, String>>;

    public function new():Void {

    }
}
class TextureLodScheduler extends AbstractLodScheduler {
    private var _sceneManager:SceneManager;
    private var _renderer:Renderer;
    private var _deferredTextureRegisteredSlot:SignalSlot5<MasterLodScheduler, Provider, Array<Provider>, String, AbstractTexture>;
    private var _deferredTextureReadySlot:SignalSlot5<MasterLodScheduler, Provider, Array<Provider>, String, AbstractTexture>;
    private var _textureResources:StringMap<TextureResourceInfo>;
    private var _eyePosition:Vec3;
    private var _fov:Float;
    private var _aspectRatio:Float;
    private var _viewport:Vec4;
    private var _assetLibrary:AssetLibrary;

    public static function create(assetLibrary:AssetLibrary) {
        var instance = new TextureLodScheduler(assetLibrary);

        return instance;
    }

    public function new(assetLibrary:AssetLibrary) {
        super();
        this._textureResources = new StringMap<TextureResourceInfo>();
        this._assetLibrary = assetLibrary;
    }

    override public function sceneManagerSet(sceneManager:SceneManager) {
        super.sceneManagerSet(sceneManager);
        _sceneManager = sceneManager;
    }

    override public function rendererSet(renderer:Renderer) {
        super.rendererSet(renderer);
        _renderer = renderer;
    }

    override public function masterLodSchedulerSet(masterLodScheduler:MasterLodScheduler) {
        super.masterLodSchedulerSet(masterLodScheduler);
        if (masterLodScheduler == null) {
            _deferredTextureRegisteredSlot = null;
            _deferredTextureReadySlot = null;
            return;
        }

        for (deferredTextureData in masterLodScheduler.deferredTextureDataSet) {
            textureRegistered(deferredTextureData);
        }
        _deferredTextureRegisteredSlot = masterLodScheduler.deferredTextureRegistered.connect(
            function(masterLodScheduler:MasterLodScheduler, data:Provider) {
                textureRegistered(data);
            });

        _deferredTextureReadySlot = masterLodScheduler.deferredTextureReady.connect(

            function(masterLodScheduler:MasterLodScheduler, data:Provider, materialDataSet:Array<Provider>, textureType:String, texture:AbstractTexture) {
                textureReady(_textureResources.get(data.uuid), data, materialDataSet, textureType, texture);
            });
    }

    override public function surfaceAdded(surface:Surface) {
        super.surfaceAdded(surface);

        var surfaceTarget = surface.target;
        var material = surface.material;

        var textures = new ObjectMap<AbstractTexture, String>();

        for (propertyName in material.data.values.keys()) {
            if (!material.data.propertyHasType(propertyName)) {
                continue;
            }
            var textureSampler:TextureSampler = material.data.get(propertyName);
            var texture = _assetLibrary.getTextureByUuid(textureSampler.uuid);

            textures.set(texture, propertyName);
        }

        for (texture in textures.keys()) {
            var textureName = textures.get(texture);
            var masterLodScheduler = this.masterLodScheduler;
            var textureData:Provider = masterLodScheduler.textureData(texture);
            if (textureData == null) {
                continue;
            }

            var resourceIt = _textureResources.get(textureData.uuid);
            var resource:TextureResourceInfo = null;

            if (resourceIt == null) {
                var resourceBase = registerResource(textureData);

                var newResourceIt = new TextureResourceInfo();
                _textureResources.set(resourceBase.uuid, newResourceIt);

                var newResource = newResourceIt;

                newResource.base = resourceBase;

                resource = newResource;

                resource.texture = texture;

                var lodDependencyProperties = this.masterLodScheduler.streamingOptions.streamedTextureLodDependencyProperties;

                for (propertyName in lodDependencyProperties) {

                    resource.propertyChangedSlots.set(surfaceTarget, surfaceTarget.data.getPropertyChanged(propertyName).connect(
                        function(store, provider, UnnamedParameter1) {
                            invalidateLodRequirement(resource.base);
                        }));
                }

                material.data.set(textureName + "MaxAvailableLod", lodToMipLevel(DEFAULT_LOD, resource.texture.width, resource.texture.height));

                material.data.set(textureName + "Size", new Vec2(texture.width, texture.height));

                material.data.set(textureName + "LodEnabled", true);

                resource.textureType = textureName;
                resource.materialDataSet.push(material.data);

                resource.maxLod = textureData.get("maxLod");
                resource.activeLod = Math.max(resource.activeLod, DEFAULT_LOD);
            }
            else {
                resource = resourceIt;
            }
        }
    }

    public function textureRegistered(data:Provider) {
        var resourceIt = _textureResources.get(data.uuid);

        var resource:TextureResourceInfo = null;

        if (resourceIt == null) {
            var resourceBase = registerResource(data);

            var newResourceIt = new TextureResourceInfo();
            _textureResources.set(resourceBase.uuid, newResourceIt);

            var newResource = newResourceIt;

            newResource.base = resourceBase;
            resource = newResource;
        }
        else {
            resource = resourceIt;
        }
    }

    public function textureReady(resource:TextureResourceInfo, data:Provider, materialDataSet:Array<Provider>, textureType:String, texture:AbstractTexture) {
        resource.texture = texture;
        resource.textureType = textureType;

        resource.maxLod = data.get("maxLod");

        for (materialData in materialDataSet) {
            resource.materialDataSet.push(materialData);

            materialData.set(textureType + "MaxAvailableLod", lodToMipLevel(DEFAULT_LOD, resource.texture.width, resource.texture.height));

            materialData.set(textureType + "Size", new Vec2(texture.width, texture.height));

            materialData.set(textureType + "LodEnabled", true);
        }
    }

    override public function viewPropertyChanged(worldToScreenMatrix:Mat4, viewMatrix:Mat4, eyePosition:Vec3, fov:Float, aspectRatio:Float, zNear:Float, zFar:Float) {
        super.viewPropertyChanged(worldToScreenMatrix, viewMatrix, eyePosition, fov, aspectRatio, zNear, zFar);

        _eyePosition = eyePosition;
        _fov = fov;
        _aspectRatio = aspectRatio;

        invalidateLodRequirement();
    }

    override public function viewportChanged(viewport:Vec4) {
        _viewport = viewport;

        invalidateLodRequirement();
    }

    override public function maxAvailableLodChanged(resource:ResourceInfo, maxAvailableLod:Int) {
        super.maxAvailableLodChanged(resource, maxAvailableLod);

        invalidateLodRequirement(resource);

        var textureResource = _textureResources.get(resource.uuid);

        textureResource.maxAvailableLod = maxAvailableLod;
    }

    override public function lodInfo(resource:ResourceInfo, time:Float) {
        var lodInfo = new LodInfo();

        var textureData = resource.data;
        var textureResource = _textureResources.get(resource.uuid);

        var previousActiveLod = textureResource.activeLod;

        var requiredLod = computeRequiredLod(textureResource, null);

        var activeLod = Math.min(requiredLod, textureResource.maxAvailableLod);

        if (previousActiveLod != activeLod) {
            textureResource.activeLod = activeLod;

            activeLodChanged(textureResource, null, previousActiveLod, activeLod);
        }

        lodInfo.requiredLod = requiredLod;
        lodInfo.priority = computeLodPriority(textureResource, null, requiredLod, activeLod, time);

        return lodInfo;
    }

    public function activeLodChanged(resource:TextureResourceInfo, surface:Surface, previousLod:Int, lod:Int) {
        var textureData = resource.base.data;

        var maxAvailableLod = textureData.get("maxAvailableLod");

        var textureType = resource.textureType;

        var maxAvailableLodPropertyName = textureType + "MaxAvailableLod";
        var lodEnabledPropertyName = textureType + "LodEnabled";

        for (materialData in resource.materialDataSet) {
            if (materialData.hasProperty(maxAvailableLodPropertyName)
            && materialData.get(maxAvailableLodPropertyName) == lodToMipLevel(maxAvailableLod, resource.texture.width, resource.texture.height)) {
                continue;
            }

            var maxLod = mipLevelToLod(0, resource.texture.width, resource.texture.height);

            var mipLevel = lodToMipLevel(maxAvailableLod, resource.texture.width, resource.texture.height);

            // fixme find proper alternative to unsetting *LodEnabled
            // property, causing performance drop
            /*
	        if (maxAvailableLod == maxLod)
	        {
	            material->data()->unset(lodEnabledPropertyName);
	        }
	*/

            materialData.set(maxAvailableLodPropertyName, mipLevel);
        }
    }

    public function computeRequiredLod(resource:TextureResourceInfo, surface:Surface) {
        return masterLodScheduler.streamingOptions.streamedTextureLodFunction ? masterLodScheduler.streamingOptions.streamedTextureLodFunction(Math.POSITIVE_INFINITY, resource.maxLod, resource.maxLod, 0.0, surface) : Math.POSITIVE_INFINITY;
    }

    public function computeLodPriority(resource:TextureResourceInfo, surface:Surface, requiredLod:Int, activeLod:Int, time:Float) {
        if (activeLod >= requiredLod) {
            return 0.0;
        }

        var lodPriorityFunction = masterLodScheduler.streamingOptions.streamedTextureLodPriorityFunction;

        if (lodPriorityFunction != null) {
            return lodPriorityFunction(activeLod, requiredLod, surface, surface != null ? surface.target.data : target.data, _sceneManager.target.data, _renderer.target.data);
        }

        return requiredLod - activeLod;
    }

    public function distanceFromEye(resource:TextureResourceInfo, surface:Surface, eyePosition:Vec3) {
        var boundingBox:BoundingBox = surface.target.getComponent(BoundingBox);
        var box = boundingBox.box;

        var distance = box.distance(eyePosition);

        return Math.max(0.0, distance);
    }

    public function lodToMipLevel(lod, textureWidth, textureHeight) {
        return MathUtil.getp2(textureWidth) - lod;
    }

    public function mipLevelToLod(mipLevel, textureWidth, textureHeight) {
        return MathUtil.getp2(textureWidth) - mipLevel;
    }

}
