package minko.audio;

import haxe.io.Bytes;
import minko.file.AbstractParser;
import minko.file.AssetLibrary;
import minko.file.File;
import minko.file.Options;

/**
 * Decodes WAV (PCM) and OGG Vorbis into OpenAL buffers.
 *
 * Register it on the loader options:
 *   options.registerParser("wav", () -> new SDLSoundParser());
 *   options.registerParser("ogg", () -> new SDLSoundParser());
 */
class SDLSoundParser extends AbstractParser {
    public function new() {
        super();
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assetLibrary:AssetLibrary) {
        try {
            var extension = File.getExtension(filename).toLowerCase();
            var sound:SDLSound = null;

            if (extension == "wav" || isRiff(data)) {
                sound = SDLSound.fromWav(data);
            }
            else if (extension == "ogg" || isOgg(data)) {
                sound = SDLSound.fromOgg(data);
            }
            else {
                throw "Unsupported audio format: " + filename;
            }

            assetLibrary.setSound(filename, sound);
            trace("SDLSoundParser " + filename + " (" + sound.sampleCount + " samples)");
            complete.execute(this);
        }
        catch (e:Dynamic) {
            // Audio is optional: keep the loader moving so a missing OpenAL
            // device does not prevent the rest of the scene from loading.
            trace("SDLSoundParser: " + Std.string(e));
            complete.execute(this);
        }
    }

    static function isRiff(data:Bytes):Bool {
        return data.length >= 4
            && data.get(0) == 0x52
            && data.get(1) == 0x49
            && data.get(2) == 0x46
            && data.get(3) == 0x46;
    }

    static function isOgg(data:Bytes):Bool {
        return data.length >= 4
            && data.get(0) == 0x4F
            && data.get(1) == 0x67
            && data.get(2) == 0x67
            && data.get(3) == 0x53;
    }
}
