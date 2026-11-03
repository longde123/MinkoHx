package minko.render.pbr;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.Blending;
import minko.render.CompareMode;
import minko.render.MipFilter;
import minko.render.Program;
import minko.render.ProgramInputs.InputType;
import minko.render.ProgramInputs.UniformInput;
import minko.render.Shader;
import minko.render.Shader.ShaderType;
import minko.render.Texture;
import minko.render.TextureFilter;
import minko.render.TextureFormat;
import minko.render.TriangleCulling;
import minko.render.VertexAttribute;
import minko.render.VertexBuffer;
import minko.render.WrapMode;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.render.pipeline.FrameContext;
import minko.render.target.GBuffer;
import minko.render.target.RenderTarget;

/**
 * Fullscreen deferred lighting pass.
 *
 * It evaluates the same GGX + Lambert BRDF as the forward renderer from the
 * G-buffer albedo/normal(+roughness)/emissive(+metallic) and a directional
 * light. When the G-buffer has a depth texture, world position is reconstructed
 * from depth and point/spot lights plus directional shadows are evaluated; the
 * depth-less fallback keeps the camera-basis view direction.
 *
 * The light defaults can be overridden through the public fields; when a
 * FrameContext is supplied, its first directional light wins.
 */
class DeferredLightingRenderer {
    public var lightDirection:Vec3;
    public var lightColor:Vec3;
    public var lightTileMapActive:Bool;

    private var _lightTileCuller:LightTileCuller;
    private var _lightTileTexture:Texture;
    public var lightIntensity:Float;
    public var ambient:Vec3;

    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _vertexBuffer:VertexBuffer;
    private var _uniforms:StringMap<UniformInput>;
    private var _floatScratch:Array<Float>;
    private var _matrixScratch:Array<Float>;
    private var _identity:Mat4;

    public function new(context:AbstractContext) {
        _context = context;
        _uniforms = new StringMap<UniformInput>();
        _lightTileCuller = new LightTileCuller();
        _lightTileTexture = null;
        lightTileMapActive = false;
        _floatScratch = [0.0, 0.0, 0.0, 0.0];
        _matrixScratch = [for (i in 0...16) 0.0];
        _identity = Mat4.identity(new Mat4());
        // Default preview light: from the camera, so a bare render() shows a
        // lit scene instead of ambient-only darkness.
        lightDirection = new Vec3(0.0, 0.0, -1.0);
        lightColor = new Vec3(1.0, 1.0, 1.0);
        lightIntensity = 1.0;
        ambient = new Vec3(0.03, 0.03, 0.03);

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.fullscreenVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PBRShaderLibrary.deferredLightingFragment());
        _vertexShader.upload();
        _fragmentShader.upload();

        _program = Program.createbyShader("DeferredLighting", context, _vertexShader, _fragmentShader);
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

