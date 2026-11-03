package minko.render.phong;

import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import minko.geometry.Geometry;
import minko.material.Material;
import minko.material.PhongMaterial;
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
import minko.render.WrapMode;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.render.pbr.PBRMath;
import minko.render.pipeline.EffectStage;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.PipelineEffectRenderer;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.RenderTarget;

/**
 * Forward Blinn-Phong renderer.
 *
 * Uses PhongMaterial parameters and the same FrameContext light/shadow inputs
 * as the PBR forward path. PipelineEffect items claim their stage first; other
 * items fall back to this renderer.
 */
class PhongForwardRenderer {
    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _uniforms:StringMap<UniformInput>;
    private var _shadowMap:AbstractTexture;
    private var _lightViewProjection:Mat4;
    private var _hasShadowMap:Bool;
    private var _pipelineEffects:PipelineEffectRenderer;
    private var _floatScratch:Array<Float>;
    private var _matrixScratch:Array<Float>;
    private var _ambient:Vec3;
    private var _materialCache:ObjectMap<Material, PhongMaterialParams>;
    private var _defaultMaterial:PhongMaterialParams;
    private var _currentMaterial:Material;
    private var _currentMaterialVersion:Int;
    private var _hasMaterialState:Bool;
    private var _boundGeometry:Geometry;
    private var _currentDoubleSided:Bool;
    private var _programDirty:Bool;

    public function new(context:AbstractContext) {
        _context = context;
        _uniforms = new StringMap<UniformInput>();
        _shadowMap = null;
        _lightViewProjection = Mat4.identity(new Mat4());
        _hasShadowMap = false;
        _pipelineEffects = new PipelineEffectRenderer(context);
        _floatScratch = [0.0, 0.0, 0.0, 0.0];
        _matrixScratch = [for (i in 0...16) 0.0];
        _ambient = new Vec3(0.03, 0.03, 0.03);
        _materialCache = new ObjectMap<Material, PhongMaterialParams>();
        _defaultMaterial = new PhongMaterialParams(
            new Vec3(1.0, 1.0, 1.0), new Vec3(0.2, 0.2, 0.2), 32.0,
            new Vec3(0.1, 0.1, 0.1), new Vec3(0.0, 0.0, 0.0), 1.0, null, null, null, false);
        _currentMaterial = null;
        _currentMaterialVersion = -1;
        _hasMaterialState = false;
        _boundGeometry = null;
        _currentDoubleSided = false;
        _programDirty = false;

        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PhongShaderLibrary.forwardVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PhongShaderLibrary.forwardFragment());
        _vertexShader.upload();
        _fragmentShader.upload();
        _program = Program.createbyShader("PhongForward", context, _vertexShader, _fragmentShader);
        _program.upload();

        for (uniform in _program.inputs.uniforms) {
            _uniforms.set(uniform.name, uniform);
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
        _hasMaterialState = false;
        _boundGeometry = null;
        _programDirty = false;

        queue.sortOpaque();
        for (item in queue.opaque) {
            drawPipelineItem(item, EffectStage.Forward, frame);
        }
        for (item in queue.alphaTest) {
            drawPipelineItem(item, EffectStage.Forward, frame);
        }
        for (item in queue.transparent) {
            drawPipelineItem(item, EffectStage.Transparent, frame);
        }
    }

    private function _bindFrameUniforms(frame:FrameContext):Void {
        _context.setProgram(_program.id);
        _context.setColorMask(true);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.BACK);

