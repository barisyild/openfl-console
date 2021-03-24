package com.junkbyte.console.core;

import openfl.display.Tileset;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Tile;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.Tilemap;
import openfl.display.TileContainer;

class TileTools {
    public static function hitList(tilemap:Tilemap):Array<TileDepth>
    {
        var localPoint:Point = tilemap.globalToLocal(new Point(Lib.current.stage.mouseX, Lib.current.stage.mouseY));

        return hitTestTile(Reflect.field(tilemap, "__group"), localPoint);
    }

    public static function hitTestTile(tile:Tile, localPoint:Point, depth:Int = 0):Array<TileDepth>
    {
        if(!tile.getBounds(__topTile(tile)).intersects(new Rectangle(localPoint.x, localPoint.y, 1, 1)))
            return null;

        if(tile.width < 1 || tile.height < 1)
            return null;

        var arr:Array<TileDepth> = [];

        if(Std.isOfType(tile, TileContainer))
        {
            var tileContainer:TileContainer = cast tile;


            var i:Int = tileContainer.numTiles - 1;

            while(i >= 0) {
                var subTile = tileContainer.getTileAt(i);
                i--;
                if(Std.isOfType(subTile, TileContainer))
                {
                    var tileDepthArray:Array<TileDepth> = hitTestTile(subTile, localPoint, depth + 1);
                    if(tileDepthArray != null)
                    {
                        for(tileDepth in tileDepthArray)
                        {
                            arr.push(tileDepth);
                        }
                    }
                }else{
                    if(__hitTestCheap(subTile, localPoint))
                    {
                        var tileDepth:TileDepth = new TileDepth(subTile, depth);
                        arr.push(tileDepth);
                    }
                }
            }
        }else{
            if(__hitTestCheap(tile, localPoint))
            {
                var tileDepth:TileDepth = new TileDepth(tile, depth);
                arr.push(tileDepth);
                return arr;
            }
        }

        return arr;
    }

    private static function __hitTestCheap(tile:Tile, localPoint:Point)
    {
        if(!tile.visible)
        {
            return false;
        }

        var originPoint:Point = __calcTileOriginPoint(tile);

        var targetTileset:Tileset = _findTileset(tile);

        if(targetTileset == null)
        {
            //tileset not found!
            return false;
        }

        var targetBitmapData:BitmapData = targetTileset.bitmapData;


        var posX:Int;
        var posY:Int;

        if(targetTileset.numRects == 1)
        {
            posX = Std.int(localPoint.x - originPoint.x);
            posY = Std.int(localPoint.y - originPoint.y);
        }else{
            var rect:Rectangle = targetTileset.getRect(tile.id);
            var startX:Int = Std.int(rect.x);
            var endX:Int = Std.int(rect.x + rect.width);
            var startY:Int = Std.int(rect.y);
            var endY:Int = Std.int(rect.y + rect.height);

            posX = Std.int(startX + (localPoint.x - originPoint.x));
            posY = Std.int(startY + (localPoint.y - originPoint.y));

            if(posX < startX || posY < startY)
            {
                return false;
            }

            if(posX > endX || posY > endY)
            {
                return false;
            }
        }

        if(targetBitmapData.getPixel32(posX, posY) != 0)
        {
            return true;
        }

        return false;
    }

    private static function _findTileset(tile:Tile):Tileset
    {
        var tileset:Tileset = null;

        while(tileset == null && tile != null)
        {
            tileset = tile.tileset;
            tile = cast tile.parent;
        }
        return tileset;
    }

    private static function __topTile(tile:Tile):Tile
    {
        if(tile.parent != null)
        {
            tile = __topTile(tile.parent);
        }
        return tile;
    }

    private static function __calcTileOriginPoint(tile:Tile):Point
    {
        var tilePoint:Point = new Point(0, 0);

        tilePoint.x += tile.x;
        tilePoint.y += tile.y;

        if(tile.parent != null)
        {
            var tileOriginPoint:Point = __calcTileOriginPoint(tile.parent);
            tilePoint.x += tileOriginPoint.x;
            tilePoint.y += tileOriginPoint.y;
        }
        return tilePoint;
    }
}
class TileDepth {
    public function new(tile:Tile, depth:Int)
    {
        this.tile = tile;
        this.depth = depth;
    }

    public var tile:Tile;
    public var depth:Int;
}