    /**
     * @param frame optional frame context; its first directional light and
     *        camera override the renderer defaults.
     */
    public function render(gbuffer:GBuffer, output:RenderTarget, frame:FrameContext = null):Void {
        if (_program == null || gbuffer == null || output == null) {
            return;
        }
        var albedo = gbuffer.albedoTexture;
        var normal = gbuffer.normalTexture;
        var emissive = gbuffer.emissiveTexture;
        if (albedo == null || normal == null || emissive == null) {
            return;
        }

        var direction = lightDirection;
        var color = lightColor;
        var intensity = lightIntensity;

        if (frame != null) {
            var light = firstDirectional(frame);
            if (light != null) {
                direction = light.direction;
                color = light.color;
                intensity = light.intensity;
            }
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

        bindTexture("uAlbedoMap", albedo.id);
        bindTexture("uNormalMap", normal.id);
        bindTexture("uEmissiveMap", emissive.id);

        var depth = gbuffer.depthTexture;
        if (depth != null) {
            bindTexture("uDepthMap", depth.id);
            setFloat("uHasDepth", 1.0);
        }
        else {
            setFloat("uHasDepth", 0.0);
        }

        var inverseViewProjection = _identity;
        if (frame != null && frame.viewMatrix != null && frame.projectionMatrix != null) {
            var viewProjection = frame.projectionMatrix * frame.viewMatrix;
            inverseViewProjection = Mat4.invert(viewProjection, new Mat4());
        }
        setMatrix("uInverseViewProjection", inverseViewProjection);

        // The shader expects L (towards the light); Light.direction is the
        // direction light travels.
        setFloat3("uLightDirection", new Vec3(-direction.x, -direction.y, -direction.z));
        setFloat3("uLightColor", color);
        setFloat("uLightIntensity", intensity);
        setFloat3("uAmbient", ambient);
        bindCameraBasis(frame);
        bindPointLights(frame);
        bindShadow(frame);
        bindCascades(frame);
        bindLocalShadows(frame);
        bindAO(frame);
        bindLightTiles(frame);

        _context.drawTriangles(0, 2);
        output.unbind(_context);
    }

    private function bindCameraBasis(frame:FrameContext):Void {
        // Fallback basis: camera looking down -Z at the origin.
        var right = new Vec3(1.0, 0.0, 0.0);
        var up = new Vec3(0.0, 1.0, 0.0);
        var forward = new Vec3(0.0, 0.0, -1.0);
        var tanHalfFov = 0.4142;
        var aspect = 1.0;

        if (frame != null && frame.viewMatrix != null && frame.projectionMatrix != null) {
            var view = frame.viewMatrix;
            right = new Vec3(view.r0c0, view.r1c0, view.r2c0);
            up = new Vec3(view.r0c1, view.r1c1, view.r2c1);
            forward = new Vec3(-view.r0c2, -view.r1c2, -view.r2c2);
            var proj = frame.projectionMatrix;
            if (Math.abs(proj.r1c1) > 1e-6) {
                tanHalfFov = 1.0 / proj.r1c1;
            }
            if (Math.abs(proj.r1c1) > 1e-6) {
                aspect = proj.r1c1 / proj.r0c0;
            }
        }

        setFloat3("uCameraRight", right);
        setFloat3("uCameraUp", up);
        setFloat3("uCameraForward", forward);
        setFloat3("uCameraPosition", frame != null ? frame.cameraPosition : new Vec3(0.0, 0.0, 0.0));
        setFloat("uTanHalfFov", tanHalfFov);
        setFloat("uAspect", aspect);
    }

    private function bindPointLights(frame:FrameContext):Void {
        var positions:Array<Float> = [];
        var colors:Array<Float> = [];
        var params:Array<Float> = [];
        var directions:Array<Float> = [];
        var count = 0;

        if (frame != null && frame.lights != null) {
            for (light in frame.lights.lights) {
                if (count >= 8) break;
                if (light.type != LightType.Point && light.type != LightType.Spot) {
                    continue;
                }
                positions.push(light.position.x);
                positions.push(light.position.y);
                positions.push(light.position.z);
                colors.push(light.color.x);
                colors.push(light.color.y);
                colors.push(light.color.z);
                params.push(light.range);
                params.push(light.intensity);
                params.push(light.innerCone);
                params.push(light.outerCone);
                directions.push(light.direction.x);
                directions.push(light.direction.y);
                directions.push(light.direction.z);
                directions.push(light.type == LightType.Spot ? 1.0 : 0.0);
                count++;
            }
        }

        setFloat("uPointLightCount", count);
        if (count == 0) {
            return;
        }
        var positionsUniform = _uniforms.get("uPointLightPositions");
        if (positionsUniform == null) positionsUniform = _uniforms.get("uPointLightPositions[0]");
        if (positionsUniform != null) {
            _context.setUniformFloat3(positionsUniform.location, count, positions);
        }
        var colorsUniform = _uniforms.get("uPointLightColors");
        if (colorsUniform == null) colorsUniform = _uniforms.get("uPointLightColors[0]");
        if (colorsUniform != null) {
            _context.setUniformFloat3(colorsUniform.location, count, colors);
        }
        var paramsUniform = _uniforms.get("uPointLightParams");
        if (paramsUniform == null) paramsUniform = _uniforms.get("uPointLightParams[0]");
        if (paramsUniform != null) {
            _context.setUniformFloat4(paramsUniform.location, count, params);
        }
        var directionsUniform = _uniforms.get("uPointLightDirections");
        if (directionsUniform == null) directionsUniform = _uniforms.get("uPointLightDirections[0]");
        if (directionsUniform != null) {
            _context.setUniformFloat4(directionsUniform.location, count, directions);
        }
    }

    private function bindCascades(frame:FrameContext):Void {
        var cascades = frame != null ? frame.shadowCascades : null;
        if (cascades == null || cascades.length <= 1) {
            setFloat("uCascadeCount", 0.0);
            return;
        }

        setFloat("uCascadeCount", cascades.length);
        var splits = frame.shadowCascadeSplits;
        var splitVec = new Vec4(
            splits != null && splits.length > 0 ? splits[0] : 1.0,
            splits != null && splits.length > 1 ? splits[1] : 1.0,
            splits != null && splits.length > 2 ? splits[2] : 1.0,
            splits != null && splits.length > 3 ? splits[3] : 1000.0);
        setFloat4("uCascadeSplits", splitVec);

        for (i in 0...4) {
            var index = i < cascades.length ? i : cascades.length - 1;
            var cascade = cascades[index];
            var mapName = "uShadowMap" + i;
            var mapUniform = _uniforms.get(mapName);
            if (mapUniform != null && mapUniform.position >= 0 && cascade.target != null && cascade.target.depth != null) {
                _context.setTextureAt(mapUniform.position, cascade.target.depth.id, mapUniform.location);
                _context.setSamplerStateAt(mapUniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
            }
            setMatrix("uShadowMatrix" + i, cascade.lightViewProjection);
        }
    }

    private function bindLocalShadows(frame:FrameContext):Void {
        var spots = frame != null ? frame.spotShadows : null;
        if (spots == null || spots.length == 0) {
            var fallbackSpot = frame != null ? frame.spotShadow : null;
            spots = fallbackSpot != null ? [fallbackSpot] : [];
        }
        setFloat("uHasSpotShadow", spots.length > 0 ? 1.0 : 0.0);
        setFloat("uSpotShadowCount", spots.length);
        if (spots.length > 0) {
            bindShadowTexture("uSpotShadowAtlas", spots[0].target);
        }
        for (i in 0...spots.length) {
            if (i > 1) break;
            var s = spots[i];
            if (i == 0) {
                setFloat("uSpotShadowLightIndex", s.lightIndex);
                setFloat("uSpotShadowCell", s.cell);
                setMatrix("uSpotShadowMatrix", s.lightViewProjection);
            }
            else {
                setFloat("uSpotShadowLightIndex1", s.lightIndex);
                setFloat("uSpotShadowCell1", s.cell);
                setMatrix("uSpotShadowMatrix1", s.lightViewProjection);
            }
        }

        var points = frame != null ? frame.pointShadows : null;
        if (points == null || points.length == 0) {
            var fallbackPoint = frame != null ? frame.pointShadow : null;
            points = fallbackPoint != null ? [fallbackPoint] : [];
        }
        setFloat("uHasPointShadow", points.length > 0 ? 1.0 : 0.0);
        setFloat("uPointShadowCount", points.length);
        for (slot in 0...points.length) {
            if (slot > 1) break;
            bindCubeTexture(slot == 0 ? "uPointShadowCube" : "uPointShadowCube1", points[slot].cube);
        }
        setFloat("uHasPointShadowCube", points.length > 0 && points[0].cube != null ? 1.0 : 0.0);
        setFloat("uHasPointShadowCube1", points.length > 1 && points[1].cube != null ? 1.0 : 0.0);
        if (points.length > 0 && points[0].atlas != null) {
            bindShadowTexture("uPointShadowAtlas", points[0].atlas);
        }
        for (slot in 0...points.length) {
            if (slot > 1) break;
            var p = points[slot];
            if (slot == 0) {
                setFloat("uPointShadowLightIndex", p.lightIndex);
                setFloat3("uPointShadowPosition", p.position);
                setFloat("uPointShadowRange", p.range);
                for (i in 0...6) {
                    if (i < p.matrices.length) setMatrix("uPointShadowMatrix" + i, p.matrices[i]);
                }
            }
            else {
                setFloat("uPointShadowLightIndex1", p.lightIndex);
                setFloat3("uPointShadowPosition1", p.position);
                setFloat("uPointShadowRange1", p.range);
                for (i in 0...6) {
                    if (i < p.matrices.length) setMatrix("uPointShadowMatrix" + (6 + i), p.matrices[i]);
                }
            }
        }
    }

    private function bindShadowTexture(name:String, target:RenderTarget):Void {
        if (target == null || target.depth == null) {
            return;
        }
        var uniform = _uniforms.get(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, target.depth.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }

    private function bindLightTiles(frame:FrameContext):Void {
        lightTileMapActive = false;
        if (frame == null || frame.lights == null) {
            setFloat("uHasLightTileMap", 0.0);
            return;
        }
        var map = _lightTileCuller.cull(frame.lights.lights, frame.viewMatrix, frame.projectionMatrix, frame.width, frame.height);
        if (map.activeLights == 0) {
            setFloat("uHasLightTileMap", 0.0);
            return;
        }
        if (_lightTileTexture == null
            || _lightTileTexture.width != map.textureWidth
            || _lightTileTexture.height != map.textureHeight) {
            if (_lightTileTexture != null) {
                _lightTileTexture.dispose();
            }
            _lightTileTexture = Texture.create(_context, map.textureWidth, map.textureHeight, false, false, true, TextureFormat.RGBA);
            _lightTileTexture.upload();
        }
        _lightTileTexture.uploadMipLevel(0, map.bytes);
        setFloat("uHasLightTileMap", 1.0);
        setFloat2("uTileSize", map.tileSize, map.tileSize);
        setFloat2("uLightTileMapSize", map.textureWidth, map.textureHeight);
        lightTileMapActive = true;

        // Always bind to the sampler's own dense slot (UniformInput.position).
        // Hardcoded units collide with other samplers (unit 7 == uShadowMap1).
        var uniform = _uniforms.get("uLightTileMap");
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, _lightTileTexture.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }

    private function bindAO(frame:FrameContext):Void {
        var ao = frame != null ? frame.aoMap : null;
        setFloat("uHasAOMap", ao != null ? 1.0 : 0.0);
        if (ao != null) {
            bindColorTexture("uAOMap", ao.color != null ? ao.color.id : -1);
        }
    }

    private function bindCubeTexture(name:String, texture:AbstractTexture):Void {
        if (texture == null) return;
        var uniform = _uniforms.get(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, texture.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }
    private function bindColorTexture(name:String, texture:Int):Void {
        if (texture < 0) return;
        var uniform = _uniforms.get(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, texture, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }

    private function bindShadow(frame:FrameContext):Void {
        setFloat("uShadowTexelSize", frame != null ? frame.shadowTexelSize : 1.0 / 512.0); setFloat("uSoftShadows", frame != null ? frame.shadowSoftness : 0.0); setFloat("uLightSize", frame != null ? frame.shadowLightSize : 0.02);
        if (frame != null && frame.shadowMap != null && frame.shadowMap.depth != null) {
            bindTexture("uShadowMap", frame.shadowMap.depth.id);
            setMatrix("uLightViewProjection", frame.lightViewProjection != null ? frame.lightViewProjection : _identity);
            setFloat("uHasShadowMap", 1.0);
        }
        else {
            setFloat("uHasShadowMap", 0.0);
        }
    }

    private function firstDirectional(frame:FrameContext):Light {
        if (frame.lights == null) {
            return null;
        }
        for (light in frame.lights.lights) {
            if (light.type == LightType.Directional) {
                return light;
            }
        }
        return null;
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
        if (uniform != null) {
            _floatScratch[0] = value;
            _context.setUniformFloat(uniform.location, 1, _floatScratch);
        }
    }

    private function setFloat2(name:String, x:Float, y:Float):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            _floatScratch[0] = x;
            _floatScratch[1] = y;
            _context.setUniformFloat2(uniform.location, 1, _floatScratch);
        }
    }

    private function setFloat3(name:String, value:Vec3):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            PBRMath.writeVec3(value, _floatScratch);
            _context.setUniformFloat3(uniform.location, 1, _floatScratch);
        }
    }

    private function setMatrix(name:String, value:Mat4):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            PBRMath.writeMat4(value, _matrixScratch);
            _context.setUniformMatrix4x4(uniform.location, 1, _matrixScratch);
        }
    }

    private function setFloat4(name:String, value:Vec4):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            _context.setUniformFloat4(uniform.location, 1, [value.x, value.y, value.z, value.w]);
        }
    }

    public function dispose():Void {
        if (_lightTileTexture != null) {
            _lightTileTexture.dispose();
            _lightTileTexture = null;
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
        if (_vertexBuffer != null) {
            _vertexBuffer.dispose();
            _vertexBuffer = null;
        }
        _uniforms = null;
        _context = null;
    }
}
