package minko.audio;

import haxe.io.Bytes;
import openal.AL;
import openal.AL.Source as ALSource;

class SDLSoundChannel extends SoundChannel {
    var _source:ALSource;
    var _remaining:Int;
    var _finished:Bool;
    var _deleted:Bool;

    public function new(sound:Sound, source:ALSource, count:Int) {
        super(sound);
        _source = source;
        _remaining = count;
        _finished = false;
        _deleted = false;
    }

    public function update() {
        if (_finished || _remaining == 0) return;

        var state = AL.getSourcei(_source, AL.SOURCE_STATE);
        if (state == AL.PLAYING) return;

        if (_remaining > 1) {
            _remaining--;
            AL.sourceRewind(_source);
            AL.sourcePlay(_source);
        }
        else {
            finish();
        }
    }

    function finish() {
        if (_finished) return;
        _finished = true;
        SDLAudio.removeChannel(this);
        AL.sourceStop(_source);
        deleteSource();
        complete.execute(this);
    }

    function deleteSource() {
        if (_deleted) return;
        _deleted = true;
        var handle = Bytes.alloc(4);
        handle.setInt32(0, _source.toInt());
        AL.deleteSources(1, handle);
    }

    override public function stop() {
        finish();
    }

    override public function get_playing():Bool {
        if (_finished) return false;
        return AL.getSourcei(_source, AL.SOURCE_STATE) == AL.PLAYING;
    }

    override public function set_transform(value:SoundTransform) {
        if (value != null && !_finished) {
            AL.sourcef(_source, AL.GAIN, value.volume);
        }
        return super.set_transform(value);
    }

    override public function dispose() {
        stop();
    }
}
