package minko.render.pbr;

import glm.Vec3;
import haxe.ds.StringMap;
import minko.render.AbstractContext;
import minko.render.Blending;
import minko.render.CompareMode;
import minko.render.MipFilter;
import minko.render.Program;
import minko.render.ProgramInputs.UniformInput;
import minko.render.Shader;
import minko.render.Shader.ShaderType;
import minko.render.TextureFilter;
import minko.render.TriangleCulling;
import minko.render.VertexAttribute;
import minko.render.VertexBuffer;
import minko.render.WrapMode;
import minko.render.target.GBuffer;
import minko.render.target.RenderTarget;

/**
 * Fullscreen G-buffer debug views (design §15: albedo/normal/depth/lighting).
 *
 * Depth needs a real depth texture, which only the native-MRT G-buffer carries
 * (and only when the backend supports depth textures). When it is unavailable
 * the Depth mode renders a magenta placeholder instead of failing.
 */
class GBufferDebugRenderer {
    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _vertexBuffer:VertexBuffer;
    private var _uniforms:StringMap<UniformInput>;
    private var _warnedNoDepth:Bool;

    public function new(context:AbstractContext) {
        _context = context;
        _uniforms = new StringMap<UniformInput>();
        _warnedNoDepth = false;

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PBRShaderLibrary.gbufferDebugFragment());
        _vertexShader.upload();
        _fragmentShader.upload();

        _program = Program.createbyShader("GBufferDebug", context, _vertexShader, _fragmentShader);
        _program.upload();
        for (uniform in _program.inputs.uniforms) {
            _uniforms.set(uniform.name, uniform);
        }

        _vertexBuffer = VertexBuffer.createbyData(context, [
            -1.0, -1.0, 0.0, 0.0,
             1.0, -1.0, 1.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0, -1.0, 0.0, 0.0,
             1.0,  1.0, 1.0, 1.0,
            -1.0,  1.0, 0.0, 1.0
        ]);
        _vertexBuffer.addAttribute("position", 2, 0);
        _vertexBuffer.addAttribute("uv", 2, 2);
    }

    public function render(gbuffer:GBuffer, mode:GBufferDebugMode, output:RenderTarget, near:Float = 0.1, far:Float = 100.0, depthScale:Float = 10.0, lightDirection:Vec3 = null):Void {
        if (_program == null || gbuffer == null || output == null) {
            return;
        }
        var albedo = gbuffer.albedoTexture;
        var normal = gbuffer.normalTexture;
        var emissive = gbuffer.emissiveTexture;
        if (albedo == null || normal == null || emissive == null) {
            return;
        }

        var depth = gbuffer.target != null ? gbuffer.target.depth : null;

        output.bind(_context, false);
        _context.setProgram(_program.id);
        _context.setDepthTest(false, CompareMode.ALWAYS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.NONE);
        _context.setColorMask(true);

        for (attribute in _program.inputs.attributes) {
            var vertexAttribute:VertexAttribute = _vertexBuffer.attribute(attribute.name);
            if (vertexAttribute != null) {
                _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size, vertexAttribute.vertexSize, vertexAttribute.offset);
            }
        }

        setFloat("uMode", mode);
        setFloat("uNear", near);
        setFloat("uFar", far);
        setFloat("uDepthScale", depthScale);
        setFloat3("uLightDirection", lightDirection != null ? lightDirection : new Vec3(0.0, 0.0, 1.0));
        bindTexture("uAlbedoMap", albedo.id);
        bindTexture("uNormalMap", normal.id);
        bindTexture("uEmissiveMap", emissive.id);

        if (depth != null) {
            setFloat("uHasDepthMap", 1.0);
            bindTexture("uDepthMap", depth.id);
        }
        else {
            setFloat("uHasDepthMap", 0.0);
            if (mode == GBufferDebugMode.Depth && !_warnedNoDepth) {
                _warnedNoDepth = true;
                trace("GBufferDebugRenderer: depth view needs an MRT G-buffer with a depth texture; showing placeholder");
            }
        }

        _context.drawTriangles(0, 2);
        output.unbind(_context);
    }

    private function bindTexture(name:String, texture:Int):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, texture, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }

    private function setFloat(name:String, value:Float):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) _context.setUniformFloat(uniform.location, 1, [value]);
    }

    private function setFloat3(name:String, value:Vec3):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) _context.setUniformFloat3(uniform.location, 1, value.toFloatArray());
    }

    public function dispose():Void {
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
        if (_vertexBuffer != null) {
            _vertexBuffer.dispose();
            _vertexBuffer = null;
        }
        _uniforms = null;
        _context = null;
    }
}
