package minko.render;
import haxe.io.Int32Array;
import haxe.io.UInt32Array;
import glm.Vec4;
import haxe.ds.IntMap;
import haxe.ds.ObjectMap;
import haxe.io.Bytes;
import js.html.Float32Array;
import js.html.Uint16Array;
import js.html.Uint8Array;
import js.html.webgl.ActiveInfo;
import js.html.webgl.Buffer;
import js.html.webgl.Framebuffer;
import js.html.webgl.GL;
import js.html.webgl.Renderbuffer;
import js.html.webgl.UniformLocation;
import Lambda;
import minko.render.Blending.Destination;
import minko.render.Blending.Mode;
import minko.render.Blending.Source;
import minko.render.ProgramInputs.AttributeInput;
import minko.render.ProgramInputs.UniformInput;
/*
* ArrayBufferView is an abstract type that is the base for the following types:
 * DataView, Float32Array, Float64Array, Int8Array, Int16Array, Int32Array, Uint8Array, Uint8ClampedArray, Uint16Array, Uint32Array.
* */
@:expose("minko.render.GlContext")
class GlContext extends AbstractContext {
    inline   function bytesToUint8Array(b:haxe.io.Bytes):Uint8Array {

        return new Uint8Array(b.getData());
    }
    static inline var GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
    static inline var GL_STENCIL = 0x1802;
    static inline var GL_COMPRESSED_RGB_S3TC_DXT1_EXT = 0x83F0;
    static inline var GL_COMPRESSED_RGBA_S3TC_DXT1_EXT = 0x83F1;

    static inline var GL_COMPRESSED_RGBA_S3TC_DXT3_EXT = 0x83F2;
    static inline var GL_COMPRESSED_RGBA_S3TC_DXT5_EXT = 0x83F3;

    static inline var GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG = 0x8C00;
    static inline var GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG = 0x8C01;
    static inline var GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG = 0x8C02;
    static inline var GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG = 0x8C03;

    static inline var GL_COMPRESSED_RGBA_PVRTC_2BPPV2_IMG = 0x9137;
    static inline var GL_COMPRESSED_RGBA_PVRTC_4BPPV2_IMG = 0x9138;
    static inline var GL_ETC1_RGB8_OES = 0x8D64;
    static inline var GL_ATC_RGB_AMD = 0x8C92;
    static inline var GL_ATC_RGBA_EXPLICIT_ALPHA_AMD = 0x8C93;
    private static var _blendingFactors:IntMap<Int> = initializeBlendFactorsMap();

