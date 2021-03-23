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

/**
 * @private
 */

//TODO: Warning, this class has been added to compile the program completely, it is completely not working.
//TODO: fix this class!
class WeakObject {

    private var _item:Array<Dynamic>;
    private var _dir:Dynamic;

    public function new() {
        _dir = {};
    }
    public function set(n:String, obj:Dynamic, strong:Bool = false):Void {
        if(obj == null)
        {
            Reflect.deleteField(_dir, n);
        }
        else
        {
            Reflect.setField(_dir, n, new WeakRef(obj, strong));
        }
    }
    public function get(n:String):Dynamic {
        var ref:WeakRef = getWeakRef(n);
        return ref != null?ref.reference:null;
    }
    public function getWeakRef(n:String):WeakRef{
        return cast(Reflect.field(_dir, n), WeakRef);
    }
    //
    // PROXY
    //
    function getProperty(n:Dynamic):Dynamic {
        return get(n);
    }

    //TODO: Warning Modified arguement, ...rest => rest:Array<Dynamic>
    public function callProperty(n:Dynamic, rest:Array<Dynamic>):Dynamic {
        var o:Dynamic = get(n);
        return o.apply(this, rest);
    }

    public function setProperty(n:Dynamic, v:Dynamic):Void {
        set(n,v);
    }

    public  function nextName(index:Int):String {
        return _item[index - 1];
    }

    public  function nextValue(index:Int):Dynamic {
        return null;
    }

    public  function nextNameIndex(index:Int):Int {
        if (index == 0) {
            _item = new Array<Dynamic>();
            for (x in Reflect.fields(_dir)) {
            _item.push(x);
            }
        }
        if (index < _item.length) {
            return index + 1;
        } else {
            return 0;
        }
    }

    public  function deleteProperty(name:Dynamic):Bool {
        return Reflect.deleteField(_dir, name);
    }

    public function toString():String{
        return "[WeakObject]";
    }
}