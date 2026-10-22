package minko.audio;

import openal.AL;
import openal.ALC;
import openal.ALC.Context as ALCContext;
import openal.ALC.Device as ALCDevice;

/**
 * OpenAL device/context owner for the HashLink backend.
 *
 * SDL itself no longer exposes an audio API through hlsdl, so playback uses
 * hlopenal. Channels are polled from SDLCanvas.step() to detect completion.
 */
class SDLAudio {
    static var _device:ALCDevice;
    static var _context:ALCContext;
    static var _initialized:Bool = false;
    static var _available:Bool = false;
    static var _channels:Array<SDLSoundChannel> = [];

    public static function initialize():Bool {
        if (_initialized) return _available;
        _initialized = true;

        try {
            _device = ALC.openDevice(null);
            if (_device == null) return _available = false;

            _context = ALC.createContext(_device, null);
            if (_context == null) return _available = false;

            if (!ALC.makeContextCurrent(_context)) return _available = false;
            ALC.loadExtensions(_device);
            AL.loadExtensions();

            AL.distanceModel(AL.INVERSE_DISTANCE);
            AL.listenerf(AL.GAIN, 1.0);
            _available = AL.getError() == AL.NO_ERROR;
        }
        catch (e:Dynamic) {
            _available = false;
        }
        return _available;
    }

    public static function isAvailable():Bool {
        return _available;
    }

    public static function update() {
        if (!_available) return;
        for (channel in _channels.copy()) channel.update();
    }

    public static function addChannel(channel:SDLSoundChannel) {
        if (_channels.indexOf(channel) < 0) _channels.push(channel);
    }

    public static function removeChannel(channel:SDLSoundChannel) {
        _channels.remove(channel);
    }

    public static function dispose() {
        for (channel in _channels.copy()) channel.stop();
        _channels = [];
        if (_context != null) {
            ALC.destroyContext(_context);
            _context = null;
        }
        if (_device != null) {
            ALC.closeDevice(_device);
            _device = null;
        }
        _available = false;
        _initialized = false;
    }
}