    static function initializeBlendFactorsMap() {
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
        m.set(Destination.ONE_MINUS_DST_ALPHA, GL.ONE_MINUS_DST_ALPHA);
        m.set(Destination.ONE_MINUS_SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
        m.set(Destination.DST_ALPHA, GL.DST_ALPHA);
        m.set(Destination.ONE_MINUS_DST_ALPHA, GL.ONE_MINUS_DST_ALPHA);

        return m;
    }
    private static var _compareFuncs:IntMap< Int> = initializeDepthFuncsMap();

    static function initializeDepthFuncsMap() {
        var m = new IntMap< Int>();

        m.set(CompareMode.ALWAYS, GL.ALWAYS);
        m.set(CompareMode.EQUAL, GL.EQUAL);
        m.set(CompareMode.GREATER, GL.GREATER);
        m.set(CompareMode.GREATER_EQUAL, GL.GEQUAL);
        m.set(CompareMode.LESS, GL.LESS);
        m.set(CompareMode.LESS_EQUAL, GL.LEQUAL);
        m.set(CompareMode.NEVER, GL.NEVER);
        m.set(CompareMode.NOT_EQUAL, GL.NOTEQUAL);

        return m;
    }
    private static var _stencilOps:IntMap< Int> = initializeStencilOperationsMap();

    static function initializeStencilOperationsMap() {
        var m = new IntMap< Int>();

        m.set(StencilOperation.KEEP, GL.KEEP);
        m.set(StencilOperation.ZERO, GL.ZERO);
        m.set(StencilOperation.REPLACE, GL.REPLACE);
        m.set(StencilOperation.INCR, GL.INCR);
        m.set(StencilOperation.INCR_WRAP, GL.INCR_WRAP);
        m.set(StencilOperation.DECR, GL.DECR);
        m.set(StencilOperation.DECR_WRAP, GL.DECR_WRAP);
        m.set(StencilOperation.INVERT, GL.INVERT);

        return m;
    }
    private static var _availableTextureFormats:IntMap< Int> = new IntMap< Int>();
    private var _errorsEnabled:Bool;
    private var _textures:IntMap<js.html.webgl.Texture>;
    private var _textureSizes:IntMap<Tuple<Int, Int>>;
    private var _textureHasMipmaps:IntMap<Bool>;
    private var _textureTypes:IntMap<TextureType>;
    private var _driverInfo:String;
    private var _oglMajorVersion:Int;
    private var _oglMinorVersion:Int;
    private var _vertexBuffers:IntMap<js.html.webgl.Buffer>;
    private var _indexBuffers:IntMap<js.html.webgl.Buffer>;
    private var _programs:IntMap<js.html.webgl.Program>;
    private var _vertexShaders:IntMap<js.html.webgl.Shader>;
    private var _fragmentShaders:IntMap<js.html.webgl.Shader>;
    private var _shaders:IntMap<js.html.webgl.Shader>;
    private var _frameBuffers:IntMap<Framebuffer>;
    private var _renderBuffers:IntMap<Renderbuffer>;
    private var _scissorTest:Bool;
    private var _scissorBox:Vec4;
    private var _viewportX:Int;
    private var _viewportY:Int;
    private var _viewportWidth:Int;
    private var _viewportHeight:Int;
    private var _oldViewportX:Int;
    private var _oldViewportY:Int;
    private var _oldViewportWidth:Int;
    private var _oldViewportHeight:Int;
    private var _currentTarget:Int;
    private var _currentIndexBuffer:Int;
    private var _currentVertexBuffer:IntMap<Int>;
    private var _currentVertexSize:IntMap<Int>;
    private var _currentVertexStride:IntMap<Int>;
    private var _currentVertexOffset:IntMap<Int>;
    private var _currentBoundTexture:Int;
    private var _currentTexture:IntMap<Int>;
    private var _currentWrapMode:IntMap< WrapMode> ;
    private var _currentTextureFilter:IntMap<TextureFilter> ;
    private var _currentMipFilter:IntMap< MipFilter> ;
    private var _currentProgram:Int;
    private var _currentBlendingMode:Mode;
    private var _currentColorMask:Bool;
    private var _currentDepthMask:Bool;
    private var _currentDepthFunc:CompareMode;
    private var _currentTriangleCulling:TriangleCulling;
    private var _currentStencilFunc:CompareMode;
    private var _currentStencilRef:Int;
    private var _currentStencilMask:Int;
    private var _currentStencilFailOp:StencilOperation;
    private var _currentStencilZFailOp:StencilOperation;
    private var _currentStencilZPassOp:StencilOperation;
    private var _vertexAttributeEnabled:IntMap<Bool>;
    private var _stencilBits:Int;
    private var _uniformInputLocations:IntMap<UniformLocation>;
    private var _uniformInputLocationKeys:ObjectMap<UniformLocation, Int>;
    static var locationCount:Int = 0;

    static var vertexBufferCount:Int = 0;
    static var indexBufferCount:Int = 0;
    static var textureCount:Int = 0;
    static var programCount:Int = 0;
    static var shaderCount:Int = 0;

    var canvas:js.html.CanvasElement;
    public var gl:js.html.webgl.RenderingContext;


    public function new() {

        super();
    }

    public function initialize() {
        _textureTypes = new IntMap<TextureType>();
        _uniformInputLocations = new IntMap<UniformLocation>();
        _uniformInputLocationKeys = new ObjectMap<UniformLocation, Int>();
        _errorsEnabled = (false);
        _textures = new IntMap<js.html.webgl.Texture>();
        _textureSizes = new IntMap<Tuple<Int, Int>>();
        _textureHasMipmaps = new IntMap<Bool>();
        _oldViewportX = _viewportX = (0);
        _oldViewportY = _viewportY = (0);
        _oldViewportWidth = _viewportWidth = (0);
        _oldViewportHeight = _viewportHeight = (0);
        _currentTarget = -1;
        _currentIndexBuffer = -1;
        _currentVertexBuffer = new IntMap<Int>();//(8, 0),
        for (i in 0...8) _currentVertexBuffer.set(i, 0);

        _currentVertexSize = new IntMap<Int>();//(8, -1),
        for (i in 0...8) _currentVertexSize.set(i, -1);
        _currentVertexStride = new IntMap<Int>();//(8, -1),
        for (i in 0...8) _currentVertexStride.set(i, -1);
        _currentVertexOffset = new IntMap<Int>();//(8, -1),
        for (i in 0...8) _currentVertexOffset.set(i, -1);
        _currentBoundTexture = (0);
        _currentTexture = new IntMap<Int>();//(8, 0),
        for (i in 0...8) _currentTexture.set(i, 0);
        _currentProgram = (0);
        _currentTriangleCulling = (TriangleCulling.BACK);
        _currentWrapMode = new IntMap< WrapMode>();
        _currentTextureFilter = new IntMap<TextureFilter>();
        _currentMipFilter = new IntMap< MipFilter>();
        _currentBlendingMode = Mode.DEFAULT;
        _currentColorMask = (true);
        _currentDepthMask = (true);
        _currentDepthFunc = (CompareMode.UNSET);
        _currentStencilFunc = (CompareMode.UNSET);
        _currentStencilRef = (0);
        _currentStencilMask = (0x1);
        _currentStencilFailOp = (StencilOperation.UNSET);
        _currentStencilZFailOp = (StencilOperation.UNSET);
        _currentStencilZPassOp = (StencilOperation.UNSET);
        _vertexAttributeEnabled = new IntMap<Bool>();//(32u, false),
        for (i in 0...32) _vertexAttributeEnabled.set(i, false);
        _stencilBits = (0);
        _vertexBuffers = new IntMap<js.html.webgl.Buffer>();
        _indexBuffers = new IntMap<js.html.webgl.Buffer>();
        _programs = new IntMap<js.html.webgl.Program>();
        _vertexShaders = new IntMap<js.html.webgl.Shader>();
        _fragmentShaders = new IntMap<js.html.webgl.Shader>();
        _shaders = new IntMap<js.html.webgl.Shader>();
        _frameBuffers = new IntMap<js.html.webgl.Framebuffer>();
        _renderBuffers = new IntMap<js.html.webgl.Renderbuffer>();

        gl.enable(GL.DEPTH_TEST);
        gl.enable(GL.BLEND);
        gl.enable(GL.CULL_FACE);
        gl.cullFace(GL.BACK);
        gl.frontFace(GL.CCW);


        _driverInfo =  "";// gl.getContextAttributes();
        trace("_getSupportedExtensions"+gl.getSupportedExtensions());
        gl.getExtension("OES_standard_derivatives");
        trace("_getSupportedExtensions"+gl.getSupportedExtensions());
        _oglMajorVersion = 2;
        _oglMinorVersion = 0;


        var viewportSettings = gl.getParameter(GL.VIEWPORT);
        _viewportX = viewportSettings[0];
        _viewportY = viewportSettings[1];
        _viewportWidth = viewportSettings[2];
        _viewportHeight = viewportSettings[3];

        setColorMask(true);
        setDepthTest(true, CompareMode.LESS);

#if  GL_ES_VERSION_2_0
	glGetIntegerv(GL_STENCIL_BITS, &_stencilBits);
#else
        _stencilBits = gl.getParameter(GL.STENCIL_BITS);
        //       _stencilBits = gl.getFramebufferAttachmentParameter(GL.FRAMEBUFFER, GL_STENCIL, GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE);
#end

        if (_stencilBits != -1) {
            gl.enable(GL.STENCIL_TEST);
            setStencilTest(CompareMode.ALWAYS, 0, 0x1, StencilOperation.KEEP, StencilOperation.KEEP, StencilOperation.KEEP);
        }

        initializeExtFunctions();

    }

    function initializeExtFunctions() {

    }

    override public function dispose() {
        for (vertexBuffer in _vertexBuffers.iterator()) {
            gl.deleteBuffer(vertexBuffer);
        }

        for (indexBuffer in _indexBuffers.iterator()) {
            gl.deleteBuffer(indexBuffer);
        }

        for (texture in _textures.iterator()) {
            gl.deleteTexture(texture);
        }

        for (program in _programs.iterator()) {
            gl.deleteProgram(program);
        }

        for (vertexShader in _vertexShaders.iterator()) {
            gl.deleteShader(vertexShader);
        }

        for (fragmentShader in _fragmentShaders.iterator()) {
            gl.deleteShader(fragmentShader);
        }
        super.dispose();
    }

    public static function create() {
        return new GlContext();
    }


    override function get_errorsEnabled() {
        return _errorsEnabled;
    }

    override function set_errorsEnabled(errors) {
        _errorsEnabled = errors;
        return errors;
    }

    override function get_driverInfo() {
        return _driverInfo;
    }

    override function get_renderTarget() {
        return _currentTarget;
    }

    override function get_viewportWidth() {
        return _viewportWidth;
    }

    override function get_viewportHeight() {
        return _viewportHeight;
    }

    override function get_currentProgram() {
        return _currentProgram;
    }

    override public function configureViewport(x:Int, y:Int, width:Int, height:Int) {
        if (x != _viewportX || y != _viewportY || width != _viewportWidth || height != _viewportHeight) {
            _viewportX = x;
            _viewportY = y;
            _viewportWidth = width;
            _viewportHeight = height;

            gl.viewport(x, y, width, height);
        }
    }


    override public function clear(red :Float= 0.0, green:Float = 0.0, blue:Float = 0.0, alpha:Float = 0.0, depth:Float = 1.0, stencil:Int = 0, mask:Int = 0xffffffff) {
        // http://www.opengl.org/sdk/docs/man/xhtml/glClearColor.xml
        //
        // void glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
        // red, green, blue, alpha Specify the red, green, blue, and alpha values used when the color buffers are cleared.
        // The initial values are all 0.
        //
        // glClearColor specify clear values for the color buffers
        gl.clearColor(red, green, blue, alpha);

        // http://www.opengl.org/sdk/docs/man/xhtml/glClearDepth.xml
        //
        // void glClearDepth(GLdouble depth);
        // void glClearDepthf(GLfloat depth);
        // depth Specifies the depth value used when the depth buffer is cleared. The initial value is 1.
        //
        // glClearDepth specify the clear value for the depth buffer
#if GL_ES_VERSION_2_0
				glClearDepthf(depth);
#else
        gl.clearDepth(depth);
#end

        // http://www.opengl.org/sdk/docs/man/xhtml/glClearStencil.xml
        //
        // void glClearStencil(GLint s)
        // Specifies the index used when the stencil buffer is cleared. The initial value is 0.
        //
        // glClearStencil specify the clear value for the stencil buffer
        if (_stencilBits != 0) {
            gl.clearStencil(stencil);
        }

        // http://www.opengl.org/sdk/docs/man/xhtml/glClear.xml
        //
        // void glClear(GLbitfield mask);
        // mask
        // Bitwise OR of masks that indicate the buffers to be cleared. The three masks are GL_COLOR_BUFFER_BIT,
        // GL_DEPTH_BUFFER_BIT, and GL_STENCIL_BUFFER_BIT.
        //
        // glClear clear buffers to preset values
        mask = (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT | GL.STENCIL_BUFFER_BIT) & mask;
        if (mask & GL.DEPTH_BUFFER_BIT != null) {
            gl.depthMask(_currentDepthMask = true);
        }
        gl.clear(mask);
    }

    override public function present() {
        // http://www.opengl.org/sdk/docs/man/xhtml/glFlush.xml
        //
        // force execution of GL commands in finite time
        //glFlush();
           gl.flush();
        //setRenderToBackBuffer();
        //  gl.useProgram(null);
        // gl.bindBuffer(GL.ARRAY_BUFFER, null);

    }

    override public function drawTriangles(firstIndex:Int, numTriangles:Int) {
        gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
//        _currentIndexBuffer = -1;
        gl.drawArrays(GL.TRIANGLES, firstIndex, numTriangles * 3);
        checkForErrors();
    }

    override public function drawIndexBufferTriangles(indexBuffer:Int, firstIndex:Int, numTriangles:Int) {
        if (_currentIndexBuffer != indexBuffer)
		{
            _currentIndexBuffer = indexBuffer;
            gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, _indexBuffers.get(indexBuffer));
        }
        checkForErrors();
        // http://www.opengl.org/sdk/docs/man/xhtml/glDrawElements.xml
        //
        // void glDrawElements(GLenum mode, GLsizei count, GLenum type, const GLvoid* indices);
        // mode Specifies what kind of primitives to render.
        // count Specifies the number of elements to be rendered.
        // type Specifies the type of the values in indices.
        // indices Specifies a pointer to the location where the indices are stored.
        //
        // glDrawElements render primitives from array data
        gl.drawElements(GL.TRIANGLES, numTriangles * 3, GL.UNSIGNED_SHORT, firstIndex);

        checkForErrors();
    }

