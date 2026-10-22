package minko.render;

import haxe.ds.IntMap;
import haxe.io.Bytes;
import glm.Vec4;
import minko.Tuple;
import minko.render.Blending.Destination;
import minko.render.Blending.Mode;
import minko.render.Blending.Source;
import minko.render.ProgramInputs.InputType;
import sdl.GL;
import sdl.GL.Buffer as GLBuffer;
import sdl.GL.Framebuffer as GLFramebuffer;
import sdl.GL.Program as GLProgram;
import sdl.GL.Renderbuffer as GLRenderbuffer;
import sdl.GL.Shader as GLShader;
import sdl.GL.Texture as GLTexture;
import sdl.GL.Uniform as GLUniform;

/**
 * Native OpenGL context for the HashLink/SDL backend.
 *
 * This is a port of the WebGL `GlContext` to the subset exposed by hlsdl.
 * Because hlsdl only exposes uniform1i/uniform4fv/uniformMatrix4fv, shaders are
 * normalized by HLShaderTools and scalar/vec2/vec3/int/bool uniforms are padded
 * to vec4 before upload. Active uniform/attribute queries are replaced by
 * parsing the original GLSL source.
 */
class SDLGLContext extends AbstractContext {

    static var textureCount = 0;
    static var vertexBufferCount = 0;
    static var indexBufferCount = 0;
    static var programCount = 0;
    static var shaderCount = 0;

    static var _blendingFactors:IntMap<Int> = initializeBlendFactors();
    static var _compareFuncs:IntMap<Int> = initializeCompareFuncs();
    static var _stencilOps:IntMap<Int> = initializeStencilOps();

