package minko.render;

import glm.Vec4;
import haxe.io.Bytes;
@:enum abstract AbstractContextFace(Int) from Int to Int {
    var POSITIVE_X = 0;
    var NEGATIVE_X = 1;
    var POSITIVE_Y = 2;
    var NEGATIVE_Y = 3;
    var POSITIVE_Z = 4;
    var NEGATIVE_Z = 5;
}

class AbstractContext {

    public function dispose() {
    }
    public var errorsEnabled(get, set):Bool;

    function get_errorsEnabled() {
        return false;
    }

    function set_errorsEnabled(errors) {
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

    public function clear(red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0, depth = 1.0, stencil = 0, mask = 0xffffffff) {

    }

    public function present() {

    }

    public function drawIndexBufferTriangles(indexBuffer:Int, firstIndex:Int, numTriangles:Int) {

    }

    public function drawTriangles(firstIndex:Int, numTriangles:Int) {

    }

    public function createVertexBuffer(size) {
        return -1;
    }

    public function setVertexBufferAt(position:Int, vertexBuffer:Int, size:Int, stride:Int, offset:Int) {

    }

    public function uploadVertexBufferData(vertexBuffer:Int, offset:Int, size:Int, data:Array<Float>) {

    }

    public function deleteVertexBuffer(vertexBuffer:Int) {

    }

    public function createIndexBuffer(size) {
        return -1;
    }

    public function uploaderIndexBufferData(indexBuffer:Int, offset:Int, size:Int, data:Array<Int>) {

    }

    public function deleteIndexBuffer(indexBuffer) {

    }

    public function createTexture(type:TextureType, width, height, mipMapping:Bool, optimizeForRenderToTexture = false, assertPowerOfTwoSized = true) {
        return -1;
    }

    public function createRectangleTexture(type:TextureType, width, height) {
        return -1;
    }

    public function createCompressedTexture(type:TextureType, format:TextureFormat, width, height, mipMapping) {
        return -1;
    }

    public function uploadTexture2dData(texture, width, height, mipLevel, data:Bytes) {

    }

    public function uploadCubeTextureData(texture, face:CubeTexture.Face, width, height, mipLevel, data:Bytes) {
    }

    public function uploadCompressedTexture2dData(texture, format:TextureFormat, width, height, size, mipLevel, data:Bytes) {

    }

    public function uploadCompressedCubeTextureData(texture, face:CubeTexture.Face, format:TextureFormat, width, height, mipLevel, data:Bytes) {

    }

    public function activateMipMapping(texture) {

    }

    public function deleteTexture(texture) {

    }

    public function setTextureAt(position, texture, location = -1) {

    }

    public function setSamplerStateAt(position, wrapping:WrapMode, filtering:TextureFilter, mipFiltering:MipFilter) {

    }

    public function createProgram() {
        return -1;
    }

    public function attachShader(program, shader) {

    }

    public function linkProgram(program) {

    }

    public function deleteProgram(program) {

    }

    public function setProgram(program) {

    }

    public function compileShader(shader) {

    }

    public function setShaderSource(shader, source) {

    }

    public function createVertexShader() {
        return -1;
    }

    public function deleteVertexShader(vertexShader) {

    }

    public function createFragmentShader() {
        return -1;
    }

    public function deleteFragmentShader(fragmentShader) {

    }

    public function getProgramInputs(program):ProgramInputs {
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

    public function setStencilTest(stencilFunc:CompareMode, stencilRef, stencilMask, stencilFailOp:StencilOperation, stencilZFailOp:StencilOperation, stencilZPassOp:StencilOperation) {

    }

    public function setScissorTest(scissorTest:Bool, NamelessParameter2:Vec4) {

    }

    public function readPixels(pixels:Bytes) {

    }

    public function readRectPixels(x, y, width, height, pixels:Bytes) {

    }

    public function setTriangleCulling(triangleCulling:TriangleCulling) {

    }

    public function setRenderToBackBuffer() {

    }

    public function setRenderToTexture(texture, enableDepthAndStencil = false) {

    }

    public function generateMipmaps(texture) {

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

    public function setVertexAttributeArray(vertexArray) {

    }

    public function new() {
    }
}