    function checkForErrors() {

//#if DEBUG
        if (_errorsEnabled && getError() != GL.NO_ERROR) {
            throw ("error: OpenGLES2Context::checkForErrors()");
            trace("\n");
            throw "";
        }
//#end
    }


    override public function createVertexBuffer(size:Int) {


        // http://www.opengl.org/sdk/docs/man/xhtml/glGenBuffers.xml
        //
        // void glGenBuffers(GLsizei n, GLuint* buffers);
        // n Specifies the number of buffer object names to be vertexBufferd.
        // buffers Specifies an array in which the generated buffer object names are stored.
        //
        // glGenBuffers returns n buffer object names in buffers. There is no
        // guarantee that the names form a contiguous set of integers; however,
        // it is guaranteed that none of the returned names was in use immediately
        // before the call to glGenBuffers.
        var vertexBuffer:Buffer = gl.createBuffer();

        // http://www.opengl.org/sdk/docs/man/xhtml/glBindBuffer.xml
        //
        // void glBindBuffer(GLenum target, GLuint buffer);
        // target Specifies the target to which the buffer object is bound.
        // buffer Specifies the name of a buffer object.
        //
        // glBindBuffer binds a buffer object to the specified buffer binding point.
        gl.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);

        // http://www.opengl.org/sdk/docs/man/xhtml/glBufferData.xml
        //
        // void glBufferData(GLenum target, GLsizeiptr size, const GLvoid* data, GLenum usage)
        // target Specifies the target buffer object.
        // size Specifies the size in bytes of the buffer object's new data store.
        // data Specifies a pointer to data that will be copied into the data store for initialization, or NULL if no data is to be copied.
        // usage Specifies the expected usage pattern of the data store.
        //
        // glBufferData creates and initializes a buffer object's data store
        gl.bufferData(GL.ARRAY_BUFFER, size * UInt32Array.BYTES_PER_ELEMENT, GL.STATIC_DRAW);
        vertexBufferCount += 1;
        _vertexBuffers.set(vertexBufferCount, vertexBuffer);

        checkForErrors();

        return vertexBufferCount;
    }

    override public function createVertexAttributeArray() {
        /*
        var vao = gl.createVertexArray();

*/
        return -1;
    }

    override public function setVertexAttributeArray(vertexArray:Int) {
        //     gl.bindVertexArray(vao);
        //  checkForErrors();
    }

    override public function setVertexBufferAt(position:Int, vertexBuffer:Int, size:Int, stride:Int, offset:Int) {
        var vertexAttributeEnabled = vertexBuffer > 0;
        var vertexBufferChanged = (_currentVertexBuffer.get(position) != vertexBuffer) || vertexAttributeEnabled;

        if (vertexBufferChanged) {
            gl.bindBuffer(GL.ARRAY_BUFFER, _vertexBuffers.get(vertexBuffer));
            checkForErrors();

            _currentVertexBuffer.set(position, vertexBuffer);
        }

        if (vertexBufferChanged
        || _currentVertexSize.get(position) != size
        || _currentVertexStride.get(position) != stride
        || _currentVertexOffset.get(position) != offset) {
            // http://www.khronos.org/opengles/sdk/docs/man/xhtml/glVertexAttribPointer.xml

            gl.vertexAttribPointer(position, size, GL.FLOAT, false, 4 * stride, (4 * offset));
            checkForErrors();

            _currentVertexSize.set(position, size);
            _currentVertexStride.set(position, stride);
            _currentVertexOffset.set(position, offset);
        }

        if (vertexBufferChanged || _vertexAttributeEnabled.get(position) != vertexAttributeEnabled) {
            if (vertexAttributeEnabled) {
                gl.enableVertexAttribArray(position);
                checkForErrors();

                _vertexAttributeEnabled.set(position, true);
            }
            else {
                gl.disableVertexAttribArray(position);
                checkForErrors();

                _vertexAttributeEnabled.set(position, false);

            }
        }
    }

    override public function uploadVertexBufferData(vertexBuffer:Int, offset:Int, size:Int, data:Array<Float>) {
        gl.bindBuffer(GL.ARRAY_BUFFER, _vertexBuffers.get(vertexBuffer));
        // http://www.opengl.org/sdk/docs/man/xhtml/glBufferSubData.xml
        //
        // void glBufferSubData(GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid* data);
        // target Specifies the target buffer object
        // offset Specifies the offset into the buffer object's data store where data replacement will begin, measured in bytes.
        // size Specifies the size in bytes of the data store region being replaced.
        // data Specifies a pointer to the new data that will be copied into the data store.
        //
        // glBufferSubData updates a subset of a buffer object's data store

        gl.bufferSubData(GL.ARRAY_BUFFER, offset * Int32Array.BYTES_PER_ELEMENT, new Float32Array(data));
        checkForErrors();
    }

    override public function deleteVertexBuffer(vertexBuffer:Int) {
        for (currentVertexBuffer in _currentVertexBuffer.keys())
            if (_currentVertexBuffer.get(currentVertexBuffer) == vertexBuffer)
                _currentVertexBuffer.set(currentVertexBuffer, 0);

        // http://www.opengl.org/sdk/docs/man/xhtml/glDeleteBuffers.xml
        //
        // void glDeleteBuffers(GLsizei n, const GLuint* buffers)
        // n Specifies the number of buffer objects to be deleted.
        // buffers Specifies an array of buffer objects to be deleted.
        //
        // glDeleteBuffers deletes n buffer objects named by the elements of the array buffers. After a buffer object is
        // deleted, it has no contents, and its name is free for reuse (for example by glGenBuffers). If a buffer object
        // that is currently bound is deleted, the binding reverts to 0 (the absence of any buffer object).
        gl.deleteBuffer(_vertexBuffers.get(vertexBuffer));
        _vertexBuffers.remove(vertexBuffer) ;
        checkForErrors();
    }

    override public function createIndexBuffer(size:Int) {
        var indexBuffer:Buffer = gl.createBuffer();
        gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, indexBuffer);


        gl.bufferData(GL.ELEMENT_ARRAY_BUFFER, size * Uint16Array.BYTES_PER_ELEMENT, GL.STATIC_DRAW);
        indexBufferCount += 1;
       // _currentIndexBuffer = indexBufferCount;
        _indexBuffers.set(indexBufferCount, indexBuffer);
        checkForErrors();

        return indexBufferCount;
    }

    override public function uploaderIndexBufferData(indexBuffer:Int, offset:Int, size:Int, data:Array<Int>) {
        if (_currentIndexBuffer != indexBuffer) {
            gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, _indexBuffers.get(indexBuffer));
            _currentIndexBuffer = indexBuffer;
        }
