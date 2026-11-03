package minko.render.pbr;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.material.PBRMaterial;
import minko.render.AbstractContext;
import minko.render.AbstractTexture;
import minko.render.Blending;
import minko.render.CompareMode;
import minko.render.MipFilter;
import minko.render.Program;
import minko.render.ProgramInputs.UniformInput;
import minko.render.Shader;
import minko.render.Shader.ShaderType;
import minko.render.Texture;
import minko.render.TextureFilter;
import minko.render.TextureFormat;
import minko.render.TriangleCulling;
import minko.render.VertexAttribute;
import minko.render.WrapMode;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.render.pbr.LightTileCuller.LightTileMap;
import minko.render.pipeline.EffectStage;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.PipelineEffectRenderer;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.RenderTarget;

/**
 * Minimal forward PBR renderer.
 *
 * This is deliberately independent from the legacy DrawCall/Pass binding
 * system: it compiles PBRShaderLibrary directly, binds geometry attributes and
 * uploads the uniform set needed by the forward shader.
 */
class PBRForwardRenderer {
    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _uniforms:StringMap<UniformInput>;
    private var _attributes:StringMap<Int>;
    private var _shadowMap:AbstractTexture;
    private var _lightViewProjection:Mat4;
    private var _hasShadowMap:Bool;
    private var _pipelineEffects:PipelineEffectRenderer;
    private var _floatScratch:Array<Float>;
    private var _matrixScratch:Array<Float>;
    private var _ambient:Vec3;
    private var _lightTileCuller:LightTileCuller;
    private var _lightTileTexture:Texture;
    private var _lightTileMap:LightTileMap;
    private var _materialCache:ObjectMap<Material, PBRMaterialParams>;
    private var _defaultMaterialParams:PBRMaterialParams;
    private var _currentMaterial:Material;
    private var _currentMaterialVersion:Int;
    private var _hasMaterialState:Bool;
    private var _boundGeometry:Geometry;
    private var _programDirty:Bool;
    private var _stateDirty:Bool;

    public function new(context:AbstractContext) {
        _context = context;
        _uniforms = new StringMap<UniformInput>();
        _attributes = new StringMap<Int>();
        _shadowMap = null;
        _lightViewProjection = Mat4.identity(new Mat4());
        _hasShadowMap = false;
        _pipelineEffects = new PipelineEffectRenderer(context);
        _floatScratch = [0.0, 0.0, 0.0, 0.0];
        _matrixScratch = [for (i in 0...16) 0.0];
        _ambient = new Vec3(0.03, 0.03, 0.03);
        _lightTileCuller = new LightTileCuller();
        _lightTileTexture = null;
        _lightTileMap = null;
        _materialCache = new ObjectMap<Material, PBRMaterialParams>();
        _defaultMaterialParams = new PBRMaterialParams(
            new Vec4(1.0, 1.0, 1.0, 1.0), 0.0, 0.5, new Vec3(0.0, 0.0, 0.0), null);
        _currentMaterial = null;
        _currentMaterialVersion = -1;
        _hasMaterialState = false;
        _boundGeometry = null;
        _programDirty = false;
        _stateDirty = false;

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.forwardVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PBRShaderLibrary.forwardFragment());
        _vertexShader.upload();
        _fragmentShader.upload();

        _program = Program.createbyShader("PBRForward", context, _vertexShader, _fragmentShader);
        _program.upload();