    static function initializeBlendFactors():IntMap<Int> {
        var m = new IntMap<Int>();
        m.set(Source.ZERO, GL.ZERO);
        m.set(Source.ONE, GL.ONE);
        m.set(Source.SRC_COLOR, GL.SRC_COLOR);
        m.set(Source.ONE_MINUS_SRC_COLOR, GL.ONE_MINUS_SRC_COLOR);
        m.set(Source.SRC_ALPHA, GL.SRC_ALPHA);
        m.set(Source.ONE_MINUS_SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
        m.set(Source.DST_ALPHA, GL.DST_ALPHA);
        m.set(Source.ONE_MINUS_DST_ALPHA, GL.ONE_MINUS_DST_ALPHA);

        m.set(Destination.ZERO, GL.ZERO);
        m.set(Destination.ONE, GL.ONE);
        m.set(Destination.DST_COLOR, GL.DST_COLOR);
        m.set(Destination.ONE_MINUS_DST_COLOR, GL.ONE_MINUS_DST_COLOR);
        m.set(Destination.SRC_ALPHA_SATURATE, GL.SRC_ALPHA_SATURATE);
        m.set(Destination.ONE_MINUS_SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
        m.set(Destination.DST_ALPHA, GL.DST_ALPHA);
        m.set(Destination.ONE_MINUS_DST_ALPHA, GL.ONE_MINUS_DST_ALPHA);
        return m;
    }

    static function initializeCompareFuncs():IntMap<Int> {
        var m = new IntMap<Int>();
        m.set(CompareMode.ALWAYS, GL.ALWAYS);
        m.set(CompareMode.EQUAL, GL.EQUAL);
        m.set(CompareMode.GREATER, GL.GREATER);
        m.set(CompareMode.GREATER_EQUAL, GL.GEQUAL);
        m.set(CompareMode.LESS, GL.LESS);
        m.set(CompareMode.LESS_EQUAL, GL.LEQUAL);
        m.set(CompareMode.NEVER, GL.NEVER);
        m.set(CompareMode.NOT_EQUAL, GL.NOTEQUAL);
        m.set(CompareMode.UNSET, GL.ALWAYS);
        return m;
    }

    static function initializeStencilOps():IntMap<Int> {
        var m = new IntMap<Int>();
        m.set(StencilOperation.KEEP, GL.KEEP);
        m.set(StencilOperation.ZERO, GL.ZERO);
        m.set(StencilOperation.REPLACE, GL.REPLACE);
        m.set(StencilOperation.INCR, GL.INCR);
        m.set(StencilOperation.INCR_WRAP, GL.INCR_WRAP);
        m.set(StencilOperation.DECR, GL.DECR);
        m.set(StencilOperation.DECR_WRAP, GL.DECR_WRAP);
        m.set(StencilOperation.INVERT, GL.INVERT);
        m.set(StencilOperation.UNSET, GL.KEEP);
        return m;
    }

    var _textures:IntMap<GLTexture>;
    var _textureSizes:IntMap<Tuple<Int, Int>>;
    var _textureHasMipmaps:IntMap<Bool>;
    var _textureTypes:IntMap<TextureType>;

    var _vertexBuffers:IntMap<GLBuffer>;
    var _indexBuffers:IntMap<GLBuffer>;
    var _programs:IntMap<GLProgram>;
    var _shaders:IntMap<GLShader>;
    var _vertexShaders:IntMap<GLShader>;
    var _fragmentShaders:IntMap<GLShader>;
    var _frameBuffers:IntMap<GLFramebuffer>;
    var _renderBuffers:IntMap<GLRenderbuffer>;

    var _uniformInputLocations:IntMap<GLUniform>;
    var _locationCount:Int;

    var _originalSources:IntMap<String>;
    var _compiledSources:IntMap<String>;
    var _programShaders:IntMap<Array<Int>>;

    var _errorsEnabled:Bool;
    var _driverInfo:String;
    var _oglMajorVersion:Int;
    var _oglMinorVersion:Int;

    var _scissorTest:Bool;
    var _scissorBox:Vec4;
    var _viewportX:Int;
    var _viewportY:Int;
    var _viewportWidth:Int;
    var _viewportHeight:Int;
    var _oldViewportX:Int;
    var _oldViewportY:Int;
    var _oldViewportWidth:Int;
    var _oldViewportHeight:Int;
    var _currentTarget:Int;
    var _currentIndexBuffer:Int;
    var _currentVertexBuffer:IntMap<Int>;
    var _currentVertexSize:IntMap<Int>;
    var _currentVertexStride:IntMap<Int>;
    var _currentVertexOffset:IntMap<Int>;
    var _currentBoundTexture:Int;
    var _currentTexture:IntMap<Int>;
    var _currentWrapMode:IntMap<WrapMode>;
    var _currentTextureFilter:IntMap<TextureFilter>;
    var _currentMipFilter:IntMap<MipFilter>;
    var _currentProgram:Int;
    var _currentBlendingMode:Mode;
    var _currentColorMask:Bool;
    var _currentDepthMask:Bool;
    var _currentDepthFunc:CompareMode;
    var _currentTriangleCulling:TriangleCulling;
    var _currentStencilFunc:CompareMode;
    var _currentStencilRef:Int;
    var _currentStencilMask:Int;
    var _currentStencilFailOp:StencilOperation;
    var _currentStencilZFailOp:StencilOperation;
    var _currentStencilZPassOp:StencilOperation;
    var _vertexAttributeEnabled:IntMap<Bool>;
    var _stencilBits:Int;

    var _initialWidth:Int;
    var _initialHeight:Int;

    public static function create(width:Int, height:Int):SDLGLContext {
        return new SDLGLContext(width, height);
    }

    public function new(width:Int, height:Int) {
        super();
        _initialWidth = width;
        _initialHeight = height;
    }

    public function initialize() {
        _textureTypes = new IntMap<TextureType>();
        _uniformInputLocations = new IntMap<GLUniform>();
        _originalSources = new IntMap<String>();
        _compiledSources = new IntMap<String>();
        _programShaders = new IntMap<Array<Int>>();
        _locationCount = 0;

        _textures = new IntMap<GLTexture>();
        _textureSizes = new IntMap<Tuple<Int, Int>>();
        _textureHasMipmaps = new IntMap<Bool>();
        _vertexBuffers = new IntMap<GLBuffer>();
        _indexBuffers = new IntMap<GLBuffer>();
        _programs = new IntMap<GLProgram>();
        _shaders = new IntMap<GLShader>();
        _vertexShaders = new IntMap<GLShader>();
        _fragmentShaders = new IntMap<GLShader>();
        _frameBuffers = new IntMap<GLFramebuffer>();
        _renderBuffers = new IntMap<GLRenderbuffer>();

        _errorsEnabled = false;
        _oldViewportX = _viewportX = 0;
        _oldViewportY = _viewportY = 0;
        _oldViewportWidth = _viewportWidth = _initialWidth;
        _oldViewportHeight = _viewportHeight = _initialHeight;

        _currentTarget = -1;
        _currentIndexBuffer = -1;
        _currentVertexBuffer = new IntMap<Int>();
        _currentVertexSize = new IntMap<Int>();
        _currentVertexStride = new IntMap<Int>();
        _currentVertexOffset = new IntMap<Int>();
        for (i in 0...8) {
            _currentVertexBuffer.set(i, 0);
            _currentVertexSize.set(i, -1);
            _currentVertexStride.set(i, -1);
            _currentVertexOffset.set(i, -1);
        }

        _currentBoundTexture = 0;
        _currentTexture = new IntMap<Int>();
        for (i in 0...8) _currentTexture.set(i, 0);

        _currentProgram = 0;
        _currentTriangleCulling = TriangleCulling.BACK;
        _currentWrapMode = new IntMap<WrapMode>();
        _currentTextureFilter = new IntMap<TextureFilter>();
        _currentMipFilter = new IntMap<MipFilter>();
        _currentBlendingMode = Mode.DEFAULT;
        _currentColorMask = true;
        _currentDepthMask = true;
        _currentDepthFunc = CompareMode.UNSET;
        _currentStencilFunc = CompareMode.UNSET;
        _currentStencilRef = 0;
        _currentStencilMask = 0x1;
        _currentStencilFailOp = StencilOperation.UNSET;
        _currentStencilZFailOp = StencilOperation.UNSET;
        _currentStencilZPassOp = StencilOperation.UNSET;
        _vertexAttributeEnabled = new IntMap<Bool>();
        for (i in 0...32) _vertexAttributeEnabled.set(i, false);

        _stencilBits = 0;
        _scissorTest = false;
        _scissorBox = new Vec4(0, 0, -1, -1);

        GL.pixelStorei(GL.UNPACK_ALIGNMENT, 1);
        GL.enable(GL.DEPTH_TEST);
        GL.enable(GL.BLEND);
        GL.enable(GL.CULL_FACE);
        GL.cullFace(GL.BACK);

        var version = Std.string(GL.getParameter(GL.VERSION));
        var reg = new EReg("([0-9]+)\\.([0-9]+)", "");
        if (reg.match(version)) {
            _oglMajorVersion = Std.parseInt(reg.matched(1));
            _oglMinorVersion = Std.parseInt(reg.matched(2));
        }
        else {
            _oglMajorVersion = 3;
            _oglMinorVersion = 2;
        }
        _driverInfo = Std.string(GL.getParameter(GL.RENDERER));

        configureViewport(0, 0, _initialWidth, _initialHeight);
        _oldViewportX = _viewportX;
        _oldViewportY = _viewportY;
        _oldViewportWidth = _viewportWidth;
        _oldViewportHeight = _viewportHeight;

        setColorMask(true);
        setDepthTest(true, CompareMode.LESS);

        _stencilBits = GL.getConfigParameter(GL.STENCIL_BITS);
        if (_stencilBits > 0) {
            GL.enable(GL.STENCIL_TEST);
            setStencilTest(CompareMode.ALWAYS, 0, 0x1, StencilOperation.KEEP, StencilOperation.KEEP, StencilOperation.KEEP);
        }
        else {
            GL.disable(GL.STENCIL_TEST);
        }
    }

    override public function dispose() {
        for (buffer in _vertexBuffers) GL.deleteBuffer(buffer);
        for (buffer in _indexBuffers) GL.deleteBuffer(buffer);
        for (texture in _textures) GL.deleteTexture(texture);
        for (shader in _vertexShaders) GL.deleteShader(shader);
        for (shader in _fragmentShaders) GL.deleteShader(shader);
        super.dispose();
    }

    override function get_errorsEnabled():Bool return _errorsEnabled;
    override function set_errorsEnabled(errors:Bool):Bool { _errorsEnabled = errors; return errors; }
    override function get_driverInfo():String return _driverInfo;
    override function get_renderTarget():Int return _currentTarget;
    override function get_viewportWidth():Int return _viewportWidth;
    override function get_viewportHeight():Int return _viewportHeight;
    override function get_currentProgram():Int return _currentProgram;

    override public function configureViewport(x:Int, y:Int, width:Int, height:Int) {
        if (x != _viewportX || y != _viewportY || width != _viewportWidth || height != _viewportHeight) {
            _viewportX = x;
            _viewportY = y;
            _viewportWidth = width;
            _viewportHeight = height;
            GL.viewport(x, y, width, height);
        }
    }

    override public function clear(red:Float = 0.0, green:Float = 0.0, blue:Float = 0.0, alpha:Float = 0.0, depth:Float = 1.0, stencil:Int = 0, mask:Int = 0xffffffff) {
        GL.clearColor(red, green, blue, alpha);
        GL.clearDepth(depth);
        if (_stencilBits != 0) GL.clearStencil(stencil);

        mask = (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT | GL.STENCIL_BUFFER_BIT) & mask;
        if ((mask & GL.DEPTH_BUFFER_BIT) != 0) {
            _currentDepthMask = true;
            GL.depthMask(true);
        }
        GL.clear(mask);
    }

    override public function present() {
        // The SDL window swap is performed by SDLBackend.swapBuffers().
    }

    override public function drawTriangles(firstIndex:Int, numTriangles:Int) {
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
        GL.drawArrays(GL.TRIANGLES, firstIndex, numTriangles * 3);
        checkForErrors();
    }

    override public function drawIndexBufferTriangles(indexBuffer:Int, firstIndex:Int, numTriangles:Int) {
        if (_currentIndexBuffer != indexBuffer) {
            _currentIndexBuffer = indexBuffer;
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, _indexBuffers.get(indexBuffer));
        }
        // OpenGL's offset argument is expressed in bytes.
        GL.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex * 2);
        checkForErrors();
    }

