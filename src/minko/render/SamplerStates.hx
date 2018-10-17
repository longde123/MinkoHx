package minko.render;
class SamplerStates {
    public static inline var PROPERTY_WRAP_MODE = "wrapMode";
    public static inline var PROPERTY_TEXTURE_FILTER = "textureFilter";
    public static inline var PROPERTY_MIP_FILTER = "mipFilter";

    public static var PROPERTY_NAMES = [ PROPERTY_WRAP_MODE,
    PROPERTY_TEXTURE_FILTER,
    PROPERTY_MIP_FILTER];

    public static inline var DEFAULT_WRAP_MODE = (WrapMode.CLAMP);
    public static inline var DEFAULT_TEXTURE_FILTER = (TextureFilter.NEAREST);
    public static inline var DEFAULT_MIP_FILTER = (MipFilter.NONE);

    public static function uniformNameToSamplerStateName(uniformName, sampleState) {
        return uniformName + "/" + sampleState;
    }

    public static function uniformNameToSamplerStateBindingName(uniformName, samplerState:String) {
        var samplerStateCapitalized = samplerState.charAt(0).toUpperCase() + samplerState.substr(1);

        return uniformName + samplerStateCapitalized;
    }

    public static function stringToWrapMode(value) {
        return value == "repeat" ? WrapMode.REPEAT : WrapMode.CLAMP;
    }

    public static function stringToTextureFilter(value) {
        return value == "linear" ? TextureFilter.LINEAR : TextureFilter.NEAREST;
    }

    public static function stringToMipFilter(value) {
        return value == "linear" ? MipFilter.LINEAR : (value == "nearest" ? MipFilter.NEAREST : MipFilter.NONE);
    }

    public var wrapMode:WrapMode;
    public var textureFilter:TextureFilter;
    public var mipFilter:MipFilter;

    public function new(wm:WrapMode, tf:TextureFilter, mf:MipFilter) {

        this.wrapMode = wm;
        this.textureFilter = tf;
        this.mipFilter = mf;
    }
}
