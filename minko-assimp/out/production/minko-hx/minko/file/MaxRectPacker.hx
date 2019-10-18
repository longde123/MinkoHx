package minko.file;
/**
	Implements different bin packer algorithms that use the MAXRECTS data structure.
	See http://clb.demon.fi/projects/even-more-rectangle-bin-packing

	Author: Jukka Jylänki
	- Original

	Author: Claus Wahlers
	- Ported to ActionScript3

	Author: Tony DiPerna
	- Ported to HaXe, optimized

	Author: Shawn Skinner (treefortress)
	- Ported back to AS3

	Author: loudo (Ludovic Bas)
	- Ported back to haxe
 */
import glm.Vec4;
import glm.Vec2;
import haxe.io.Bytes;
import minko.utils.MathUtil;
import minko.file.JPEGParser.AtlasMipMaps;
import minko.math.Rect;
class AtlasBuilder
{
    public function new(){

    }

    static public function fixMipMapLevel(data:Bytes, width:Int, height:Int, bytesPerPixel) {
        var endX = width;
        var endY = height;
        var idx = 0;
        var numLevels = MathUtil.getp2(width) + 1 ;
        var dataOffset = 0;
        var offsetY = 0;
        for (level in 1... numLevels) {
            var mipMapWidth = Math.floor(Math.max(width >> level, 1));
            var mipMapHeight = Math.floor(Math.max(height >> level, 1));
            dataOffset += width * mipMapHeight * bytesPerPixel;
            offsetY += mipMapHeight;
            for (y in offsetY...Math.floor(mipMapHeight / 2) + offsetY) {
                var lw = mipMapWidth;
                while (lw < width) {
                    for (xx in 0...mipMapWidth) {
                        var x = xx;
                        var xy1 = (x + y * width) * bytesPerPixel;
                        x = lw + xx;
                        var xy2 = (x + y * width) * bytesPerPixel;
                        for (i in 0... bytesPerPixel) {
                            data.set(xy2 ++, data.get(xy1++));
                        }
                    }
                    lw += mipMapWidth;

                }

            }
        }

    }
    public function fixAtlasMipMaps(data:PixelData, width:Int, height:Int):AtlasMipMaps {

        var numLevels = MathUtil.getp2(width) + 1 ;
        var rgba:PixelData = new PixelData(width, height, Bytes.alloc(width * width * data.bytesPerPixel));
        rgba.bytesPerPixel = data.bytesPerPixel;

        var actualHeight = height;

        var diff = height - width * 2 - 1;
        actualHeight = height + Math.floor((diff + 1) / 2);


        var actualY = actualHeight;
        var source_atlasList = [ ];

        for (level in 1... numLevels) {
            var mipMapWidth = Math.floor(Math.max(width >> level, 1));
            var mipMapHeight = Math.floor(Math.max(actualHeight >> level, 1));
            var r = new Rect();
            r.y = actualY;
            r.height = mipMapHeight;
            r.width = mipMapWidth;
            source_atlasList.push(r);
            actualY += mipMapHeight;
        }
        trace(source_atlasList);
        var padding:Int = 1;
        var dest_atlasList:Array<Rect> =  buildFromAtlasRect(source_atlasList, padding, width, actualHeight);
        dest_atlasList = dest_atlasList.map(function(d:Rect) {
            d.y += actualHeight;
            return d;
        });

        rgba.copyPixels(data, new Rect(0, 0, width, actualHeight), new Vec2(0, 0));
        //计算新的uv偏移t s
        var uv=[new Vec4(0,0,width/width,actualHeight/height)];

        for (i in 0...source_atlasList.length) {
            var s:Rect = source_atlasList[i];
            var d:Rect = dest_atlasList[i];
            rgba.copyPixels(data, s, new Vec2(d.x, d.y));
            rgba.copyPixels(data, new Rect(s.x, s.y, s.width, padding), new Vec2(d.x, d.y - padding));

            rgba.copyPixels(data, new Rect(s.x, s.y + s.height - padding, s.width, padding), new Vec2(d.x, d.y + d.height));

            rgba.copyPixels(data, new Rect(s.x, s.y, padding, s.height), new Vec2(d.x - padding, d.y));
            rgba.copyPixels(data, new Rect(s.x + s.width - padding, s.y, padding, s.height), new Vec2(d.x + d.width, d.y));
            uv.push(new Vec4(d.x/width,d.y/height,d.width/width,d.height/height));

        }

        trace(uv);


        return {
            uv:uv,
            data:rgba
        };

    }
    public function fixMipMaps(data:PixelData, width:Int, height:Int):PixelData  {

        var numLevels = MathUtil.getp2(width) + 1 ;
        var rgba:PixelData = new PixelData(width, height, Bytes.alloc(width * width * data.bytesPerPixel));
        rgba.bytesPerPixel = data.bytesPerPixel;

        var actualHeight = height;

        var diff = height - width * 2 - 1;
        actualHeight = height + Math.floor((diff + 1) / 2);


        var actualY = actualHeight;
        var source_atlasList = [ new Rect(0,0,width,actualHeight) ];

        for (level in 1... numLevels) {
            var mipMapWidth = Math.floor(Math.max(width >> level, 1));
            var mipMapHeight = Math.floor(Math.max(actualHeight >> level, 1));
            var r = new Rect();
            r.y = actualY;
            r.height = mipMapHeight;
            r.width = mipMapWidth;
            source_atlasList.push(r);
            actualY += mipMapHeight;
        }
        trace(source_atlasList);
        var padding:Int = 1;
        var dest_atlasList:Array<Rect> =source_atlasList.concat([]);


        for (i in 0...source_atlasList.length) {
            var s:Rect = source_atlasList[i];
            var d:Rect = dest_atlasList[i];
            rgba.copyPixels(data, s, new Vec2(d.x, d.y));
        }


        return  rgba;

    }
    public function  buildFromAtlasRect(atlasList:Array<Rect>,  padding:Int = 2, width:Int = 1024, height:Int = 1024):Array<Rect>
    {
        var packer:MaxRectPacker = new MaxRectPacker(width, height);
        var len:Int = atlasList.length;
        var tmp=[];
        for(i in 0...len){
            var rectData = atlasList[i];
            var rect = packer.quickInsert((rectData.width) + padding * 2, (rectData.height) + padding * 2);

            trace(rect);
            //Add padding
            rect.x += padding;
            rect.y += padding;
            rect.width -= padding * 2;
            rect.height -= padding * 2;

            tmp.push(rect);
        }

        return tmp;
    }
}
class MaxRectPacker
{

