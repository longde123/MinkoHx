package minko.input;
import haxe.ds.IntMap;
import minko.input.Joystick.Button;
class SDLJoystick {

    public static var NativeToHtmlMap:IntMap<Button> = NativeToHtmlMap_init();

    static function NativeToHtmlMap_init() {
        var NativeToHtmlMap = new IntMap<Button>();
        NativeToHtmlMap.set(Button.DPadUp, Button.X);
        NativeToHtmlMap.set(Button.DPadDown, Button.Y);
        NativeToHtmlMap.set(Button.DPadLeft, Button.Home);
        NativeToHtmlMap.set(Button.DPadRight, Button.LT);
        NativeToHtmlMap.set(Button.Start, Button.RB);
        NativeToHtmlMap.set(Button.Select, Button.LB);
        NativeToHtmlMap.set(Button.L3, Button.A);
        NativeToHtmlMap.set(Button.R3, Button.B);
        NativeToHtmlMap.set(Button.LB, Button.Start);
        NativeToHtmlMap.set(Button.RB, Button.Select);
        NativeToHtmlMap.set(Button.A, Button.DPadUp);
        NativeToHtmlMap.set(Button.B, Button.DPadDown);
        NativeToHtmlMap.set(Button.X, Button.DPadLeft);
        NativeToHtmlMap.set(Button.Y, Button.DPadRight);
        NativeToHtmlMap.set(Button.Home, Button.Nothing);
        NativeToHtmlMap.set(Button.LT, Button.L3);
        NativeToHtmlMap.set(Button.RT, Button.R3);
        return NativeToHtmlMap;

    }

    public static var HtmlToNativeMap:IntMap<Button> = HtmlToNativeMap_init();

    static function HtmlToNativeMap_init() {
        var HtmlToNativeMap:IntMap<Button> = new IntMap<Button>();
        HtmlToNativeMap.set(Button.X, Button.DPadUp);
        HtmlToNativeMap.set(Button.Y, Button.DPadDown);
        HtmlToNativeMap.set(Button.Home, Button.DPadLeft);
        HtmlToNativeMap.set(Button.LT, Button.DPadRight);
        HtmlToNativeMap.set(Button.RB, Button.Start);
        HtmlToNativeMap.set(Button.LB, Button.Select);
        HtmlToNativeMap.set(Button.A, Button.L3);
        HtmlToNativeMap.set(Button.B, Button.R3);
        HtmlToNativeMap.set(Button.Start, Button.LB);
        HtmlToNativeMap.set(Button.Select, Button.RB);
        HtmlToNativeMap.set(Button.DPadUp, Button.A);
        HtmlToNativeMap.set(Button.DPadDown, Button.B);
        HtmlToNativeMap.set(Button.DPadLeft, Button.X);
        HtmlToNativeMap.set(Button.DPadRight, Button.Y);
        HtmlToNativeMap.set(Button.Nothing, Button.Home);
        HtmlToNativeMap.set(Button.L3, Button.LT);
        HtmlToNativeMap.set(Button.R3, Button.RT);
        return HtmlToNativeMap;
    }


    public static var ButtonNames:IntMap<String> = ButtonNames_init();

    static function ButtonNames_init() {
        var ButtonNames:IntMap<String> = new IntMap<String>();
        ButtonNames.set(Button.DPadUp, "DPadUp");
        ButtonNames.set(Button.DPadDown, "DPadDown");
        ButtonNames.set(Button.DPadLeft, "DPadLeft");
        ButtonNames.set(Button.DPadRight, "DPadRight");
        ButtonNames.set(Button.Start, "Start");
        ButtonNames.set(Button.Select, "Select");
        ButtonNames.set(Button.L3, "L3");
        ButtonNames.set(Button.R3, "R3");
        ButtonNames.set(Button.LB, "LB");
        ButtonNames.set(Button.RB, "RB");
        ButtonNames.set(Button.A, "A");
        ButtonNames.set(Button.B, "B");
        ButtonNames.set(Button.X, "X");
        ButtonNames.set(Button.Y, "Y");
        ButtonNames.set(Button.Home, "Home");
        ButtonNames.set(Button.LT, "LT");
        ButtonNames.set(Button.RT, "RT");
        return ButtonNames;
    }

    public function new() {
    }
}