//        if(_indexBuffersSize.get(indexBuffer)!=size){
//            throw "_indexBuffersSize.get(indexBuffer)!=size";
//        }


        gl.bufferSubData(GL.ELEMENT_ARRAY_BUFFER, offset * Uint16Array.BYTES_PER_ELEMENT, new Uint16Array(data));
        checkForErrors();
    }


    public override function deleteIndexBuffer(indexBuffer:Int) {
        if (_currentIndexBuffer == indexBuffer) {
            _currentIndexBuffer = -1;
        }
        gl.deleteBuffer(_indexBuffers.get(indexBuffer));
        _indexBuffers.remove(indexBuffer);
        checkForErrors();
    }

    override public function createTexture(type:TextureType, width:Int, height:Int, mipMapping:Bool, optimizeForRenderToTexture:Bool = false, assertPowerOfTwoSized:Bool = true) {


        if (assertPowerOfTwoSized) {
            // make sure width is a power of 2
            if (!((width != 0) && (width & (width - 1)) == 0))
                throw ("width");

            // make sure height is a power of 2
            if (!((height != 0) && (height & (height - 1)) == 0))
                throw ("height");
        }
        else {
            if (mipMapping)
                throw ("assertPowerOfTwoSized must be true when mipMapping is true");
        }

        // http://www.opengl.org/sdk/docs/man/xhtml/glGenTextures.xml
        //
        // void glGenTextures(GLsizei n, GLuint* textures)
        // n Specifies the number of texture names to be generated.
        // textures Specifies an array in which the generated texture names are stored.
        //
        // glGenTextures generate texture names
        var texture:js.html.webgl.Texture = gl.createTexture();

        // http://www.opengl.org/sdk/docs/man/xhtml/glBindTexture.xml
        //
        // void glBindTexture(GLenum target, GLuint texture);
        // target Specifies the target to which the texture is bound.
        // texture Specifies the name of a texture.
        //
        // glBindTexture bind a named texture to a texturing target
        var glTarget = (type == TextureType.Texture2D
        ? GL.TEXTURE_2D
        : GL.TEXTURE_CUBE_MAP);

        gl.bindTexture(glTarget, texture);
        textureCount++;
        _currentBoundTexture = textureCount;
        //texture;

        // default sampler states
        gl.texParameteri(glTarget, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        gl.texParameteri(glTarget, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        gl.texParameteri(glTarget, GL.TEXTURE_MAG_FILTER, GL.NEAREST);

        _textures.set(textureCount, texture);
        _textureSizes.set(textureCount, new Tuple<Int, Int>(width, height));
        _textureHasMipmaps.set(textureCount, mipMapping);
        _textureTypes.set(textureCount, type);

        _currentWrapMode.set(textureCount, WrapMode.CLAMP);
        _currentTextureFilter.set(textureCount, TextureFilter.NEAREST);
        _currentMipFilter.set(textureCount, MipFilter.NONE);

        // http://www.opengl.org/sdk/docs/man/xhtml/glTexImage2D.xml
        //
        // void glTexImage2D(GLenum target, GLint level, GLint internalFormat, GLsizei width, GLsizei height, GLint border,
        // GLenum format, GLenum type, const GLvoid* data);
        // target Specifies the target texture.
        // level Specifies the level-of-detail number. Level 0 is the base image level. Level n is the nth mipmap reduction
        // image. If target is GL_TEXTURE_RECTANGLE or GL_PROXY_TEXTURE_RECTANGLE, level must be 0.
        // internalFormat Specifies the number of color components in the texture. Must be one of base internal formats given in Table 1,
        // one of the sized internal formats given in Table 2, or one of the compressed internal formats given in Table 3,
        // below.
        // width Specifies the width of the texture image.
        // height Specifies the height of the texture image.
        // border This value must be 0.
        // format Specifies the format of the pixel data.
        // type Specifies the data type of the pixel data
        // data Specifies a pointer to the image data in memory.
        //
        // glTexImage2D specify a two-dimensional texture image
        if (mipMapping) {
            var level = 0;
            var h = height;
            var w = width;
            var size = width > height ? width : height;
            while (size > 0) {
                if (type == TextureType.Texture2D)
                    gl.texImage2D(GL.TEXTURE_2D, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                else {
                    gl.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_X, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    gl.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_X, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    gl.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Y, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    gl.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    gl.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Z, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                    gl.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, level, GL.RGBA, w, h, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                }

                ++level;
                size = size >> 1;
                w = w >> 1;
                h = h >> 1;
            }
        }
        else {
            if (type == TextureType.Texture2D)
                gl.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
            else {
                gl.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                gl.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                gl.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                gl.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                gl.texImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
                gl.texImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
            }
        }

        if (optimizeForRenderToTexture)
            createRTTBuffers(type, textureCount, width, height);

        checkForErrors();

        return textureCount;
    }


    override public function createRectangleTexture(type:TextureType, width:Int, height:Int) {
        return createTexture(type, width, height, false, false, false);
    }

    override public function createCompressedTexture(type:TextureType, format:TextureFormat, width:Int, height:Int, mipMapping:Bool) {


        // make sure width is a power of 2
        if (!((width != 0) && (width & (width - 1)) == 0))
            throw ("width");

        // make sure height is a power of 2
        if (!((height != 0) && (height & (height - 1)) == 0))
            throw ("height");

        // http://www.opengl.org/sdk/docs/man/xhtml/glGenTextures.xml
        //
        // void glGenTextures(GLsizei n, GLuint* textures)
        // n Specifies the number of texture names to be generated.
        // textures Specifies an array in which the generated texture names are stored.
        //
        // glGenTextures generate texture names
        var texture = gl.createTexture();

        // http://www.opengl.org/sdk/docs/man/xhtml/glBindTexture.xml
        //
        // void glBindTexture(GLenum target, GLuint texture);
        // target Specifies the target to which the texture is bound.
        // texture Specifies the name of a texture.
        //
        // glBindTexture bind a named texture to a texturing target
        var glTarget = (type == TextureType.Texture2D
        ? GL.TEXTURE_2D
        : GL.TEXTURE_CUBE_MAP);

        gl.bindTexture(glTarget, texture);
        textureCount++;
        _currentBoundTexture = textureCount ;

        // default sampler states
        gl.texParameteri(glTarget, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        gl.texParameteri(glTarget, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
        gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        gl.texParameteri(glTarget, GL.TEXTURE_MAG_FILTER, GL.NEAREST);


        _textures.set(textureCount, texture);
        _textureSizes.set(textureCount, new Tuple<Int, Int>(width, height));
        _textureHasMipmaps.set(textureCount, mipMapping);
        _textureTypes.set(textureCount, type);

        _currentWrapMode.set(textureCount, WrapMode.CLAMP);
        _currentTextureFilter.set(textureCount, TextureFilter.NEAREST);
        _currentMipFilter.set(textureCount, MipFilter.NONE);

        var oglFormat = availableTextureFormats().get(format);
        var level = 0;
        var h = height;
        var w = width;
        if (mipMapping) {


            var size = width > height ? width : height;
            while (size > 0) {
                var dataSize = TextureFormatInfo.textureSize(format, w, h);
                var data:Bytes = Bytes.alloc(dataSize) ;//fill 0
                //todo data
                if (type == TextureType.Texture2D)
                    gl.compressedTexImage2D(GL.TEXTURE_2D, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                else {
                    gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_X, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                    gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_X, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                    gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Y, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                    gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                    gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Z, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                    gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                }

                ++level;
                size = size >> 1;
                w = w >> 1;
                h = h >> 1;
            }
        }
        else {
            var dataSize = TextureFormatInfo.textureSize(format, width, height);
            var data:Bytes = Bytes.alloc(dataSize);//fill 0

            if (type == TextureType.Texture2D)
                gl.compressedTexImage2D(GL.TEXTURE_2D, level, oglFormat, w, h, 0, bytesToUint8Array(data));
            else {
                gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_X, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_X, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Y, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_POSITIVE_Z, level, oglFormat, w, h, 0, bytesToUint8Array(data));
                gl.compressedTexImage2D(GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, level, oglFormat, w, h, 0, bytesToUint8Array(data));
            }
        }

        checkForErrors();

        return textureCount;

    }

    public function getTextureType(textureId:Int) {
        var foundTypeIt = _textureTypes.get(textureId);

//Debug.Assert(foundTypeIt != _textureTypes.end());

        return foundTypeIt;
    }

    override public function uploadTexture2dData(texture:Int, width:Int, height:Int, mipLevel:Int, data:Bytes) {
//Debug.Assert(getTextureType(texture) == TextureType.Texture2D);

        gl.bindTexture(GL.TEXTURE_2D, _textures.get(texture));
        gl.texImage2D(GL.TEXTURE_2D, mipLevel, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, bytesToUint8Array(data));

        _currentBoundTexture = texture;

        checkForErrors();
    }

    override public function uploadCubeTextureData(texture:Int, face:CubeTexture.Face, width:Int, height:Int, mipLevel:Int, data:Bytes) {
//Debug.Assert(getTextureType(texture) == TextureType.CubeTexture);

        gl.bindTexture(GL.TEXTURE_CUBE_MAP, _textures.get(texture));

        var cubeFace:Int = 0;
        switch (face)
        {
            case minko.render.CubeTexture.Face.POSITIVE_X:
                cubeFace = GL.TEXTURE_CUBE_MAP_POSITIVE_X;

            case minko.render.CubeTexture.Face.NEGATIVE_X:
                cubeFace = GL.TEXTURE_CUBE_MAP_NEGATIVE_X;

            case minko.render.CubeTexture.Face.POSITIVE_Y:
                cubeFace = GL.TEXTURE_CUBE_MAP_POSITIVE_Y;

            case minko.render.CubeTexture.Face.NEGATIVE_Y:
                cubeFace = GL.TEXTURE_CUBE_MAP_NEGATIVE_Y;

            case minko.render.CubeTexture.Face.POSITIVE_Z:
                cubeFace = GL.TEXTURE_CUBE_MAP_POSITIVE_Z;

            case minko.render.CubeTexture.Face.NEGATIVE_Z:
                cubeFace = GL.TEXTURE_CUBE_MAP_NEGATIVE_Z;

            default:
                throw "";
        }

        gl.texImage2D(cubeFace, mipLevel, GL.RGBA, width, height, 0, GL.RGBA, GL.UNSIGNED_BYTE, bytesToUint8Array(data));

        _currentBoundTexture = texture;

        checkForErrors();
    }

    override public function uploadCompressedTexture2dData(texture:Int, format:TextureFormat, width:Int, height:Int, size:Int, mipLevel:Int, data:Bytes) {
//Debug.Assert(getTextureType(texture) == TextureType.Texture2D);

        var formats = availableTextureFormats();

        gl.bindTexture(GL.TEXTURE_2D, _textures.get(texture));
        gl.compressedTexSubImage2D(GL.TEXTURE_2D, mipLevel, 0, 0, width, height, formats.get(format), bytesToUint8Array(data));

        _currentBoundTexture = texture;

        checkForErrors();
    }

    override public function uploadCompressedCubeTextureData(texture:Int, face:CubeTexture.Face, format:TextureFormat, width:Int, height:Int, mipLevel:Int, data:Bytes) {

        // FIXME
        throw "";
    }

    override public function activateMipMapping(texture:Int) {
        _textureHasMipmaps.set(texture, true);
    }

    override public function deleteTexture(texture:Int) {


        gl.deleteTexture(_textures.get(texture));
        _textures.remove(texture) ;
        if (_frameBuffers.exists(texture)) {
            gl.deleteFramebuffer(_frameBuffers.get(texture));
            _frameBuffers.remove(texture);

            gl.deleteRenderbuffer(_renderBuffers.get(texture));
            _renderBuffers.remove(texture);
        }

        _textureSizes.remove(texture);
        _textureHasMipmaps.remove(texture);
        _textureTypes.remove(texture);

        _currentWrapMode.remove(texture);
        _currentTextureFilter.remove(texture);
        _currentMipFilter.remove(texture);
        _currentTexture.set(texture, 0);
        _currentBoundTexture = (_currentBoundTexture == texture ? 0 : _currentBoundTexture);

        checkForErrors();
    }

    override public function setTextureAt(position:Int, texture:Int, location :Int= -1) {
        var textureIsValid = texture > 0;

        if (!textureIsValid) {
            return;
        }

        if (position >= Lambda.count(_currentTexture)) {
            return;
        }

        var glTarget = getTextureType(texture) == TextureType.Texture2D ? GL.TEXTURE_2D : GL.TEXTURE_CUBE_MAP;

        if (_currentTexture.get(position) != texture || _currentBoundTexture != texture) {
            gl.activeTexture(GL.TEXTURE0 + position);
            gl.bindTexture(glTarget, _textures.get(texture));

            _currentTexture.set(position, texture);
            _currentBoundTexture = texture;
        }

        if (textureIsValid && location >= 0) {
            gl.uniform1i(_uniformInputLocations.get(location), position);
        }

        checkForErrors();
    }

    override public function setSamplerStateAt(position:Int, wrapping:WrapMode, filtering:TextureFilter, mipFiltering:MipFilter) {
        var texture = _currentTexture.get(position);
        var glTarget = getTextureType(texture) == TextureType.Texture2D ? GL.TEXTURE_2D : GL.TEXTURE_CUBE_MAP;

        var active = false;

        // disable mip mapping if mip maps are not available
        if (!_textureHasMipmaps.get(texture)) {
            mipFiltering = MipFilter.NONE;
        }

        if (_currentWrapMode.get(texture) != wrapping) {
            _currentWrapMode.set(texture, wrapping);

            gl.activeTexture(GL.TEXTURE0 + position);
            active = true;
            switch (wrapping)
            {
                case WrapMode.CLAMP :
                    gl.texParameteri(glTarget, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                    gl.texParameteri(glTarget, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

                case WrapMode.REPEAT :
                    gl.texParameteri(glTarget, GL.TEXTURE_WRAP_S, GL.REPEAT);
                    gl.texParameteri(glTarget, GL.TEXTURE_WRAP_T, GL.REPEAT);

            }
        }

        if (_currentTextureFilter.get(texture) != filtering || _currentMipFilter.get(texture) != mipFiltering) {
            _currentTextureFilter.set(texture, filtering);
            _currentMipFilter.set(texture, mipFiltering);

            if (!active) {
                gl.activeTexture(GL.TEXTURE0 + position);
            }

            switch (filtering)
            {
                case TextureFilter.NEAREST :
                    switch (mipFiltering)
                    {
                        case MipFilter.NONE :
                            gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.NEAREST);

                        case MipFilter.NEAREST :
                            gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.NEAREST_MIPMAP_NEAREST);

                        case MipFilter.LINEAR :
                            gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.NEAREST_MIPMAP_LINEAR);

                    }

                    gl.texParameteri(glTarget, GL.TEXTURE_MAG_FILTER, GL.NEAREST);

                case TextureFilter.LINEAR :
                    switch (mipFiltering)
                    {
                        case MipFilter.NONE :
                            gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.LINEAR);

                        case MipFilter.NEAREST :
                            gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_NEAREST);

                        case MipFilter.LINEAR :
                            gl.texParameteri(glTarget, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);

                    }
                    gl.texParameteri(glTarget, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

            }
        }

        checkForErrors();
    }

    override public function createProgram() {
        var handle = gl.createProgram();

        checkForErrors();
        programCount++;
        _programs.set(programCount, handle);

        return programCount;
    }

    override public function attachShader(program:Int, shader:Int) {
        gl.attachShader(_programs.get(program), _shaders.get(shader));

        checkForErrors();
    }

    override public function linkProgram(program:Int) {

        gl.linkProgram(_programs.get(program));

        #if DEBUG
		var errors = getProgramInfoLogs(program);

		if (!errors.empty())
		{
			trace(errors);
			trace("\n");
		}
	#end

        checkForErrors();
    }

    override public function deleteProgram(program:Int) {


        gl.deleteProgram(_programs.get(program));
        _programs.remove(program) ;
        checkForErrors();
    }

    override public function compileShader(shader:Int) {
        gl.compileShader(_shaders.get(shader));

       /// #if DEBUG
		var errors = getShaderCompilationLogs(shader);

		if ( errors!="")
		{
			var  source:String= getShaderSource(shader);

			trace("Shader source (glShaderSource_" + shader + "):\n" + source);
			trace("Shader errors (glShaderSource_" + shader + "):\n" + errors);

			throw  ("Shader compilation failed. Enable debug logs to display errors.");
		}
	//#end

        checkForErrors();
    }

    override public function setProgram(program:Int) {
        if (_currentProgram == program) {
            return;
        }

        _currentProgram = program;

        gl.useProgram(_programs.get(program));

        checkForErrors();
    }

    override public function setShaderSource(shader:Int, source:String) {
        var sourceString:String = source;

        gl.shaderSource(_shaders.get(shader), sourceString);

        checkForErrors();
    }

    public function getShaderSource(shader:Int) {
        var source = gl.getShaderSource(_shaders.get(shader));
        checkForErrors();
        return source;
    }

    override public function createVertexShader() {
        var vertexShader = gl.createShader(GL.VERTEX_SHADER);
        shaderCount++;
        _vertexShaders.set(shaderCount, vertexShader);
        _shaders.set(shaderCount, vertexShader);
        checkForErrors();

        return shaderCount;
    }

    override public function deleteVertexShader(vertexShader:Int) {


        gl.deleteShader(_vertexShaders.get(vertexShader));
        _vertexShaders.remove(vertexShader) ;
        _shaders.remove(vertexShader) ;
        checkForErrors();
    }

    override public function createFragmentShader() {
        var fragmentShader = gl.createShader(GL.FRAGMENT_SHADER);
        shaderCount++;
        _fragmentShaders.set(shaderCount, fragmentShader);
        _shaders.set(shaderCount, fragmentShader);
        checkForErrors();

        return shaderCount;
    }

    override public function deleteFragmentShader(fragmentShader:Int) {

        gl.deleteShader(_fragmentShaders.get(fragmentShader));
        _fragmentShaders.remove(fragmentShader) ;
        _shaders.remove(fragmentShader) ;
        checkForErrors();
    }

    override public function getProgramInputs(program:Int) {
        setProgram(program);
        var ip = new ProgramInputs();
        ip.setProgramInputs(getUniformInputs(_programs.get(program)), getAttributeInputs(_programs.get(program)));
        return ip;
    }

    public function convertInputType(type:Int) {
        switch (type)
        {
            case GL.FLOAT:
                return ProgramInputs.InputType.float1;
            case GL.FLOAT_VEC2:
                return ProgramInputs.InputType.float2;
            case GL.FLOAT_VEC3:
                return ProgramInputs.InputType.float3;
            case GL.FLOAT_VEC4:
                return ProgramInputs.InputType.float4;
            case GL.INT:
                return ProgramInputs.InputType.int1;
            case GL.INT_VEC2:
                return ProgramInputs.InputType.int2;
            case GL.INT_VEC3:
                return ProgramInputs.InputType.int3;
            case GL.INT_VEC4:
                return ProgramInputs.InputType.int4;
            case GL.BOOL:
                return ProgramInputs.InputType.bool1;
            case GL.BOOL_VEC2:
                return ProgramInputs.InputType.bool2;
            case GL.BOOL_VEC3:
                return ProgramInputs.InputType.bool3;
            case GL.BOOL_VEC4:
                return ProgramInputs.InputType.bool4;
            case GL.FLOAT_MAT3:
                return ProgramInputs.InputType.float9;
            case GL.FLOAT_MAT4:
                return ProgramInputs.InputType.float16;
            case GL.SAMPLER_2D:
                return ProgramInputs.InputType.sampler2d;
            case GL.SAMPLER_CUBE:
                return ProgramInputs.InputType.samplerCube;
            default:
                throw ("unsupported type");
                return ProgramInputs.InputType.unknown;
        }
    }

    public function getUniformInput(program:Int, name:String):ProgramInputs.UniformInput {
        var inputs:Array<ProgramInputs.UniformInput> = getUniformInputs(_programs.get(program));
        inputs = inputs.filter(function(i:ProgramInputs.UniformInput) return i.name == name);
        return inputs.length > 0 ? inputs[0] : null;
    }

    inline function getUniformInputs(program:js.html.webgl.Program):Array<ProgramInputs.UniformInput> {
        var inputs:Array<ProgramInputs.UniformInput> = [];

        var total = -1;
        var maxUniformNameLength = -1;

        // maxUniformNameLength=gl.getProgramParameter(program, GL.ACTIVE_UNIFORM_MAX_LENGTH );
        total = gl.getProgramParameter(program, GL.ACTIVE_UNIFORMS);

        for (i in 0... total) {

            var activeInfo:ActiveInfo = gl.getActiveUniform(program, i);
            checkForErrors();
            var name = activeInfo.name;
            var size = activeInfo.size;
            var type = activeInfo.type;

            var inputType = convertInputType(type);
            var location = gl.getUniformLocation(program, name);

            if (location != null && inputType != ProgramInputs.InputType.unknown) {
                //todo;
                if (_uniformInputLocationKeys.exists(location) == false) {
                    locationCount++;
                    _uniformInputLocationKeys.set(location, locationCount);
                    _uniformInputLocations.set(locationCount, location);
                }
                var location_index = _uniformInputLocationKeys.get(location);
                inputs.push(new UniformInput(name, location_index, size, inputType));
            }
        }

        return inputs;
    }

    public function getAttributeInput(program:Int, name:String):ProgramInputs.AttributeInput {
        var inputs:Array<ProgramInputs.AttributeInput> = getAttributeInputs(_programs.get(program));
        inputs = inputs.filter(function(i:ProgramInputs.AttributeInput) return i.name == name);
        return inputs.length > 0 ? inputs[0] : null;
    }

    inline function getAttributeInputs(program:js.html.webgl.Program):Array<ProgramInputs.AttributeInput> {
        var inputs:Array<ProgramInputs.AttributeInput> = [];

        var total = -1;
        var maxAttributeNameLength = -1;

//glGetProgramiv(program, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH, maxAttributeNameLength);
        total = gl.getProgramParameter(program, GL.ACTIVE_ATTRIBUTES);

        for (i in 0...total) {


            var activeInfo:ActiveInfo = gl.getActiveAttrib(program, i);
            var size = activeInfo.size;
            var type = activeInfo.type;
            var name = activeInfo.name;
            checkForErrors();


            var location = gl.getAttribLocation(program, name);

            if (location >= 0) {
                inputs.push(new AttributeInput(name, location));
            }
        }

        return inputs;
    }

    public function getShaderCompilationLogs(shader:Int) {
        var compileStatus = gl.getShaderParameter(_shaders.get(shader), GL.COMPILE_STATUS);
        if (compileStatus == false) {
//var buffer:String =gl.getShaderSource(_shaders.get(shader));
            //todo
            var logs = gl.getShaderInfoLog(_shaders.get(shader));
            return logs ;
        }
        return "";
    }

    public function getProgramInfoLogs(program:Int) {
        var programInfo = gl.getProgramInfoLog(_programs.get(program));
        return programInfo;
    }

    override public function setBlendingModeSD(source:Blending.Source, destination:Blending.Destination) {
        if (( source | destination) != _currentBlendingMode) {
            _currentBlendingMode = ( source | destination);

            gl.blendFunc(_blendingFactors.get(source & 0x00ff), _blendingFactors.get(destination & 0xff00));

            checkForErrors();
        }
    }

    override public function setBlendingMode(blendingMode:Blending.Mode) {

        if (blendingMode != _currentBlendingMode) {
            _currentBlendingMode = blendingMode;

            gl.blendFunc(_blendingFactors.get(blendingMode & 0x00ff), _blendingFactors.get(blendingMode & 0xff00));

            checkForErrors();
        }
    }

    override public function setDepthTest(depthMask:Bool, depthFunc:CompareMode) {
        if (depthMask != _currentDepthMask || depthFunc != _currentDepthFunc) {
            _currentDepthMask = depthMask;
            _currentDepthFunc = depthFunc;

            gl.depthMask(depthMask);
            gl.depthFunc(_compareFuncs.get(depthFunc));

            checkForErrors();
        }
    }

    override public function setColorMask(colorMask:Bool) {
        if (_currentColorMask != colorMask) {
            _currentColorMask = colorMask;

            gl.colorMask(colorMask, colorMask, colorMask, colorMask);

            checkForErrors();
        }

    }

    override public function setStencilTest(stencilFunc:CompareMode, stencilRef:Int, stencilMask:Int, stencilFailOp:StencilOperation, stencilZFailOp:StencilOperation, stencilZPassOp:StencilOperation) {

        if (stencilFunc != _currentStencilFunc || stencilRef != _currentStencilRef || stencilMask != _currentStencilMask) {
            _currentStencilFunc = stencilFunc;
            _currentStencilRef = stencilRef;
            _currentStencilMask = stencilMask;

            gl.stencilFunc(_compareFuncs.get(stencilFunc), stencilRef, stencilMask);

            checkForErrors();
        }


        if (stencilFailOp != _currentStencilFailOp || stencilZFailOp != _currentStencilZFailOp || stencilZPassOp != _currentStencilZPassOp) {
            _currentStencilFailOp = stencilFailOp;
            _currentStencilZFailOp = stencilZFailOp;
            _currentStencilZPassOp = stencilZPassOp;

            gl.stencilOp(_stencilOps.get(stencilFailOp), _stencilOps.get(stencilZFailOp), _stencilOps.get(stencilZPassOp));

            checkForErrors();
        }
    }

    override public function readRectPixels(x:Int, y:Int, width:Int, height:Int, pixels:Bytes) {
        gl.readPixels(x, y, width, height, GL.RGBA, GL.UNSIGNED_BYTE, @:privateAccess pixels.b);
        checkForErrors();
    }

    override public function setScissorTest(scissorTest:Bool, scissorBox:Vec4) {

        if (scissorTest == _scissorTest && scissorBox.equals(_scissorBox)  ) {
            return;
        }

        if (scissorTest) {
            gl.enable(GL.SCISSOR_TEST);

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

            gl.scissor(x, y, width, height);
        }
        else {
            gl.disable(GL.SCISSOR_TEST);
        }

        _scissorTest = scissorTest;
        _scissorBox = scissorBox;

        checkForErrors();
    }

    override public function readPixels(pixels:Bytes) {
        gl.readPixels(_viewportX, _viewportY, _viewportWidth, _viewportHeight, GL.RGBA, GL.UNSIGNED_BYTE, @:privateAccess pixels.b);

        checkForErrors();
    }

    override public function setTriangleCulling(triangleCulling:TriangleCulling) {
        if (triangleCulling == _currentTriangleCulling) {
            return;
        }

        if (_currentTriangleCulling == TriangleCulling.NONE) {
            gl.enable(GL.CULL_FACE);
        }
        _currentTriangleCulling = triangleCulling;

        switch (triangleCulling)
        {
            case TriangleCulling.NONE:
                gl.disable(GL.CULL_FACE);

            case TriangleCulling.BACK :
                gl.cullFace(GL.BACK);

            case TriangleCulling.FRONT :
                gl.cullFace(GL.FRONT);

            case TriangleCulling.BOTH :
                gl.cullFace(GL.FRONT_AND_BACK);

        }

        checkForErrors();
    }

    function createRTTBuffers(type:TextureType, textureKey:Int, width:Int, height:Int) {
        var texture = _textures.get(textureKey);
        var frameBuffer = gl.createFramebuffer();

        // bind the framebuffer object
        gl.bindFramebuffer(GL.FRAMEBUFFER, frameBuffer);
        // attach a texture to the FBO
        if (type == TextureType.Texture2D)
            gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, texture, 0);
        else {
            gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 0, GL.TEXTURE_CUBE_MAP_POSITIVE_X, texture, 0);
            gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 1, GL.TEXTURE_CUBE_MAP_NEGATIVE_X, texture, 0);
            gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 2, GL.TEXTURE_CUBE_MAP_POSITIVE_Y, texture, 0);
            gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 3, GL.TEXTURE_CUBE_MAP_NEGATIVE_Y, texture, 0);
            gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 4, GL.TEXTURE_CUBE_MAP_POSITIVE_Z, texture, 0);
            gl.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0 + 5, GL.TEXTURE_CUBE_MAP_NEGATIVE_Z, texture, 0);
        }


        // gen renderbuffer
        var renderBuffer = gl.createRenderbuffer();
        // bind renderbuffer
        gl.bindRenderbuffer(GL.RENDERBUFFER, renderBuffer);
        // init as a depth buffer
