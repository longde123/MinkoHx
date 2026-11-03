package minko.render.pipeline;

import glm.Mat4;
import glm.Mat4.Mat4Base;
import glm.Vec2;
import glm.Vec2.Vec2Base;
import glm.Vec3;
import glm.Vec3.Vec3Base;
import glm.Vec4;
import glm.Vec4.Vec4Base;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import StringBuf;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.CompareMode;
import minko.render.MipFilter;
import minko.render.Program;
import minko.render.ProgramInputs.InputType;
import minko.render.ProgramInputs.UniformInput;
import minko.render.Shader;
import minko.render.Shader.ShaderType;
import minko.render.TextureFilter;
import minko.render.WrapMode;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.render.pbr.PBRMath;

/**
 * Draws RenderItems that carry a PipelineEffect.
 *
 * One PipelineTechnique is one compiled Program, uniforms are resolved from the
 * technique's UniformSource list, and vertex attributes are bound by their
 * Geometry name.
 *
 * The renderer does not bind render targets, clear them or configure viewports;
 * the calling render path is responsible for that.
 */
class PipelineEffectRenderer {
    private var _context:AbstractContext;
    private var _cache:ObjectMap<PipelineTechnique, CompiledPipelineEffect>;
    private var _identity:Mat4;
    private var _matrixScratch:Array<Float>;
    private var _fallbackCompiler:PipelineEffectFallbackCompiler;

    public function new(context:AbstractContext) {
        _context = context;
        _cache = new ObjectMap<PipelineTechnique, CompiledPipelineEffect>();
        _identity = Mat4.identity(new Mat4());
        _matrixScratch = [for (i in 0...16) 0.0];
        _fallbackCompiler = new PipelineEffectFallbackCompiler();
    }

    /**
     * Returns true when the effect claimed the item for this stage. The caller
     * must not run its PBR fallback in that case.
     */
    public function draw(item:RenderItem, effect:PipelineEffect, stage:EffectStage, frame:FrameContext):Bool {
        if (item == null || effect == null) {
            return false;
        }

        var technique = effect.techniqueFor(stage);
        if (technique == null) {
            return false;
        }

        return _drawTechnique(item, effect, technique, frame);
    }

    /**
     * Draw a fallback variant of a multi-output GBuffer technique into one
     * attachment. Returns false when the shader cannot be split (the caller
     * keeps its PBR fallback).
     */
    public function drawFallback(item:RenderItem, effect:PipelineEffect, attachment:Int, frame:FrameContext):Bool {
        if (item == null || effect == null) {
            return false;
        }
        var variants = _fallbackCompiler.variants(effect);
        if (variants == null || attachment < 0 || attachment >= variants.length) {
            return false;
        }
        return _drawTechnique(item, effect, variants[attachment], frame);
    }

    private function _drawTechnique(item:RenderItem, effect:PipelineEffect, technique:PipelineTechnique, frame:FrameContext):Bool {
        var compiled = _compile(effect, technique);
        var geometry = item.geometry;
        if (geometry == null || geometry.indices == null) {
            return true;
        }

        var context = _context;
        context.setProgram(compiled.program.id);
        _applyState(technique.state);

        for (uniform in technique.uniforms) {
            var input = compiled.uniforms.get(uniform.name);
            if (input != null) {
                _uploadUniform(input, uniform.source, item, frame);
            }
        }

        for (attribute in compiled.program.inputs.attributes) {
            if (!geometry.hasVertexAttribute(attribute.name)) {
                continue;
            }
            var vertexAttribute = geometry.getVertexAttribute(attribute.name);
            context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size,
                vertexAttribute.vertexSize, vertexAttribute.offset);
        }

