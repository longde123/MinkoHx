package minko.audio;
class SDLAudio {
    public function new(canvas) {
/*
        Int flags = MIX_INIT_OGG;
        Int result = 0;

        if (flags != (result = Mix_Init(flags))) {
            //LOG_ERROR("Could not initialize mixer: " << result << " (" << Mix_GetError());
        }
        else {
            Mix_OpenAudio(22050, AUDIO_S16SYS, 2, 0);
            Mix_ChannelFinished(SDLSoundChannel.channelComplete);
            Mix_AllocateChannels(32);
        }
*/
    }

    static public function create(canvas) {
        return new SDLAudio(canvas);

    }

    public function dispose() {
/*
        Mix_ChannelFinished(null);
        Mix_AllocateChannels(0);
        Mix_CloseAudio();
*/
    }
}