        for (uniform in _program.inputs.uniforms) {
            _uniforms.set(uniform.name, uniform);
        }
        for (attribute in _program.inputs.attributes) {
            _attributes.set(attribute.name, attribute.location);
        }
    }

    public function setShadowMap(target:RenderTarget, lightViewProjection:Mat4):Void {
        _shadowMap = target != null ? target.depth : null;
        _lightViewProjection = lightViewProjection != null ? lightViewProjection : Mat4.identity(new Mat4());
        _hasShadowMap = _shadowMap != null;
    }

    public function render(queue:RenderQueue, frame:FrameContext, target:RenderTarget):Void {
        if (frame != null && frame.shadowMap != null) {
            setShadowMap(frame.shadowMap, frame.lightViewProjection);
        }
        else {
            setShadowMap(null, null);
        }

        if (_program == null || _program.id < 0) {
            return;
        }

        _bindFrameUniforms(frame);
        prepareLightTiles(frame);

        _hasMaterialState = false;
        _boundGeometry = null;
        _programDirty = false;
        _stateDirty = false;
        queue.sortOpaque();
        for (item in queue.opaque) {
            drawPipelineItem(item, EffectStage.Forward, frame);
        }
        for (item in queue.alphaTest) {
            drawPipelineItem(item, EffectStage.Forward, frame);
        }
        _context.setBlendingMode(Blending.Mode.ALPHA);
        for (item in queue.transparent) {
            drawPipelineItem(item, EffectStage.Transparent, frame);
        }
    }

    public function renderTransparent(queue:RenderQueue, frame:FrameContext):Void {
        if (_program == null || _program.id < 0) {
            return;
        }

        _bindFrameUniforms(frame);
        prepareLightTiles(frame);
        _context.setBlendingMode(Blending.Mode.ALPHA);
        _hasMaterialState = false;
        _boundGeometry = null;
        _programDirty = false;
        _stateDirty = false;

        for (item in queue.transparent) {
            drawPipelineItem(item, EffectStage.Transparent, frame);
        }
    }

    private function _bindFrameUniforms(frame:FrameContext):Void {
        if (frame != null && frame.shadowMap != null) {
            setShadowMap(frame.shadowMap, frame.lightViewProjection);
        }
        else {
            setShadowMap(null, null);
        }

        var context = _context;
        context.setProgram(_program.id);
        context.setColorMask(true);
        context.setDepthTest(true, CompareMode.LESS);
        context.setBlendingMode(Blending.Mode.DEFAULT);
        context.setTriangleCulling(TriangleCulling.BACK);

        var light = firstDirectional(frame);
        var lightDirection = light != null ? light.direction : new Vec3(0.0, -1.0, 0.0);
        var lightColor = light != null ? light.color : new Vec3(1.0, 1.0, 1.0);
        var lightIntensity = light != null ? light.intensity : 1.0;

        setMatrix("viewMatrix", frame.viewMatrix);
        setMatrix("projectionMatrix", frame.projectionMatrix);
        setFloat3("uCameraPosition", frame.cameraPosition);
        setFloat3("uAmbient", _ambient);
        setFloat3("uLightDirection", lightDirection);
        setFloat3("uLightColor", lightColor);
        setFloat("uLightIntensity", lightIntensity);
        setFloat("uPointLightCount", 0);
        setFloat("uHasShadowMap", _hasShadowMap ? 1 : 0);
        setFloat("uShadowTexelSize", frame != null ? frame.shadowTexelSize : 1.0 / 512.0); setFloat("uSoftShadows", frame != null ? frame.shadowSoftness : 0.0); setFloat("uLightSize", frame != null ? frame.shadowLightSize : 0.02);
        if (_hasShadowMap) {
            setMatrix("uLightViewProjection", _lightViewProjection);
            var shadowUniform = _uniforms.get("uShadowMap");
            if (shadowUniform != null && shadowUniform.position >= 0) {
                _context.setTextureAt(shadowUniform.position, _shadowMap.id, shadowUniform.location);
                _context.setSamplerStateAt(shadowUniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
            }
        }

        bindPointLights(frame);
        bindCascades(frame);
        bindLocalShadows(frame);
    }

    private function bindLocalShadows(frame:FrameContext):Void {
        var spots = frame != null ? frame.spotShadows : null;
        if (spots == null || spots.length == 0) {
            var fallback = frame != null ? frame.spotShadow : null;
            spots = fallback != null ? [fallback] : [];
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

    private function bindCubeTexture(name:String, texture:AbstractTexture):Void {
        if (texture == null) {
            return;
        }
        var uniform = uniformInput(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, texture.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }
    private function bindShadowTexture(name:String, target:RenderTarget):Void {
        if (target == null || target.depth == null) {
            return;
        }
        var uniform = uniformInput(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, target.depth.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }

    private function prepareLightTiles(frame:FrameContext):Void {
        _lightTileMap = null;
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
        _lightTileMap = map;
        setFloat("uHasLightTileMap", 1.0);
        setFloat2("uLightTileMapSize", map.textureWidth, map.textureHeight);
        setFloat2("uTileSize", map.tileSize, map.tileSize);
    }

    private function bindLightTileMap():Void {
        if (_lightTileMap == null || _lightTileTexture == null) {
            return;
        }
        var uniform = uniformInput("uLightTileMap");
        if (uniform != null && uniform.position >= 0) {
            // Dedicated texture unit: material maps may alias the reflected unit.
            var unit = 7;
            _context.setTextureAt(unit, _lightTileTexture.id, uniform.location);
            _context.setSamplerStateAt(unit, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
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
            var mapUniform = uniformInput(mapName);
            if (mapUniform != null && mapUniform.position >= 0 && cascade.target != null && cascade.target.depth != null) {
                _context.setTextureAt(mapUniform.position, cascade.target.depth.id, mapUniform.location);
                _context.setSamplerStateAt(mapUniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
            }
            setMatrix("uShadowMatrix" + i, cascade.lightViewProjection);
        }
    }

    private function drawPipelineItem(item:RenderItem, stage:EffectStage, frame:FrameContext):Void {
        if (_stateDirty) {
            applyDefaultState(stage);
            _stateDirty = false;
        }
        if (item.pipelineEffect != null && _pipelineEffects.draw(item, item.pipelineEffect, stage, frame)) {
            _hasMaterialState = false;
            _boundGeometry = null;
            _programDirty = true;
            _stateDirty = true;
            return;
        }
        drawItem(item, frame);
    }

    private function applyDefaultState(stage:EffectStage):Void {
        _context.setColorMask(true);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setTriangleCulling(TriangleCulling.BACK);
        _context.setBlendingMode(stage == EffectStage.Transparent ? Blending.Mode.ALPHA : Blending.Mode.DEFAULT);
    }

    private function drawItem(item:RenderItem, frame:FrameContext):Void {
        var geometry = item.geometry;
        if (geometry == null || geometry.indices == null) {
            return;
        }

        // A PipelineEffect draw may have switched the active program/state.
        if (_programDirty) {
            _context.setProgram(_program.id);
            _programDirty = false;
        }

        var material = item.material;
        var world = item.worldMatrix != null ? item.worldMatrix : Mat4.identity(new Mat4());

        setMatrix("modelMatrix", world);
        if (item.normalMatrix == null) {
            item.normalMatrix = PBRMath.normalMatrix(world, new Mat4());
        }
        setMatrix("normalMatrix", item.normalMatrix);

        if (!_hasMaterialState
            || material != _currentMaterial
            || (material != null && material.version != _currentMaterialVersion)) {
            var materialParams = _materialParams(material);
            setFloat4("uBaseColor", materialParams.baseColor);
            setFloat("uMetallic", materialParams.metallic);
            setFloat("uRoughness", materialParams.roughness);
            setFloat3("uEmissive", materialParams.emissive);
            setFloat("uHasBaseColorMap", materialParams.baseColorMap != null ? 1 : 0);
            if (materialParams.baseColorMap != null) {
                var mapUniform = _uniforms.get("uBaseColorMap");
                if (mapUniform != null && mapUniform.position >= 0) {
                    _context.setTextureAt(mapUniform.position, materialParams.baseColorMap.id, mapUniform.location);
                    _context.setSamplerStateAt(mapUniform.position, WrapMode.REPEAT, TextureFilter.LINEAR, MipFilter.NONE);
                }
            }
            _currentMaterial = material;
            _currentMaterialVersion = material != null ? material.version : -1;
            _hasMaterialState = true;
        }

        if (geometry != _boundGeometry) {
            for (attribute in _program.inputs.attributes) {
                var vertexAttribute:VertexAttribute = geometry.getVertexAttribute(attribute.name);
                if (vertexAttribute != null) {
                    _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size, vertexAttribute.vertexSize, vertexAttribute.offset);
                }
            }
            _boundGeometry = geometry;
        }

        bindLightTileMap();
        _context.drawIndexBufferTriangles(geometry.indices.id, 0, Math.floor(geometry.indices.numIndices / 3));
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

    private function bindPointLights(frame:FrameContext):Void {
        if (frame.lights == null) {
            return;
        }

        var positions:Array<Float> = [];
        var colors:Array<Float> = [];
        var params:Array<Float> = [];
        var directions:Array<Float> = [];
        var count = 0;
        var maxLights = 8;

        for (light in frame.lights.lights) {
            if (count >= maxLights) {
                break;
            }
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

        setFloat("uPointLightCount", count);
        if (count == 0) {
            return;
        }

        var positionsUniform = uniformInput("uPointLightPositions");
        if (positionsUniform != null) {
            _context.setUniformFloat3(positionsUniform.location, count, positions);
        }
        var colorsUniform = uniformInput("uPointLightColors");
        if (colorsUniform != null) {
            _context.setUniformFloat3(colorsUniform.location, count, colors);
        }
        var paramsUniform = uniformInput("uPointLightParams");
        if (paramsUniform != null) {
            _context.setUniformFloat4(paramsUniform.location, count, params);
        }
        var directionsUniform = uniformInput("uPointLightDirections");
        if (directionsUniform != null) {
            _context.setUniformFloat4(directionsUniform.location, count, directions);
        }
    }

    private function _materialParams(material:Material):PBRMaterialParams {
        if (material == null) {
            return _defaultMaterialParams;
        }
        var params = _materialCache.get(material);
        if (params == null || params.version != material.version) {
            params = new PBRMaterialParams(
                material.hasProperty(PBRMaterial.BASE_COLOR) ? cast material.get(PBRMaterial.BASE_COLOR) : new Vec4(1.0, 1.0, 1.0, 1.0),
                material.hasProperty(PBRMaterial.METALLIC) ? cast material.get(PBRMaterial.METALLIC) : 0.0,
                material.hasProperty(PBRMaterial.ROUGHNESS) ? cast material.get(PBRMaterial.ROUGHNESS) : 0.5,
                material.hasProperty(PBRMaterial.EMISSIVE) ? cast material.get(PBRMaterial.EMISSIVE) : new Vec3(0.0, 0.0, 0.0),
                material.hasProperty(PBRMaterial.BASE_COLOR_MAP) ? cast material.get(PBRMaterial.BASE_COLOR_MAP) : null);
            params.version = material.version;
            _materialCache.set(material, params);
        }
        return params;
    }

    private function setFloat(name:String, value:Float):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            _floatScratch[0] = value;
            _context.setUniformFloat(uniform.location, 1, _floatScratch);
        }
    }

    private function uniformInput(name:String):Null<UniformInput> {
        var uniform = _uniforms.get(name);
        if (uniform == null) {
            uniform = _uniforms.get(name + "[0]");
        }
        return uniform;
    }

    private function setInt(name:String, value:Int):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            _context.setUniformInt(uniform.location, 1, [value]);
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

    private function setFloat4(name:String, value:Vec4):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            PBRMath.writeVec4(value, _floatScratch);
            _context.setUniformFloat4(uniform.location, 1, _floatScratch);
        }
    }

    private function setMatrix(name:String, value:Mat4):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            PBRMath.writeMat4(value, _matrixScratch);
            _context.setUniformMatrix4x4(uniform.location, 1, _matrixScratch);
        }
    }

    public function dispose():Void {
        if (_pipelineEffects != null) {
            _pipelineEffects.dispose();
            _pipelineEffects = null;
        }
        if (_lightTileTexture != null) {
            _lightTileTexture.dispose();
            _lightTileTexture = null;
        }
        _lightTileMap = null;
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
        _attributes = null;
        _materialCache = null;
        _defaultMaterialParams = null;
        _context = null;
    }
}

private class PBRMaterialParams {
    public var baseColor:Vec4;
    public var metallic:Float;
    public var roughness:Float;
    public var emissive:Vec3;
    public var baseColorMap:AbstractTexture;
    public var version:Int;

    public function new(baseColor:Vec4, metallic:Float, roughness:Float, emissive:Vec3, baseColorMap:AbstractTexture) {
        this.baseColor = baseColor;
        this.metallic = metallic;
        this.roughness = roughness;
        this.emissive = emissive;
        this.baseColorMap = baseColorMap;
        this.version = -1;
    }
}
