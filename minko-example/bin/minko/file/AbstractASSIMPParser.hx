package minko.file;

import Lambda;
import Lambda;
import assimp.format.Defs;
import glm.Mat3;
import assimp.format.Material.AiMaterialTexture;
import assimp.format.Material.AiTexture;
import assimp.format.AiMatKeys;
import assimp.format.Anim.AiKey;
import assimp.Config.AiComponent;
import assimp.Assimp;
import assimp.Assimp;
import minko.data.Binding.Source;
import minko.render.Blending.Destination;
import minko.animation.AbstractTimeline;
import assimp.format.Defs.AiColor4D;
import minko.render.TriangleCulling;
import assimp.format.Material.AiBlendMode;
import minko.render.Effect;
import assimp.format.Material.AiShadingMode;
import minko.material.PhongMaterial;
import minko.material.BasicMaterial;
import assimp.Types.AiReturn;
import minko.render.AbstractTexture;
import minko.utils.MathUtil;
import assimp.format.Material.AiString;
import minko.render.Priority;
import minko.render.States;
import assimp.format.Defs.AiQuaternion;
import assimp.format.Anim.AiQuatKey;
import assimp.format.Anim.AiVectorKey;
import assimp.format.Anim.AiNodeAnim;
import assimp.format.Anim.AiAnimation;
import assimp.format.Mesh.AiBone;
import minko.component.MasterAnimation;
import minko.component.Skinning;
import minko.animation.Matrix4x4Timeline;
import minko.component.Animation;
import minko.geometry.Bone;
import minko.geometry.Skin;
import minko.component.SpotLight;
import minko.component.PointLight;
import minko.component.DirectionalLight;
import glm.GLM;
import assimp.format.Defs.AiColor3D;
import assimp.format.Light.AiLightSourceType;
import minko.component.PerspectiveCamera;
import minko.component.Surface;
import assimp.format.Mesh.AiPrimitiveType;
import minko.render.VertexBuffer;
import minko.component.Transform;
import assimp.format.Defs.AiVector3D;
import assimp.format.MetaData.AiMetadataType;
import assimp.format.MetaData.AiMetadataEntry;
import minko.component.Metadata;
import minko.component.AbstractAnimation;
import minko.scene.NodeSet;
import assimp.format.Scene.AiScene;
import assimp.AiPostProcessStep;
import assimp.ProgressHandler;
import haxe.io.Bytes;
import glm.Quat;
import glm.Vec3;
import glm.Vec4;
import minko.render.AbstractContext;
import minko.render.IndexBuffer;
import assimp.format.Material.AiTextureType;
import assimp.Importer;
import minko.signal.Signal2.SignalSlot2;
import minko.signal.Signal.SignalSlot;
import assimp.format.Material.AiMaterial;
import minko.material.Material;
import minko.geometry.Geometry;
import glm.Mat4;
import haxe.ds.StringMap;
import assimp.format.Mesh.AiMesh;
import assimp.format.Scene.AiNode;
import haxe.ds.ObjectMap;
import minko.scene.Node;
import haxe.ds.IntMap;

typedef NodeTransformInfo = minko.Tuple.Tuple3<Node, Array<Mat4>, Mat4>;
class AbstractASSIMPParser extends AbstractParser {


    private var _numDependencies:Int;
    private var _numLoadedDependencies:Int;
    private var _filename:String;
    private var _resolvedFilename:String;
    private var _assetLibrary:AssetLibrary;
    private var _options:Options;

    private var _symbol:Node;
    private var _nodeToAiNode:ObjectMap<Node, AiNode> ;
    private var _aiNodeToNode:ObjectMap<AiNode, Node> ;
    private var _aiMeshToNode:ObjectMap<AiMesh, Node>;

    private var _nameToNode:StringMap<Node>;
    private var _nameToAnimMatrices:StringMap<Array<Mat4>>;
    private var _alreadyAnimatedNodes:Array<Node>;//set sort

    private var _aiMaterialToMaterial:ObjectMap<AiMaterial, Material>;
    private var _aiMeshToGeometry:ObjectMap<AiMesh, Geometry>;

    private var _meshNames:Array<String>;// = new SortedSet<string>();
    private var _textureFilenameToAssetName:StringMap<String>;
    private var _loaderCompleteSlots:ObjectMap<Loader, SignalSlot<Loader>>;
    private var _loaderErrorSlots:ObjectMap<Loader, SignalSlot2<Loader, String>> ;
    private var _importer:Importer;
    private var _validAssetNames:StringMap<String>;


    static public function initializeTextureTypeToName() {
        var typeToString:IntMap<String> = new IntMap();

        typeToString.set(AiTextureType.diffuse, "diffuseMap");
        typeToString.set(AiTextureType.specular, "specularMap");
        typeToString.set(AiTextureType.opacity, "alphaMap");
        typeToString.set(AiTextureType.normals, "normalMap");
        typeToString.set(AiTextureType.reflection, "environmentMap2d"); // not sure about this one
        typeToString.set(AiTextureType.lightmap, "lightMap");

        return typeToString;
    }
    public static var _textureTypeToName:IntMap<String> = initializeTextureTypeToName();
    public static var PNAME_TRANSFORM = "matrix";

    public static var MAX_NUM_UV_CHANNELS = 2 ;

    private static function createIndexBuffer(mesh:AiMesh, context:AbstractContext):IndexBuffer {
        var indexData = [for (i in 0...3 * mesh.numFaces) 0];// new List<T>(3 * mesh.numFaces, 0);

        for (faceId in 0...mesh.numFaces) {
            var face = mesh.faces[faceId];

            for (j in 0...3) {
                indexData[j + 3 * faceId] = face.indices[j];
            }
        }

        return IndexBuffer.createbyData(context, indexData);
    }

    public static function packColor(color:Vec4) {
        return Vec4.dot(color, new Vec4(1.0, 1.0 / 255.0, 1.0 / 65025.0, 1.0 / 16581375.0));
    }

    private var createMeshSurface_id:Int;


    public function new() {
        super();
        this.createMeshSurface_id=0;
        this._numDependencies = 0;
        this._numLoadedDependencies = 0;
        this._filename = "";
        this._assetLibrary = null;
        this._options = null;
        this._symbol = null;
        this._nodeToAiNode = new ObjectMap<Node, AiNode>();
        this._aiNodeToNode = new ObjectMap<AiNode, Node>();
        this._aiMeshToNode = new ObjectMap<AiMesh, Node>();
        this._nameToNode = new StringMap<Node>();
        this._nameToAnimMatrices = new StringMap<Array<Mat4>>();
        this._alreadyAnimatedNodes = new Array<Node>();
        this._meshNames = new Array<String>();
        this._textureFilenameToAssetName=new StringMap<String>();
        this._loaderCompleteSlots = new ObjectMap<Loader, SignalSlot<Loader>>();
        this._loaderErrorSlots = new ObjectMap<Loader, SignalSlot2<Loader, String>>();
        this._validAssetNames= new StringMap<String>();

        this._aiMaterialToMaterial=new ObjectMap<AiMaterial, Material>();
        this._aiMeshToGeometry=new ObjectMap<AiMesh, Geometry>();
        this._importer = null;
    }

    public function provideLoaders(importer:Importer):Void {

    }

