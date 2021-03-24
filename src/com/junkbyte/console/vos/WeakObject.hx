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

class WeakObject {

    private var _map:Map<String, WeakRef>;
    private var _weakMap:Map<String, WeakRef>;

    public function new() {
        _map = new Map();
        _weakMap = new Map();
    }

    public function get(n:String):Dynamic {
        var ref:WeakRef = getWeakRef(n);
        return ref != null?ref.reference:null;
    }

    public function set(n:String, obj:Dynamic, strong:Bool = false):Void {
        remove(n);

        if(obj != null)
        {
            if(strong)
            {
                _map.set(n, new WeakRef(obj, strong));
            }else{
                _weakMap.set(n, new WeakRef(obj, strong));
            }
        }
    }

    public function remove(n:String):Void {
        if(_weakMap.exists(n))
        {
            _weakMap.remove(n);
        }else if(_map.exists(n))
        {
            _map.remove(n);
        }
    }

    public function exists(n:String):Bool {
        return _weakMap.exists(n) || _map.exists(n);
    }

    public function keys():Array<String>
    {
        var keys:Array<String> = [];
        for(key in _weakMap.keys())
        {
            keys.push(key);
        }
        for(key in _map.keys())
        {
            keys.push(key);
        }
        return keys;
    }

    public function getWeakRef(n:String):WeakRef {
        if(_weakMap.exists(n))
            return _weakMap.get(n);
        else if(_map.exists(n))
            return _map.get(n);
        return null;
    }

    /*public function getProperty(n:Dynamic):Dynamic {
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
    }*/
}