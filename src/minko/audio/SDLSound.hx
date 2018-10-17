package minko.audio;
class SDLSound extends Sound {
    private var _chunk:Mix_Chunk;

    public function new() {
    }


    override public function dispose() {
    }

    public function play(count) {

        if (count < 0) {
            throw ("count cannot be less than zero");
        }

        var channel = new SDLSoundChannel(this);

        channel.channel = (Mix_PlayChannel(-1, _chunk, count == 0 ? -1 : (count == 1 ? 0 : count)));

        if (channel._channel < 0) {
            throw ("Fail playing sound: " << Mix_GetError());
            return null;
        }

        return channel;

    }
}
