package minko.render.pbr;

import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import glm.Vec4;
import haxe.ds.StringMap;
import minko.geometry.Geometry;
import minko.render.AbstractContext;
import minko.render.CubeTexture;
import minko.render.Blending;
import minko.render.CompareMode;
import minko.render.Program;
import minko.render.Shader;
import minko.render.Shader.ShaderType;
import minko.render.TriangleCulling;
import minko.render.VertexAttribute;
import minko.render.light.Light;
import minko.render.light.Light.LightType;
import minko.render.pipeline.EffectStage;
import minko.render.pipeline.FrameContext;
import minko.render.pipeline.PipelineEffectRenderer;
import minko.render.pipeline.RenderItem;
import minko.render.pipeline.RenderQueue;
import minko.render.target.RenderTarget;

/**
 * Directional shadow-map pass.
 *
 * Renders shadow casters into a RenderTarget that has a depth texture. The
 * PBR forward renderer samples that depth texture through uShadowMap.
 */
class ShadowRenderer {
    public var cascadeCount:Int;
    public var splitLambda:Float;
    public var softShadows:Bool;
    public var lightSize:Float;

    private var _context:AbstractContext;
    private var _program:Program;
    private var _vertexShader:Shader;
    private var _fragmentShader:Shader;
    private var _lightViewProjectionLocation:Int;
    private var _distanceProgram:Program;
    private var _distanceVertexShader:Shader;
    private var _distanceFragmentShader:Shader;
    private var _distanceMatrixLocation:Int;
    private var _distanceLightPositionLocation:Int;
    private var _distanceRangeLocation:Int;
    private var _pipelineEffects:PipelineEffectRenderer;
    private var _matrixScratch:Array<Float>;

