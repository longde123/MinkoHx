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

/**
 * Fullscreen tonemap/post-process renderer.
 *
 * It owns a fullscreen quad and a compiled tonemap Program. PostProcessChain
 * callbacks can use it to turn an HDR scene target into an LDR target.
 */
class FullscreenRenderer {
    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _vertexBuffer:VertexBuffer;
    private var _uniforms:StringMap<UniformInput>;

    public function new(context:AbstractContext) {
        _context = context;
        _uniforms = new StringMap<UniformInput>();

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PBRShaderLibrary.tonemapFragment());
        _vertexShader.upload();
        _fragmentShader.upload();

        _program = Program.createbyShader("FullscreenTonemap", context, _vertexShader, _fragmentShader);
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

    public function render(input:AbstractTexture, output:RenderTarget, exposure:Float = 1.0, gamma:Float = 2.2):Void {
        if (_program == null || input == null || output == null) {
            return;
        }

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

        var colorUniform = _uniforms.get("uColorMap");
        if (colorUniform != null && colorUniform.position >= 0) {
            _context.setTextureAt(colorUniform.position, input.id, colorUniform.location);
            _context.setSamplerStateAt(colorUniform.position, WrapMode.CLAMP, TextureFilter.LINEAR, MipFilter.NONE);
        }

        var exposureUniform = _uniforms.get("uExposure");
        if (exposureUniform != null) {
            _context.setUniformFloat(exposureUniform.location, 1, [exposure]);
        }
        var gammaUniform = _uniforms.get("uGamma");
        if (gammaUniform != null) {
            _context.setUniformFloat(gammaUniform.location, 1, [gamma]);
        }

        _context.drawTriangles(0, 2);
        output.unbind(_context);
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