    function checkForErrors() {
        if (_errorsEnabled) {
            var error = GL.getError();
            if (error != GL.NO_ERROR) trace("SDLGLContext GL error: " + error);
        }
    }

    override public function createVertexBuffer(size:Int) {
        var buffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, buffer);
        GL.bufferDataSize(GL.ARRAY_BUFFER, size * 4, GL.STATIC_DRAW);
        vertexBufferCount++;
        _vertexBuffers.set(vertexBufferCount, buffer);
        checkForErrors();
        return vertexBufferCount;
    }

    override public function createVertexAttributeArray() return -1;
    override public function setVertexAttributeArray(vertexArray:Int) {}

    override public function setVertexBufferAt(position:Int, vertexBuffer:Int, size:Int, stride:Int, offset:Int) {
        var vertexAttributeEnabled = vertexBuffer > 0;
        var vertexBufferChanged = (_currentVertexBuffer.get(position) != vertexBuffer) || vertexAttributeEnabled;

        if (vertexBufferChanged) {
            GL.bindBuffer(GL.ARRAY_BUFFER, _vertexBuffers.get(vertexBuffer));
            _currentVertexBuffer.set(position, vertexBuffer);
        }

        if (vertexBufferChanged
        || _currentVertexSize.get(position) != size
        || _currentVertexStride.get(position) != stride
        || _currentVertexOffset.get(position) != offset) {
            GL.vertexAttribPointer(position, size, GL.FLOAT, false, 4 * stride, 4 * offset);
            _currentVertexSize.set(position, size);
            _currentVertexStride.set(position, stride);
            _currentVertexOffset.set(position, offset);
        }

        if (vertexBufferChanged || _vertexAttributeEnabled.get(position) != vertexAttributeEnabled) {
            if (vertexAttributeEnabled) {
                GL.enableVertexAttribArray(position);
                _vertexAttributeEnabled.set(position, true);
            }
            else {
                GL.disableVertexAttribArray(position);
                _vertexAttributeEnabled.set(position, false);
            }
        }
        checkForErrors();
    }

    override public function uploadVertexBufferData(vertexBuffer:Int, offset:Int, size:Int, data:Array<Float>) {
        GL.bindBuffer(GL.ARRAY_BUFFER, _vertexBuffers.get(vertexBuffer));
        var bytes = Bytes.alloc(data.length * 4);
        for (i in 0...data.length) bytes.setFloat(i * 4, data[i]);
        GL.bufferSubData(GL.ARRAY_BUFFER, offset * 4, bytes.getData(), 0, bytes.length);
        checkForErrors();
    }

    override public function deleteVertexBuffer(vertexBuffer:Int) {
        for (key in _currentVertexBuffer.keys()) {
            if (_currentVertexBuffer.get(key) == vertexBuffer) _currentVertexBuffer.set(key, 0);
        }
        GL.deleteBuffer(_vertexBuffers.get(vertexBuffer));
        _vertexBuffers.remove(vertexBuffer);
        checkForErrors();
    }

    override public function createIndexBuffer(size:Int) {
        var buffer = GL.createBuffer();
        GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, buffer);
        GL.bufferDataSize(GL.ELEMENT_ARRAY_BUFFER, size * 2, GL.STATIC_DRAW);
        indexBufferCount++;
        _indexBuffers.set(indexBufferCount, buffer);
        checkForErrors();
        return indexBufferCount;
    }

    override public function uploaderIndexBufferData(indexBuffer:Int, offset:Int, size:Int, data:Array<Int>) {
        if (_currentIndexBuffer != indexBuffer) {
            GL.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, _indexBuffers.get(indexBuffer));
            _currentIndexBuffer = indexBuffer;
        }
        var bytes = Bytes.alloc(data.length * 2);
        for (i in 0...data.length) bytes.setUInt16(i * 2, data[i]);
        GL.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, offset * 2, bytes.getData(), 0, bytes.length);
        checkForErrors();
    }

    override public function deleteIndexBuffer(indexBuffer:Int) {
        if (_currentIndexBuffer == indexBuffer) _currentIndexBuffer = -1;
        GL.deleteBuffer(_indexBuffers.get(indexBuffer));
        _indexBuffers.remove(indexBuffer);
        checkForErrors();
    }

    override public function createTexture(type:TextureType, width:Int, height:Int, mipMapping:Bool, optimizeForRenderToTexture:Bool = false, assertPowerOfTwoSized:Bool = true) {
        if (assertPowerOfTwoSized) {
            if (!((width != 0) && (width & (width - 1)) == 0)) throw "width";
            if (!((height != 0) && (height & (height - 1)) == 0)) throw "height";
        }
        else if (mipMapping) {
            throw "assertPowerOfTwoSized must be true when mipMapping is true";
        }

        var texture = GL.createTexture();
        var target = type == TextureType.Texture2D ? GL.TEXTURE_2D : GL.TEXTURE_CUBE_MAP;
        GL.bindTexture(target, texture);
        textureCount++;
        _currentBoundTexture = textureCount;

        GL.texParameteri(target, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(target, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        GL.texParameteri(target, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        GL.texParameteri(target, GL.TEXTURE_MAG_FILTER, GL.NEAREST);

        _textures.set(textureCount, texture);
        _textureSizes.set(textureCount, new Tuple<Int, Int>(width, height));
        _textureHasMipmaps.set(textureCount, mipMapping);
        _textureTypes.set(textureCount, type);

        _currentWrapMode.set(textureCount, WrapMode.CLAMP);
        _currentTextureFilter.set(textureCount, TextureFilter.NEAREST);
        _currentMipFilter.set(textureCount, MipFilter.NONE);

        if (mipMapping) {
            var level = 0;
            var h = height;
            var w = width;
            var size = width > height ? width : height;
            while (size > 0) {
                if (type == TextureType.Texture2D) {
                    GL.texImage2D(GL.TEXTURE_2D, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                }
                else {
                    GL.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_X, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    GL.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_X, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    GL.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Y, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    GL.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    GL.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Z, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    GL.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                }
                level++;
                size = size >> 1;
                w = w >> 1;
                h = h >> 1;
            }
        }
        else {
            if (type == TextureType.Texture2D) {
                GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
            }
            else {
                GL.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                GL.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                GL.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                GL.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                GL.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                GL.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
            }
        }

        if (optimizeForRenderToTexture) createRTTBuffers(type, textureCount, width, height);
        checkForErrors();
        return textureCount;
    }

    override public function createRectangleTexture(type:TextureType, width:Int, height:Int) {
        return createTexture(type, width, height, false, false, false);
    }

    override public function createCompressedTexture(type:TextureType, format:TextureFormat, width:Int, height:Int, mipMapping:Bool) {
        throw "Compressed textures are not supported by the HashLink backend";
        return -1;
    }

    public function getTextureType(textureId:Int):TextureType {
        return _textureTypes.get(textureId);
    }

    override public function uploadTexture2dData(texture:Int, width:Int, height:Int, mipLevel:Int, data:Bytes) {
        GL.bindTexture(GL.TEXTURE_2D, _textures.get(texture));
        GL.texImage2D(GL.TEXTURE_2D, mipLevel, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, data.getData());
        _currentBoundTexture = texture;
        checkForErrors();
    }

    override public function uploadCubeTextureData(texture:Int, face:CubeTexture.Face, width:Int, height:Int, mipLevel:Int, data:Bytes) {
        GL.bindTexture(GL.TEXTURE_CUBE_MAP, _textures.get(texture));
        var cubeFace:Int = switch (face) {
            case CubeTexture.Face.POSITIVE_X: GL.TEXTURE_CUBE_MAP_POSITIVE_X;
            case CubeTexture.Face.NEGATIVE_X: GL.TEXTURE_CUBE_MAP_NEGATIVE_X;
            case CubeTexture.Face.POSITIVE_Y: GL.TEXTURE_CUBE_MAP_POSITIVE_Y;
            case CubeTexture.Face.NEGATIVE_Y: GL.TEXTURE_CUBE_MAP_NEGATIVE_Y;
            case CubeTexture.Face.POSITIVE_Z: GL.TEXTURE_CUBE_MAP_POSITIVE_Z;
            case CubeTexture.Face.NEGATIVE_Z: GL.TEXTURE_CUBE_MAP_NEGATIVE_Z;
        };
        GL.texImage2D(cubeFace, mipLevel, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, data.getData());
        _currentBoundTexture = texture;
        checkForErrors();
    }

    override public function uploadCompressedTexture2dData(texture:Int, format:TextureFormat, width:Int, height:Int, size:Int, mipLevel:Int, data:Bytes) {
        throw "Compressed textures are not supported by the HashLink backend";
    }

    override public function uploadCompressedCubeTextureData(texture:Int, face:CubeTexture.Face, format:TextureFormat, width:Int, height:Int, mipLevel:Int, data:Bytes) {
        throw "Compressed textures are not supported by the HashLink backend";
    }

    override public function activateMipMapping(texture:Int) {
        _textureHasMipmaps.set(texture, true);
    }

    override public function deleteTexture(texture:Int) {
        GL.deleteTexture(_textures.get(texture));
        _textures.remove(texture);
        if (_frameBuffers.exists(texture)) {
            GL.deleteFramebuffer(_frameBuffers.get(texture));
            _frameBuffers.remove(texture);
            GL.deleteRenderbuffer(_renderBuffers.get(texture));
            _renderBuffers.remove(texture);
        }
        _textureSizes.remove(texture);
        _textureHasMipmaps.remove(texture);
        _textureTypes.remove(texture);
        _currentWrapMode.remove(texture);
        _currentTextureFilter.remove(texture);
        _currentMipFilter.remove(texture);
        _currentTexture.set(texture, 0);
        if (_currentBoundTexture == texture) _currentBoundTexture = 0;
        checkForErrors();
    }

    override public function setTextureAt(position:Int, texture:Int, location:Int = -1) {
        if (texture <= 0 || !_currentTexture.exists(position)) return;
        var textureType = _textureTypes.get(texture);
        var target = textureType == TextureType.CubeTexture ? GL.TEXTURE_CUBE_MAP : GL.TEXTURE_2D;
        if (_currentTexture.get(position) != texture || _currentBoundTexture != texture) {
            GL.activeTexture(GL.TEXTURE0 + position);
            GL.bindTexture(target, _textures.get(texture));
            _currentTexture.set(position, texture);
            _currentBoundTexture = texture;
        }
        if (location >= 0) {
            var uniform = _uniformInputLocations.get(location);
            if (uniform != null) GL.uniform1i(uniform, position);
        }
        checkForErrors();
    }

    override public function setSamplerStateAt(position:Int, wrapping:WrapMode, filtering:TextureFilter, mipFiltering:MipFilter) {
        var texture = _currentTexture.get(position);
        if (texture == null || texture <= 0) return;
        var textureType = _textureTypes.get(texture);
        var target = textureType == TextureType.CubeTexture ? GL.TEXTURE_CUBE_MAP : GL.TEXTURE_2D;

        if (_textureHasMipmaps.get(texture) != true) mipFiltering = MipFilter.NONE;

        var active = false;
        if (_currentWrapMode.get(texture) != wrapping) {
            _currentWrapMode.set(texture, wrapping);
            GL.activeTexture(GL.TEXTURE0 + position);
            active = true;
            if (wrapping == WrapMode.CLAMP) {
                GL.texParameteri(target, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                GL.texParameteri(target, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
            }
            else {
                GL.texParameteri(target, GL.TEXTURE_WRAP_S, GL.REPEAT);
                GL.texParameteri(target, GL.TEXTURE_WRAP_T, GL.REPEAT);
            }
        }

        if (_currentTextureFilter.get(texture) != filtering || _currentMipFilter.get(texture) != mipFiltering) {
            _currentTextureFilter.set(texture, filtering);
            _currentMipFilter.set(texture, mipFiltering);
            if (!active) GL.activeTexture(GL.TEXTURE0 + position);

            if (filtering == TextureFilter.NEAREST) {
                var min = switch (mipFiltering) {
                    case MipFilter.NONE: GL.NEAREST;
                    case MipFilter.NEAREST: GL.NEAREST_MIPMAP_NEAREST;
                    case MipFilter.LINEAR: GL.NEAREST_MIPMAP_LINEAR;
                };
                GL.texParameteri(target, GL.TEXTURE_MIN_FILTER, min);
                GL.texParameteri(target, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
            }
            else {
                var min = switch (mipFiltering) {
                    case MipFilter.NONE: GL.LINEAR;
                    case MipFilter.NEAREST: GL.LINEAR_MIPMAP_NEAREST;
                    case MipFilter.LINEAR: GL.LINEAR_MIPMAP_LINEAR;
                };
                GL.texParameteri(target, GL.TEXTURE_MIN_FILTER, min);
                GL.texParameteri(target, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
            }
        }
        checkForErrors();
    }

    override public function createProgram() {
        var handle = GL.createProgram();
        programCount++;
        _programs.set(programCount, handle);
        return programCount;
    }

    override public function attachShader(program:Int, shader:Int) {
        GL.attachShader(_programs.get(program), _shaders.get(shader));
        var list = _programShaders.get(program);
        if (list == null) {
            list = [];
            _programShaders.set(program, list);
        }
        list.push(shader);
        checkForErrors();
    }

    override public function linkProgram(program:Int) {
        GL.linkProgram(_programs.get(program));
        if (Std.int(GL.getProgramParameter(_programs.get(program), GL.LINK_STATUS)) != 1) {
            throw "Program link failed:\n" + GL.getProgramInfoLog(_programs.get(program));
        }
        checkForErrors();
    }

    override public function deleteProgram(program:Int) {
        _programs.remove(program);
        _programShaders.remove(program);
        checkForErrors();
    }

    override public function compileShader(shader:Int) {
        GL.compileShader(_shaders.get(shader));
        if (Std.int(GL.getShaderParameter(_shaders.get(shader), GL.COMPILE_STATUS)) != 1) {
            var log = GL.getShaderInfoLog(_shaders.get(shader));
            throw "Shader compilation failed:\n" + log + "\n" + getShaderSource(shader);
        }
        checkForErrors();
    }

    override public function setProgram(program:Int) {
        if (_currentProgram == program) return;
        _currentProgram = program;
        GL.useProgram(_programs.get(program));
        checkForErrors();
    }

    override public function setShaderSource(shader:Int, source:String) {
        _originalSources.set(shader, source);
        var compiled = HLShaderTools.rewrite(source);
        _compiledSources.set(shader, compiled);
        GL.shaderSource(_shaders.get(shader), compiled);
        checkForErrors();
    }

    public function getShaderSource(shader:Int) {
        var source = _compiledSources.get(shader);
        return source == null ? "" : source;
    }

    override public function createVertexShader() {
        var shader = GL.createShader(GL.VERTEX_SHADER);
        shaderCount++;
        _vertexShaders.set(shaderCount, shader);
        _shaders.set(shaderCount, shader);
        return shaderCount;
    }

    override public function deleteVertexShader(vertexShader:Int) {
        GL.deleteShader(_vertexShaders.get(vertexShader));
        _vertexShaders.remove(vertexShader);
        _shaders.remove(vertexShader);
        checkForErrors();
    }

    override public function createFragmentShader() {
        var shader = GL.createShader(GL.FRAGMENT_SHADER);
        shaderCount++;
        _fragmentShaders.set(shaderCount, shader);
        _shaders.set(shaderCount, shader);
        return shaderCount;
    }

    override public function deleteFragmentShader(fragmentShader:Int) {
        GL.deleteShader(_fragmentShaders.get(fragmentShader));
        _fragmentShaders.remove(fragmentShader);
        _shaders.remove(fragmentShader);
        checkForErrors();
    }

    override public function getProgramInputs(program:Int):ProgramInputs {
        var inputs = new ProgramInputs();
        var shaders = _programShaders.get(program);
        if (shaders == null) return inputs;

        var vertexSource:String = null;
        var fragmentSource:String = null;
        for (shader in shaders) {
            if (_vertexShaders.exists(shader)) vertexSource = _originalSources.get(shader);
            else if (_fragmentShaders.exists(shader)) fragmentSource = _originalSources.get(shader);
        }

        var combined = (vertexSource == null ? "" : vertexSource) + "\n" + (fragmentSource == null ? "" : fragmentSource);
        var uniforms = HLShaderTools.parseUniforms(combined);
        var seen = new Map<String, Bool>();
        for (decl in uniforms) {
            var inputType = typeToInputType(decl.type);
            if (inputType == InputType.unknown) continue;

            var isArray = decl.isArray;
            var lookup = isArray ? decl.name + "[0]" : decl.name;
            var location = GL.getUniformLocation(_programs.get(program), lookup);
            if (location == null && isArray) {
                location = GL.getUniformLocation(_programs.get(program), decl.name);
            }
            if (location == null) continue;

            var size = decl.arraySize;
            if (size < 0) size = probeArraySize(program, decl.name);
            if (size < 1) size = 1;
            var inputName = isArray ? decl.name + "[0]" : decl.name;
            if (seen.exists(inputName)) continue;
            seen.set(inputName, true);

            _locationCount++;
            _uniformInputLocations.set(_locationCount, location);
            inputs.uniforms.push(new ProgramInputs.UniformInput(inputName, _locationCount, size, inputType));
        }

        if (vertexSource != null) {
            for (attribute in HLShaderTools.parseAttributes(vertexSource)) {
                var location = GL.getAttribLocation(_programs.get(program), attribute);
                if (location >= 0) inputs.attributes.push(new ProgramInputs.AttributeInput(attribute, location));
            }
        }
        return inputs;
    }

    function probeArraySize(program:Int, name:String):Int {
        var p = _programs.get(program);
        var n = 1;
        while (n < 64 && GL.getUniformLocation(p, name + "[" + n + "]") != null) n++;
        return n;
    }

    function typeToInputType(type:String):InputType {
        return switch (type) {
            case "float": InputType.float1;
            case "vec2": InputType.float2;
            case "vec3": InputType.float3;
            case "vec4": InputType.float4;
            case "mat3": InputType.float9;
            case "mat4": InputType.float16;
            case "int": InputType.int1;
            case "ivec2": InputType.int2;
            case "ivec3": InputType.int3;
            case "ivec4": InputType.int4;
            case "bool": InputType.bool1;
            case "bvec2": InputType.bool2;
            case "bvec3": InputType.bool3;
            case "bvec4": InputType.bool4;
            case "sampler2D": InputType.sampler2d;
            case "samplerCube": InputType.samplerCube;
            default: InputType.unknown;
        };
    }

    public function getShaderCompilationLogs(shader:Int):String {
        if (Std.int(GL.getShaderParameter(_shaders.get(shader), GL.COMPILE_STATUS)) == 0) {
            return GL.getShaderInfoLog(_shaders.get(shader));
        }
        return "";
    }

    public function getProgramInfoLogs(program:Int):String {
        return GL.getProgramInfoLog(_programs.get(program));
    }

    function blendValue(factor:Int):Int {
        var value = _blendingFactors.get(factor);
        return value == null ? GL.ONE : value;
    }

    override public function setBlendingModeSD(source:Source, destination:Destination) {
        var mode = source | destination;
        if (mode != _currentBlendingMode) {
            _currentBlendingMode = mode;
            GL.blendFunc(blendValue(source & 0xff), blendValue(destination & 0xff00));
            checkForErrors();
        }
    }

    override public function setBlendingMode(blendingMode:Mode) {
        if (blendingMode != _currentBlendingMode) {
            _currentBlendingMode = blendingMode;
            GL.blendFunc(blendValue(blendingMode & 0xff), blendValue(blendingMode & 0xff00));
            checkForErrors();
        }
    }

    override public function setDepthTest(depthMask:Bool, depthFunc:CompareMode) {
        if (depthMask != _currentDepthMask || depthFunc != _currentDepthFunc) {
            _currentDepthMask = depthMask;
            _currentDepthFunc = depthFunc;
            GL.depthMask(depthMask);
            GL.depthFunc(_compareFuncs.get(depthFunc));
            checkForErrors();
        }
    }

    override public function setColorMask(colorMask:Bool) {
        if (_currentColorMask != colorMask) {
            _currentColorMask = colorMask;
            GL.colorMask(colorMask, colorMask, colorMask, colorMask);
            checkForErrors();
        }
    }

    override public function setStencilTest(stencilFunc:CompareMode, stencilRef:Int, stencilMask:Int, stencilFailOp:StencilOperation, stencilZFailOp:StencilOperation, stencilZPassOp:StencilOperation) {
        if (stencilFunc != _currentStencilFunc || stencilRef != _currentStencilRef || stencilMask != _currentStencilMask) {
            _currentStencilFunc = stencilFunc;
            _currentStencilRef = stencilRef;
            _currentStencilMask = stencilMask;
            GL.stencilFuncSeparate(GL.FRONT_AND_BACK, _compareFuncs.get(stencilFunc), stencilRef, stencilMask);
            checkForErrors();
        }
        if (stencilFailOp != _currentStencilFailOp || stencilZFailOp != _currentStencilZFailOp || stencilZPassOp != _currentStencilZPassOp) {
            _currentStencilFailOp = stencilFailOp;
            _currentStencilZFailOp = stencilZFailOp;
            _currentStencilZPassOp = stencilZPassOp;
            GL.stencilOpSeparate(GL.FRONT_AND_BACK, _stencilOps.get(stencilFailOp), _stencilOps.get(stencilZFailOp), _stencilOps.get(stencilZPassOp));
            checkForErrors();
        }
    }

    override public function readRectPixels(x:Int, y:Int, width:Int, height:Int, pixels:Bytes) {
        GL.readPixels(x, y, width, height, GL.RGBA, GL.UNSIGNED_BYTE, pixels.getData());
        checkForErrors();
    }

    override public function setScissorTest(scissorTest:Bool, scissorBox:Vec4) {
        if (scissorTest == _scissorTest && scissorBox.equals(_scissorBox)) return;

        if (scissorTest) {
            GL.enable(GL.SCISSOR_TEST);
            var x = 0;
            var y = 0;
            var width = 0;
            var height = 0;
            if (scissorBox.z < 0 || scissorBox.w < 0) {
                x = _viewportX;
                y = _viewportY;
                width = _viewportWidth;
                height = _viewportHeight;
            }
            else {
                x = Std.int(scissorBox.x);
                y = Std.int(scissorBox.y);
                width = Std.int(scissorBox.z);
                height = Std.int(scissorBox.w);
            }
            GL.scissor(x, y, width, height);
        }
        else {
            GL.disable(GL.SCISSOR_TEST);
        }
        _scissorTest = scissorTest;
        _scissorBox = scissorBox;
        checkForErrors();
    }

    override public function readPixels(pixels:Bytes) {
        GL.readPixels(_viewportX, _viewportY, _viewportWidth, _viewportHeight, GL.RGBA, GL.UNSIGNED_BYTE, pixels.getData());
        checkForErrors();
    }

    override public function setTriangleCulling(triangleCulling:TriangleCulling) {
        if (triangleCulling == _currentTriangleCulling) return;
        if (_currentTriangleCulling == TriangleCulling.NONE) GL.enable(GL.CULL_FACE);
        _currentTriangleCulling = triangleCulling;
        switch (triangleCulling) {
            case TriangleCulling.NONE: GL.disable(GL.CULL_FACE);
            case TriangleCulling.BACK: GL.cullFace(GL.BACK);
            case TriangleCulling.FRONT: GL.cullFace(GL.FRONT);
            case TriangleCulling.BOTH: GL.cullFace(GL.FRONT_AND_BACK);
        }
        checkForErrors();
    }

    function createRTTBuffers(type:TextureType, textureKey:Int, width:Int, height:Int) {
        var texture = _textures.get(textureKey);
        var frameBuffer = GL.createFramebuffer();
        GL.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);
        if (type == TextureType.Texture2D) {
            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
        }
        else {
            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_CUBE_MAP_POSITIVE_X, texture, 0);
            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 1, GL.TEXTURE_CUBE_MAP_NEGATIVE_X, texture, 0);
            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 2, GL.TEXTURE_CUBE_MAP_POSITIVE_Y, texture, 0);
            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 3, GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, texture, 0);
            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 4, GL.TEXTURE_CUBE_MAP_POSITIVE_Z, texture, 0);
            GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 5, GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, texture, 0);
        }

        var renderBuffer = GL.createRenderbuffer();
        GL.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
        GL.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);
        GL.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);

        _frameBuffers.set(textureKey, frameBuffer);
        _renderBuffers.set(textureKey, renderBuffer);

        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        GL.bindRenderbuffer(GL.RENDERBUFFER, null);
        checkForErrors();
    }

    override public function setRenderToBackBuffer() {
        if (_currentTarget == -1) return;
        GL.bindFramebuffer(GL.FRAMEBUFFER, null);
        GL.bindRenderbuffer(GL.RENDERBUFFER, null);
        configureViewport(_oldViewportX, _oldViewportY, _oldViewportWidth, _oldViewportHeight);
        _currentTarget = -1;
        checkForErrors();
    }

    override public function setRenderToTexture(texture:Int, enableDepthAndStencil:Bool = false) {
        if (texture == _currentTarget) return;
        if (!_frameBuffers.exists(texture) || !_renderBuffers.exists(texture)) {
            throw "this texture cannot be used for RTT";
        }
        if (_currentTarget == -1) {
            _oldViewportX = _viewportX;
            _oldViewportY = _viewportY;
            _oldViewportWidth = _viewportWidth;
            _oldViewportHeight = _viewportHeight;
        }
        _currentTarget = texture;
        GL.bindFramebuffer(GL.FRAMEBUFFER, _frameBuffers.get(texture));
        if (enableDepthAndStencil) GL.bindRenderbuffer(GL.RENDERBUFFER, _renderBuffers.get(texture));

        var size = _textureSizes.get(texture);
        configureViewport(0, 0, size.first, size.second);
        checkForErrors();
    }

    public function getError():Int {
        return GL.getError();
    }

    override public function generateMipmaps(texture:Int) {
        GL.bindTexture(GL.TEXTURE_2D, _textures.get(texture));
        GL.generateMipmap(GL.TEXTURE_2D);
        checkForErrors();
        _currentBoundTexture = texture;
    }

    function uploadVec4(location:Int, count:Int, values:Array<Float>, components:Int) {
        var uniform = _uniformInputLocations.get(location);
        if (uniform == null || count <= 0) return;
        var bytes = Bytes.alloc(count * 16);
        for (i in 0...count) {
            for (j in 0...components) {
                var sourceIndex = i * components + j;
                if (sourceIndex < values.length) bytes.setFloat(i * 16 + j * 4, values[sourceIndex]);
            }
        }
        GL.uniform4fv(uniform, bytes.getData(), 0, count);
    }

    override public function setUniformFloat(location:Int, count:Int, v:Array<Float>) uploadVec4(location, count, v, 1);
    override public function setUniformFloat2(location:Int, count:Int, v:Array<Float>) uploadVec4(location, count, v, 2);
    override public function setUniformFloat3(location:Int, count:Int, v:Array<Float>) uploadVec4(location, count, v, 3);
    override public function setUniformFloat4(location:Int, count:Int, v:Array<Float>) uploadVec4(location, count, v, 4);

    override public function setUniformMatrix4x4(location:Int, count:Int, v:Array<Float>) {
        var uniform = _uniformInputLocations.get(location);
        if (uniform == null || count <= 0) return;
        var bytes = Bytes.alloc(count * 64);
        for (i in 0...(count * 16)) {
            if (i < v.length) bytes.setFloat(i * 4, v[i]);
        }
        GL.uniformMatrix4fv(uniform, false, bytes.getData(), 0, count);
    }

    function intsToFloats(v:Array<Int>):Array<Float> {
        var r = new Array<Float>();
        for (value in v) r.push(value);
        return r;
    }

    override public function setUniformInt(location:Int, count:Int, v:Array<Int>) uploadVec4(location, count, intsToFloats(v), 1);
    override public function setUniformInt2(location:Int, count:Int, v:Array<Int>) uploadVec4(location, count, intsToFloats(v), 2);
    override public function setUniformInt3(location:Int, count:Int, v:Array<Int>) uploadVec4(location, count, intsToFloats(v), 3);
    override public function setUniformInt4(location:Int, count:Int, v:Array<Int>) uploadVec4(location, count, intsToFloats(v), 4);

    public function supportsExtension(extensionNameString:String):Bool {
        return GL.hasExtension(extensionNameString);
    }

    public function availableTextureFormats():IntMap<Int> {
        var formats = new IntMap<Int>();
        formats.set(TextureFormat.RGB, GL.RGB);
        formats.set(TextureFormat.RGBA, GL.RGBA);
        return formats;
    }
}
