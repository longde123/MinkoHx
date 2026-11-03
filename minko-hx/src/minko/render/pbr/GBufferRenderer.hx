package minko.render.pbr;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.StringMap;
import minko.geometry.Geometry;
import minko.material.PBRMaterial;
import minko.render.AbstractContext;
import minko.render.Blending;
import minko.render.CompareMode;
import minko.render.Program;
import minko.render.Shader;
import minko.render.Shader.ShaderType;
import minko.render.TriangleCulling;
import minko.render.VertexAttribute;
import minko.render.pipeline.EffectStage;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.PipelineEffectRenderer;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.GBuffer;

/**
 * Writes the opaque scene into the G-Buffer attachments.
 *
 * With native MRT this is one draw per item into the bound GBuffer target.
 * The multipass fallback is expected to bind target 0/1/2 and call drawItem()
 * three times with a material/shader variant.
 */
class GBufferRenderer {
    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _uniforms:StringMap<Int>;
    private var _pipelineEffects:PipelineEffectRenderer;
    private var _floatScratch:Array<Float>;
    private var _matrixScratch:Array<Float>;

    public function new(context:AbstractContext) {
        _context = context;
        _uniforms = new StringMap<Int>();
        _pipelineEffects = new PipelineEffectRenderer(context);
        _floatScratch = [0.0, 0.0, 0.0, 0.0];
        _matrixScratch = [for (i in 0...16) 0.0];

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.forwardVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PBRShaderLibrary.gbufferFragment());
        _vertexShader.upload();
        _fragmentShader.upload();

        _program = Program.createbyShader("PBRGBuffer", context, _vertexShader, _fragmentShader);
        _program.upload();
        for (uniform in _program.inputs.uniforms) {
            _uniforms.set(uniform.name, uniform.location);
        }
    }

    public function render(queue:RenderQueue, frame:FrameContext, gbuffer:GBuffer):Void {
        if (_program == null || gbuffer == null) {
            return;
        }
        gbuffer.bindGBuffer(_context);

        // The G-buffer must not inherit render state from whatever ran before
        // it. In particular ALPHA blending left by a previous forward pass
        // multiplies the normal attachment by its alpha channel (roughness) and
        // the emissive attachment by metallic, corrupting both.
        _context.setColorMask(true);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.BACK);
        _context.clear(0.0, 0.0, 0.0, 1.0, 1.0, 0);

        _context.setProgram(_program.id);
        setMatrix("viewMatrix", frame.viewMatrix);
        setMatrix("projectionMatrix", frame.projectionMatrix);

        for (item in queue.opaque) {
            drawPipelineItem(item, frame);
        }
        for (item in queue.alphaTest) {
            drawPipelineItem(item, frame);
        }
    }

    private function drawPipelineItem(item:RenderItem, frame:FrameContext):Void {
        applyDefaultState();
        if (item.pipelineEffect != null && _pipelineEffects.draw(item, item.pipelineEffect, EffectStage.GBuffer, frame)) {
            return;
        }
        drawItem(item, frame);
    }

    private function applyDefaultState():Void {
        _context.setColorMask(true);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setTriangleCulling(TriangleCulling.BACK);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
    }

    private function drawItem(item:RenderItem, frame:FrameContext):Void {
        var geometry = item.geometry;
        if (geometry == null || geometry.indices == null) {
            return;
        }

        // A PipelineEffect draw may have switched the active program.
        _context.setProgram(_program.id);

        var material = item.material;
        var baseColor:Vec4 = material != null && material.hasProperty(PBRMaterial.BASE_COLOR)
            ? cast material.get(PBRMaterial.BASE_COLOR)
            : new Vec4(1.0, 1.0, 1.0, 1.0);
        var metallic:Float = material != null && material.hasProperty(PBRMaterial.METALLIC)
            ? cast material.get(PBRMaterial.METALLIC)
            : 0.0;
        var roughness:Float = material != null && material.hasProperty(PBRMaterial.ROUGHNESS)
            ? cast material.get(PBRMaterial.ROUGHNESS)
            : 0.5;
        var emissive:Vec3 = material != null && material.hasProperty(PBRMaterial.EMISSIVE)
            ? cast material.get(PBRMaterial.EMISSIVE)
            : new Vec3(0.0, 0.0, 0.0);

        var world = item.worldMatrix != null ? item.worldMatrix : Mat4.identity(new Mat4());
        setMatrix("modelMatrix", world);
        if (item.normalMatrix == null) {
            item.normalMatrix = PBRMath.normalMatrix(world, new Mat4());
        }
        setMatrix("normalMatrix", item.normalMatrix);
        setFloat4("uBaseColor", baseColor);
        setFloat("uMetallic", metallic);
        setFloat("uRoughness", roughness);
        setFloat3("uEmissive", emissive);

        for (attribute in _program.inputs.attributes) {
            var vertexAttribute:VertexAttribute = geometry.getVertexAttribute(attribute.name);
            if (vertexAttribute != null) {
                _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size, vertexAttribute.vertexSize, vertexAttribute.offset);
            }
        }

        _context.drawIndexBufferTriangles(geometry.indices.id, 0, Math.floor(geometry.indices.numIndices / 3));
    }

    private function setFloat(name:String, value:Float):Void {
        var location = _uniforms.get(name);
        if (location != null) {
            _floatScratch[0] = value;
            _context.setUniformFloat(location, 1, _floatScratch);
        }
    }

    private function setFloat3(name:String, value:Vec3):Void {
        var location = _uniforms.get(name);
        if (location != null) {
            PBRMath.writeVec3(value, _floatScratch);
            _context.setUniformFloat3(location, 1, _floatScratch);
        }
    }

    private function setFloat4(name:String, value:Vec4):Void {
        var location = _uniforms.get(name);
        if (location != null) {
            PBRMath.writeVec4(value, _floatScratch);
            _context.setUniformFloat4(location, 1, _floatScratch);
        }
    }

    private function setMatrix(name:String, value:Mat4):Void {
        var location = _uniforms.get(name);
        if (location != null) {
            PBRMath.writeMat4(value, _matrixScratch);
            _context.setUniformMatrix4x4(location, 1, _matrixScratch);
        }
    }

    public function dispose():Void {
        if (_pipelineEffects != null) {
            _pipelineEffects.dispose();
            _pipelineEffects = null;
        }
        if (_program != null) {
            _program.dispose();
            _program = null;
        }
        if (_vertexShader != null) {
            _vertexShader.dispose();
            _vertexShader = null;
        }
        if (_fragmentShader != null) {
            _fragmentShader.dispose();
            _fragmentShader = null;
        }
        _uniforms = null;
        _context = null;
    }
}