    override public function dispose() {
        _importer = null;
    }



    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {

            nextParse(filename, resolvedFilename, options, data, assetLibrary,[]);


    }
    function nextParse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary,  buffers:Array<Bytes>) {
        var pos = resolvedFilename.lastIndexOf("\\/");
        options = options.clone();
        if (pos > 0) {
            options.includePaths.push(resolvedFilename.substring(0, pos));
        }

        _filename = filename;
        _resolvedFilename = resolvedFilename;
        _assetLibrary = assetLibrary;
        _options = options;

        initImporter();

        //fixme : find a way to handle loading dependencies asynchronously
        var ioHandlerOptions = options.clone();
        ioHandlerOptions.loadAsynchronously = (false);

        var ioHandler = new IOHandler(ioHandlerOptions, _assetLibrary, _resolvedFilename);
        ioHandler.errorFunction(function(self, filename, error) {
            _error.execute(this, "MissingAssetDependency" + filename + error);
        });

        _importer.ioHandler = (ioHandler);
        var progressHandler = new ProgressHandler();
        progressHandler.progressFunction(function(progress) {
            this.progress.execute(this, progress);
        });
        _importer.progressHandler = (progressHandler);

        // Sample_005339_08932_25_14 gltf 加载 一起是 900mb内存
        //启动 230mb
        //这里用了 300mb 内存
        var scene:AiScene = importScene(filename, resolvedFilename, options, data, assetLibrary,buffers);

        if (scene == null) {
            return;
        }
        trace("parseDependencies");


        //这里用了 400mb内存
        parseDependencies(resolvedFilename, scene);
        if (_numDependencies == 0) {
            trace("allDependenciesLoaded");

            //
            allDependenciesLoaded(scene);
        }

    }

    public function importScene(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary,  buffers:Array<Bytes>):AiScene {
        //gltf
        var scene:AiScene = _importer.readFileFromMemory(data, 0, File.getExtension(filename),buffers);

        if (scene == null) {
            _error.execute(this, (_importer.getErrorString()));

            return null;
        }

        return scene;
    }

    public function getPostProcessingFlags(scene:AiScene, options:Options):Int {
        if (scene.numMeshes == 0) {
            return 0 ;
        }

        var numMaterials = scene.numMaterials;
        var numTextures = scene.numTextures;
        for (materialId in 0...numMaterials) {
            var aiMat = scene.materials[materialId];
            for (textureType in AbstractASSIMPParser._textureTypeToName.keys()) {
                numTextures += aiMat.getMaterialTextureCount(textureType);
            }
        }

        var flags = AiPostProcessStep.JoinIdenticalVertices | AiPostProcessStep.GenSmoothNormals | AiPostProcessStep.LimitBoneWeights | AiPostProcessStep.GenUVCoords | AiPostProcessStep.FlipUVs | AiPostProcessStep.SortByPType | AiPostProcessStep.Triangulate | AiPostProcessStep.ImproveCacheLocality | AiPostProcessStep.FindInvalidData | AiPostProcessStep.ValidateDataStructure | AiPostProcessStep.RemoveComponent;

        if (options.optimizeForRendering) {
            flags |= AiPostProcessStep.SplitLargeMeshes;
        }

        var removeComponentFlags = 0;
        if (numMaterials == 0 || numTextures == 0) {
            removeComponentFlags |= AiComponent.TANGENTS_AND_BITANGENTS;
        }

        _importer.set(Assimp.AI_CONFIG_PP_GSN_MAX_SMOOTHING_ANGLE, options.normalMaxSmoothingAngle);
        _importer.set(Assimp.AI_CONFIG_PP_RVC_FLAGS, removeComponentFlags);

        if (!options.preserveMaterials) {
            // this flags discards unused materials in addition to
            // removing duplicated ones
            flags |= AiPostProcessStep.RemoveRedundantMaterials;
        }

        return flags;
    }

    public function applyPostProcessing(scene:AiScene, postProcessingFlags) {
        //todo
        var processedScene:AiScene = _importer.applyPostProcessing(postProcessingFlags);

        return processedScene;
    }

    public function allDependenciesLoaded(scene:AiScene) {

        var processedScene = scene;

        var postProcessingFlags = getPostProcessingFlags(scene, _options);

        if (postProcessingFlags != 0) {
            processedScene = applyPostProcessing(scene, postProcessingFlags);
        }

        if (processedScene == null) {
            _error.execute(this, (_importer.getErrorString()));

            return;
        }
        trace("convertScene");
        convertScene(scene);
    }

    public function initImporter() {
        if (_importer != null) {
            return;
        }

        _importer = new Importer();

      //  #if ( ASSIMP_BUILD_NO_IMPORTER_INSTANCIATION)
		provideLoaders( _importer);
	//#end

        _importer.set(Assimp.AI_CONFIG_IMPORT_FBX_PRESERVE_PIVOTS, _options.includeAnimation);
    }

    public function convertScene(scene:AiScene) {
        LOG_DEBUG(_numDependencies + " dependencies loaded!");

        #if DEBUG
		if (_numDependencies != _numLoadedDependencies)
		{
			throw std::logic_error("_numDependencies != _numLoadedDependencies");
		}
	#end

        var symbolRootName = File.removePrefixPathFromFilename(_filename);
        trace("createNode");
        _symbol = createNode(scene, null, symbolRootName);
        trace("createSceneTree");
        createSceneTree(_symbol, scene, scene.rootNode, _options.assetLibrary);

        if (_options.preserveMaterials) {
            trace("createUnusedMaterials");
            createUnusedMaterials(scene, _options.assetLibrary, _options);
        }

        #if DEBUG_ASSIMP
		printNode(std::cout << "\n", _symbol, 0) << std::endl;
	#end
        trace("createLights");
        createLights(scene);
        trace("createCameras");
        createCameras(scene);

        if (_options.includeAnimation) {
            trace("createSkins");
            createSkins(scene);
            trace("createAnimations");
            createAnimations(scene, true);
        }

        #if DEBUG_ASSIMP
		printNode(std::cout << "\n", _symbol, 0) << std::endl;
	#end

        #if DEBUG_ASSIMP_DOT
		dotPrint("aiscene.dot", scene);
		dotPrint("minkoscene.dot", _symbol);
	#end

        // file::Options::nodeFunction
        trace("applyFunc");
        applyFunc(_symbol, _options.nodeFunction);

        if (_options.includeAnimation) {
            // file::Options::startAnimation
            var animations:NodeSet = NodeSet.createbyNode(_symbol).descendants(true).where(function(n:Node) {
                return n.hasComponent(AbstractAnimation);
            });
            for (n in animations.nodes) {
                if (_options.startAnimation) {
                    var ani:AbstractAnimation = cast n.getComponent(AbstractAnimation);
                    ani.play();
                }
                else {
                    var ani:AbstractAnimation = cast n.getComponent(AbstractAnimation);
                    ani.stop();
                }
            }
        }

        if (_numDependencies == _numLoadedDependencies) {
            trace("finalize");
            finalize();
        }
    }

    public function createNode(scene:AiScene, node:AiNode, name:String):Node {
        var metadata = new Metadata();

        if (node == null || !parseMetadata(scene, node, _options, metadata.data)) {
            return Node.create(name);
        }

        var minkoNode = new Node();

        var uuidIt = metadata.has("minko_uuid");

        if (uuidIt != false) {
            minkoNode = Node.create(name);
            minkoNode.uuid = metadata.get("minko_uuid");
        }
        else {
            minkoNode = Node.create(name);
        }

        for (entry in metadata.keys()) {
            _options.attributeFunction(minkoNode, entry, metadata.get(entry));
        }

        minkoNode.addComponent(Metadata.create(metadata.data));

        return minkoNode;
    }

    public function createSceneTree(minkoNode:Node, scene:AiScene, ainode:AiNode, assets:AssetLibrary) {
        minkoNode.addComponent(getTransformFromAssimp(ainode));

        // create surfaces for each node mesh
        for (j in 0...ainode.numMeshes) {
            var aimesh:AiMesh = scene.meshes[ainode.meshes[j]];
            if (aimesh == null) {
                continue;
            }

            _aiMeshToNode.set(aimesh, minkoNode);
            createMeshSurface(minkoNode, scene, aimesh);
        }

        // traverse the node's children
        for (i in 0...ainode.numChildren) {
            var aichild:AiNode = ainode.children[i];
            if (aichild == null) {
                continue;
            }

            var childName = aichild.name;
            var childNode = createNode(scene, aichild, childName);

            _nodeToAiNode.set(childNode, aichild);
            _aiNodeToNode.set(aichild, childNode);
            if (childName != null) {
                _nameToNode.set(childName, childNode);
            }

            //Recursive call
            createSceneTree(childNode, scene, aichild, assets);

            minkoNode.addChild(childNode);
        }
    }


    public function parseMetadata(scene:AiScene, ainode:AiNode, options:Options, metadata:StringMap<String>) {
        if (ainode.metaData == null) {
            return false;
        }

        for (key in ainode.metaData.keys()) {
            var data:AiMetadataEntry< Any> = ainode.metaData.get(key);
            var dataString = "";
            switch (data.type)
            {
                case AiMetadataType.AISTRING:
                    dataString = cast data.data;
                case AiMetadataType.AIVECTOR3D:
                    {
                        var vec3:AiVector3D = cast (data.data);
                        dataString = vec3.toString();
                    }
                case AiMetadataType.BOOL:
                    dataString = Std.string(data.data);
                case AiMetadataType.FLOAT:
                    dataString = Std.string(data.data);
                case AiMetadataType.INT32:
                    dataString = Std.string(data.data);
                case AiMetadataType.UINT64:
                    dataString = Std.string(data.data);
                default: {

                }
            }

            metadata.set(key, dataString);
        }

        return true;
    }

    public function applyFunc(node:Node, func:Node -> Node):Void {
        func(node);

        if (node != null) {
            for (n in node.children) {
                applyFunc(n, func);
            }
        }
    }


    public function getTransformFromAssimp(ainode:AiNode):Transform {
        return Transform.createbyMatrix4(convertMat4(ainode.transformation));
    }

    public function createMeshGeometry(minkoNode:Node, mesh:AiMesh, meshName:String):Geometry {
        var existingGeometry = _aiMeshToGeometry.exists(mesh);

        if (existingGeometry != false) {
            return _aiMeshToGeometry.get(mesh);
        }

        var vertexSize = 0;

        if (mesh.hasPositions()) {
            vertexSize += 3;
        }
        if (mesh.hasNormals()) {
            vertexSize += 3 ;
        }
        if (mesh.getNumUVChannels() > 0) {
            vertexSize += Math.floor(Math.min(mesh.getNumUVChannels() * 2, AbstractASSIMPParser.MAX_NUM_UV_CHANNELS * 2));
        }
        if (mesh.hasVertexColors(0)) {
            vertexSize += 4;
        }

        var vertexData = [for (i in 0...vertexSize * mesh.numVertices) 0.0];//new List<float>(vertexSize * mesh.numVertices, 0.0f);
        var vId = 0;
        for (vertexId in 0... mesh.numVertices) {
            if (mesh.hasPositions()) {
                var vec:AiVector3D = mesh.vertices[vertexId];
                vertexData[vId++] = vec.x;
                vertexData[vId++] = vec.y;
                vertexData[vId++] = vec.z;
            }

            if (mesh.hasNormals()) {
                var vec:AiVector3D = mesh.normals[vertexId];
                vertexData[vId++] = vec.x;
                vertexData[vId++] = vec.y;
                vertexData[vId++] = vec.z;
            }

            for (i in 0...Math.floor(Math.min(mesh.getNumUVChannels(), AbstractASSIMPParser.MAX_NUM_UV_CHANNELS))) {
                var vec:AiVector3D = mesh.textureCoords[i][vertexId];
                vertexData[vId++] = vec.x;
                vertexData[vId++] = vec.y;
            }

            if (mesh.hasVertexColors(0)) {
                var color = mesh.colors[0][vertexId];
                var packedColor = new Vec4(color.r, color.g, color.b, color.a);
                vertexData[vId++] = packedColor.r;
                vertexData[vId++] = packedColor.g;
                vertexData[vId++] = packedColor.b;
                vertexData[vId++] = packedColor.a;
            }
        }

        var indices:IndexBuffer = null;
        var numIndices = mesh.numFaces * 3;
        if (_options.optimizeForRendering || numIndices <= (Math.POSITIVE_INFINITY)) {
            indices = createIndexBuffer(mesh, _assetLibrary.context);
        }
        else {
            indices = createIndexBuffer(mesh, _assetLibrary.context);
        }

        // create the geometry's vertex and index buffers
        var geometry = Geometry.create();
        var vertexBuffer = VertexBuffer.createbyData(_assetLibrary.context, vertexData);
        var attrOffset = 0;
        if (mesh.hasPositions()) {
            vertexBuffer.addAttribute("position", 3, attrOffset);
            attrOffset += 3 ;
        }
        if (mesh.hasNormals()) {
            vertexBuffer.addAttribute("normal", 3, attrOffset);
            attrOffset += 3 ;
        }
        for (i in 0...Math.floor(Math.min(mesh.getNumUVChannels(), AbstractASSIMPParser.MAX_NUM_UV_CHANNELS))) {
            var attributeName = "uv" + (i > 0 ? Std.string(i) : "");
            vertexBuffer.addAttribute(attributeName, 2, attrOffset);
            attrOffset += 2 ;
        }
        if (mesh.hasVertexColors(0)) {
            vertexBuffer.addAttribute("color", 4, attrOffset);
            attrOffset += 4 ;
        }

        geometry.addVertexBuffer(vertexBuffer);
        geometry.indices = (indices);
        geometry = _options.geometryFunction(meshName, geometry);
        _aiMeshToGeometry.set(mesh, geometry) ;
        _assetLibrary.setGeometry(meshName, geometry);
        return geometry;
    }

    public function getValidAssetName(name:String):String {
        var validAssetNameIt = _validAssetNames.exists(name);
        if (validAssetNameIt != false) {
            return _validAssetNames.get(name);
        }
        var validAssetName:String = name;
        validAssetName = File.removePrefixPathFromFilename(validAssetName);
        //todo
        var invalidSymbolRegex = ~/[^a-zA-Z0-9_\.-]+/g;
        validAssetName = invalidSymbolRegex.replace(validAssetName, "");
        _validAssetNames.set(name, validAssetName);
        return validAssetName;
    }

    public function getMaterialName(materialName:String) {
        return getValidAssetName(materialName);
    }

    public function getMeshName(meshName:String) {
        return getValidAssetName(meshName);
    }
    inline function LOG_ERROR(arg):Void {
        throw "LOG_ERROR"+arg;
    }
    inline function LOG_WARNING(arg):Void {
        trace("LOG_WARNING"+arg);
    }
    inline function LOG_DEBUG(arg):Void {
        trace("LOG_DEBUG"+arg);
    }
    public function createMeshSurface(minkoNode:Node, scene:AiScene, mesh:AiMesh):Void {
        if (mesh == null) {
            return;
        }

        var meshName = getMeshName(mesh.name);

        var primitiveType = mesh.primitiveTypes;

        if (primitiveType != AiPrimitiveType.TRIANGLE) {
            LOG_WARNING("primitive type for mesh '" + meshName + "' is not TRIANGLE");

            return;
        }

        var realMeshName = meshName;
        //	static int id = 0;

        while (Lambda.has(_meshNames, realMeshName)) {
            realMeshName = meshName + "_" + (createMeshSurface_id++);
        }

        _meshNames.push(realMeshName);

        var aiMat = scene.materials[mesh.materialIndex];
        var geometry = createMeshGeometry(minkoNode, mesh, realMeshName);
        var material = createMaterial(aiMat);
        var effect = chooseEffectByShadingMode(aiMat);

        minkoNode.addComponent(Surface.create(geometry, material, effect, "default", realMeshName));
    }

    public function createCameras(scene:AiScene) {
        for (i in 0... scene.numCameras) {
            var aiCamera = scene.cameras[i];
            var aiPosition = aiCamera.position;
            var aiLookAt = aiCamera.lookAt;
            var aiUp = aiCamera.up;

            var cameraName = aiCamera.name;

            var cameraNode:Node = cameraName != null ? findNode(cameraName) : null;

            if (cameraNode != null) {
                var half_fovy:Float = Math.atan(Math.tan(aiCamera.horizontalFOV * .5) * aiCamera.aspect);

                cameraNode.addComponent(PerspectiveCamera.create(aiCamera.aspect, half_fovy, aiCamera.clipPlaneNear, aiCamera.clipPlaneFar));
                if (!cameraNode.hasComponent(Transform)) {
                    cameraNode.addComponent(Transform.create());
                }

                // cameraNode->component<Transform>()->matrix(math::inverse(math::lookAt(
                // 	math::vec3(aiPosition.x, aiPosition.y, aiPosition.z),
                // 	math::vec3(aiLookAt.x, aiLookAt.y, aiLookAt.z),
                // 	math::vec3(aiUp.x, aiUp.y, aiUp.z)
                // )));
            }
        }
    }

    public function createUnusedMaterials(scene:AiScene, assetLibrary:AssetLibrary, options:Options):Void {
        for (i in 0...scene.numMaterials) {
            var aiMaterial = scene.materials[i];

            createMaterial(aiMaterial);
        }
    }

    public function createLights(scene:AiScene):Void {
        for (i in 0...scene.numLights) {
            var aiLight = scene.lights[i];
            var lightName = aiLight.name;

            if (aiLight.type == AiLightSourceType.UNDEFINED) {
                LOG_WARNING("The type of the '" + lightName + "' has not been properly recognized.");
                continue;
            }

            var lightNode:Node = findNode(lightName);

            if (lightNode == null) {
                continue;
            }

            //// specular colors are ignored (diffuse colors are sent to discrete lights, ambient colors create ambient lights)
            //const aiColor3D& aiAmbientColor = aiLight->mColorAmbient;
            //if (!aiAmbientColor.IsBlack())
            //{
            //	auto ambientLight = AmbientLight::create()
            //		->ambient(1.0f)
            //		->color(Vector3::create(aiAmbientColor.r, aiAmbientColor.g, aiAmbientColor.b));

            //	lightNode->addComponent(ambientLight);
            //}

            var aiDiffuseColor:AiColor3D = aiLight.colorDiffuse;
            var aiDirection:AiVector3D = aiLight.direction;
            var aiPosition:AiVector3D = aiLight.position;

            if (aiDirection.length() > 0.0) {
                var direction = new Vec3(aiDirection.x, aiDirection.y, aiDirection.z);
                var position = new Vec3(aiPosition.x, aiPosition.y, aiPosition.z);

                var transform:Transform = cast lightNode.getComponent(Transform);
                if (transform != null) {
                    direction = MathUtil.mat4_mat3(transform.matrix) * direction;
                    position = MathUtil.vec4_vec3(transform.matrix * MathUtil.vec3_vec4(position, 1.0));
                }
                else {
                    lightNode.addComponent(Transform.create());
                }

                var lookAt = position + direction;
                lookAt = !MathUtil.vec3_equals(lookAt, new Vec3()) ? Vec3.normalize(lookAt, new Vec3()) : lookAt;

                var matrix = GLM.lookAt(position, lookAt, new Vec3(0.0, 1.0, 0.0), new Mat4());
                transform.matrix = matrix;
            }

            var diffuse = 1.0;
            var specular = 1.0;
            var color:Vec3 = new Vec3(aiDiffuseColor.r, aiDiffuseColor.g, aiDiffuseColor.b);

            switch (aiLight.type)
            {
                case AiLightSourceType.DIRECTIONAL:
                    var dir = DirectionalLight.create(diffuse, specular);
                    dir.color = (color);
                    lightNode.addComponent(dir);
                case AiLightSourceType.POINT:
                    var point = PointLight.create(diffuse, specular, aiLight.attenuationConstant, aiLight.attenuationLinear, aiLight.attenuationQuadratic);
                    point.color = (color);
                    lightNode.addComponent(point);
                case AiLightSourceType.SPOT:
                    var spot = SpotLight.create(aiLight.angleInnerCone, aiLight.angleOuterCone, diffuse, specular, aiLight.attenuationConstant, aiLight.attenuationLinear, aiLight.attenuationQuadratic);
                    spot.color = (color);
                    lightNode.addComponent(spot);
                default: {

                }
            }
        }
    }

    public function findNode(name:String):Node {
        var foundNodeIt = _nameToNode.exists(name);
        return foundNodeIt != false ? _nameToNode.get(name) : null;
    }

    public function parseDependencies(filename:String, scene:AiScene):Void {


        _numDependencies = 0;
        var path:AiMaterialTexture = new AiMaterialTexture();
        for (materialId in 0... scene.numMaterials) {
            var aiMat:AiMaterial = scene.materials[materialId];

            for (textureType in AbstractASSIMPParser._textureTypeToName.keys()) {
                var numTextures = aiMat.getMaterialTextureCount(textureType);

                for (textureId in 0...numTextures) {
                    //todo path
                    var texFound:Bool = aiMat.getMaterialTexture(textureType, textureId, path);

                    if (texFound) {
                        var filename = path.file;

                        if (filename == null) {
                            continue;
                        }

                        var assetName = File.removePrefixPathFromFilename(filename);

                        _textureFilenameToAssetName.set(filename, assetName);
                    }
                }
            }
        }

        _numDependencies = Lambda.count(_textureFilenameToAssetName);

        for (filenameToAssetNamePair in _textureFilenameToAssetName.keys()) {
            loadTexture(filenameToAssetNamePair, _textureFilenameToAssetName.get(filenameToAssetNamePair), _options, scene);
        }
    }


    public function finalize() {
        Lambda.iter(_loaderCompleteSlots, function(l:SignalSlot<Loader>) {
            l.dispose();
        });
        Lambda.iter(_loaderErrorSlots, function(l:SignalSlot2<Loader, String>) {
            l.dispose();
        });
        _loaderCompleteSlots = new ObjectMap<Loader, SignalSlot<Loader>>();
        _loaderErrorSlots = new ObjectMap<Loader, SignalSlot2<Loader, String>>() ;

        _assetLibrary.setSymbol(_filename, _symbol);

        complete.execute(this);


    }

    public function loadTexture(textureFilename:String, assetName:String, options:Options, scene:AiScene) {
        var textureParentPrefixPath = File.extractPrefixPathFromFilename(_resolvedFilename);

        var texturePrefixPath = File.extractPrefixPathFromFilename(textureFilename);

        var loader = Loader.create();

        loader.options = (options.clone());

        //loader.options.includePaths.push(textureParentPrefixPath + "/" + texturePrefixPath);
        loader.options.includePaths=[textureParentPrefixPath + "/" + texturePrefixPath];
        _loaderCompleteSlots.set(loader, loader.complete.connect(function(l:Loader) {
            textureCompleteHandler(l, scene);
        }));


        _loaderErrorSlots.set(loader, loader.error.connect(function(textureLoader, error) {
            ++_numLoadedDependencies;
            LOG_DEBUG("Unable to find texture with filename '" + assetName + "'");

            _error.execute(this, ("MissingTextureDependency" + assetName));

            if (_numDependencies == _numLoadedDependencies) {
                allDependenciesLoaded(scene);
            }
        }));

        loader.queue(assetName).load();
    }



    public function textureCompleteHandler(loader:Loader, scene:AiScene) {
        LOG_DEBUG(_numLoadedDependencies + "/" + _numDependencies + " texture(s) loaded");

        ++_numLoadedDependencies;

        if (_numDependencies == _numLoadedDependencies) {
            allDependenciesLoaded(scene);
        }
    }


    public function getSkinNumFrames(aimesh:AiMesh):Int {
//Debug.Assert(aimesh != null && _aiMeshToNode.count(aimesh) > 0);
        var minkoMesh = _aiMeshToNode.get(aimesh);
        var meshNode = minkoMesh.parent ;
//Debug.Assert(meshNode);

        var numFrames = 0;

        for (boneId in 0... aimesh.numBones) {
            var currentNode = findNode(aimesh.bones[boneId].name);
            do {
                if (currentNode == null) {
                    break;
                }

                if (_nameToAnimMatrices.exists(currentNode.name)  ) {
                    var numNodeFrames = Lambda.count(_nameToAnimMatrices.get(currentNode.name));
//Debug.Assert(numNodeFrames > 0);

                    if (numFrames == 0) {
                        numFrames = numNodeFrames;
                    }
                    else if (numFrames != numNodeFrames) {
                        LOG_WARNING("Inconsistent number of frames between the different parts of a same mesh!");
                        numFrames = Math.floor(Math.max(numFrames, numNodeFrames)); // FIXME
                    }
                }
                currentNode = currentNode.parent ;
            } while (currentNode != meshNode);
        }

        return numFrames;
    }

    public function createSkins(aiscene:AiScene) {
        if (_options.skinningFramerate == 0) {
            return;
        }

        // resample all animations with the specified temporal precision
        // and store them in the _nameToAnimMatrices map.
        sampleAnimations(aiscene);

        // add a Skinning component to all animated mesh
        for (meshId in 0...aiscene.numMeshes) {
            createSkin(aiscene.meshes[meshId]);
        }
    }

    public function createSkin(aimesh:AiMesh) {
        if (aimesh == null || aimesh.numBones == 0) {
            return;
        }

        var meshName = aimesh.name ;
        if (!_aiMeshToNode.exists(aimesh)) {
            return;
        }


        var supposedSkeletonRoot = getSkeletonRoot(aimesh);

        var meshNode = _aiMeshToNode.get(aimesh);
        var numBones = aimesh.numBones;
        var numFrames = getSkinNumFrames(aimesh);

        if (numFrames == 0) {
            LOG_WARNING("Failed to flatten skinning information. Most likely involved nodes do not share a common animation.");
            return;
        }
        var duration = Std.int(Math.floor(1e+3 * numFrames / _options.skinningFramerate)); // in milliseconds
        var skin:Skin = Skin.create(numBones, duration, numFrames);
        var skeletonRoot = getSkeletonRoot(aimesh); //findNode("ALL");
        var boneTransforms = [];// new List<List<float>>(numBones, new List<float>(numFrames * 16, 0.0f));
       /// var modelToRootMatrices = [for (i in 0...numFrames) Mat4.identity(new Mat4())];// new List<math.mat4>(numFrames);

        var boneNodes:Array<Node> = [];// new List<scene.Node.Ptr>();
//
//for  (  m in modelToRootMatrices)
//{
//m = math.mat4();
//}

        for (boneId in 0...numBones) {
            var bone:Bone = createBone(aimesh.bones[boneId]);
            var boneName = (aimesh.bones[boneId].name);
            var node = _nameToNode.get(boneName);
            boneNodes.push(node);
            if (bone == null) {
                return;
            }

            var boneOffsetMatrix = bone.offsetMatrix;
//            if( boneId ==23){
//                trace("");
//            }
            var modelToRootMatrices = [for (i in 0...numFrames) Mat4.identity(new Mat4())];
            precomputeModelToRootMatrices(node, skeletonRoot, modelToRootMatrices);
            skin.setBone(boneId, bone);

            for (frameId in 0...numFrames) {
                var dest1:Mat4= modelToRootMatrices[frameId] * boneOffsetMatrix;
//                if(frameId==300 &&boneId ==23){
//                    trace("");
//                }
                skin.setMatrix(frameId, boneId,dest1);
            }
        }

        // also find all bone children that must also be animated and synchronized with the
        // skinning component.
//        var slaves:Array<Node> = [];//new SortedSet<Node.Ptr>();
//        var slaveAnimations:Array<Animation> = [];// new List<Animation.Ptr>();
//
//        for (boneId in 0... numBones) {
//            var childrenWithSurface:NodeSet = NodeSet.createbyNode(boneNodes[boneId]).descendants(true).where(function(n:Node) {
//                return n.hasComponent(Surface);
//            });
//
//            slaves = slaves.concat(childrenWithSurface.nodes);
//        }
//
//        var timetable = [for (i in 0...numFrames) 0];//new List<@uint>(numFrames, 0);
//        for (i in 0...numFrames) {
//            timetable[i] = Std.int(Math.floor(i * duration / (numFrames - 1)));
//        }
//
//        slaves.reverse();
//        // slaveAnimations.Capacity = slaves.Count;
//        for (n in slaves) {
//            var matrices = [for (m in 0...numFrames)  Mat4.identity(new Mat4())];//new List<math.mat4>(numFrames);
////        foreach (var m in matrices)
////        {
////        m = math.mat4();
////        }
//
//            precomputeModelToRootMatrices(n, skeletonRoot, matrices);
//
//            var timeline = Matrix4x4Timeline.create(AbstractASSIMPParser.PNAME_TRANSFORM, duration, timetable, matrices);
//            var animation = Animation.create([timeline]);
//
//            n.addComponent(animation);
//            slaveAnimations.push(animation);
//            _alreadyAnimatedNodes.push(n);
//        }

        // for (auto& n : slaves) // FIXME
        // {
        // 	if (n->parent())
        // 		n->parent()->removeChild(n);
        // 	skeletonRoot->addChild(n);
        // }

        // add skinning component to mesh
        var skinning = Skinning.create(skin.reorganizeByVertices(), _options.skinningMethod, _assetLibrary.context, skeletonRoot);

        meshNode.addComponent(skinning);
        trace("skinned node: ");
        trace(meshNode.name);
        trace("\n");
        trace("skinned node parent: ");
        trace(meshNode.parent.name);
        trace("\n");
        meshNode.addComponent(MasterAnimation.create());

        var irrelevantTransformNodes:Array<Node> = [];//new SortedSet<Node.Ptr>();

        for (boneNode in boneNodes) {
            var boneNodeDescendants:NodeSet = NodeSet.createbyNode(boneNode).descendants(true).where(function(descendant:Node) {
                return descendant.hasComponent(Transform);
            });

            var tmp:Array<Node>=boneNodeDescendants.nodes.filter(function(n) return !Lambda.has(irrelevantTransformNodes,n));
            irrelevantTransformNodes = irrelevantTransformNodes.concat(tmp);

            var boneNodeParent = boneNode.parent ;

            while (boneNodeParent != skeletonRoot) {
                if(!Lambda.has(irrelevantTransformNodes,boneNodeParent))
                    irrelevantTransformNodes.push(boneNodeParent);
                boneNodeParent = boneNodeParent.parent;
            }
        }

        var animatedNodes:NodeSet = NodeSet.createbyNode(skeletonRoot).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Animation) || descendant.hasComponent(Skinning);
        });

        for (i in 0...animatedNodes.nodes.length) {
            var animatedNode = animatedNodes.nodes[i];
            var animatedNodeDescendants:NodeSet = NodeSet.createbyNode(animatedNode).descendants(true).where(function(animatedNodeDescendant:Node) {
                return animatedNodeDescendant.hasComponent(Transform);
            });

            var tmp:Array<Node>=animatedNodeDescendants.nodes.filter(function(n) return !Lambda.has(irrelevantTransformNodes,n));
            irrelevantTransformNodes = irrelevantTransformNodes.concat(tmp);

            // auto animatedNodeParent = animatedNode->parent();
            //
            // while (animatedNodeParent != skeletonRoot)
            // {
            //     irrelevantTransformNodes.insert(animatedNodeParent);
            //
            //     animatedNodeParent = animatedNodeParent->parent();
            // }
        }

        for (irrelevantTransformNode in irrelevantTransformNodes) {
            var transform:Transform = cast irrelevantTransformNode.getComponent(Transform);
            transform.matrix =  Mat4.identity(new Mat4());
        }
    }

    public function getSkeletonRoot(aimesh:AiMesh):Node {
        var skeletonRoot:Node = null;
        var boneAncestor:Node = getBoneCommonAncestor(aimesh);
        var currentNode = boneAncestor;

        while (true) {
            if (currentNode == null) {
                break;
            }
//todo count
            if (_nameToAnimMatrices.exists(currentNode.name) ) {
                skeletonRoot = currentNode;
            }

            currentNode = currentNode.parent;
        }

        return skeletonRoot != null ? (skeletonRoot.parent != null ? skeletonRoot.parent : _symbol) : boneAncestor;
    }

    public function getBoneCommonAncestor(aimesh:AiMesh):Node {
        if (aimesh != null && aimesh.numBones > 0) {
            var bonePath:Array<Array<Node>> = [];//new List< List<Node.Ptr>>();
//bonePath.Capacity = aimesh.numBones;

            // compute the common ancestor of all bones influencing the specified mesh
            var minDepth:Int = 2147483647 ;
            for (boneId in 0... aimesh.numBones) {
                var boneNode = findNode(aimesh.bones[boneId].name);
                if (boneNode == null) {
                    continue;
                }

                var tmp = [];
                bonePath.push(tmp);//new List<Node.Ptr>());

                var currentNode = boneNode;
                do {
                    if (currentNode == null) {
                        break;
                    }

                    tmp.push(currentNode);
                    currentNode = currentNode.parent;
                } while (true);

                tmp.reverse();

                if (tmp.length < minDepth) {
                    minDepth = tmp.length;
                }
            }

            if (bonePath.length == 0) {
                return _symbol;
            }

            for (d in 0...minDepth) {
                var node = bonePath[0][d];
                var isCommon = true;
                var boneId = 1;
                while (boneId < aimesh.numBones && isCommon) {
                    if (bonePath[boneId][d] != node) {
                        isCommon = false;
                        break;
                    }
                    ++boneId;
                }

                if (!isCommon) {
                    if (d > 0) {
                        return bonePath[0][d - 1];
                    }
                    else {
                        return _symbol;
                    }
                }
            }
        }
        return _symbol;
    }


    public function precomputeModelToRootMatrices(node:Node, root:Node, modelToRootMatrices:Array<Mat4>) {
//Debug.Assert(node != null && modelToRootMatrices.Count > 0);


        // precompute the sequence of local-to-parent transformations from node to root
        var transformsUpToRoot:Array<NodeTransformInfo> = [];
        var currentNode = node;
        do {
            if (currentNode == null) {
                break;
            }

            var currentName = currentNode.name ;
            var tmp:NodeTransformInfo = new NodeTransformInfo(null, null, null);
            transformsUpToRoot.push(tmp);

            tmp.first = currentNode;
            tmp.second = [];
            tmp.thiree = null;

            var foundAnimMatricesIt = _nameToAnimMatrices.exists(currentName);
            if (foundAnimMatricesIt != false ) {
                tmp.second = _nameToAnimMatrices.get(currentName);
            }
            else if (currentNode.hasComponent(Transform)) {
                var t:Transform = cast currentNode.getComponent(Transform);
                tmp.thiree = t.matrix ;
            }

            currentNode = currentNode.parent;
        } while (currentNode != root); // the transform of the root is not accounted for!

        // collapse transform from node to root for each frame of the animation
        var numFrames = modelToRootMatrices.length;

        for (frameId in 0...numFrames) {
            var modelToRoot:Mat4 =   Mat4.identity(new Mat4()) ;// warning: not a copy

           // modelToRoot = new Mat4();

            for (trfInfo in transformsUpToRoot ) {
                var animMatrices = trfInfo.second;
                var matrix = trfInfo.thiree;

                if ( animMatrices.length > 0) {
                    matrix =animMatrices[Math.floor(Math.min(frameId, animMatrices.length - 1))];
                    modelToRoot =  matrix * modelToRoot;
                }
                else if (matrix != null) {
                    modelToRoot = matrix * modelToRoot;
                }
            }

            modelToRootMatrices[frameId]=modelToRoot;
        }
    }

    public function createBone(aibone:AiBone):Bone {
        var boneName = aibone.name ;
        if (aibone == null || (_nameToNode.exists(boneName) ==false) ) {
            return null;
        }

        var offsetMatrix = convertMat4(aibone.offsetMatrix);

        var boneVertexIds:Array<Int> = [for (i in 0...aibone.numWeights) 0];// new List<ushort>(aibone.numWeights, 0);
        var boneVertexWeights:Array<Float> = [for (i in 0...aibone.numWeights) 0.0];// = new List<float>(aibone.numWeights, 0.0f);

        for (i in 0...aibone.numWeights) {
            boneVertexIds[i] = aibone.weights[i].vertexId;
            boneVertexWeights[i] = aibone.weights[i].weight;
        }

        return Bone.create(_nameToNode.get(boneName), offsetMatrix, boneVertexIds, boneVertexWeights);
    }


    public function sampleAnimations(scene:AiScene) {
        _nameToAnimMatrices = new StringMap<Array<Mat4>>();

        if (scene == null) {
            return;
        }

        for (animId in 0... scene.numAnimations) {
            sampleAnimation(scene.animations[animId]);
        }
    }

    public function sampleAnimation(animation:AiAnimation) {
        if (animation == null || animation.ticksPerSecond < 1e-6 || _options.skinningFramerate == 0) {
            return;
        }

        var numFrames :Int=  Math.floor(_options.skinningFramerate * animation.duration / animation.ticksPerSecond);
        numFrames = numFrames < 2 ? 2 : numFrames;

        var timeStep :Float= animation.duration / (numFrames - 1);
        var sampleTimes:Array<Float> = [for (i in 0...numFrames) 0.0];
        for (frameId in 1...numFrames) {
            sampleTimes[frameId] = sampleTimes[frameId - 1] + timeStep;
        }

        for (channelId in 0...animation.numChannels) {
            var nodeAnimation = animation.channels[channelId];
            var nodeName = nodeAnimation.nodeName;
            // According to the ASSIMP documentation, animated nodes should come with existing, unique names.

            if (nodeName != null) {

                _nameToAnimMatrices.set(nodeName, []);// new List<math.mat4>();
//                if (nodeName == "node-G_Circle_rotation_pied") {
//                    var matrices3 = _nameToAnimMatrices.get(nodeName);
//                }
                sample(nodeAnimation, sampleTimes, _nameToAnimMatrices.get(nodeName));
//                var samplematrices:Array<Mat4>=_nameToAnimMatrices.get(nodeName);
//                var samplematrices2:Array<Mat4>=_nameToAnimMatrices.get(nodeName);
            }
        }
    }

    public function sample(nodeAnimation:AiNodeAnim, times:Array<Float>, matrices:Array<Mat4>) {
//Debug.Assert(nodeAnimation);


        #if DEBUG
		//std::cout << "\nsample animation of mesh('" << nodeAnimation->mNodeName.C_Str() << "')" << std::endl;
	#end
//todo
//matrices.Resize(times.Count);

        var sample_position:Vec3;
        var sample_scaling:Vec3;
        var sample_rotation:Quat;
        var sample_rotationMatrix:Mat3;
        // precompute time factors
        var positionKeyTimeFactors:Array<Float> = [for(i in 0...nodeAnimation.numPositionKeys) 0.0];
        var rotationKeyTimeFactors:Array<Float> =[for(i in 0...nodeAnimation.numRotationKeys) 0.0];
        var scalingKeyTimeFactors:Array<Float> =[for(i in 0...nodeAnimation.numScalingKeys) 0.0];
        positionKeyTimeFactors=computeTimeFactors(nodeAnimation.numPositionKeys, nodeAnimation.positionKeys, positionKeyTimeFactors);
        rotationKeyTimeFactors=computeTimeFactors(nodeAnimation.numRotationKeys, nodeAnimation.rotationKeys, rotationKeyTimeFactors);
        scalingKeyTimeFactors=computeTimeFactors(nodeAnimation.numScalingKeys, nodeAnimation.scalingKeys, scalingKeyTimeFactors);

        for (frameId in 0...times.length) {
            var time = times[frameId];

            // sample position from keys
            sample_position = sampleVec3(nodeAnimation.positionKeys, positionKeyTimeFactors, time);

            // sample rotation from keys
            sample_rotation = sampleQuat(nodeAnimation.rotationKeys, rotationKeyTimeFactors, time);
            sample_rotation = Quat.normalize(sample_rotation, new Quat());

            if (sample_rotation.length() == 0.0) {
                sample_rotationMatrix = Mat3.identity(new Mat3());
            }
            else {
                sample_rotationMatrix = Defs.mat3_cast(sample_rotation);
            }

            // sample scaling from keys
            sample_scaling = sampleVec3(nodeAnimation.scalingKeys, scalingKeyTimeFactors, time);

            // recompose the interpolated matrix at the specified  frame
            var arr:Array<Float>=[ sample_scaling.x * sample_rotationMatrix.r0c0, sample_scaling.y * sample_rotationMatrix.r1c0, sample_scaling.z * sample_rotationMatrix.r2c0, 0.0,
            sample_scaling.x * sample_rotationMatrix.r0c1, sample_scaling.y * sample_rotationMatrix.r1c1, sample_scaling.z * sample_rotationMatrix.r2c1, 0.0,
            sample_scaling.x * sample_rotationMatrix.r0c2, sample_scaling.y * sample_rotationMatrix.r1c2, sample_scaling.z * sample_rotationMatrix.r2c2, 0.0,
            sample_position.x, sample_position.y, sample_position.z, 1.0];
            var interpolated_matrix:Mat4= arr;

            matrices[frameId] = interpolated_matrix;

            #if DEBUG
			// std::cout << "\tframeID = " << frameId << "\ttime = " << time << "\nM = " << matrices[frameId]->toString() << std::endl;
	#end
        }
    }

    public function sampleVec3(keys:Array<AiVectorKey>, keyTimeFactors:Array<Float>, time:Float) {
        var output = new Vec3();
        var numKeys = keyTimeFactors.length;
        var id = getIndexForTime(numKeys, keys, time);
        var value0 = keys[id].value;

        if (id == numKeys - 1) {
            output = new Vec3(value0.x, value0.y, value0.z);
        }
        else {
            var w1 = (time - keys[id].time) * keyTimeFactors[id];
            var w0 = 1.0 - w1;
            var value1 = keys[id + 1].value;

            output = new Vec3(w0 * value0.x + w1 * value1.x, w0 * value0.y + w1 * value1.y, w0 * value0.z + w1 * value1.z);
        }

        return output;
    }

    public function sampleQuat(keys:Array<AiQuatKey>, keyTimeFactors:Array<Float>, time:Float) {

        var output = new Quat();
        var numKeys = keyTimeFactors.length;
        var id = getIndexForTime(numKeys, keys, time);
        var value0 = keys[id].value;

        if (id == numKeys - 1) {
            output = new Quat(value0.w, value0.x, value0.y, value0.z);
        }
        else {
            var w1 = (time - keys[id].time) * keyTimeFactors[id];
            var w0 = 1.0 - w1;
            var value1 = keys[id + 1].value;
            var interp = Defs.slerp(value0, value1, w1);
            output = convertQuat(interp);
        }

        return output;
    }

    function computeTimeFactors<T:AiKey>(numKeys:Int, keys:Array<T>, keyTimeFactors:Array<Float>):Array<Float> {
//todo keyTimeFactors.Resize(numKeys);


        if (numKeys == 0 || keys == null) {
            return keyTimeFactors;
        }

        for (keyId in 0... numKeys - 1) {
            keyTimeFactors[keyId] = (1.0 / (keys[keyId + 1].time - keys[keyId].time + 1.401298E-45 ));
        }

        keyTimeFactors[numKeys- 1] = 1.0 ;
        return keyTimeFactors;
    }

    function getIndexForTime<T:AiKey>(numKeys:Int, keys:Array<T>, time:Float):Int {
        if (numKeys == 0 || keys == null) {
            return 0;
        }

        var id :Int= 0;
        var lowerId :Int= 0;
        var upperId :Int= numKeys - 1;
        while (upperId - lowerId > 1) {
            id = (lowerId + upperId) >> 1;
            if (keys[id].time > time) {
                upperId = id;
            }
            else {
                lowerId = id;
            }
        }

        return lowerId;
    }
    inline function convertVec3( vec3:AiVector3D)
    {
        return vec3;
    }
    inline function  convertQuat(  quaternion:AiQuaternion)
    {
        return quaternion;
    }
    public function convertMat4( matrix:AiMatrix4x4)
    {
        // Assimp aiMatrix4x4 are row-major meanwhile
        // glm mat4 are column-major (so are OpenGL matrices)

        var arr=matrix.toFloatArray();

        var m:AiMatrix4x4 = new AiMatrix4x4(
            arr[ 0], arr[ 1], arr[ 2], arr[3],
            arr[ 4], arr[ 5], arr[ 6], arr[7],
            arr[ 8], arr[ 9], arr[10], arr[11],
            arr[ 12], arr[ 13], arr[14], arr[15]
        );
        return m;
    }
