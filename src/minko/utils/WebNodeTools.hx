package minko.utils;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import js.html.CSSStyleDeclaration;
import js.html.ImageData;
import js.html.ImageElement;
import minko.data.PixelData;

class WebNodeTools {
    static public var MAX_SIZE = 4096;

    public static function createCanvasElement():CanvasElement {
        var r = js.Browser.document.createCanvasElement();
        var r_style:CSSStyleDeclaration = r.style;
        r_style.position = "absolute";
        // disable canvas selection indication from mouse/touch swiping:
        r_style.setProperty("-webkit-touch-callout", "none");
        r_style.setProperty("user-select", "none");
        return r;
    }

    public static function loadFromBytes(t:String, c:Bytes, ?h:PixelData -> Void) {
        var component:CanvasElement = createCanvasElement();
        var o:ImageElement = untyped js.Browser.document.createElement("img");
        var n:CanvasElement = component;
        var q:CanvasRenderingContext2D;
        var f:Dynamic -> Void = null;
        var i:Int, l:Int;
        var p:ImageData;

        f = function(_) {
            o.removeEventListener("load", f);
            //

            n.width = Math.floor(Math.min(MathUtil.clp2(o.width), MAX_SIZE));
            n.height = Math.floor(Math.min(MathUtil.clp2(o.height), MAX_SIZE));
            q = n.getContext("2d");
            //
            q.drawImage(o, 0, 0, o.width, o.height, 0, 0, n.width, n.height);
            p = q.getImageData(0, 0, n.width, n.height);

            //
            if (h != null) h({
                width : n.width,
                height :n.height,
                pixels: Bytes.ofData(p.data.buffer)
            });
            component.remove();
            o.remove();
            o = null;
            p = null;

        };

        o.addEventListener("load", f);
        o.src = "data:image/" + t + ";base64," + Base64.encode(c);
    }
}
