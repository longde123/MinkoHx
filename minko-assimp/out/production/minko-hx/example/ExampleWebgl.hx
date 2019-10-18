package example;
import glm.GLM;
import glm.Mat4;
import glm.Vec3;
import minko.AbstractCanvas;
import minko.render.GlContext;
import minko.WebCanvas;
class ExampleWebgl {
      public function new() {

        var TEXTURE_FILENAME = "texture/box.png";
        var EFFECT_FILENAME = "effect/Basic.effect";
        var canvas:WebCanvas = WebCanvas.create("Example - Cube");

        var context:GlContext = cast canvas.context;
        function initShader() {
            var vs = context.createVertexShader();
            context.setShaderSource(vs, " attribute vec3 aVertexPosition;
        uniform mat4 uMVMatrix;
        uniform mat4 uPMatrix;
        void main(void) {
            gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
        }");
            context.compileShader(vs);
            var fs = context.createFragmentShader();
            context.setShaderSource(fs, " precision mediump float;
        void main(void) {
            gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
        }");
            context.compileShader(fs);
            var shaderProgram = context.createProgram();
            context.attachShader(shaderProgram, vs);
            context.attachShader(shaderProgram, fs);
            context.linkProgram(shaderProgram);
            return shaderProgram;
        }
        var shaderProgram = initShader();
        var vertexPositionAttribute = context.getAttributeInput(shaderProgram, "aVertexPosition");
        var pMatrixUniform = context.getUniformInput(shaderProgram, "uPMatrix");
        var mvMatrixUniform = context.getUniformInput(shaderProgram, "uMVMatrix");
        function initVertexBuffer() {
            var vertices = [
                0.0, 1.0, 0.0,
                -1.0, -1.0, 0.0,
                1.0, -1.0, 0.0
            ];
            var vertexBuffer = context.createVertexBuffer(vertices.length);
            context.uploadVertexBufferData(vertexBuffer, 0, vertices.length, vertices);
            return vertexBuffer;
        }
        var vertexBuffer = initVertexBuffer();

        var mvMatrix = new Mat4() ;
        var pMatrix = new Mat4();


        GLM.perspective(45, canvas.aspectRatio, 0.1, 100.0, pMatrix);
        GLM.translate(new Vec3(-1.5, 0.0, -7.0), mvMatrix);


        var enterFrame = canvas.enterFrame.connect(function(canvas:AbstractCanvas, time, deltaTime) {

            context.setProgram(shaderProgram);
            context.setVertexBufferAt(vertexPositionAttribute.location, vertexBuffer, 3, 0, 0);
            context.setUniformMatrix4x4(pMatrixUniform.location, 0, pMatrix.toFloatArray());
            context.setUniformMatrix4x4(mvMatrixUniform.location, 0, mvMatrix.toFloatArray());
            context.drawTriangles(0, 1);

        });


        canvas.run();
    }
}
