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
import openfl.utils.Dictionary;

/**
 * @private
 */
class WeakRef{

    private var _val:Dynamic;
    private var _strong:Bool; // strong flag

    // Known issue: storing a function reference that's on timeline don't seem to work on next frame. fix = manually store as strong ref.
    // There is abilty to use strong reference incase you need to mix -
    // weak and strong references together somewhere
    public function new(ref:Dynamic, strong:Bool = false) {
        _strong = strong;
        reference = ref;
    }

    public var reference(get, set):Dynamic;
    public function get_reference():Dynamic {
        if(_strong){
            return _val;
        }else{
            for(X in Reflect.fields(_val)){
                return X;
            }
        }
        return null;
    }

    public function set_reference(ref:Dynamic):Dynamic{
        if(_strong){
            _val = ref;
        }else{
            _val = {};
            Reflect.setField(_val, ref, null);
        }
        return ref;
    }

    public var strong(get, never):Bool;

    public function get_strong():Bool{
        return _strong;
    }

    /*
    // Removed to save compile size
    public function set_strong(b:Bool):Bool {
        if(_strong != b){
            var ref:Dynamic = reference;
            _strong = b;
            reference = ref;
        }
        return b;
    }*/
}