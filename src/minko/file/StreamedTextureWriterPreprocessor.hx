package minko.file;
import glm.Vec2;
import glm.Vec3;
import glm.Vec4;
import haxe.io.Bytes;
import minko.component.Surface;
import minko.component.TextureLodScheduler;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.render.Texture;
import minko.render.TextureFormat;
import minko.render.VertexBuffer;
import minko.scene.Node;
import minko.scene.NodeSet;
import minko.signal.Signal2;
import minko.utils.MathUtil;
class Options {
    private static var InstanceFieldsInitialized = false;

    private function InitializeInstanceFields() {
        all = computeVertexColor | smoothVertexColor;
    }

    private static var none = 0;

    private static var computeVertexColor = 1 << 0;
    private static var smoothVertexColor = 1 << 1;

    private static var all;

    private var flags;

    public function new() {
        if (!InstanceFieldsInitialized) {
            InitializeInstanceFields();
            InstanceFieldsInitialized = true;
        }
        this.flags = none;
    }
}

class StreamedTextureWriterPreprocessor extends AbstractWriterPreprocessor<Node> {

    private var _options:Options;

    private var _statusChanged:Signal2<AbstractWriterPreprocessor<Node>, String>;

    override public function get_statusChanged() {
        return _statusChanged;
    }

    public static function create() {
        var instance = (new StreamedTextureWriterPreprocessor());

        return instance;
    }
    public var options(null, set):Options;

    function set_options(op) {
        _options.copyFrom(op);
        return op;
    }
    public var progressRate(get, null):Float;

    function get_progressRate() {
        return 1.0;
    }


    private static function packColor(color:Vec3):Vec3 {
        return Vec3.dot(color, new Vec3(1.0, 1.0 / 255.0, 1.0 / 65025.0), new Vec3());
    }

    public function new() {
        super();
        this._statusChanged = new Signal2<AbstractWriterPreprocessor<Node>, String>();
    }

    public function process(node:Node, assetLibrary:AssetLibrary) {
        node.addComponent(TextureLodScheduler.create(assetLibrary));

        if ((_options.flags & Options.computeVertexColor) != 0) {
            computeVertexColorAttributes(node, assetLibrary);
        }
    }

    public function computeVertexColorAttributes(node:Node, assetLibrary:AssetLibrary) {
        var surfaceNodes:NodeSet = NodeSet.create(node).descendants(true).where(function(descendant:Node) {
            return descendant.hasComponent(Surface);
        });

        for (surfaceNode in surfaceNodes.nodes()) {
            var surfaces:Array<Surface> = surfaceNode.getComponents(Surface);
            for (surface in surfaces) {
                var geometry = surface.geometry;
                var material = surface.material;

                if (geometry.hasVertexAttribute("uv") && material.data.hasProperty("diffuseMap")) {
                    computeVertexColorAttributes(geometry, material, assetLibrary);
                }
            }
        }
    }

    public function computeVertexColorAttributes(geometry:Geometry, material:Material, assetLibrary:AssetLibrary) {
        var __diffuseMap:Texture = material.data.get("diffuseMap");
        var diffuseMap:Texture = (assetLibrary.getTextureByUuid(__diffuseMap.sampler.uuid, true));

        if (diffuseMap == null) {
            return;
        }

        var format = diffuseMap.format;

        var numComponents = 0;

        if (format == TextureFormat.RGB) {
            numComponents = 3;
        }
        else if (format == TextureFormat.RGBA) {
            numComponents = 4;
        }
        else {
            return;
        }

        var textureData = diffuseMap.data ;

        var uvVertexBuffer = geometry.vertexBuffer("uv");
        var uvVertexAttribute = uvVertexBuffer.attribute("uv");

        var numVertices = uvVertexBuffer.numVertices;

        var colorVertexBuffer:VertexBuffer = null;

        if (geometry.hasVertexAttribute("color")) {
            colorVertexBuffer = geometry.vertexBuffer("color");
        }

        var colorVertexAttributeOffset = 0;
        var colorVertexAttributeSize = 1;
        var colorVertexBufferVertexSize = colorVertexAttributeSize;

        var defaultColorVertexBufferData = new Array<Float>();

        var colorVertexBufferData = 0;

        if (colorVertexBuffer != null) {
            var colorVertexAttribute = colorVertexBuffer.attribute("color");

            colorVertexAttributeOffset = colorVertexAttribute.offset;
            colorVertexAttributeSize = colorVertexAttribute.size;
            colorVertexBufferVertexSize = colorVertexAttribute.vertexSize;

            colorVertexBufferData = colorVertexBuffer.data;
        }
        else {
            //todo
//defaultColorVertexBufferData.resize(numVertices * colorVertexBufferVertexSize);

            colorVertexBufferData = defaultColorVertexBufferData ;
        }

        for (i in 0...numVertices) {
            var uvIndex = i * uvVertexAttribute.vertexSize + uvVertexAttribute.offset;
            var colorIndex = i * colorVertexBufferVertexSize + colorVertexAttributeOffset;

            var uv = MathUtil.make_vec2(uvVertexBuffer.data[uvIndex]);

            var color = new Vec4(0.0, 0.0, 0.0, 1.0);

            sampleColor(diffuseMap.width, diffuseMap.height, numComponents, textureData, uv, color);

            var packedColor = packColor(color).toFloatArray();

            for (j in 0...colorVertexAttributeSize) {
                colorVertexBufferData[colorIndex + j] = packedColor[j];
            }
        }

        if (colorVertexBuffer == null) {
            var colorVertexBuffer = VertexBuffer.create(assetLibrary.context, colorVertexBufferData, colorVertexBufferData + numVertices * colorVertexBufferVertexSize);

            colorVertexBuffer.addAttribute("color", colorVertexAttributeSize, colorVertexAttributeOffset);

            geometry.addVertexBuffer(colorVertexBuffer);
        }
    }

    public function sampleColor(width, height, numComponents, textureData:Bytes, uv:Vec2, color:Vec4) {
        if ((_options.flags & Options.smoothVertexColor) != 0) {
            // fixme: apply bilinear filtering
        }
        else {
            var normalizedU = MathUtil.fract(uv.x);//uv.s
            var normalizedV = MathUtil.fract(uv.y);//uv.t

            normalizedU = normalizedU < 0.0 ? 1.0 - normalizedU : normalizedU;
            normalizedV = normalizedV < 0.0 ? 1.0 - normalizedV : normalizedV;

            var x = Math.floor(normalizedU * width);
            var y = Math.floor(normalizedV * height);

            var index = (x + y * width) * numComponents;

            for (i in 0... numComponents) {
                color[i] = textureData[index + i] / 255.0 ;
            }
        }
    }

}
