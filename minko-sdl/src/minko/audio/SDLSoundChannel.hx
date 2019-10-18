package minko.audio;
import haxe.ds.IntMap;
class SDLSoundChannel extends SoundChannel {
/*
    private var _channel:Int;
    public static var _activeChannels:IntMap<SDLSoundChannel> = new IntMap<SDLSoundChannel>();

    public function new(sound:Sound) {
        this._sound = sound;
        this._channel = 0;
    }

    override public function dispose() {
        stop();
    }

    override public function stop() {
        if (_channel >= 0) {
            Mix_HaltChannel(_channel);
        }
    }

    override function set_transform(value:SoundTransform) {
        if (!value == null && _channel >= 0) {
            Mix_SetPanning(_channel, Math.floor(value.left * value.volume * 255), Math.floor(value.right * value.volume * 255));
        }
        return super.set_transform(value);
    }


    public var channel(null, set):Int;

    function set_channel(c) {
        _channel = c;
        _activeChannels.set(c, this);
    }

    public function channelComplete(c) {
        if (_activeChannels.exists(c) == false) {
            return;
        }
        var channel = _activeChannels.get(c);
        _activeChannels.remove(c);
        channel._channel = -1;
        channel.complete.execute(channel);
    }

    override function get_playing() {
        return _channel != -1;
    }
    */
}
