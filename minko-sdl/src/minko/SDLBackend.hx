package minko;
class SDLBackend extends AbstractBackend {
    public function new() {
    }

    static public function create() {
        return new SDLBackend();
    }
}
