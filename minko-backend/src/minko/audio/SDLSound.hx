package minko.audio;

import haxe.io.Bytes;
import haxe.io.BytesInput;
import minko.native.Ogg;
import openal.AL;
import openal.AL.Buffer as ALBuffer;
import openal.AL.Source as ALSource;

class SDLSound extends Sound {
    public var buffer:ALBuffer;
    public var format:Int;
    public var frequency:Int;
    public var sampleCount:Int;
    var _disposed:Bool = false;

    public function new(buffer:ALBuffer, format:Int, frequency:Int, sampleCount:Int) {
        super();
        this.buffer = buffer;
        this.format = format;
        this.frequency = frequency;
        this.sampleCount = sampleCount;
    }

    public static function fromWav(data:Bytes):SDLSound {
        if (!SDLAudio.initialize()) throw "OpenAL is not available";
        var wave = new format.wav.Reader(new BytesInput(data)).read();
        var header = wave.header;
        if (header.channels != 1 && header.channels != 2) {
            throw "Unsupported WAV channel count: " + header.channels;
        }
        var format = switch [header.channels, header.bitsPerSample] {
            case [1, 8]: AL.FORMAT_MONO8;
            case [1, 16]: AL.FORMAT_MONO16;
            case [2, 8]: AL.FORMAT_STEREO8;
            case [2, 16]: AL.FORMAT_STEREO16;
            default: throw "Unsupported WAV format: " + header.bitsPerSample + " bits / " + header.channels + " channels";
        };
        var sampleCount = Std.int(wave.data.length / (header.channels * (header.bitsPerSample >> 3)));
        var buffer = createBuffer(wave.data, format, header.samplingRate);
        return new SDLSound(buffer, format, header.samplingRate, sampleCount);
    }

    public static function fromOgg(data:Bytes):SDLSound {
        if (!SDLAudio.initialize()) throw "OpenAL is not available";
        var reader = Ogg.open(data.getData(), data.length);
        if (reader == null) throw "Failed to open OGG data";

        var bitrate = 0;
        var frequency = 0;
        var samples = 0;
        var channels = 0;
        Ogg.info(reader, bitrate, frequency, samples, channels);
        if (channels != 1 && channels != 2) throw "Unsupported OGG channel count: " + channels;

        var pcm = Bytes.alloc(samples * channels * 2);
        var pointer:hl.Bytes = @:privateAccess pcm.b;
        var total = 0;
        while (total < pcm.length) {
            var read = Ogg.read(reader, pointer.offset(total), pcm.length - total, 2);
            if (read < 0) throw "Failed to decode OGG data";
            if (read == 0) break;
            total += read;
        }
        if (total <= 0) throw "Empty OGG data";

        var format = channels == 1 ? AL.FORMAT_MONO16 : AL.FORMAT_STEREO16;
        var pcmData = total == pcm.length ? pcm : pcm.sub(0, total);
        var buffer = createBuffer(pcmData, format, frequency);
        return new SDLSound(buffer, format, frequency, Std.int(total / (channels * 2)));
    }

    static function createBuffer(pcm:Bytes, format:Int, frequency:Int):ALBuffer {
        var handle = Bytes.alloc(4);
        AL.genBuffers(1, handle);
        var buffer = ALBuffer.ofInt(handle.getInt32(0));
        AL.bufferData(buffer, format, pcm.getData(), pcm.length, frequency);
        if (AL.getError() != AL.NO_ERROR) throw "Failed to upload OpenAL buffer";
        return buffer;
    }

    override public function play(count:Int = 1):SoundChannel {
        if (count < 0) throw "count cannot be less than zero";
        if (!SDLAudio.initialize()) return null;

        var handle = Bytes.alloc(4);
        AL.genSources(1, handle);
        var source = ALSource.ofInt(handle.getInt32(0));
        if (AL.getError() != AL.NO_ERROR) throw "Failed to create OpenAL source";

        AL.sourcei(source, AL.BUFFER, buffer.toInt());
        AL.sourcei(source, AL.LOOPING, count == 0 ? AL.TRUE : AL.FALSE);
        AL.sourcef(source, AL.GAIN, 1.0);

        var channel = new SDLSoundChannel(this, source, count);
        SDLAudio.addChannel(channel);
        AL.sourcePlay(source);
        return channel;
    }

    override public function dispose() {
        if (!_disposed) {
            _disposed = true;
            var handle = Bytes.alloc(4);
            handle.setInt32(0, buffer.toInt());
            AL.deleteBuffers(1, handle);
        }
    }
}