    public function new(context:AbstractContext) {
        _context = context;
        cascadeCount = 1;
        splitLambda = 0.5;
        softShadows = false;
        lightSize = 0.02;
        _matrixScratch = [for (i in 0...16) 0.0];
        _vertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.shadowVertex());
        _fragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PBRShaderLibrary.shadowFragment());
        _vertexShader.upload();
        _fragmentShader.upload();
        _program = Program.createbyShader("PBRShadow", context, _vertexShader, _fragmentShader);
        _program.upload();
        _pipelineEffects = new PipelineEffectRenderer(context);
        _lightViewProjectionLocation = -1;
        _distanceVertexShader = Shader.createbySource(context, ShaderType.VERTEX_SHADER, PBRShaderLibrary.shadowDistanceVertex());
        _distanceFragmentShader = Shader.createbySource(context, ShaderType.FRAGMENT_SHADER, PBRShaderLibrary.shadowDistanceFragment());
        _distanceVertexShader.upload();
        _distanceFragmentShader.upload();
        _distanceProgram = Program.createbyShader("PBRShadowDistance", context, _distanceVertexShader, _distanceFragmentShader);
        _distanceProgram.upload();
        _distanceMatrixLocation = -1;
        _distanceLightPositionLocation = -1;
        _distanceRangeLocation = -1;
        for (uniform in _distanceProgram.inputs.uniforms) {
            if (uniform.name == "lightViewProjection") _distanceMatrixLocation = uniform.location;
            else if (uniform.name == "uLightPosition") _distanceLightPositionLocation = uniform.location;
            else if (uniform.name == "uRange") _distanceRangeLocation = uniform.location;
        }
        for (uniform in _program.inputs.uniforms) {
            if (uniform.name == "lightViewProjection") {
                _lightViewProjectionLocation = uniform.location;
            }
        }
    }

    public function render(queue:RenderQueue, frame:FrameContext, target:RenderTarget, lightViewProjection:Mat4,
                           viewportX:Int = 0, viewportY:Int = 0, viewportWidth:Int = -1, viewportHeight:Int = -1,
                           bindTarget:Bool = true):Void {
        if (_program == null || target == null || target.depth == null) {
            return;
        }

        if (bindTarget) {
            target.bind(_context, true);
            _context.clear(1.0, 1.0, 1.0, 1.0, 1.0, 0);
        }
        if (viewportWidth > 0 && viewportHeight > 0) {
            _context.configureViewport(viewportX, viewportY, viewportWidth, viewportHeight);
        }
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.BACK);
        _context.setProgram(_program.id);

        if (_lightViewProjectionLocation >= 0) {
            PBRMath.writeMat4(lightViewProjection, _matrixScratch);
            _context.setUniformMatrix4x4(_lightViewProjectionLocation, 1, _matrixScratch);
        }

        if (frame != null) {
            frame.lightViewProjection = lightViewProjection;
        }

        for (item in queue.shadowCasters) {
            applyDefaultState();
            if (item.pipelineEffect != null && _pipelineEffects.draw(item, item.pipelineEffect, EffectStage.Shadow, frame)) {
                continue;
            }
            drawItem(item);
        }

        target.unbind(_context);
    }

    public function renderPointAtlas(queue:RenderQueue, frame:FrameContext, atlas:RenderTarget, faceSize:Int,
                                     light:Light, lightIndex:Int):Array<Mat4> {
        var matrices:Array<Mat4> = [];
        var directions = [
            new Vec3(1.0, 0.0, 0.0), new Vec3(-1.0, 0.0, 0.0),
            new Vec3(0.0, 1.0, 0.0), new Vec3(0.0, -1.0, 0.0),
            new Vec3(0.0, 0.0, 1.0), new Vec3(0.0, 0.0, -1.0)
        ];
        var ups = [
            new Vec3(0.0, -1.0, 0.0), new Vec3(0.0, -1.0, 0.0),
            new Vec3(0.0, 0.0, 1.0), new Vec3(0.0, 0.0, -1.0),
            new Vec3(0.0, -1.0, 0.0), new Vec3(0.0, -1.0, 0.0)
        ];
        atlas.bind(_context, true);
        _context.clear(1.0, 1.0, 1.0, 1.0, 1.0, 0);
        for (i in 0...6) {
            var direction = directions[i];
            var center = new Vec3(light.position.x + direction.x, light.position.y + direction.y, light.position.z + direction.z);
            var view = GLM.lookAt(light.position, center, ups[i], new Mat4());
            var projection = GLM.perspective(Math.PI / 2.0, 1.0, 0.1, Math.max(light.range, 0.2), new Mat4());
            var matrix = projection * view;
            var column = i % 3;
            var row = Std.int(i / 3);
            render(queue, frame, atlas, matrix, column * faceSize, row * faceSize, faceSize, faceSize, false);
            matrices.push(matrix);
        }
        atlas.unbind(_context);
        return matrices;
    }

    /**
     * Render one point light into a hardware cube map. Each face gets its own
     * 90-degree view; the fragment shader writes linear distance / range so
     * the consumer can sample with textureCube(direction) and compare against
     * length(worldPosition - lightPosition) without per-face matrices.
     */
    public function renderPointCube(queue:RenderQueue, frame:FrameContext, cubeTexture:Int, faceSize:Int,
                                    light:Light, lightIndex:Int):Void {
        if (_distanceProgram == null || queue == null) {
            return;
        }
        var faces = [
            CubeTexture.Face.POSITIVE_X, CubeTexture.Face.NEGATIVE_X,
            CubeTexture.Face.POSITIVE_Y, CubeTexture.Face.NEGATIVE_Y,
            CubeTexture.Face.POSITIVE_Z, CubeTexture.Face.NEGATIVE_Z
        ];
        var directions = [
            new Vec3(1.0, 0.0, 0.0), new Vec3(-1.0, 0.0, 0.0),
            new Vec3(0.0, 1.0, 0.0), new Vec3(0.0, -1.0, 0.0),
            new Vec3(0.0, 0.0, 1.0), new Vec3(0.0, 0.0, -1.0)
        ];
        var ups = [
            new Vec3(0.0, -1.0, 0.0), new Vec3(0.0, -1.0, 0.0),
            new Vec3(0.0, 0.0, 1.0), new Vec3(0.0, 0.0, -1.0),
            new Vec3(0.0, -1.0, 0.0), new Vec3(0.0, -1.0, 0.0)
        ];
        var range = Math.max(light.range, 0.2);
        for (i in 0...6) {
            var direction = directions[i];
            var center = new Vec3(light.position.x + direction.x, light.position.y + direction.y, light.position.z + direction.z);
            var view = GLM.lookAt(light.position, center, ups[i], new Mat4());
            var projection = GLM.perspective(Math.PI / 2.0, 1.0, 0.1, range, new Mat4());
            var matrix = projection * view;

            _context.beginCubeFaceRender(cubeTexture, faces[i], faceSize);
            _context.setDepthTest(true, CompareMode.LESS);
            _context.setBlendingMode(Blending.Mode.DEFAULT);
            _context.setTriangleCulling(TriangleCulling.BACK);
            _context.setProgram(_distanceProgram.id);
            if (_distanceMatrixLocation >= 0) {
                PBRMath.writeMat4(matrix, _matrixScratch);
                _context.setUniformMatrix4x4(_distanceMatrixLocation, 1, _matrixScratch);
            }
            if (_distanceLightPositionLocation >= 0) {
                _context.setUniformFloat3(_distanceLightPositionLocation, 1, [light.position.x, light.position.y, light.position.z]);
            }
            if (_distanceRangeLocation >= 0) {
                _context.setUniformFloat(_distanceRangeLocation, 1, [range]);
            }
            for (item in queue.shadowCasters) {
                var geometry = item.geometry;
                if (geometry == null || geometry.indices == null) continue;
                _context.setProgram(_distanceProgram.id);
                var world = item.worldMatrix != null ? item.worldMatrix : Mat4.identity(new Mat4());
                for (uniform in _distanceProgram.inputs.uniforms) {
                    if (uniform.name == "modelMatrix") {
                        PBRMath.writeMat4(world, _matrixScratch);
                        _context.setUniformMatrix4x4(uniform.location, 1, _matrixScratch);
                    }
                }
                for (attribute in _distanceProgram.inputs.attributes) {
                    var vertexAttribute:VertexAttribute = geometry.getVertexAttribute(attribute.name);
                    if (vertexAttribute != null) {
                        _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size, vertexAttribute.vertexSize, vertexAttribute.offset);
                    }
                }
                _context.drawIndexBufferTriangles(geometry.indices.id, 0, Math.floor(geometry.indices.numIndices / 3));
            }
            _context.endCubeFaceRender();
        }
    }
    public function renderSpot(queue:RenderQueue, frame:FrameContext, target:RenderTarget, light:Light, lightIndex:Int):Mat4 {
        var direction = Vec3.normalize(light.direction, new Vec3());
        var up = Math.abs(Vec3.dot(direction, new Vec3(0.0, 1.0, 0.0))) > 0.99
            ? new Vec3(0.0, 0.0, 1.0)
            : new Vec3(0.0, 1.0, 0.0);
        var eye = light.position;
        var center = new Vec3(eye.x + direction.x, eye.y + direction.y, eye.z + direction.z);
        var view = GLM.lookAt(eye, center, up, new Mat4());
        var fov = 2.0 * Math.acos(Math.max(-1.0, Math.min(1.0, light.outerCone)));
        fov = Math.max(1.0 * Math.PI / 180.0, Math.min(179.0 * Math.PI / 180.0, fov));
        var projection = GLM.perspective(fov, 1.0, 0.1, Math.max(light.range, 0.2), new Mat4());
        var lightViewProjection = projection * view;
        render(queue, frame, target, lightViewProjection);
        return lightViewProjection;
    }

    public function renderSpotAtlas(queue:RenderQueue, frame:FrameContext, atlas:RenderTarget, cellSize:Int,
                                   cell:Int, light:Light, lightIndex:Int, bindTarget:Bool = false):Mat4 {
        var direction = Vec3.normalize(light.direction, new Vec3());
        var up = Math.abs(Vec3.dot(direction, new Vec3(0.0, 1.0, 0.0))) > 0.99
            ? new Vec3(0.0, 0.0, 1.0)
            : new Vec3(0.0, 1.0, 0.0);
        var eye = light.position;
        var center = new Vec3(eye.x + direction.x, eye.y + direction.y, eye.z + direction.z);
        var view = GLM.lookAt(eye, center, up, new Mat4());
        var fov = 2.0 * Math.acos(Math.max(-1.0, Math.min(1.0, light.outerCone)));
        fov = Math.max(1.0 * Math.PI / 180.0, Math.min(179.0 * Math.PI / 180.0, fov));
        var projection = GLM.perspective(fov, 1.0, 0.1, Math.max(light.range, 0.2), new Mat4());
        var lightViewProjection = projection * view;
        render(queue, frame, atlas, lightViewProjection, cell * cellSize, 0, cellSize, cellSize, bindTarget);
        return lightViewProjection;
    }

    public function renderPointAtlasCell(queue:RenderQueue, frame:FrameContext, atlas:RenderTarget, faceSize:Int,
                                         baseCell:Int, light:Light, lightIndex:Int, bindTarget:Bool = false):Array<Mat4> {
        var matrices:Array<Mat4> = [];
        var directions = [
            new Vec3(1.0, 0.0, 0.0), new Vec3(-1.0, 0.0, 0.0),
            new Vec3(0.0, 1.0, 0.0), new Vec3(0.0, -1.0, 0.0),
            new Vec3(0.0, 0.0, 1.0), new Vec3(0.0, 0.0, -1.0)
        ];
        var ups = [
            new Vec3(0.0, -1.0, 0.0), new Vec3(0.0, -1.0, 0.0),
            new Vec3(0.0, 0.0, 1.0), new Vec3(0.0, 0.0, -1.0),
            new Vec3(0.0, -1.0, 0.0), new Vec3(0.0, -1.0, 0.0)
        ];
        for (i in 0...6) {
            var direction = directions[i];
            var center = new Vec3(light.position.x + direction.x, light.position.y + direction.y, light.position.z + direction.z);
            var view = GLM.lookAt(light.position, center, ups[i], new Mat4());
            var projection = GLM.perspective(Math.PI / 2.0, 1.0, 0.1, Math.max(light.range, 0.2), new Mat4());
            var matrix = projection * view;
            var cellIndex = baseCell + i;
            var column = cellIndex % 4;
            var row = Std.int(cellIndex / 4);
            render(queue, frame, atlas, matrix, column * faceSize, row * faceSize, faceSize, faceSize, bindTarget && i == 0);
            matrices.push(matrix);
        }
        return matrices;
    }

    /**
     * Render a small directional CSM set. Each target receives one cascade.
     * Returns the cascade matrices in order; the first cascade is also exposed
     * through frame.shadowMap for single-map consumers.
     */
    public function renderCascades(queue:RenderQueue, frame:FrameContext, targets:Array<RenderTarget>, lightDirection:Vec3,
                                   cameraView:Mat4, cameraProjection:Mat4, near:Float, far:Float):Array<Mat4> {
        var count = Std.int(Math.max(1, Math.min(cascadeCount, targets.length)));
        var matrices:Array<Mat4> = [];
        var cascades:Array<ShadowCascade> = [];
        var splits:Array<Float> = [];

        var viewProjection = cameraProjection * cameraView;
        var inverseViewProjection = Mat4.invert(viewProjection, new Mat4());
        var lightDir = Vec3.normalize(lightDirection, new Vec3());
        var previous = near;

        var nearCorners:Array<Vec3> = [];
        var farCorners:Array<Vec3> = [];
        for (y in 0...2) {
            for (x in 0...2) {
                var clipX = x == 0 ? -1.0 : 1.0;
                var clipY = y == 0 ? -1.0 : 1.0;
                var nearWorld = Mat4.multVec(inverseViewProjection, new Vec4(clipX, clipY, -1.0, 1.0), new Vec4());
                var farWorld = Mat4.multVec(inverseViewProjection, new Vec4(clipX, clipY, 1.0, 1.0), new Vec4());
                var nearInvW = 1.0 / Math.max(Math.abs(nearWorld.w), 0.0001);
                var farInvW = 1.0 / Math.max(Math.abs(farWorld.w), 0.0001);
                nearCorners.push(new Vec3(nearWorld.x * nearInvW, nearWorld.y * nearInvW, nearWorld.z * nearInvW));
                farCorners.push(new Vec3(farWorld.x * farInvW, farWorld.y * farInvW, farWorld.z * farInvW));
            }
        }

        for (i in 0...count) {
            var ratio = (i + 1) / count;
            var linear = near + (far - near) * ratio;
            var logarithmic = near * Math.pow(far / near, ratio);
            var split = splitLambda * logarithmic + (1.0 - splitLambda) * linear;
            splits.push(split);

            var sliceNear = previous;
            var sliceFar = split;
            previous = split;

            var center = new Vec3(0.0, 0.0, 0.0);
            var corners:Array<Vec3> = [];
            var tNear = (sliceNear - near) / Math.max(far - near, 0.0001);
            var tFar = (sliceFar - near) / Math.max(far - near, 0.0001);
            for (index in 0...4) {
                var n = nearCorners[index];
                var f = farCorners[index];
                var atNear = new Vec3(n.x + (f.x - n.x) * tNear, n.y + (f.y - n.y) * tNear, n.z + (f.z - n.z) * tNear);
                var atFar = new Vec3(n.x + (f.x - n.x) * tFar, n.y + (f.y - n.y) * tFar, n.z + (f.z - n.z) * tFar);
                corners.push(atNear);
                corners.push(atFar);
                center.x += atNear.x + atFar.x;
                center.y += atNear.y + atFar.y;
                center.z += atNear.z + atFar.z;
            }
            center.x /= corners.length;
            center.y /= corners.length;
            center.z /= corners.length;

            var radius = 0.0;
            for (point in corners) {
                var dx = point.x - center.x;
                var dy = point.y - center.y;
                var dz = point.z - center.z;
                radius = Math.max(radius, Math.sqrt(dx * dx + dy * dy + dz * dz));
            }
            radius = Math.max(radius, 0.1);

            var up = Math.abs(Vec3.dot(lightDir, new Vec3(0.0, 1.0, 0.0))) > 0.99
                ? new Vec3(0.0, 0.0, 1.0)
                : new Vec3(0.0, 1.0, 0.0);
            var eye = new Vec3(center.x - lightDir.x * radius * 2.0,
                center.y - lightDir.y * radius * 2.0,
                center.z - lightDir.z * radius * 2.0);
            var lightView = GLM.lookAt(eye, center, up, new Mat4());
            var lightProjection = GLM.orthographic(-radius, radius, -radius, radius, 0.1, radius * 4.0, new Mat4());
            var lightViewProjection = lightProjection * lightView;

            render(queue, frame, targets[i], lightViewProjection);
            matrices.push(lightViewProjection);
            cascades.push(new ShadowCascade(targets[i], lightViewProjection, split));
        }

        frame.shadowCascades = cascades;
        frame.shadowCascadeSplits = splits;
        frame.shadowMap = targets[0];
        frame.lightViewProjection = matrices[0];
        return matrices;
    }

    private function applyDefaultState():Void {
        _context.setColorMask(true);
        _context.setDepthTest(true, CompareMode.LESS);
        _context.setBlendingMode(Blending.Mode.DEFAULT);
        _context.setTriangleCulling(TriangleCulling.BACK);
    }

    private function drawItem(item:RenderItem):Void {
        var geometry = item.geometry;
        if (geometry == null || geometry.indices == null) {
            return;
        }

        // A PipelineEffect draw may have switched the active program.
        _context.setProgram(_program.id);

        var world = item.worldMatrix != null ? item.worldMatrix : Mat4.identity(new Mat4());
        for (uniform in _program.inputs.uniforms) {
            if (uniform.name == "modelMatrix") {
                PBRMath.writeMat4(world, _matrixScratch);
                _context.setUniformMatrix4x4(uniform.location, 1, _matrixScratch);
            }
        }

        for (attribute in _program.inputs.attributes) {
            var vertexAttribute:VertexAttribute = geometry.getVertexAttribute(attribute.name);
            if (vertexAttribute != null) {
                _context.setVertexBufferAt(attribute.location, vertexAttribute.resourceId, vertexAttribute.size, vertexAttribute.vertexSize, vertexAttribute.offset);
            }
        }

        _context.drawIndexBufferTriangles(geometry.indices.id, 0, Math.floor(geometry.indices.numIndices / 3));
    }

    public function dispose():Void {
        if (_pipelineEffects != null) {
            _pipelineEffects.dispose();
            _pipelineEffects = null;
        }
        if (_program != null) _program.dispose();
        if (_vertexShader != null) _vertexShader.dispose();
        if (_fragmentShader != null) _fragmentShader.dispose();
        if (_distanceProgram != null) _distanceProgram.dispose();
        if (_distanceVertexShader != null) _distanceVertexShader.dispose();
        if (_distanceFragmentShader != null) _distanceFragmentShader.dispose();
        _program = null;
        _vertexShader = null;
        _fragmentShader = null;
        _context = null;
    }
}
