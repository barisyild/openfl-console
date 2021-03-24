/*
*
* Copyright (c) 2008-2010 Lu Aye Oo
*
* @author 		Lu Aye Oo
*
* http://code.google.com/p/flash-console/
*
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*
*/
package com.junkbyte.console.vos;
import openfl.utils.ByteArray;
import openfl.geom.Rectangle;

/**
	 * @private
	 */
class GraphGroup {

    public static inline var FPS:UInt = 1;
    public static inline var MEM:UInt = 2;

    public var type:UInt = 0;
    public var name:String = null;
    public var freq:Int = 1; // update every n number of frames.
    public var low:Float = 0;
    public var hi:Float = 0;
    public var fixed:Bool = false;
    public var averaging:UInt = 0;
    public var inv:Bool = false;
    public var interests:Array<GraphInterest> = [];
    public var rect:Rectangle = null;
    //
    //
    public var idle:Int = 0;

    public function new(n:String){
        name = n;
    }

    public function updateMinMax(v:Float):Void {
        if(v != Math.NaN && !fixed){
            if(low == Math.NaN) {
                low = v;
                hi = v;
            }
            if(v > hi) hi = v;
            if(v < low) low = v;
        }
    }
    //
    //
    //
    public function toBytes(bytes:ByteArray):Void {
        bytes.writeUTF(name);
        bytes.writeUnsignedInt(type);
        bytes.writeUnsignedInt(idle);
        bytes.writeDouble(low);
        bytes.writeDouble(hi);
        bytes.writeBoolean(inv);
        bytes.writeUnsignedInt(interests.length);
        for(gi in interests)
        {
            gi.toBytes(bytes);
        }
    }

    public static function FromBytes(bytes:ByteArray):GraphGroup {
        var g:GraphGroup = new GraphGroup(bytes.readUTF());
        g.type = bytes.readUnsignedInt();
        g.idle = bytes.readUnsignedInt();
        g.low = bytes.readDouble();
        g.hi = bytes.readDouble();
        g.inv = bytes.readBoolean();
        var len:UInt = bytes.readUnsignedInt();
        while(len != 0){
            g.interests.push(GraphInterest.FromBytes(bytes));
            len--;
        }
        return g;
    }
}