#if  GL_ES_VERSION_2_0
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
#else
        gl.renderbufferStorage(GL.RENDERBUFFER, GL.DEPTH_COMPONENT16, width, height);
#end
        // FIXME: create & attach stencil buffer

        // attach to the FBO for depth
        gl.framebufferRenderbuffer(GL.FRAMEBUFFER, GL.DEPTH_ATTACHMENT, GL.RENDERBUFFER, renderBuffer);

        var status = gl.checkFramebufferStatus(GL.FRAMEBUFFER);
        if (status != GL.FRAMEBUFFER_COMPLETE)
            throw "";

        _frameBuffers.set(textureKey, frameBuffer);
        _renderBuffers.set(textureKey, renderBuffer);

        // unbind
        gl.bindFramebuffer(GL.FRAMEBUFFER, null);
        gl.bindRenderbuffer(GL.RENDERBUFFER, null);

        checkForErrors();
    }

    override public function setRenderToBackBuffer() {
        if (_currentTarget == -1) {
            return;
        }

        gl.bindFramebuffer(GL.FRAMEBUFFER, null);
        gl.bindRenderbuffer(GL.RENDERBUFFER, null);

        configureViewport(_oldViewportX, _oldViewportY, _oldViewportWidth, _oldViewportHeight);

        _currentTarget = -1;

        checkForErrors();
    }

    override public function setRenderToTexture(texture:Int, enableDepthAndStencil :Bool= false) {
        if (texture == _currentTarget) {
            return;
        }

        if (_frameBuffers.exists(texture) == false) {
            throw ("this texture cannot be used for RTT");
        }
        if (_renderBuffers.exists(texture) == false) {
            throw ("this texture cannot be used for RTT");
        }
        if (_currentTarget == -1) {
            _oldViewportX = _viewportX;
            _oldViewportY = _viewportY;
            _oldViewportWidth = _viewportWidth;
            _oldViewportHeight = _viewportHeight;
        }
        _currentTarget = texture;

        gl.bindFramebuffer(GL.FRAMEBUFFER, _frameBuffers.get(texture));
        checkForErrors();

        if (enableDepthAndStencil) {
            gl.bindRenderbuffer(GL.RENDERBUFFER, _renderBuffers.get(texture));
            // attach to the FBO for depth
            checkForErrors();
        }

        var textureSize:Tuple<Int, Int> = _textureSizes.get(texture);

        configureViewport(0, 0, textureSize.first, textureSize.second);
        checkForErrors();
    }


    public function getError() {
        return 0;
        var error = gl.getError();

        switch (error)
        {

            case GL.INVALID_ENUM:
                throw ("GL_INVALID_ENUM");

            case GL.INVALID_FRAMEBUFFER_OPERATION:
                throw("GL_INVALID_FRAMEBUFFER_OPERATION");

            case GL.INVALID_VALUE:
                throw("GL_INVALID_VALUE");

            case GL.INVALID_OPERATION:
                throw("GL_INVALID_OPERATION");

            case GL.OUT_OF_MEMORY:
                throw("GL_OUT_OF_MEMORY");

            default:

        }

        return error;
    }

    override public function generateMipmaps(texture:Int) {
        gl.bindTexture(GL.TEXTURE_2D, _textures.get(texture));

        // glGenerateMipmap exists in OpenGL ES 2.0+ or OpenGL 3.0+
        // https://www.khronos.org/opengles/sdk/docs/man/xhtml/glGenerateMipmap.xml
        // https://www.opengl.org/sdk/docs/man/html/glGenerateMipmap.xhtml
        #if ! GL_ES_VERSION_2_0
        if (_oglMajorVersion < 3) {
            //if (supportsExtension("GL_SGIS_generate_mipmap")) {
            gl.generateMipmap(GL.TEXTURE_2D);
            //}
            #if DEBUG
			else
			{
				throw std::runtime_error("Missing OpenGL extension: 'GL_SGIS_generate_mipmap'.");
			}
	#end
        }
        else {
            #end
            gl.generateMipmap(GL.TEXTURE_2D);
        }

        checkForErrors();

        _currentBoundTexture = texture;
    }

    override public function setUniformFloat(location:Int, count:Int, v:Array<Float>) {
        gl.uniform1fv(_uniformInputLocations.get(location), v);
    }

    override public function setUniformFloat2(location:Int, count:Int, v:Array<Float>) {
        gl.uniform2fv(_uniformInputLocations.get(location), v);
    }

    override public function setUniformFloat3(location:Int, count:Int, v:Array<Float>) {
        gl.uniform3fv(_uniformInputLocations.get(location), v);
    }

    override public function setUniformFloat4(location:Int, count:Int, v:Array<Float>) {
        gl.uniform4fv(_uniformInputLocations.get(location), v);
    }

    override public function setUniformMatrix4x4(location:Int, count:Int, v:Array<Float>) {
        gl.uniformMatrix4fv(_uniformInputLocations.get(location), false, v);
    }

    override public function setUniformInt(location:Int, count:Int, v:Array<Int>) {
        gl.uniform1iv(_uniformInputLocations.get(location), v);
    }

    override public function setUniformInt2(location:Int, count:Int, v:Array<Int>) {
        gl.uniform2iv(_uniformInputLocations.get(location), v);
    }

    override public function setUniformInt3(location:Int, count:Int, v:Array<Int>) {
        gl.uniform3iv(_uniformInputLocations.get(location), v);
    }

    override public function setUniformInt4(location:Int, count:Int, v:Array<Int>) {
        gl.uniform4iv(_uniformInputLocations.get(location), v);
    }

    public function supportsExtension(extensionNameString:String) {

        return gl.getExtension(extensionNameString) != null;
    }

    public function availableTextureFormats():IntMap< Int > {

        if (Lambda.count(_availableTextureFormats) > 0) {
            return _availableTextureFormats;
        }

        var formats = _availableTextureFormats;

        formats.set(TextureFormat.RGB, GL.RGB);
        formats.set(TextureFormat.RGBA, GL.RGBA) ;

        var rawFormats:Array<Int> = gl.getParameter(GL.COMPRESSED_TEXTURE_FORMATS);
        for (rawFormat in rawFormats) {
            switch (rawFormat)
            {

                case GL_COMPRESSED_RGB_S3TC_DXT1_EXT:
                    formats.set(TextureFormat.RGB_DXT1, GL_COMPRESSED_RGB_S3TC_DXT1_EXT);
                    break;
                case GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:
                    formats.set(TextureFormat.RGBA_DXT1, GL_COMPRESSED_RGBA_S3TC_DXT1_EXT);
                    break;

                case GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:
                    formats.set(TextureFormat.RGBA_DXT3, GL_COMPRESSED_RGBA_S3TC_DXT3_EXT);
                    break;
                case GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:
                    formats.set(TextureFormat.RGBA_DXT5, GL_COMPRESSED_RGBA_S3TC_DXT5_EXT);
                    break;

                case GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:
                    formats.set(TextureFormat.RGB_PVRTC1_2BPP, GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG);
                    break;
                case GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:
                    formats.set(TextureFormat.RGB_PVRTC1_4BPP, GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG);
                    break;
                case GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG:
                    formats.set(TextureFormat.RGBA_PVRTC1_2BPP, GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG);
                    break;
                case GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:
                    formats.set(TextureFormat.RGBA_PVRTC1_4BPP, GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG);
                    break;

                case GL_COMPRESSED_RGBA_PVRTC_2BPPV2_IMG:
                    formats.set(TextureFormat.RGBA_PVRTC2_2BPP, GL_COMPRESSED_RGBA_PVRTC_2BPPV2_IMG);
                    break;
                case GL_COMPRESSED_RGBA_PVRTC_4BPPV2_IMG:
                    formats.set(TextureFormat.RGBA_PVRTC2_4BPP, GL_COMPRESSED_RGBA_PVRTC_4BPPV2_IMG);
                    break;

                case GL_ETC1_RGB8_OES:
                    formats.set(TextureFormat.RGB_ETC1, GL_ETC1_RGB8_OES);
                    formats.set(TextureFormat.RGBA_ETC1, GL_ETC1_RGB8_OES);
                    break;

                case GL_ATC_RGB_AMD:
                    formats.set(TextureFormat.RGB_ATITC, GL_ATC_RGB_AMD);
                    break;
                case GL_ATC_RGBA_EXPLICIT_ALPHA_AMD:
                    formats.set(TextureFormat.RGBA_ATITC, GL_ATC_RGBA_EXPLICIT_ALPHA_AMD);
                    break;

                default:
                    break;
            }
        }

        return formats;
    }
}
