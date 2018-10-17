package minko.component;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import minko.component.AbstractLodScheduler.ResourceInfo;
import minko.data.Provider;
import minko.data.Store;
import minko.geometry.Geometry;
import minko.math.Box;
import minko.scene.Node;
import minko.signal.Signal.SignalSlot;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal3.SignalSlot3;
import minko.StreamingCommon.ProgressiveOrderedMeshLodInfo;
import minko.utils.MathUtil;
private class SurfaceInfo {
    public var surface:Surface;
    public var box:Box;
    public var layoutChangedSlot:SignalSlot2<Node, Node>;
    public var layoutMaskChangedSlot:SignalSlot< AbstractComponent >;

    public var activeLod:Int;

    public var requiredPrecisionLevel:Float;

    public var weight:Float;

    public function new(surface:Surface) {
        this.surface = surface;
        this.box = new Box();
        this.layoutChangedSlot = null;
        this.layoutMaskChangedSlot = null;
        this.activeLod = -1;
        this.requiredPrecisionLevel = 0;
        this.weight = 0.0;
    }
}

private class POPGeometryResourceInfo {
    public var base:ResourceInfo;

    public var geometry:Geometry;

    public var minLod:Int;
    public var maxLod:Int;
    public var minAvailableLod:Int;
    public var maxAvailableLod:Int;
    public var fullPrecisionLod:Int;

    public var availableLods:IntMap<ProgressiveOrderedMeshLodInfo>;

    public var defaultLodInfo:ProgressiveOrderedMeshLodInfo;
    public var lodToClosestValidLod:Array<ProgressiveOrderedMeshLodInfo>;
    public var precisionLevelToClosestLod:Array<ProgressiveOrderedMeshLodInfo>;
    public var propertyChangedSlots:ObjectMap<Node, SignalSlot3<Store, Provider, String>>;
    public var surfaceInfoCollection:Array<SurfaceInfo>;

    public function new() {
        this.base = null;
        this.geometry = new Geometry();
        this.minLod = -1;
        this.maxLod = -1;
        this.minAvailableLod = -1;
        this.maxAvailableLod = -1;
        this.fullPrecisionLod = -1;
        this.availableLods = null;
        this.lodToClosestValidLod = [];
        this.precisionLevelToClosestLod = [];
        this.propertyChangedSlots = new ObjectMap<Node, SignalSlot3<Store, Provider, String>>();
        this.surfaceInfoCollection = [];
    }
}

class POPGeometryLodScheduler extends AbstractLodScheduler {
    private var _sceneManager:SceneManager;
    private var _renderer:Renderer;

    private var _popGeometryResources:ObjectMap<Provider, POPGeometryResourceInfo>;

    private var _eyePosition:Vec3;
    private var _fov:Float;
    private var _aspectRatio:Float;

    private var _viewport:Vec4;

    private var _worldToScreenMatrix:Mat4;
    private var _viewMatrix:Mat4;

    private var _blendingRange:Float;

    public static function create() {
        var instance = new POPGeometryLodScheduler();

        return instance;
    }

    public function new() {
        super();
        this._eyePosition = new Vec3();
        this._fov = 0.0;
        this._aspectRatio = 0.0;
        this._viewport = new Vec3();
        this._worldToScreenMatrix = new Mat4();
        this._viewMatrix = new Mat4();
        this._blendingRange = 0.0 ;
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

        if (masterLodScheduler != null) {
            blendingRange(masterLodScheduler.streamingOptions.popGeometryBlendingRange);
        }
    }