        var light = firstDirectional(frame);
        setMatrix("viewMatrix", frame.viewMatrix);
        setMatrix("projectionMatrix", frame.projectionMatrix);
        setFloat3("uCameraPosition", frame.cameraPosition);
        setFloat3("uAmbient", _ambient);
        setFloat3("uLightDirection", light != null ? light.direction : new Vec3(0.0, -1.0, 0.0));
        setFloat3("uLightColor", light != null ? light.color : new Vec3(1.0, 1.0, 1.0));
        setFloat("uLightIntensity", light != null ? light.intensity : 1.0);
        setFloat("uHasShadowMap", _hasShadowMap ? 1.0 : 0.0);
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
        bindLocalShadows(frame);
    }

    private function bindLocalShadows(frame:FrameContext):Void {
        var spots = frame != null ? frame.spotShadows : null;
        if (spots == null || spots.length == 0) {
            var fallbackSpot = frame != null ? frame.spotShadow : null;
            spots = fallbackSpot != null ? [fallbackSpot] : [];
        }
        setFloat("uHasSpotShadow", spots.length > 0 ? 1.0 : 0.0);
        setFloat("uSpotShadowCount", spots.length);
        if (spots.length > 0) bindShadowTexture("uSpotShadowAtlas", spots[0].target);
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
        if (points.length > 0 && points[0].atlas != null) bindShadowTexture("uPointShadowAtlas", points[0].atlas);
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
        if (texture == null) return;
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
        var uniform = _uniforms.get(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, target.depth.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.CLAMP, TextureFilter.NEAREST, MipFilter.NONE);
        }
    }

    private function drawPipelineItem(item:RenderItem, stage:EffectStage, frame:FrameContext):Void {
        if (item.pipelineEffect != null && _pipelineEffects.draw(item, item.pipelineEffect, stage, frame)) {
            _hasMaterialState = false;
            _boundGeometry = null;
            _programDirty = true;
            return;
        }
        drawItem(item, stage, frame);
    }

    private function drawItem(item:RenderItem, stage:EffectStage, frame:FrameContext):Void {
        var geometry = item.geometry;
        if (geometry == null || geometry.indices == null) {
            return;
        }

        if (_programDirty) {
            _context.setProgram(_program.id);
            _programDirty = false;
        }

        var material = item.material;
        var params = _materialParams(material);
        if (!_hasMaterialState || material != _currentMaterial
            || (material != null && material.version != _currentMaterialVersion)) {
            setFloat4("uDiffuse", new Vec4(params.diffuse.x, params.diffuse.y, params.diffuse.z, 1.0));
            setFloat3("uSpecular", params.specular);
            setFloat("uShininess", params.shininess);
            setFloat3("uAmbient", params.ambient);
            setFloat3("uEmissive", params.emissive);
            setFloat("uAlpha", params.alpha);
            bindTexture("uDiffuseMap", params.diffuseMap, "uHasDiffuseMap");
            bindTexture("uSpecularMap", params.specularMap, "uHasSpecularMap");
            bindTexture("uNormalMap", params.normalMap, "uHasNormalMap");
            _currentMaterial = material;
            _currentMaterialVersion = material != null ? material.version : -1;
            _hasMaterialState = true;
        }
        setFloat("uHasNormalMap", params.normalMap != null && geometry.hasVertexAttribute("tangent") ? 1.0 : 0.0);

        var doubleSided = params.doubleSided;
        _context.setTriangleCulling(doubleSided ? TriangleCulling.NONE : TriangleCulling.BACK);
        _context.setBlendingMode(stage == EffectStage.Transparent ? Blending.Mode.ALPHA : Blending.Mode.DEFAULT);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setColorMask(true);

        var world = item.worldMatrix != null ? item.worldMatrix : Mat4.identity(new Mat4());
        setMatrix("modelMatrix", world);
        if (item.normalMatrix == null) {
            item.normalMatrix = PBRMath.normalMatrix(world, new Mat4());
        }
        setMatrix("normalMatrix", item.normalMatrix);

        if (geometry != _boundGeometry) {
            for (attribute in _program.inputs.attributes) {
                var vertexAttribute:VertexAttribute = geometry.getVertexAttribute(attribute.name);
                if (vertexAttribute != null) {
                    _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size, vertexAttribute.vertexSize, vertexAttribute.offset);
                }
            }
            _boundGeometry = geometry;
        }

        _context.drawIndexBufferTriangles(geometry.indices.id, 0, Math.floor(geometry.indices.numIndices / 3));
    }

    private function _materialParams(material:Material):PhongMaterialParams {
        if (material == null) {
            return _defaultMaterial;
        }
        var params = _materialCache.get(material);
        if (params == null || params.version != material.version) {
            params = new PhongMaterialParams(
                material.hasProperty(PhongMaterial.DIFFUSE) ? cast material.get(PhongMaterial.DIFFUSE) : new Vec3(1.0, 1.0, 1.0),
                material.hasProperty(PhongMaterial.SPECULAR) ? cast material.get(PhongMaterial.SPECULAR) : new Vec3(0.2, 0.2, 0.2),
                material.hasProperty(PhongMaterial.SHININESS) ? cast material.get(PhongMaterial.SHININESS) : 32.0,
                material.hasProperty(PhongMaterial.AMBIENT) ? cast material.get(PhongMaterial.AMBIENT) : new Vec3(0.1, 0.1, 0.1),
                material.hasProperty(PhongMaterial.EMISSIVE) ? cast material.get(PhongMaterial.EMISSIVE) : new Vec3(0.0, 0.0, 0.0),
                material.hasProperty(PhongMaterial.ALPHA) ? cast material.get(PhongMaterial.ALPHA) : 1.0,
                material.hasProperty(PhongMaterial.DIFFUSE_MAP) ? cast material.get(PhongMaterial.DIFFUSE_MAP) : null,
                material.hasProperty(PhongMaterial.SPECULAR_MAP) ? cast material.get(PhongMaterial.SPECULAR_MAP) : null,
                material.hasProperty(PhongMaterial.NORMAL_MAP) ? cast material.get(PhongMaterial.NORMAL_MAP) : null,
                material.hasProperty(PhongMaterial.DOUBLE_SIDED) ? cast material.get(PhongMaterial.DOUBLE_SIDED) : false);
            params.version = material.version;
            _materialCache.set(material, params);
        }
        return params;
    }

    private function bindTexture(name:String, texture:AbstractTexture, flagName:String):Void {
        var flag = _uniforms.get(flagName);
        if (flag != null) {
            setFloat(flagName, texture != null ? 1.0 : 0.0);
        }
        if (texture == null) {
            return;
        }
        var uniform = _uniforms.get(name);
        if (uniform != null && uniform.position >= 0) {
            _context.setTextureAt(uniform.position, texture.id, uniform.location);
            _context.setSamplerStateAt(uniform.position, WrapMode.REPEAT, TextureFilter.LINEAR, MipFilter.NONE);
        }
    }

    private function firstDirectional(frame:FrameContext):Light {
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

    private function bindPointLights(frame:FrameContext):Void {
        var positions:Array<Float> = [];
        var colors:Array<Float> = [];
        var params:Array<Float> = [];
        var directions:Array<Float> = [];
        var count = 0;

        if (frame != null && frame.lights != null) {
            for (light in frame.lights.lights) {
                if (count >= 8) break;
                if (light.type != LightType.Point && light.type != LightType.Spot) continue;
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
        if (count == 0) return;

        var positionsUniform = uniformInput("uPointLightPositions");
        if (positionsUniform != null) _context.setUniformFloat3(positionsUniform.location, count, positions);
        var colorsUniform = uniformInput("uPointLightColors");
        if (colorsUniform != null) _context.setUniformFloat3(colorsUniform.location, count, colors);
        var paramsUniform = uniformInput("uPointLightParams");
        if (paramsUniform != null) _context.setUniformFloat4(paramsUniform.location, count, params);
        var directionsUniform = uniformInput("uPointLightDirections");
        if (directionsUniform != null) _context.setUniformFloat4(directionsUniform.location, count, directions);
    }

    private function uniformInput(name:String):Null<UniformInput> {
        var uniform = _uniforms.get(name);
        if (uniform == null) {
            uniform = _uniforms.get(name + "[0]");
        }
        return uniform;
    }

    private function setFloat(name:String, value:Float):Void {
        var uniform = _uniforms.get(name);
        if (uniform != null) {
            _floatScratch[0] = value;
            _context.setUniformFloat(uniform.location, 1, _floatScratch);
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
            _floatScratch[0] = value.x;
            _floatScratch[1] = value.y;
            _floatScratch[2] = value.z;
            _floatScratch[3] = value.w;
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
        if (_pipelineEffects != null) _pipelineEffects.dispose();
        if (_program != null) _program.dispose();
        if (_vertexShader != null) _vertexShader.dispose();
        if (_fragmentShader != null) _fragmentShader.dispose();
        _pipelineEffects = null;
        _program = null;
        _vertexShader = null;
        _fragmentShader = null;
        _uniforms = null;
        _materialCache = null;
        _context = null;
    }
}

private class PhongMaterialParams {
    public var diffuse:Vec3;
    public var specular:Vec3;
    public var shininess:Float;
    public var ambient:Vec3;
    public var emissive:Vec3;
    public var alpha:Float;
    public var diffuseMap:AbstractTexture;
    public var specularMap:AbstractTexture;
    public var normalMap:AbstractTexture;
    public var doubleSided:Bool;
    public var version:Int;

    public function new(diffuse:Vec3, specular:Vec3, shininess:Float, ambient:Vec3, emissive:Vec3,
                        alpha:Float, diffuseMap:AbstractTexture, specularMap:AbstractTexture,
                        normalMap:AbstractTexture, doubleSided:Bool) {
        this.diffuse = diffuse;
        this.specular = specular;
        this.shininess = shininess;
        this.ambient = ambient;
        this.emissive = emissive;
        this.alpha = alpha;
        this.diffuseMap = diffuseMap;
        this.specularMap = specularMap;
        this.normalMap = normalMap;
        this.doubleSided = doubleSided;
        this.version = -1;
    }
}
