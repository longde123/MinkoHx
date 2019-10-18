package minko;
@:expose("minko.AbstractBackend")
class AbstractBackend {
    static public function create() {
        return new AbstractBackend();
    }

    public function new() {
    }

    public function initialize(canvas) {

    }

    public function swapBuffers(canvas) {
    }

    public function run(canvas:AbstractCanvas) {
        if(canvas.active) {
            canvas.step();
        }
    }

    public function wait(canvas, ms) {
    }
}
