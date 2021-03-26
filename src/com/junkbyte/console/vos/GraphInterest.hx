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
import com.junkbyte.console.core.Executer;
import com.junkbyte.console.vos.WeakRef;

    /**
	 * @private
	 */
class GraphInterest {

    private var _ref:WeakRef = null;
    public var _prop:String = null;
    private var useExec:Bool = false;
    public var key:String = null;
    //TODO: Warning Modified arguement, col:Number => col:Int
    public var col:Int = 0x000000;
    public var v:Float = 0;
    public var avg:Float = 0;

    //TODO: Warning Modified arguement, color:Number => color:Int
    public function new(keystr:String = "", color:Int = 0):Void {
        col = color;
        key = keystr;
    }

    public function setObject(object:Dynamic, property:String):Float {
        _ref = new WeakRef(object);
        _prop = property;
        useExec = FlashRegex.search(_prop, ~/[^\w\d]/) >= 0;
            //
        v = getCurrentValue();
        avg = v;
        return v;
    }

    public var obj(get, never):Dynamic;
    public function get_obj():Dynamic{
        return _ref!=null?_ref.reference:null;
    }

    public var prop(get, never):String;

    public function get_prop():String {
        return _prop;
    }
    //
    //
    //
    public function getCurrentValue():Float {
        return useExec ? Executer.Exec(obj, _prop) : Reflect.field(obj, _prop);
    }

    public function setValue(val:Float, averaging:UInt = 0):Void{
        v = val;
        if(averaging>0)
        {
            if(Math.isNaN(avg))
            {
                avg = v;
            }
            else
            {
                avg += ((v-avg)/averaging);
            }
        }
    }
    //
    //
    //
    public function toBytes(bytes:ByteArray):Void {
        bytes.writeUTF(key);
        bytes.writeUnsignedInt(col);
        bytes.writeDouble(v);
        bytes.writeDouble(avg);
    }

    public static function FromBytes(bytes:ByteArray):GraphInterest {
        var interest:GraphInterest = new GraphInterest(bytes.readUTF(), bytes.readUnsignedInt());
        interest.v = bytes.readDouble();
        interest.avg = bytes.readDouble();
        return interest;
    }
}