    public var freeRects:Array<Rect>;

    var binWidth:Float;
    var binHeight:Float;

    public function new(width:Float, height:Float):Void {
        init(width, height);
    }
    public function init(width:Float, height:Float):Void {
        binWidth = width;
        binHeight = height;
        freeRects = [];
        freeRects.push(new Rect(0, 0, width, height));
    }

    public function quickInsert(width:Float, height:Float):Rect {
        var newNode:Rect = quickFindPositionForNewNodeBestAreaFit(width, height);

        if (newNode.height == 0) {
            return null;
        }

        var numRectsToProcess:Int = freeRects.length;
        var i:Int = 0;
        while (i < numRectsToProcess) {
            if (splitFreeNode(freeRects[i], newNode)) {
                freeRects.splice(i, 1);
                --numRectsToProcess;
                --i;
            }
            i++;
        }

        pruneFreeList();
        return newNode;
    }

    inline private function quickFindPositionForNewNodeBestAreaFit(width:Float, height:Float):Rect {
        var score:Float = Math.POSITIVE_INFINITY;
        var areaFit:Float;
        var r:Rect;
        var bestNode:Rect = new Rect();

        var len:Int = freeRects.length;
        for(i in 0...len) {
            r = freeRects[i];
            // Try to place the rectangle in upright (non-flipped) orientation.
            if (r.width >= width && r.height >= height) {
                areaFit = r.width * r.height - width * height;
                if (areaFit < score) {
                    bestNode.x = r.x;
                    bestNode.y = r.y;
                    bestNode.width = width;
                    bestNode.height = height;
                    score = areaFit;
                }
            }
        }

        return bestNode;
    }

    private function splitFreeNode(freeNode:Rect, usedNode:Rect):Bool {
        var newNode:Rect;
        // Test with SAT if the rectangles even intersect.
        if (usedNode.x >= freeNode.x + freeNode.width ||
        usedNode.x + usedNode.width <= freeNode.x ||
        usedNode.y >= freeNode.y + freeNode.height ||
        usedNode.y + usedNode.height <= freeNode.y) {
            return false;
        }
        if (usedNode.x < freeNode.x + freeNode.width && usedNode.x + usedNode.width > freeNode.x) {
            // New node at the top side of the used node.
            if (usedNode.y > freeNode.y && usedNode.y < freeNode.y + freeNode.height) {
                newNode = freeNode.clone();
                newNode.height = usedNode.y - newNode.y;
                freeRects.push(newNode);
            }
            // New node at the bottom side of the used node.
            if (usedNode.y + usedNode.height < freeNode.y + freeNode.height) {
                newNode = freeNode.clone();
                newNode.y = usedNode.y + usedNode.height;
                newNode.height = freeNode.y + freeNode.height - (usedNode.y + usedNode.height);
                freeRects.push(newNode);
            }
        }
        if (usedNode.y < freeNode.y + freeNode.height && usedNode.y + usedNode.height > freeNode.y) {
            // New node at the left side of the used node.
            if (usedNode.x > freeNode.x && usedNode.x < freeNode.x + freeNode.width) {
                newNode = freeNode.clone();
                newNode.width = usedNode.x - newNode.x;
                freeRects.push(newNode);
            }
            // New node at the right side of the used node.
            if (usedNode.x + usedNode.width < freeNode.x + freeNode.width) {
                newNode = freeNode.clone();
                newNode.x = usedNode.x + usedNode.width;
                newNode.width = freeNode.x + freeNode.width - (usedNode.x + usedNode.width);
                freeRects.push(newNode);
            }
        }
        return true;
    }

    private function pruneFreeList():Void  {
        // Go through each pair and remove any rectangle that is redundant.
        var i:Int = 0;
        var j:Int = 0;
        var len:Int = freeRects.length;
        var tmpRect:Rect;
        var tmpRect2:Rect;
        while (i < len) {
            j = i + 1;
            tmpRect = freeRects[i];
            while (j < len) {
                tmpRect2 = freeRects[j];
                if (isContainedIn(tmpRect,tmpRect2)) {
                    freeRects.splice(i, 1);
                    --i;
                    --len;
                    break;
                }
                if (isContainedIn(tmpRect2,tmpRect)) {
                    freeRects.splice(j, 1);
                    --len;
                    --j;
                }
                j++;
            }
            i++;
        }
    }

    inline private function isContainedIn(a:Rect, b:Rect):Bool {
        return a.x >= b.x && a.y >= b.y	&& a.x + a.width <= b.x + b.width && a.y + a.height <= b.y + b.height;
    }

}