    override public function surfaceAdded(surface:Surface) {
        super.surfaceAdded(surface);

        var surfaceTarget = surface.target;
        var geometry = surface.geometry;

        var masterLodScheduler = this.masterLodScheduler;

        var geometryData = masterLodScheduler.geometryData(geometry);

        if (geometryData == null) {
            return;
        }

        var resourceIt = _popGeometryResources.get(geometryData);

        var resource:POPGeometryResourceInfo = null;

        if (resourceIt == null) {
            var resourceBase = registerResource(geometryData);
            _popGeometryResources.set(resourceBase.data, new POPGeometryResourceInfo());

            var newResource = _popGeometryResources.get(resourceBase.data);

            newResource.base = resourceBase;

            resource = newResource;

            resource.geometry = geometry;
            resource.fullPrecisionLod = geometry.data.get("popFullPrecisionLod");

            var availableLods:IntMap<ProgressiveOrderedMeshLodInfo> = resourceBase.data.get("availableLods");

            resource.availableLods = availableLods;

            var maxLodIt = availableLods.iterator().next(); //todo rbegin
            resource.minLod = maxLodIt._level;

            if (maxLodIt._level == resource.fullPrecisionLod) {
                maxLodIt = availableLods.iterator().next();
            }

            resource.maxLod = maxLodIt._level;

            var lodRangeSize = resource.fullPrecisionLod + 1;

            resource.lodToClosestValidLod = [];//.resize(lodRangeSize);
            resource.precisionLevelToClosestLod = [];//.resize(lodRangeSize);

            updateClosestLods(resource);
            var lodDependencyProperties = this.masterLodScheduler.streamingOptions.popGeometryLodDependencyProperties();

            for (propertyName in lodDependencyProperties) {

                resource.propertyChangedSlots.set(surfaceTarget, surfaceTarget.data.getPropertyChanged(propertyName).connect(
                    function(store:Store, provider:Provider, UnnamedParameter1:String) {
                        invalidateLodRequirement(resource.base);
                    }));
            }
        }
        else {
            resource = resourceIt;
        }


        var surfaceInfoIt = Lambda.find(resource.surfaceInfoCollection, function(surfaceInfo:SurfaceInfo) {
            return surfaceInfo.surface == surface;
        });

        if (surfaceInfoIt != null) {
            return;
        }

        resource.surfaceInfoCollection.remove(surface);
        var surfaceInfo = resource.surfaceInfoCollection[resource.surfaceInfoCollection.length - 1];//todo back();

        var boundingBox:BoundingBox = surfaceTarget.getComponent(BoundingBox);
        surfaceInfo.box = boundingBox.box;

        surfaceInfo.weight = 0.0;
        surfaceInfo.layoutChangedSlot = surfaceTarget.layoutChanged.connect(function(node, target) {
            if (node != target) {
                return;
            }

            layoutChanged(resource, surfaceInfo);
        });
        surfaceInfo.layoutMaskChangedSlot = surface.layoutMaskChanged.connect(function(component) {
            layoutChanged(resource, surfaceInfo);
        });

        surface.numIndices = (0);
        surface.data.set("popLod", 0.0);
        surface.data.set("popLodEnabled", true);

        if (blendingIsActive(resource, surfaceInfo)) {
            blendingRangeChanged(resource, surfaceInfo, _blendingRange);
        }
    }

    override public function surfaceRemoved(surface:Surface) {
        super.surfaceRemoved(surface);

        var surfaceTarget = surface.target;
        var geometry = surface.geometry;

        var masterLodScheduler = this.masterLodScheduler;

        var geometryData = masterLodScheduler.geometryData(geometry);

        if (geometryData == null) {
            return;
        }

        var resourceIt = _popGeometryResources.exists(geometryData);

        if (resourceIt == false) {
            return;
        }

        var resource = _popGeometryResources.get(geometryData);

        resource.surfaceInfoCollection = resource.surfaceInfoCollection.filter(function(surfaceInfo:SurfaceInfo) {
            return surfaceInfo.surface != surface;
        });

    }

    override public function viewPropertyChanged(worldToScreenMatrix:Mat4, viewMatrix:Mat4, eyePosition:Vec3, fov:Float, aspectRatio:Float, zNear:Float, zFar:Float) {
        super.viewPropertyChanged(worldToScreenMatrix, viewMatrix, eyePosition, fov, aspectRatio, zNear, zFar);

        _eyePosition = eyePosition;
        _fov = fov;
        _aspectRatio = aspectRatio;
        _worldToScreenMatrix = worldToScreenMatrix;
        _viewMatrix = viewMatrix;

        invalidateLodRequirement();
    }

    override public function viewportChanged(viewport:Vec4) {
        _viewport = viewport;

        invalidateLodRequirement();
    }

    override public function maxAvailableLodChanged(resource:ResourceInfo, maxAvailableLod:Int) {
        super.maxAvailableLodChanged(resource, maxAvailableLod);

        invalidateLodRequirement(resource);

        var popGeometryResource = _popGeometryResources.get(resource.data);

        if (popGeometryResource.minAvailableLod < 0) {
            popGeometryResource.minAvailableLod = maxAvailableLod;
        }
        else {
            popGeometryResource.minAvailableLod = Math.min(maxAvailableLod, popGeometryResource.minAvailableLod);
        }

        popGeometryResource.maxAvailableLod = Math.max(maxAvailableLod, popGeometryResource.maxAvailableLod);

        updateClosestLods(popGeometryResource);
    }

