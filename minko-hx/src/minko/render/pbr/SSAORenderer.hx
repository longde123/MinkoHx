package minko.render.pbr;

import glm.Mat4;
import glm.Vec3;
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
import minko.render.pipeline.FrameContext;
import minko.render.target.GBuffer;
import minko.render.target.RenderTarget;

/**
 * Screen-space ambient occlusion for the deferred G-buffer.
 *
 * Reconstructs view-space positions from depth, samples a fixed hemisphere
 * kernel and writes AO into a single RGBA target (rgba = ao).
 */
class SSAORenderer {
    public var radius:Float;
    public var bias:Float;
    public var power:Float;
    public var intensity:Float;
    public var blur:Bool;

    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _blurProgram:Program;
    private var _blurFragmentShader:Shader;
    private var _vertexBuffer:VertexBuffer;
    private var _uniforms:StringMap<UniformInput>;
    private var _blurUniforms:StringMap<UniformInput>;
    private var _kernel:Array<Float>;
    private var _matrixScratch:Array<Float>;

    public function new(context:AbstractContext) {
        _context = context;
        radius = 0.6;
        bias = 0.025;
        power = 1.4;
        intensity = 1.0;
        blur = true;
        _uniforms = new StringMap<UniformInput>();
        _blurUniforms = new StringMap<UniformInput>();
        _matrixScratch = [for (i in 0...16) 0.0];
        _kernel = buildKernel();

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, _fragmentSource());
        _vertexShader.upload();
        _fragmentShader.upload();
        _program = Program.createbyShader("SSAO", context, _vertexShader, _fragmentShader);
        _program.upload();
        for (uniform in _program.inputs.uniforms) {
            _uniforms.set(uniform.name, uniform);
        }

