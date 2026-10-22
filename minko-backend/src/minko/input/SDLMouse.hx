package minko.input;
class SDLMouse extends Mouse {
    public static function create(canvas) {
        return new SDLMouse(canvas);
    }

    public function new(canvas) {
        super(canvas);
    }
}