    override public function lodInfo(resource:ResourceInfo, time:Float) {
        var lodInfo = new LodInfo();

        var popGeometryResource = _popGeometryResources.get(resource.data);

        var maxRequiredLod = 0;
        var maxPriority = 0.0;

        for (surfaceInfo in popGeometryResource.surfaceInfoCollection) {
            var surface = surfaceInfo.surface;

            var previousActiveLod = surfaceInfo.activeLod;

            var activeLod = previousActiveLod;

            var requiredPrecisionLevel = 0.0;
            var requiredLod = computeRequiredLod(popGeometryResource, surfaceInfo, requiredPrecisionLevel);
            var lodIndex = MathUtil.clamp(requiredLod, popGeometryResource.minLod, popGeometryResource.fullPrecisionLod);
            var lod = popGeometryResource.lodToClosestValidLod[lodIndex];

            if (lod.isValid) {
                activeLod = lod._level;
            }

            if (previousActiveLod != activeLod) {
                surfaceInfo.activeLod = activeLod;

                activeLodChanged(popGeometryResource, surfaceInfo, previousActiveLod, activeLod, requiredPrecisionLevel);
            }

            if (surfaceInfo.requiredPrecisionLevel != requiredPrecisionLevel) {
                surfaceInfo.requiredPrecisionLevel = requiredPrecisionLevel;

                requiredPrecisionLevelChanged(popGeometryResource, surfaceInfo);
            }

            if (blendingIsActive(popGeometryResource, surfaceInfo)) {
                updateBlendingLod(popGeometryResource, surfaceInfo);
            }

            maxRequiredLod = Math.Max(requiredLod, maxRequiredLod);

            var priority = computeLodPriority(popGeometryResource, surfaceInfo, requiredLod, activeLod, time);

            if (priority > 0.0) {
                surfaceInfo.weight = priority;
            }

            maxPriority = Math.max(priority, maxPriority);
        }

        lodInfo.requiredLod = maxRequiredLod;
        lodInfo.priority = maxPriority;

        return lodInfo;
    }

    public function layoutChanged(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo) {
        invalidateLodRequirement(resource.base);
    }

    public function activeLodChanged(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo, previousLod:Int, lod:Int, requiredPrecisionLevel:Float) {
        var provider = resource.base.data;

        var activeLod = resource.availableLods.get(lod);

        var numIndices = (activeLod._indexOffset + activeLod._indexCount);

        surfaceInfo.surface.numIndices(numIndices);
        surfaceInfo.surface.data.set("popLod", activeLod._precisionLevel);
    }

    public function computeRequiredLod(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo, requiredPrecisionLevel:Float) {
        var target = surfaceInfo.surface.target;

        var box:Box = surfaceInfo.box;

        var worldMinBound = box.bottomLeft;
        var worldMaxBound = box.topRight;

        var targetDistance = distanceFromEye(resource, surfaceInfo, _eyePosition);

        if (targetDistance <= 0) {
            var maxPrecisionLevel = Math.POSITIVE_INFINITY;

            requiredPrecisionLevel = maxPrecisionLevel;
            var lodIndex = MathUtil.clamp(maxPrecisionLevel, resource.minLod, resource.fullPrecisionLod);
            var requiredLod = resource.precisionLevelToClosestLod[lodIndex];

            return masterLodScheduler.streamingOptions.popGeometryLodFunction ? masterLodScheduler.streamingOptions.popGeometryLodFunction(requiredLod._level, resource.maxLod, resource.fullPrecisionLod, surfaceInfo.weight, surfaceInfo.surface) : requiredLod._level;
        }

        var defaultPopGeometryError:Float = (masterLodScheduler.streamingOptions.popGeometryErrorToleranceThreshold);

        var popErrorBound = masterLodScheduler.streamingOptions.popGeometryErrorFunction ? masterLodScheduler.streamingOptions.popGeometryErrorFunction(defaultPopGeometryError, surfaceInfo.surface) : defaultPopGeometryError;

        var viewportHeight = _viewport.w > 0.0 ? _viewport.w : 600.0;

        var unitSize = Math.abs(2.0 * Math.Tan(0.5 * _fov) * targetDistance / viewportHeight);
        function glm_length(n) return n;
        //todo
        requiredPrecisionLevel = Math.log(glm_length(worldMaxBound - worldMinBound) / (unitSize * (popErrorBound + 1)));

        var ceiledRequiredPrecisionLevel = Math.ceil(requiredPrecisionLevel);
        var lodIndex = MathUtil.clamp(ceiledRequiredPrecisionLevel, resource.minLod, resource.fullPrecisionLod);
        var requiredLod = resource.precisionLevelToClosestLod[lodIndex];

        return masterLodScheduler.streamingOptions.popGeometryLodFunction ? masterLodScheduler.streamingOptions.popGeometryLodFunction(requiredLod._level, resource.maxLod, resource.fullPrecisionLod, surfaceInfo.weight, surfaceInfo.surface) : requiredLod._level;
    }

