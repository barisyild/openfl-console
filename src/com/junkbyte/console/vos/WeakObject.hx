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

import openfl.utils.Dictionary;

@:generic class WeakObject<T> {

    private var _dict:Dictionary<T, WeakRef> = new Dictionary<T, WeakRef>();

    public function new() {

    }

    public function get(n:T):Dynamic {
        var ref:WeakRef = getWeakRef(n);
        return ref != null ? ref.reference : null;
    }

    public function set(n:T, obj:Dynamic, strong:Bool = false):Void {
        remove(n);

        if(obj != null)
            _dict.set(n, new WeakRef(obj, strong));
    }

    public function remove(n:T):Void {
        _dict.remove(n);
    }

    public function exists(n:T):Bool {
        if(_dict.exists(n))
            return get(n) != null;

        return false;
    }

    public function getReferenceIndex(reference:Dynamic):Null<T>
    {
        for(key in _dict)
        {
            var weakRef = _dict.get(key);
            if(weakRef.reference == reference)
            {
                return key;
            }
        }

        return null;
    }

    public function keys():Array<T> {
        var keys:Array<T> = [];
        for(key in _dict)
            keys.push(key);
        return keys;
    }

    public function getWeakRef(n:T):WeakRef {
        return _dict.get(n);
    }
}