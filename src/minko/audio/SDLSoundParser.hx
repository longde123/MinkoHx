package minko.audio;
import haxe.io.Bytes;
import minko.file.AbstractParser;
import minko.file.AssetLibrary;
import minko.file.Options;
class SDLSoundParser extends AbstractParser {
    public function new() {
    }

    override public function parse(filename:String, resolvedFilename:String, options:Options, data:Bytes, assets:AssetLibrary) {

        var sound = new SDLSound();

        SDL_RWops ops = SDL_RWFromConstMem(data, data.length);

        sound._chunk = Mix_LoadWAV_RW(ops, 0);

        if (sound._chunk == null) {
            error.execute(this, "file.Error(SDL_GetError())");
            return;
        }

        SDL_FreeRW(ops);

        assets.setSound(filename, sound);

        complete.execute(this);


    }
}