    public function computeLodPriority(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo, requiredLod:Int, activeLod:Int, time:Float) {
        if (activeLod >= requiredLod) {
            return 0.0;
        }

        var lodPriorityFunction = masterLodScheduler.streamingOptions.popGeometryLodPriorityFunction();

        if (lodPriorityFunction != null) {
            return lodPriorityFunction(activeLod, requiredLod, surfaceInfo.surface, surfaceInfo.surface.target.data, _sceneManager.target.data, _renderer.target.data);
        }

        return requiredLod - activeLod;
    }

    public function findClosestValidLod(resource:POPGeometryResourceInfo, lod:Int, result:ProgressiveOrderedMeshLodInfo) {
        //todo
        var data = resource.base.data;

        var lods = resource.availableLods;

        if (Lambda.count(lods) == 0) {
            return false;
        }

        var validLods = new IntMap< ProgressiveOrderedMeshLodInfo>();

        for (lodKey in lods.keys()) {
            var lod = lods.get(lodKey);
            if (lod.isValid()) {
                validLods.set(lodKey, lod);
            }
        }
        if (Lambda.count(validLods) == 0) {
            return false;
        }

        var closestLodIt = validLods.get(lod);

        if (closestLodIt == null) {
            result = validLods.iterator().next();//todo rbegin
        }
        else {
            result = closestLodIt;
        }

        return true;
    }

    public function findClosestLodByPrecisionLevel(resource:POPGeometryResourceInfo, precisionLevel:Int, result:ProgressiveOrderedMeshLodInfo) {
        var data = resource.base.data;

        var lods = resource.availableLods;


        if (Lambda.count(lods)) {
            return false;
        }

        for (lod in lods) {


            if (lod._precisionLevel >= precisionLevel) {
                result = lod;

                return true;
            }
        }

        result = lods.iterator().next(); //todo rbegin

        return true;
    }

    public function updateClosestLods(resource:POPGeometryResourceInfo) {
        var lowerLod = resource.minLod;
        var upperLod = resource.fullPrecisionLod + 1;

        for (lod in lowerLod... upperLod) {
            var closestValidLod:ProgressiveOrderedMeshLodInfo = null;

            //todo clone
            resource.lodToClosestValidLod[lod] = findClosestValidLod(resource, lod, closestValidLod) ? closestValidLod : POPGeometryResourceInfo.defaultLodInfo;

            var closestLodByPrecisionLevel:ProgressiveOrderedMeshLodInfo = null;
            //todo clone
            resource.precisionLevelToClosestLod[lod] = findClosestLodByPrecisionLevel(resource, lod, closestLodByPrecisionLevel) ? closestLodByPrecisionLevel : POPGeometryResourceInfo.defaultLodInfo;
        }
    }

    public function distanceFromEye(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo, eyePosition:Vec3) {
        var box = surfaceInfo.box;

        var distance = box.distance(eyePosition);

        return Math.max(0.0, distance);
    }

    public function requiredPrecisionLevelChanged(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo) {
    }

    public function blendingIsActive(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo) {
        return _blendingRange > 0.0 ;
    }

    public function updateBlendingLod(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo) {
        surfaceInfo.surface.data.set("popBlendingLod", blendingLod(resource, surfaceInfo));
    }

    public function blendingRange(value) {
        if (_blendingRange == value) {
            return;
        }

        _blendingRange = value;

        for (resource in _popGeometryResources) {

            for (surfaceInfo in resource.surfaceInfoCollection) {
                blendingRangeChanged(resource, surfaceInfo, _blendingRange);
            }
        }
    }

    public function blendingRangeChanged(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo, blendingRange:Float) {
        if (_blendingRange > 0.0) {
            surfaceInfo.surface.data.set("popBlendingLod", blendingLod(resource, surfaceInfo));
            surfaceInfo.surface.data.set("popBlendingEnabled", true);
        }
        else {
            surfaceInfo.surface.data.unset("popBlendingEnabled");
        }
    }

    public function blendingLod(resource:POPGeometryResourceInfo, surfaceInfo:SurfaceInfo) {
        var requiredPrecisionLevel = surfaceInfo.requiredPrecisionLevel;

        var blendingLod = requiredPrecisionLevel >= (resource.maxLod + 1) ? resource.fullPrecisionLod : requiredPrecisionLevel;

        blendingLod = MathUtil.clamp(blendingLod, (surfaceInfo.activeLod - 1), surfaceInfo.activeLod);

        return blendingLod;
    }

}
