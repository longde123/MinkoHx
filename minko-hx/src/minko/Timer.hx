package minko;

import minko.utils.MathUtil;
class Timer {

    /**
		The FPS on which "tmod" have values are based on.
		Can be freely configured if your gameplay runs at a different speed.
		Default : 60
	**/
    public static var wantedFPS = 60.;

    /**
		The maximum amount of time between two frames (in seconds).
		If the time exceed this amount, Timer will consider these lags are to be ignored.
		Default : 0.5
	**/
    public static var maxDeltaTime = 0.5;

    /**
		The smoothing done between frames. A smoothing of 0 gives "real time" values, higher values will smooth
		the results for tmod/dt/fps over frames using the formula   dt = lerp(dt, elapsedTime, smoothFactor)
		Default : 0 on HashLink, 0.95 on other platforms
	**/
    public static var smoothFactor = 0.95;

    /**
		The last timestamp in which update() function was called.
	**/
    public static var lastTimeStamp(default,null) = haxe.Timer.stamp();
    public static var startTimeStamp(default,null) = haxe.Timer.stamp();
    /**
		The amount of time (unsmoothed) that was spent since the last frame.
	**/
    public static var elapsedTime(default,null) = 0.;

    /**
		A frame counter, increases on each call to update()
	**/
    public static var frameCount = 0;

    /**
		The smoothed elapsed time (in seconds).
	**/
    public static var dt : Float = 1 / wantedFPS;

    /**
		The smoothed frame modifier, based on wantedFPS. Its value is the same as dt/wantedFPS
		Allows to express movements in terms of pixels-per-frame-at-wantedFPS instead of per second.
	**/
    public static var tmod(get,set) : Float;

    static var currentDT : Float = 1 / wantedFPS;
    public static var remainingTime : Float = 1 / wantedFPS;

    /**
		Update the timer calculus on each frame. This is automatically called by hxd.App
	**/
    public static function update() {
        frameCount++;
        var newTime = haxe.Timer.stamp();
        elapsedTime = newTime - lastTimeStamp;
        lastTimeStamp = newTime;
        if( elapsedTime < maxDeltaTime ){
            currentDT = MathUtil.lerp(elapsedTime, currentDT, smoothFactor);
            remainingTime=1 / wantedFPS-currentDT;
        }
        else{
            elapsedTime = 1 / wantedFPS;
            remainingTime=0;
        }

        dt = currentDT;

    }

    inline static function get_tmod() {
        return dt * wantedFPS;
    }

    inline static function set_tmod(v:Float) {
        dt = v / wantedFPS;
        return v;
    }

    /**
		The current smoothed FPS.
	**/
    public static function fps() : Float {
        // use currentDT to prevent gameplay change of dt to affect the displayed fps
        return 1. / currentDT;
    }

    /**
		After some loading / long processing, call skip() in order to prevent
		it from impacting your smoothed values.
	**/
    public static function skip() {
        lastTimeStamp = haxe.Timer.stamp();
    }

    /**
		Similar as skip() but also reset dt to default value.
		Can be used when starting a new game if you want to discard any previous measurement.
	**/
    public static function reset() {
        startTimeStamp=lastTimeStamp = haxe.Timer.stamp();
        dt = currentDT = 1. / wantedFPS;
    }
}