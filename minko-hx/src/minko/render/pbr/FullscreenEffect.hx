package minko.render.pbr;

import haxe.ds.StringMap;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
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
import minko.render.target.RenderTarget;

typedef FullscreenSetup = FullscreenEffect -> Void;

/**
 * Generic fullscreen effect.
 *
 * Owns one fullscreen quad and one compiled fragment program. The caller binds
 * its own textures/uniforms through the setup callback.
 */
class FullscreenEffect {
    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _vertexBuffer:VertexBuffer;
    private var _uniforms:StringMap<UniformInput>;

    public function new(context:AbstractContext, name:String, fragmentSource:String) {
        _context = context;
        _uniforms = new StringMap<UniformInput>();

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, fragmentSource);
        _vertexShader.upload();
        _fragmentShader.upload();

        _program = Program.createbyShader(name, context, _vertexShader, _fragmentShader);
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

    public function render(output:RenderTarget, setup:FullscreenSetup = null):Void {
        if (_program == null) {
            return;
        }

        if (output != null) {
            output.bind(_context, false);
        }
        else {
            _context.setRenderToBackBuffer();
        }
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

        if (setup != null) {
            setup(this);
        }

        _context.drawTriangles(0, 2);
#if hl
        sdl.GL.finish();
#end

        if (output != null) {
            output.unbind(_context);
        }
    }

    public function setTexture(name:String, texture:AbstractTexture):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null && uniform.position >= 0 && texture != null) {
            _context.setTextureAt(uniform.position, texture.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.LINEAR, MipFilter.NONE);
        }
    }

    public function setFloat(name:String, value:Float):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) _context.setUniformFloat(uniform.location, 1, [value]);
    }

    public function setVec2(name:String, x:Float, y:Float):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) _context.setUniformFloat2(uniform.location, 1, [x, y]);
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
