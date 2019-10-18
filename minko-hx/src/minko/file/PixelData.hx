package minko.file;
import minko.math.Rect;
import glm.Vec2;
import haxe.io.Bytes;
@:expose("minko.data.PixelData")
class PixelData  {
    public var pixels:Bytes;
    public var width:Int;
    public var height:Int;
    public var bytesPerPixel:Int;
    public function new(w:Int,h:Int,p:Bytes):Void {
        width=w;
        height=h;
        pixels=p;
    }


    public function copyPixels(sourceBitmapData:PixelData, sourceRect:Rect  , destPoint:Vec2 ):Void {
        for(y in 0...Math.floor(sourceRect.height)){
            for(x in 0...Math.floor(sourceRect.width)){
                var xy1 = Math.floor(( (sourceRect.x +x) + (y +sourceRect.y) *  sourceBitmapData.width) * bytesPerPixel);
                var xy2 = Math.floor(( (destPoint.x +x) + (y +destPoint.y) *  width) * bytesPerPixel);
                for (i in 0... bytesPerPixel) {
                    pixels.set(xy2 ++, sourceBitmapData.pixels.get(xy1++));
                }
            }
        }
    }
}
