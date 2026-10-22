package minko.audio;
@:expose
class Sound {
    public function new() {
    }

    /**
     * Play the sound.
     *
     * `count` follows the Minko convention: 0 loops forever, 1 plays once,
     * values greater than 1 repeat the sound that many times.
     */
    public function play(count:Int = 1):SoundChannel {
        return null;
    }

    public function dispose() {
    }
}