//    public function convert(scaling:AiVector3D, quaternion:AiQuaternion, translation:AiVector3D) {
//        var output = new Mat4();
//
//        var convert_rotation:Quat;
//        var convert_rotationMatrix:Mat4;
//
//        convert_rotationMatrix = math.mat4_cast(Quat.normalize((quaternion), new Quat()));
//        var rotationData = convert_rotationMatrix;
//
//        return new Mat4(scaling.x * rotationData[0][0], scaling.y * rotationData[0][1], scaling.z * rotationData[0][2], 0.0,
//        scaling.x * rotationData[1][0], scaling.y * rotationData[1][1], scaling.z * rotationData[1][2], 0.0,
//        scaling.x * rotationData[2][0], scaling.y * rotationData[2][1], scaling.z * rotationData[2][2], 0.0,
//        translation.x, translation.y, translation.z, 1.0);
//    }

    public function createMaterial(aiMat:AiMaterial):Material {
        var existingMaterial = _aiMaterialToMaterial.exists(aiMat);

        if (existingMaterial != false) {
            return _aiMaterialToMaterial.get(aiMat);
        }

        var material:Material = chooseMaterialByShadingMode(aiMat);

        if (aiMat == null) {
            return material;
        }

        var materialName = "";

        var rawMaterialName = "";
        if (aiMat.hasProperty(AiMatKeys.NAME)) {
            rawMaterialName = aiMat.getProperty(AiMatKeys.NAME).getStringValue();
            materialName = rawMaterialName;
        }

        materialName = getMaterialName(materialName);

        var blendingMode = getBlendingMode(aiMat);
        var srcBlendingMode:Source = ( blendingMode & 0x00ff);
        var dstBlendingMode:Destination = ( blendingMode & 0xff00);

        material.data.set("blendingMode", blendingMode);
        material.data.set(States.PROPERTY_BLENDING_SOURCE, srcBlendingMode);
        material.data.set(States.PROPERTY_BLENDING_DESTINATION, dstBlendingMode);
        material.data.set("triangleCulling", getTriangleCulling(aiMat));
        material.data.set("wireframe", getWireframe(aiMat)); // bool

        if ((blendingMode & Destination.ZERO) == 0) {
            material.data.set("priority", Priority.TRANSPARENT);
            material.data.set("zSorted", true);
        }
        else {
            material.data.set("priority", Priority.OPAQUE);
            material.data.set("zSorted", false);
        }

        var opacity = setScalarProperty(material, "opacity", aiMat, AiMatKeys.OPACITY, 1.0);
        var shininess = setScalarProperty(material, "shininess", aiMat, AiMatKeys.SHININESS, 0.0);
        var reflectivity = setScalarProperty(material, "reflectivity", aiMat, AiMatKeys.REFLECTIVITY, 1.0);
        var shininessStr = setScalarProperty(material, "shininessStrength", aiMat, AiMatKeys.SHININESS_STRENGTH, 1.0);
        var refractiveIdx = setScalarProperty(material, "refractiveIndex", aiMat, AiMatKeys.REFRACTI, 1.0);
        var bumpScaling = setScalarProperty(material, "bumpScaling", aiMat, AiMatKeys.BUMPSCALING, 1.0);
        var defaultValue:Vec4=new Vec4(0,0,0,1);
        var diffuseColor = setColorProperty(material, "diffuseColor", aiMat, AiMatKeys.COLOR_DIFFUSE, defaultValue);
        var specularColor = setColorProperty(material, "specularColor", aiMat, AiMatKeys.COLOR_SPECULAR, defaultValue);
        var ambientColor = setColorProperty(material, "ambientColor", aiMat, AiMatKeys.COLOR_AMBIENT, defaultValue);
        var emissiveColor = setColorProperty(material, "emissiveColor", aiMat, AiMatKeys.COLOR_EMISSIVE, defaultValue);
        var reflectiveColor = setColorProperty(material, "reflectiveColor", aiMat, AiMatKeys.COLOR_REFLECTIVE, defaultValue);
        var transparentColor = setColorProperty(material, "transparentColor", aiMat, AiMatKeys.COLOR_TRANSPARENT, defaultValue);

        var epsilon = 0.1;

        var hasSpecular = ((!MathUtil.vec4_equals(specularColor, new Vec4()) && specularColor.w > 0.0)
        || aiMat.getMaterialTextureCount(AiTextureType.specular) >= 1 )
        && shininess > (1.0 + epsilon);

        if (!hasSpecular) {
            // Gouraud-like shading (-> no specular)

            material.data.unset("shininess");
            specularColor.w = 0.0;
        }

        var transparent = opacity > 0.0 && opacity < 1.0;

        if (transparent) {
            diffuseColor.w = opacity;
            if (hasSpecular) {
                specularColor.w = opacity;
            }
            ambientColor.w = opacity;
            emissiveColor.w = opacity;
            reflectiveColor.w = opacity;
            transparentColor.w = opacity;

            material.data.set("diffuseColor", diffuseColor);
            if (hasSpecular) {
                material.data.set("specularColor", specularColor);
            }
            material.data.set("ambientColor", ambientColor);
            material.data.set("emissiveColor", emissiveColor);
            material.data.set("reflectiveColor", reflectiveColor);
            material.data.set("transparentColor", transparentColor);

            enableTransparency(material);
        }

        for (textureType in AbstractASSIMPParser._textureTypeToName.keys()) {
            var textureName = AbstractASSIMPParser._textureTypeToName.get(textureType);
            var numTextures = aiMat.getMaterialTextureCount(textureType);

            if (numTextures == 0) {
                continue;
            }

            var path = new AiMaterialTexture();
            //todo
            if (aiMat.getMaterialTexture(textureType, 0, path)) {
                var textureFilename = path.file;
                var textureAssetNameIt = _textureFilenameToAssetName.exists(textureFilename);

                if (textureAssetNameIt == false) {
                    continue;
                }

                var textureAssetName = _textureFilenameToAssetName.get(textureFilename);
                var texture = _assetLibrary.texture(textureAssetName);
                var textureIsValid = texture != null;
                texture = cast(_options.textureFunction(textureAssetName, texture));
                if (!textureIsValid && texture != null) {
                    _assetLibrary.setTexture(textureAssetName, texture);
                }

                if (texture != null) {
                    material.data.set(textureName, texture);
                    textureSet(material, textureName, texture);
                }
            }
        }

        var createMaterial_materialNameId:Int = 0;
        var uniqueMaterialName = materialName;
        while (_assetLibrary.material(uniqueMaterialName) != null) {
            uniqueMaterialName = materialName + "_" + (createMaterial_materialNameId++);
        }
        material.data.set("name", uniqueMaterialName);
        var processedMaterial = _options.materialFunction(uniqueMaterialName, material);
        _aiMaterialToMaterial.set(aiMat, processedMaterial) ;
        _assetLibrary.setMaterial(uniqueMaterialName, processedMaterial);
        return processedMaterial;
    }



    public function textureSet(material:Material, textureTypeName:String, texture:AbstractTexture) {
        // Alpha map
        if (textureTypeName == AbstractASSIMPParser._textureTypeToName.get(AiTextureType.opacity)) {
            enableTransparency(material);

            if (!material.data.hasProperty("alphaThreshold")) {
                material.data.set("alphaThreshold", .5);
            }
        }
    }


    public function chooseMaterialByShadingMode(aiMat:AiMaterial):Material {
        if (aiMat == null &&_options.material != null) {
            return Material.createbyMaterial(_options.material);
        }
//        aiShadingMode shading_mode = aiShadingMode_Flat;
//        if (mat.Get(AI_MATKEY_SHADING_MODEL, shading_mode) == AI_SUCCESS) {
//            ChunkWriter chunk(writer, Discreet3DS::CHUNK_MAT_SHADING);
//
//            Discreet3DS::shadetype3ds shading_mode_out;
//            switch(shading_mode) {
//            case aiShadingMode_Flat:
//            case aiShadingMode_NoShading:
//            shading_mode_out = Discreet3DS::Flat;
//            break;
//
//            case aiShadingMode_Gouraud:
//            case aiShadingMode_Toon:
//            case aiShadingMode_OrenNayar:
//            case aiShadingMode_Minnaert:
//            shading_mode_out = Discreet3DS::Gouraud;
//            break;
//
//            case aiShadingMode_Phong:
//            case aiShadingMode_Blinn:
//            case aiShadingMode_CookTorrance:
//            case aiShadingMode_Fresnel:
//            shading_mode_out = Discreet3DS::Phong;
//            break;
//
//            default:
//            shading_mode_out = Discreet3DS::Flat;
//            ai_assert(false);
//            };
//            writer.PutU2(static_cast<uint16_t>(shading_mode_out));
//        }

        if (aiMat.hasProperty(AiMatKeys.SHADING_MODEL)) {

            var shadingMode:Int = aiMat.getProperty(AiMatKeys.SHADING_MODEL).getIntegerValue();
            switch (shadingMode)
            {
                case AiShadingMode.flat:
                    return BasicMaterial.create();

                case AiShadingMode.phong
                | AiShadingMode.blinn
                | AiShadingMode.cookTorrance
                | AiShadingMode.fresnel
                | AiShadingMode.toon
                | AiShadingMode.gouraud
                | AiShadingMode.orenNayar
                | AiShadingMode.minnaert:
                    return PhongMaterial.create();

                //case AiShadingMode.noShading:
                default:
                    return Material.createbyMaterial(_options.material);
            }
        }
        else {
            return Material.createbyMaterial(_options.material);
        }
    }

    public function chooseEffectByShadingMode(aiMat:AiMaterial):Effect {
        var effect:Effect = _options.effect;

        if (effect == null && aiMat != null) {


            if (aiMat.hasProperty(AiMatKeys.SHADING_MODEL)) {
                var shadingMode:Int = aiMat.getProperty(AiMatKeys.SHADING_MODEL).getIntegerValue() ;
                switch ( shadingMode)
                {
                    case AiShadingMode.flat:
                    case AiShadingMode.gouraud:
                    case AiShadingMode.toon:
                    case AiShadingMode.orenNayar:
                    case AiShadingMode.minnaert:
                        if (_assetLibrary.effect("effect/Basic.effect") != null) {
                            effect = _assetLibrary.effect("effect/Basic.effect");
                        }
                        else {
                            LOG_ERROR("Basic effect not available in the asset library.");
                        }

                    case AiShadingMode.phong:
                    case AiShadingMode.blinn:
                    case AiShadingMode.cookTorrance:
                    case AiShadingMode.fresnel:
                        if (_assetLibrary.effect("effect/Phong.effect") != null) {
                            effect = _assetLibrary.effect("effect/Phong.effect");
                        }
                        else {
                            LOG_ERROR("Phong effect not available in the asset library.");
                        }
                    case AiShadingMode.noShading:
                    default: {

                    }
                }
            }
        }

        // apply effect function
        return _options.effectFunction(effect);
    }

    public function getBlendingMode(aiMat:AiMaterial):minko.render.Blending.Mode {
        var blendMode:Int;
        if (aiMat != null && aiMat.hasProperty(AiMatKeys.BLEND_FUNC)) {
            blendMode = aiMat.getProperty(AiMatKeys.BLEND_FUNC).getIntegerValue();
            switch ( blendMode)
            {
                case AiBlendMode.alpha: // src * alpha + dst * (1 - alpha)
                    return minko.render.Blending.Mode.ALPHA;
                case AiBlendMode.additive:
                    return minko.render.Blending.Mode.ADDITIVE;
                default:
                    return minko.render.Blending.Mode.DEFAULT;
            }
        }
        else {
            return minko.render.Blending.Mode.DEFAULT;
        }
    }

    public function getTriangleCulling(aiMat:AiMaterial):TriangleCulling {
        var twoSided:Int;
        if (aiMat != null && aiMat.hasProperty(AiMatKeys.TWOSIDED)) {
            twoSided = aiMat.getProperty(AiMatKeys.TWOSIDED).getIntegerValue();
            return twoSided == 0 ? TriangleCulling.NONE : TriangleCulling.BACK;
        }
        else {
            return TriangleCulling.BACK;
        }
    }


    public function getWireframe(aiMat:AiMaterial):Bool {
        var wireframe:Int = 0;
        if (aiMat != null && aiMat.hasProperty(AiMatKeys.TWOSIDED)) {
            wireframe = aiMat.getProperty(AiMatKeys.TWOSIDED).getIntegerValue();
        }
        return wireframe != 0 ;
    }

    public function setColorProperty(material:Material, propertyName:String, aiMat:AiMaterial, aiMatKeyName:String, defaultValue:Vec4):Vec4 {
//Debug.Assert(material != null && aiMat != null);

        var color = new AiColor4D();
        color.r = defaultValue.x;
        color.g = defaultValue.y;
        color.b = defaultValue.z;
        color.a = defaultValue.w;
        if (aiMat != null && aiMat.hasProperty(aiMatKeyName)) {
            var property=aiMat.getProperty(aiMatKeyName);
            color = property.getColor4DValue();
        }
        material.data.set(propertyName, new Vec4(color.r, color.g, color.b, color.a));

        return cast material.data.get(propertyName);
    }

    public function setScalarProperty(material:Material, propertyName:String, aiMat:AiMaterial, aiMatKeyName:String, defaultValue:Float) {
//Debug.Assert(material != null && aiMat != null);

        var scalar = defaultValue;
        if (aiMat != null && aiMat.hasProperty(aiMatKeyName)) {
            scalar = aiMat.getProperty(aiMatKeyName).getFloatValue();
        }
        material.data.set(propertyName, scalar);

        return cast material.data.get(propertyName);
    }

    public function createAnimations(scene:AiScene, interpolate:Bool) {
        if (scene.numAnimations == 0) {
            return;
        }

        sampleAnimations(scene); //re done

        if (Lambda.empty(_nameToAnimMatrices)) {
            return;
        }

        var nodeToTimelines:ObjectMap<Node, Array<AbstractTimeline>> = new ObjectMap<Node, Array<AbstractTimeline>>();
        for (nameToMatricesPair in _nameToAnimMatrices.keys()) {
            var node = _nameToNode.get(nameToMatricesPair);
            nodeToTimelines.set(node, []);
        }
        for (nameToMatricesPair in _nameToAnimMatrices.keys()) {
            var node = _nameToNode.get(nameToMatricesPair);
            var ainode = _nodeToAiNode.get(node);
            var aiParentNode = ainode;

            var isSkinned = false;

            while (aiParentNode != null && !isSkinned) {
                for (i in 0... aiParentNode.numMeshes) {
                    var meshId = aiParentNode.meshes[i];

                    isSkinned = isSkinned || scene.meshes[meshId].numBones > 0 ;
                }

                aiParentNode = aiParentNode.parent;
            }

            if (isSkinned) {
                continue;
            }

            var matrices: Array<Mat4> = _nameToAnimMatrices.get(nameToMatricesPair);

            var numFrames = matrices.length;
            var duration = numFrames * _options.skinningFramerate ;

            var timetable = [for (i in 0...numFrames) 0];//new List<uint>(numFrames, 0u);

            var timeStep = duration / (numFrames - 1);

            for (frameId in 1...numFrames) {
                timetable[frameId] = Std.int(timetable[frameId - 1] + timeStep);
            }

            nodeToTimelines.get(node).push(Matrix4x4Timeline.create(AbstractASSIMPParser.PNAME_TRANSFORM, duration, timetable, matrices, interpolate));
        }

        //actual  bone node animation
        // fixme: find actual animation root
        var animationRootNode = _nameToNode.get(_nameToAnimMatrices.keys().next()).root;

        for (nodeAndTimelines in nodeToTimelines.keys()) {
            var second=nodeToTimelines.get(nodeAndTimelines);
            nodeAndTimelines.addComponent(Animation.create(second));
        }

        if (!animationRootNode.hasComponent(MasterAnimation)) {
            animationRootNode.addComponent(MasterAnimation.create());
        }
    }

    public function enableTransparency(material:Material) {
        material.data.set("priority", Priority.TRANSPARENT);
        material.data.set("zSorted", true);

        var blendingMode = minko.render.Blending.Mode.ALPHA;
        var srcBlendingMode:Source = (blendingMode & 0x00ff);
        var dstBlendingMode:Destination = (blendingMode & 0xff00);
        material.data.set("blendingMode", blendingMode);
        material.data.set(States.PROPERTY_BLENDING_SOURCE, srcBlendingMode);
        material.data.set(States.PROPERTY_BLENDING_DESTINATION, dstBlendingMode);
    }

}