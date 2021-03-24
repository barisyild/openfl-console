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
import com.junkbyte.console.utils.FlashRegex;
import openfl.utils.ByteArray;

/**
	 * @private
	 */
class Log{
    public var line:UInt;
    public var text:String;
    public var ch:String;
    public var priority:Int;
    public var repeat:Bool;
    public var html:Bool;
    public var time:UInt;
    //public var stack:String;

    public var timeStr:String;
    public var lineStr:String;
    public var chStr:String;
    //
    public var next:Log;
    public var prev:Log;
    //
    public function new(txt:String, cc:String, pp:Int, repeating:Bool = false, ishtml:Bool = false){
        text = txt;
        ch = cc;
        priority = pp;
        repeat = repeating;
        html = ishtml;
    }
    public function toBytes(bytes:ByteArray):Void {
        var t:ByteArray = new ByteArray();
        t.writeUTFBytes(text);// because writeUTF can't accept more than 65535
        bytes.writeUnsignedInt(t.length);
        bytes.writeBytes(t);
        bytes.writeUTF(ch);
        bytes.writeInt(priority);
        bytes.writeBoolean(repeat);
    }
    public static function FromBytes(bytes:ByteArray):Log{
        var t:String = bytes.readUTFBytes(bytes.readUnsignedInt());
        var c:String = bytes.readUTF();
        var p:Int = bytes.readInt();
        var r:Bool = bytes.readBoolean();
        return new Log(t, c, p, r, true);
    }

    public function plainText():String{
        var text = this.text;

        text = FlashRegex.replace(text, ~/<.*?>/g, "");
        text = FlashRegex.replace(text, ~/&lt;/g, "<");
        text = FlashRegex.replace(text, ~/&gt;/g, ">");
        return text;
    }
    public function toString():String{
        return "["+ch+"] " + plainText();
    }

    public function clone():Log{
        var l:Log = new Log(text, ch, priority, repeat, html);
        l.line = line;
        l.time = time;
        //l.stack = stack;
        return l;
    }
}