        _blurFragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, _blurFragmentSource());
        _blurFragmentShader.upload();
        _blurProgram = Program.createbyShader("SSAOBlur", context, _vertexShader, _blurFragmentShader);
        _blurProgram.upload();
        for (uniform in _blurProgram.inputs.uniforms) {
            _blurUniforms.set(uniform.name, uniform);
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

    public function render(gbuffer:GBuffer, output:RenderTarget, frame:FrameContext):Void {
        if (_program == null || gbuffer == null || output == null) {
            return;
        }
        var depth = gbuffer.depthTexture;
        var normal = gbuffer.normalTexture;
        if (depth == null || normal == null || frame == null) {
            return;
        }

        if (blur && frame.targetPool != null) {
            var temporary = frame.targetPool.acquire(output.width, output.height);
            _renderAO(gbuffer, temporary, frame);
            _renderBlur(temporary, output, gbuffer.depthTexture);
            frame.targetPool.release(temporary);
        }
        else {
            _renderAO(gbuffer, output, frame);
        }
    }

    private function _renderAO(gbuffer:GBuffer, output:RenderTarget, frame:FrameContext):Void {
        var depth = gbuffer.depthTexture;
        var normal = gbuffer.normalTexture;
        output.bind(_context, false);
        _context.setProgram(_program.id);
        _context.setDepthTest(false, CompareMode.ALWAYS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.NONE);
        _context.setColorMask(true);

        for (attribute in _program.inputs.attributes) {
            var vertexAttribute:VertexAttribute = _vertexBuffer.attribute(attribute.name);
            if (vertexAttribute != null) {
                _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size,
                    vertexAttribute.vertexSize, vertexAttribute.offset);
            }
        }

        bindTexture("uDepthMap", depth.id);
        bindTexture("uNormalMap", normal.id);
        setMatrix("uProjection", frame.projectionMatrix);
        setMatrix("uInverseProjection", Mat4.invert(frame.projectionMatrix, new Mat4()));
        setMatrix("uView", frame.viewMatrix);
        setFloat3("uCameraPosition", frame.cameraPosition);
        setFloat("uRadius", radius);
        setFloat("uBias", bias);
        setFloat("uPower", power);
        setFloat("uIntensity", intensity);

        var kernelUniform = _uniforms.get("uKernel");
        if (kernelUniform == null) kernelUniform = _uniforms.get("uKernel[0]");
        if (kernelUniform != null) {
            _context.setUniformFloat3(kernelUniform.location, Std.int(_kernel.length / 3), _kernel);
        }

        _context.drawTriangles(0, 2);
        output.unbind(_context);
    }

    private function _renderBlur(input:RenderTarget, output:RenderTarget, depth:AbstractTexture):Void {
        output.bind(_context, false);
        _context.setProgram(_blurProgram.id);
        _context.setDepthTest(false, CompareMode.ALWAYS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.NONE);
        _context.setColorMask(true);

        for (attribute in _blurProgram.inputs.attributes) {
            var vertexAttribute:VertexAttribute = _vertexBuffer.attribute(attribute.name);
            if (vertexAttribute != null) {
                _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size,
                    vertexAttribute.vertexSize, vertexAttribute.offset);
            }
        }

        var colorUniform = _blurUniforms.get("uColorMap");
        if (colorUniform != null && colorUniform.position >= 0 && input.color != null) {
            _context.setTextureAt(colorUniform.position, input.color.id, colorUniform.location);
            _context.setSamplerStateAt(colorUniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
        var texelUniform = _blurUniforms.get("uTexelSize");
        if (texelUniform != null) {
            _context.setUniformFloat2(texelUniform.location, 1, [1.0 / input.width, 1.0 / input.height]);
        }
        var depthUniform = _blurUniforms.get("uDepthMap");
        if (depthUniform != null && depthUniform.position >= 0 && depth != null) {
            _context.setTextureAt(depthUniform.position, depth.id, depthUniform.location);
            _context.setSamplerStateAt(depthUniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }

        _context.drawTriangles(0, 2);
        output.unbind(_context);
    }

    private function _blurFragmentSource():String {
        return [
            "varying vec2 vUV;",
            "uniform sampler2D uColorMap;",
            "uniform sampler2D uDepthMap;",
            "uniform vec2 uTexelSize;",
            "void main() {",
            "    float centerDepth = texture2D(uDepthMap, vUV).r;",
            "    float sum = 0.0;",
            "    float weight = 0.0;",
            "    for (int y = -1; y <= 1; ++y) {",
            "        for (int x = -1; x <= 1; ++x) {",
            "            vec2 uv = vUV + vec2(float(x), float(y)) * uTexelSize;",
            "            float sampleDepth = texture2D(uDepthMap, uv).r;",
            "            float w = abs(sampleDepth - centerDepth) < 0.001 ? 1.0 : 0.0;",
            "            sum += texture2D(uColorMap, uv).r * w;",
            "            weight += w;",
            "        }",
            "    }",
            "    gl_FragColor = vec4(vec3(sum / max(weight, 1.0)), 1.0);",
            "}"
        ].join("\n");
    }

    private function buildKernel():Array<Float> {
        var kernel:Array<Float> = [];
        var count = 16;
        for (i in 0...count) {
            var angle = i * 2.399963;
            var radius = Math.sqrt((i + 0.5) / count);
            var x = Math.cos(angle) * radius;
            var y = Math.sin(angle) * radius;
            var z = Math.sqrt(Math.max(0.0, 1.0 - x * x - y * y));
            var scale = 0.2 + 0.8 * (i / count);
            kernel.push(x * scale);
            kernel.push(y * scale);
            kernel.push(z * scale);
        }
        return kernel;
    }

    private function _fragmentSource():String {
        return [
            "varying vec2 vUV;",
            "uniform sampler2D uDepthMap;",
            "uniform sampler2D uNormalMap;",
            "uniform mat4 uProjection;",
            "uniform mat4 uInverseProjection;",
            "uniform mat4 uView;",
            "uniform vec3 uCameraPosition;",
            "uniform float uRadius;",
            "uniform float uBias;",
            "uniform float uPower;",
            "uniform float uIntensity;",
            "uniform vec3 uKernel[16];",
            "void main() {",
            "    float depth = texture2D(uDepthMap, vUV).r;",
            "    if (depth >= 0.99999) {",
            "        gl_FragColor = vec4(1.0);",
            "        return;",
            "    }",
            "    vec2 ndc = vUV * 2.0 - 1.0;",
            "    vec4 clip = vec4(ndc, depth * 2.0 - 1.0, 1.0);",
            "    vec4 view = uInverseProjection * clip;",
            "    view.xyz /= max(view.w, 0.0001);",
            "    vec3 normal = normalize(texture2D(uNormalMap, vUV).xyz * 2.0 - 1.0);",
            "    vec3 viewNormal = normalize(mat3(uView) * normal);",
            "    vec3 tangent = abs(viewNormal.z) < 0.999 ? normalize(cross(vec3(0.0, 0.0, 1.0), viewNormal)) : vec3(1.0, 0.0, 0.0);",
            "    vec3 bitangent = cross(viewNormal, tangent);",
            "    float occlusion = 0.0;",
            "    for (int i = 0; i < 16; ++i) {",
            "        vec3 sampleView = view.xyz + (tangent * uKernel[i].x + bitangent * uKernel[i].y + viewNormal * uKernel[i].z) * uRadius;",
            "        vec4 sampleClip = uProjection * vec4(sampleView, 1.0);",
            "        vec2 sampleUV = sampleClip.xy / max(sampleClip.w, 0.0001) * 0.5 + 0.5;",
            "        if (sampleUV.x < 0.0 || sampleUV.x > 1.0 || sampleUV.y < 0.0 || sampleUV.y > 1.0) continue;",
            "        float sampleDepth = texture2D(uDepthMap, sampleUV).r;",
            "        vec4 sampleDepthClip = vec4(sampleUV * 2.0 - 1.0, sampleDepth * 2.0 - 1.0, 1.0);",
            "        vec4 sampleDepthView = uInverseProjection * sampleDepthClip;",
            "        sampleDepthView.xyz /= max(sampleDepthView.w, 0.0001);",
            "        float rangeCheck = smoothstep(0.0, 1.0, uRadius / max(abs(view.z - sampleDepthView.z), 0.0001));",
            "        if (sampleDepthView.z >= view.z + uBias) {",
            "            occlusion += rangeCheck;",
            "        }",
            "    }",
            "    float ao = 1.0 - clamp(occlusion / 16.0 * uIntensity, 0.0, 1.0);",
            "    ao = pow(ao, uPower);",
            "    gl_FragColor = vec4(vec3(ao), 1.0);",
            "}"
        ].join("\n");
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

    private function setMatrix(name:String, value:Mat4):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            PBRMath.writeMat4(value, _matrixScratch);
            _context.setUniformMatrix4x4(uniform.location, 1, _matrixScratch);
        }
    }

    public function dispose():Void {
        if (_blurProgram != null) _blurProgram.dispose();
        if (_blurFragmentShader != null) _blurFragmentShader.dispose();
        if (_program != null) _program.dispose();
        if (_vertexShader != null) _vertexShader.dispose();
        if (_fragmentShader != null) _fragmentShader.dispose();
        if (_vertexBuffer != null) _vertexBuffer.dispose();
        _blurProgram = null;
        _blurFragmentShader = null;
        _program = null;
        _vertexShader = null;
        _fragmentShader = null;
        _vertexBuffer = null;
        _uniforms = null;
        _blurUniforms = null;
        _context = null;
    }
}
