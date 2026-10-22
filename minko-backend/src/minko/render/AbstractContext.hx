package minko.render;

import glm.Vec4;
import haxe.io.Bytes;
@:expose("minko.render.AbstractContextFace")
@:enum abstract AbstractContextFace(Int) from Int to Int {
    var POSITIVE_X = 0;
    var NEGATIVE_X = 1;
    var POSITIVE_Y = 2;
    var NEGATIVE_Y = 3;
    var POSITIVE_Z = 4;
    var NEGATIVE_Z = 5;
}

@:expose("minko.render.AbstractContext")
class AbstractContext {

    public function dispose() {
    }
    public var errorsEnabled(get, set):Bool;

    function get_errorsEnabled() {
        return false;
    }

    function set_errorsEnabled(errors:Bool) {
        return errors;

    }
    public var driverInfo(get, null):String;

    function get_driverInfo() {
        return "";
    }

    public var renderTarget(get, null):Int;

    public var viewportWidth(get, null):Int;

    public var viewportHeight(get, null):Int;

    public var currentProgram(get, null):Int;

    function get_renderTarget() {
        return -1;
    }

    function get_viewportWidth() {
        return -1;
    }

    function get_viewportHeight() {
        return -1;
    }

    function get_currentProgram() {
        return -1;
    }

    public function configureViewport(x:Int, y:Int, width:Int, height:Int) {

    }

    public function clear(red:Float = 0.0, green:Float = 0.0, blue:Float = 0.0, alpha:Float = 0.0, depth:Float = 1.0, stencil:Int = 0, mask:Int = 0xffffffff) {

    }

    public function present() :Void{

    }

    public function drawIndexBufferTriangles(indexBuffer:Int, firstIndex:Int, numTriangles:Int) {

    }

    public function drawTriangles(firstIndex:Int, numTriangles:Int) {

    }

    public function createVertexBuffer(size:Int) {
        return -1;
    }

    public function setVertexBufferAt(position:Int, vertexBuffer:Int, size:Int, stride:Int, offset:Int) {

    }

    public function uploadVertexBufferData(vertexBuffer:Int, offset:Int, size:Int, data:Array<Float>) {

    }

    public function deleteVertexBuffer(vertexBuffer:Int) {

    }

    public function createIndexBuffer(size:Int) {
        return -1;
    }

    public function uploaderIndexBufferData(indexBuffer:Int, offset:Int, size:Int, data:Array<Int>) {

    }

    public function deleteIndexBuffer(indexBuffer:Int) {

    }

    public function createTexture(type:TextureType, width:Int, height:Int, mipMapping:Bool, optimizeForRenderToTexture:Bool = false, assertPowerOfTwoSized :Bool= true) {
        return -1;
    }

    public function createRectangleTexture(type:TextureType, width:Int, height:Int) {
        return -1;
    }

    public function createCompressedTexture(type:TextureType, format:TextureFormat, width:Int, height:Int, mipMapping:Bool) {
        return -1;
    }

    public function uploadTexture2dData(texture:Int, width:Int, height:Int, mipLevel:Int, data:Bytes) {

    }

    public function uploadCubeTextureData(texture:Int, face:CubeTexture.Face, width:Int, height:Int, mipLevel:Int, data:Bytes) {
    }

    public function uploadCompressedTexture2dData(texture:Int, format:TextureFormat, width:Int, height:Int, size:Int, mipLevel:Int, data:Bytes) {

    }

    public function uploadCompressedCubeTextureData(texture:Int, face:CubeTexture.Face, format:TextureFormat, width:Int, height:Int, mipLevel:Int, data:Bytes) {

    }

    public function activateMipMapping(texture:Int) {

    }

    public function deleteTexture(texture:Int) {

    }

    public function setTextureAt(position:Int, texture:Int, location :Int= -1) {

    }

    public function setSamplerStateAt(position:Int, wrapping:WrapMode, filtering:TextureFilter, mipFiltering:MipFilter) {

    }

    public function createProgram() {
        return -1;
    }

    public function attachShader(program:Int, shader:Int) {

    }

    public function linkProgram(program:Int) {

    }

    public function deleteProgram(program:Int) {

    }

    public function setProgram(program:Int) {

    }

    public function compileShader(shader:Int) {

    }

    public function setShaderSource(shader:Int, source:String) {

    }

    public function createVertexShader() {
        return -1;
    }

    public function deleteVertexShader(vertexShader:Int) {

    }

    public function createFragmentShader() {
        return -1;
    }

    public function deleteFragmentShader(fragmentShader:Int) {

    }

    public function getProgramInputs(program:Int):ProgramInputs {
        return null;
    }

    public function setBlendingModeSD(source:Blending.Source, destination:Blending.Destination) {

    }

    public function setBlendingMode(blendMode:Blending.Mode) {

    }

    public function setColorMask(NamelessParameter:Bool) {

    }

    public function setDepthTest(depthMask:Bool, depthFunc:CompareMode) {

    }

    public function setStencilTest(stencilFunc:CompareMode, stencilRef:Int, stencilMask:Int, stencilFailOp:StencilOperation, stencilZFailOp:StencilOperation, stencilZPassOp:StencilOperation) {

    }

    public function setScissorTest(scissorTest:Bool, NamelessParameter2:Vec4) {

    }

    public function readPixels(pixels:Bytes) {

    }

    public function readRectPixels(x:Int, y:Int, width:Int, height:Int, pixels:Bytes) {

    }

    public function setTriangleCulling(triangleCulling:TriangleCulling) {

    }

    public function setRenderToBackBuffer() {

    }

    public function setRenderToTexture(texture:Int, enableDepthAndStencil:Bool = false) {

    }

    public function generateMipmaps(texture:Int) {

    }

    public function setUniformFloat(location:Int, count:Int, v:Array<Float>) {

    }

    public function setUniformFloat2(location:Int, count:Int, v:Array<Float>) {

    }


    public function setUniformFloat3(location:Int, count:Int, v:Array<Float>) {

    }

    public function setUniformFloat4(location:Int, count:Int, v:Array<Float>) {

    }

    public function setUniformMatrix4x4(location:Int, count:Int, v:Array<Float>) {

    }

    public function setUniformInt(location:Int, count:Int, v:Array<Int>) {

    }

    public function setUniformInt2(location:Int, count:Int, v:Array<Int>) {

    }

    public function setUniformInt3(location:Int, count:Int, v:Array<Int>) {

    }

    public function setUniformInt4(location:Int, count:Int, v:Array<Int>) {

    }

    public function createVertexAttributeArray() {


        return -1;
    }

    public function setVertexAttributeArray(vertexArray:Int) {

    }

    public function new() {
    }
}
