package minko.render.pbr;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.StringMap;
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
import minko.render.target.RenderTarget;

/**
 * Multipass G-Buffer fallback for backends without MRT.
 *
 * Renders opaque geometry three times, once per attachment. The shaders are
 * single-output variants of the MRT G-Buffer shader.
 */
class GBufferFallbackRenderer {
    private var _context:AbstractContext;
    private var _programs:Array<Program>;
    private var _uniformMaps:Array<StringMap<Int>>;
    private var _vertexShaders:Array<Shader>;
    private var _fragmentShaders:Array<Shader>;
    private var _floatScratch:Array<Float>;
    private var _matrixScratch:Array<Float>;
    private var _pipelineEffects:PipelineEffectRenderer;

    public function new(context:AbstractContext) {
        _context = context;
        _programs = [];
        _uniformMaps = [];
        _vertexShaders = [];
        _fragmentShaders = [];
        _floatScratch = [0.0, 0.0, 0.0, 0.0];
        _matrixScratch = [for (i in 0...16) 0.0];
        _pipelineEffects = new PipelineEffectRenderer(context);

        addProgram("GBufferAlbedo", PBRShaderLibrary.gbufferAlbedoFragment());
        addProgram("GBufferNormal", PBRShaderLibrary.gbufferNormalFragment());
        addProgram("GBufferEmissive", PBRShaderLibrary.gbufferEmissiveFragment());
    }

    private function addProgram(name:String, fragmentSource:String):Void {
        var vertexShader = Shader.createbySource(_context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.forwardVertex());
        var fragmentShader = Shader.createbySource(_context, ShaderType.FRAGMENT_SHADER, fragmentSource);
        vertexShader.upload();
        fragmentShader.upload();
        var program = Program.createbyShader(name, _context, vertexShader, fragmentShader);
        program.upload();
        var uniforms = new StringMap<Int>();
        for (uniform in program.inputs.uniforms) {
            uniforms.set(uniform.name, uniform.location);
        }
        _vertexShaders.push(vertexShader);
        _fragmentShaders.push(fragmentShader);
        _programs.push(program);
        _uniformMaps.push(uniforms);
    }

    public function render(queue:RenderQueue, frame:FrameContext, gbuffer:GBuffer):Void {
        if (gbuffer == null || gbuffer.albedo == null || gbuffer.normal == null || gbuffer.emissive == null) {
            return;
        }
        renderPass(0, gbuffer.albedo, queue, frame);
        renderPass(1, gbuffer.normal, queue, frame);
        renderPass(2, gbuffer.emissive, queue, frame);
    }

    private function renderPass(index:Int, target:RenderTarget, queue:RenderQueue, frame:FrameContext):Void {
        var program = _programs[index];
        var uniforms = _uniformMaps[index];

        target.bind(_context, true);

        // Same state isolation as the MRT path: never inherit blending or
        // depth state from a previous pass.
        _context.setColorMask(true);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.BACK);
        _context.clear(0.0, 0.0, 0.0, 1.0, 1.0, 0);
        _context.setProgram(program.id);

        setMatrix(uniforms, "viewMatrix", frame.viewMatrix);
        setMatrix(uniforms, "projectionMatrix", frame.projectionMatrix);

        var stage = index == 0 ? EffectStage.GBufferAlbedo
            : index == 1 ? EffectStage.GBufferNormal
            : EffectStage.GBufferEmissive;

        for (item in queue.opaque) {
            if (item.pipelineEffect != null) {
                if (_pipelineEffects.draw(item, item.pipelineEffect, stage, frame)) {
                    continue;
                }
                if (_pipelineEffects.drawFallback(item, item.pipelineEffect, index, frame)) {
                    continue;
                }
            }
            drawItem(program, uniforms, item, frame);
        }
        for (item in queue.alphaTest) {
            if (item.pipelineEffect != null) {
                if (_pipelineEffects.draw(item, item.pipelineEffect, stage, frame)) {
                    continue;
                }
                if (_pipelineEffects.drawFallback(item, item.pipelineEffect, index, frame)) {
                    continue;
                }
            }
            drawItem(program, uniforms, item, frame);
        }

        target.unbind(_context);
    }

    private function drawItem(program:Program, uniforms:StringMap<Int>, item:RenderItem, frame:FrameContext):Void {
        var geometry = item.geometry;
        if (geometry == null || geometry.indices == null) {
            return;
        }

        // A PipelineEffect draw may have switched the active program/state.
        _context.setProgram(program.id);
        applyPassState();

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
        setMatrix(uniforms, "modelMatrix", world);
        if (item.normalMatrix == null) {
            item.normalMatrix = PBRMath.normalMatrix(world, new Mat4());
        }
        setMatrix(uniforms, "normalMatrix", item.normalMatrix);
        setFloat4(uniforms, "uBaseColor", baseColor);
        setFloat(uniforms, "uMetallic", metallic);
        setFloat(uniforms, "uRoughness", roughness);
        setFloat3(uniforms, "uEmissive", emissive);

        for (attribute in program.inputs.attributes) {
            var vertexAttribute:VertexAttribute = geometry.getVertexAttribute(attribute.name);
            if (vertexAttribute != null) {
                _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size, vertexAttribute.vertexSize, vertexAttribute.offset);
            }
        }

        _context.drawIndexBufferTriangles(geometry.indices.id, 0, Math.floor(geometry.indices.numIndices / 3));
    }

    private function setFloat(uniforms:StringMap<Int>, name:String, value:Float):Void {
        var location = uniforms.get(name);
        if (location != null) {
            _floatScratch[0] = value;
            _context.setUniformFloat(location, 1, _floatScratch);
        }
    }

    private function setFloat3(uniforms:StringMap<Int>, name:String, value:Vec3):Void {
        var location = uniforms.get(name);
        if (location != null) {
            PBRMath.writeVec3(value, _floatScratch);
            _context.setUniformFloat3(location, 1, _floatScratch);
        }
    }

    private function setFloat4(uniforms:StringMap<Int>, name:String, value:Vec4):Void {
        var location = uniforms.get(name);
        if (location != null) {
            PBRMath.writeVec4(value, _floatScratch);
            _context.setUniformFloat4(location, 1, _floatScratch);
        }
    }

    private function setMatrix(uniforms:StringMap<Int>, name:String, value:Mat4):Void {
        var location = uniforms.get(name);
        if (location != null) {
            PBRMath.writeMat4(value, _matrixScratch);
            _context.setUniformMatrix4x4(location, 1, _matrixScratch);
        }
    }

    private function applyPassState():Void {
        _context.setColorMask(true);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.BACK);
    }

    public function dispose():Void {
        if (_pipelineEffects != null) {
            _pipelineEffects.dispose();
            _pipelineEffects = null;
        }
        for (program in _programs) {
            if (program != null) program.dispose();
        }
        for (shader in _vertexShaders) {
            if (shader != null) shader.dispose();
        }
        for (shader in _fragmentShaders) {
            if (shader != null) shader.dispose();
        }
        _programs = [];
        _uniformMaps = [];
        _vertexShaders = [];
        _fragmentShaders = [];
        _context = null;
    }
}
