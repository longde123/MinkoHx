package minko;
import minko.audio.SDLAudio;
import minko.input.Joystick;
import minko.input.SDLKeyboard;
import minko.input.SDLMouse;
import minko.input.SDLTouch;
import minko.render.GlContext;
class SDLCanvas extends Canvas {
    private var _audio:SDLAudio;

    public function new() {
    }

    override public function initialize() {

        #if MINKO_PLATFORM == MINKO_PLATFORM_ANDROID
		Options.registerDefaultProtocol("file",function() return new APKProtocol());
	#end


        initializeWindow();
        initializeContext();
        initializeInputs();

        #if MINKO_PLATFORM != MINKO_PLATFORM_HTML5 && MINKO_PLATFORM != MINKO_PLATFORM_ANDROID
		registerWorker("file-protocol",function() return new FileProtocolWorker());
	#end


        #if MINKO_PLATFORM == MINKO_PLATFORM_ANDROID
		registerWorker("apk-protocol",function() return new APKProtocolWorker());
	#end

    }

    public function initializeInputs() {
        _mouse = SDLMouse.create(this);
        _keyboard = SDLKeyboard.create();
        _touch = SDLTouch.create(this);

    }

    public function initializeWindow() {


        _audio = SDLAudio.create(this);
    }

    public function initializeContext() {

        _backend = SDLBackend.create();

        _backend.initialize(this);

        _context = GlContext.create();

        if (!_context) {
            throw ("Could not create context");
        }
    }

    override public function getJoystickAxis(joy:Joystick, axis:Int):Int {
        var id = joy.joystickId;

        if (_joysticks.exists(id) == false) {
            return -1;
        }

        return SDL_JoystickGetAxis(_joysticks.get(id).joystick, axis);
    }

    override public function quit() {
        _active = false;

        _audio = null;
    }
}