        context.drawIndexBufferTriangles(geometry.indices.id, 0, Math.floor(geometry.indices.numIndices / 3));
        return true;
    }

    private function _compile(effect:PipelineEffect, technique:PipelineTechnique):CompiledPipelineEffect {
        var compiled = _cache.get(technique);
        if (compiled != null
            && compiled.macroVersion == technique.macroVersion
            && compiled.vertexSource == technique.vertexSource
            && compiled.fragmentSource == technique.fragmentSource) {
            return compiled;
        }
        if (compiled != null) {
            compiled.dispose();
        }

        var macroPrefix = _macroPrefix(technique);
        var vertexShader = Shader.createbySource(_context, ShaderType.VERTEX_SHADER, macroPrefix + technique.vertexSource);
        var fragmentShader = Shader.createbySource(_context, ShaderType.FRAGMENT_SHADER, macroPrefix + technique.fragmentSource);
        vertexShader.upload();
        fragmentShader.upload();

        var label = "PipelineEffect:" + effect.name + ":" + technique.stage;
        var program = Program.createbyShader(label, _context, vertexShader, fragmentShader);
        program.upload();

        var uniforms = new StringMap<UniformInput>();
        for (input in program.inputs.uniforms) {
            uniforms.set(input.name, input);
        }

        compiled = new CompiledPipelineEffect(program, vertexShader, fragmentShader, uniforms,
            macroPrefix, technique.vertexSource, technique.fragmentSource, technique.macroVersion);
        _cache.set(technique, compiled);
        return compiled;
    }

    private function _macroPrefix(technique:PipelineTechnique):String {
        var names = [];
        for (name in technique.macros.keys()) {
            names.push(name);
        }
        names.sort(function(a:String, b:String):Int {
            return a < b ? -1 : (a > b ? 1 : 0);
        });

        var buffer = new StringBuf();
        for (name in names) {
            var value = technique.macros.get(name);
            if (value == null) {
                continue;
            }
            buffer.add("#define ");
            buffer.add(name);
            if (value != "") {
                buffer.add(" ");
                buffer.add(value);
            }
            buffer.add("\n");
        }
        return buffer.toString();
    }

    private function _applyState(state:PipelineState):Void {
        if (state == null) {
            state = PipelineState.opaque();
        }

        _context.setColorMask(state.colorMask);
        if (state.depthTest) {
            _context.setDepthTest(state.depthWrite, CompareMode.LESS);
        }
        else {
            _context.setDepthTest(false, CompareMode.ALWAYS);
        }
        _context.setTriangleCulling(state.triangleCulling);
        _context.setBlendingModeSD(state.blendingSource, state.blendingDestination);
    }

    private function _uploadUniform(input:UniformInput, source:UniformSource, item:RenderItem, frame:FrameContext):Void {
        var type = input.type;

        if (type == InputType.sampler2d || type == InputType.samplerCube) {
            var texture = _resolveTexture(source, item, frame);
            if (texture != null && input.position >= 0) {
                _context.setTextureAt(input.position, texture.id, input.location);
                _context.setSamplerStateAt(input.position, WrapMode.CLAMP, TextureFilter.LINEAR, MipFilter.NONE);
            }
            return;
        }

        if (type == InputType.float16) {
            var matrix = _resolveMatrix(source, item, frame);
            if (matrix != null) {
                PBRMath.writeMat4(matrix, _matrixScratch);
                _context.setUniformMatrix4x4(input.location, 1, _matrixScratch);
            }
            return;
        }

        var size = _sizeOf(type);
        if (size == 0) {
            return;
        }

        if (type == InputType.float1 || type == InputType.float2 || type == InputType.float3 || type == InputType.float4) {
            var values = _resolveFloats(source, item, frame, size);
            if (values == null) {
                return;
            }
            switch (size) {
                case 1:
                    _context.setUniformFloat(input.location, 1, values);
                case 2:
                    _context.setUniformFloat2(input.location, 1, values);
                case 3:
                    _context.setUniformFloat3(input.location, 1, values);
                case 4:
                    _context.setUniformFloat4(input.location, 1, values);
            }
            return;
        }

        var ints = _resolveInts(source, item, frame, size);
        if (ints == null) {
            return;
        }
        switch (size) {
            case 1:
                _context.setUniformInt(input.location, 1, ints);
            case 2:
                _context.setUniformInt2(input.location, 1, ints);
            case 3:
                _context.setUniformInt3(input.location, 1, ints);
            case 4:
                _context.setUniformInt4(input.location, 1, ints);
        }
    }

    private function _resolveTexture(source:UniformSource, item:RenderItem, frame:FrameContext):AbstractTexture {
        switch (source) {
            case MaterialProperty(property):
                if (item.material == null) {
                    return null;
                }
                var materialValue = item.material.get(property);
                return Std.isOfType(materialValue, AbstractTexture) ? cast materialValue : null;
            case Constant(value):
                return Std.isOfType(value, AbstractTexture) ? cast value : null;
            case ShadowMap:
                return frame != null && frame.shadowMap != null ? frame.shadowMap.depth : null;
            default:
                return null;
        }
    }

    private function _resolveMatrix(source:UniformSource, item:RenderItem, frame:FrameContext):Mat4 {
        switch (source) {
            case ModelMatrix:
                return _worldMatrix(item);
            case NormalMatrix:
                if (item.normalMatrix == null) {
                    item.normalMatrix = PBRMath.normalMatrix(_worldMatrix(item), new Mat4());
                }
                return item.normalMatrix;
            case ViewMatrix:
                return frame != null ? frame.viewMatrix : null;
            case ProjectionMatrix:
                return frame != null ? frame.projectionMatrix : null;
            case LightViewProjection:
                return frame != null ? frame.lightViewProjection : null;
            case MaterialProperty(property):
                if (item.material != null) {
                    var materialValue = item.material.get(property);
                    if (Std.isOfType(materialValue, Mat4Base)) {
                        return cast materialValue;
                    }
                }
                return null;
            case Constant(value):
                return Std.isOfType(value, Mat4Base) ? cast value : null;
            default:
                return null;
        }
    }

    private function _resolveFloats(source:UniformSource, item:RenderItem, frame:FrameContext, size:Int):Array<Float> {
        switch (source) {
            case MaterialProperty(property):
                if (item.material == null) {
                    return null;
                }
                return _toFloats(item.material.get(property), size);
            case Constant(value):
                return _toFloats(value, size);
            case CameraPosition:
                return frame != null ? _toFloats(frame.cameraPosition, size) : null;
            case Time:
                return frame != null ? [frame.time] : null;
            case LightDirection:
                var directionLight = _firstDirectional(frame);
                return directionLight != null ? _toFloats(directionLight.direction, size) : _toFloats(new Vec3(0.0, -1.0, 0.0), size);
            case LightColor:
                var colorLight = _firstDirectional(frame);
                return colorLight != null ? _toFloats(colorLight.color, size) : _toFloats(new Vec3(1.0, 1.0, 1.0), size);
            case LightIntensity:
                var intensityLight = _firstDirectional(frame);
                return [intensityLight != null ? intensityLight.intensity : 1.0];
            case HasShadowMap:
                return [frame != null && frame.shadowMap != null ? 1.0 : 0.0];
            default:
                return null;
        }
    }

    private function _resolveInts(source:UniformSource, item:RenderItem, frame:FrameContext, size:Int):Array<Int> {
        var floats = _resolveFloats(source, item, frame, size);
        if (floats == null) {
            return null;
        }
        var ints = [];
        for (value in floats) {
            ints.push(Std.int(value));
        }
        return ints;
    }

    private function _toFloats(value:Dynamic, size:Int):Array<Float> {
        if (value == null) {
            return null;
        }

        if (Std.isOfType(value, Vec4Base)) {
            var v:Vec4 = cast value;
            return [v.x, v.y, v.z, v.w].slice(0, size);
        }
        if (Std.isOfType(value, Vec3Base)) {
            var v:Vec3 = cast value;
            return [v.x, v.y, v.z].slice(0, size);
        }
        if (Std.isOfType(value, Vec2Base)) {
            var v:Vec2 = cast value;
            return [v.x, v.y].slice(0, size);
        }
        if (Std.isOfType(value, Mat4Base)) {
            return cast(value, Mat4).toFloatArray().slice(0, size);
        }
        if (Std.isOfType(value, Array)) {
            var array:Array<Dynamic> = cast value;
            var floats = [];
            for (i in 0...array.length) {
                floats.push(_toFloat(array[i]));
            }
            return floats.slice(0, size);
        }
        if (Std.isOfType(value, Bool)) {
            return [cast(value, Bool) ? 1.0 : 0.0];
        }
        if (Std.isOfType(value, Float) || Std.isOfType(value, Int)) {
            return [_toFloat(value)];
        }

        return null;
    }

    private function _toFloat(value:Dynamic):Float {
        if (Std.isOfType(value, Bool)) {
            return cast(value, Bool) ? 1.0 : 0.0;
        }
        return cast(value, Float);
    }

    private function _worldMatrix(item:RenderItem):Mat4 {
        return item.worldMatrix != null ? item.worldMatrix : _identity;
    }

    private function _firstDirectional(frame:FrameContext):Light {
        if (frame == null || frame.lights == null) {
            return null;
        }
        for (light in frame.lights.lights) {
            if (light.type == LightType.Directional) {
                return light;
            }
        }
        return null;
    }

    private function _sizeOf(type:InputType):Int {
        if (type == InputType.float1 || type == InputType.int1 || type == InputType.bool1) {
            return 1;
        }
        if (type == InputType.float2 || type == InputType.int2 || type == InputType.bool2) {
            return 2;
        }
        if (type == InputType.float3 || type == InputType.int3 || type == InputType.bool3) {
            return 3;
        }
        if (type == InputType.float4 || type == InputType.int4 || type == InputType.bool4) {
            return 4;
        }
        return 0;
    }

    public function dispose():Void {
        if (_fallbackCompiler != null) {
            _fallbackCompiler.clear();
            _fallbackCompiler = null;
        }
        if (_cache != null) {
            for (technique in _cache.keys()) {
                var compiled = _cache.get(technique);
                if (compiled != null) {
                    compiled.dispose();
                }
            }
            _cache = null;
        }
        _context = null;
    }
}

private class CompiledPipelineEffect {
    public var program:Program;
    public var vertexShader:Shader;
    public var fragmentShader:Shader;
    public var uniforms:StringMap<UniformInput>;
    public var macroPrefix:String;
    public var vertexSource:String;
    public var fragmentSource:String;
    public var macroVersion:Int;

    public function new(program:Program, vertexShader:Shader, fragmentShader:Shader, uniforms:StringMap<UniformInput>,
                        macroPrefix:String, vertexSource:String, fragmentSource:String, macroVersion:Int) {
        this.program = program;
        this.vertexShader = vertexShader;
        this.fragmentShader = fragmentShader;
        this.uniforms = uniforms;
        this.macroPrefix = macroPrefix;
        this.vertexSource = vertexSource;
        this.fragmentSource = fragmentSource;
        this.macroVersion = macroVersion;
    }

    public function dispose():Void {
        if (program != null) {
            program.dispose();
            program = null;
        }
        if (vertexShader != null) {
            vertexShader.dispose();
            vertexShader = null;
        }
        if (fragmentShader != null) {
            fragmentShader.dispose();
            fragmentShader = null;
        }
        uniforms = null;
        macroPrefix = null;
        vertexSource = null;
        fragmentSource = null;
    }
}
