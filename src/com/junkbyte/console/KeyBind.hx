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
package com.junkbyte.console;

import openfl.errors.Error;
class KeyBind
{

    private var _code:Bool;
    private var _key:String;

    /**
		 * @param code Pass a single string (e.g. "a") OR pass keyCode (e.g. Keyboard.F1)
		 * @param shift Set true if shift key needs to be pressed to trigger
		 * @param ctrl Set true if ctrl key needs to be pressed to trigger
		 * @param alt Set true if alt key needs to be pressed to trigger
		 */
    public function new(v:Dynamic, shift:Bool = false, ctrl:Bool = false, alt:Bool = false, onUp:Bool = false)
    {
        _key = Std.string(v).toUpperCase();
        if(Std.isOfType(v, Int)){
            _code = true;
        }else if(v == null || _key.length != 1) {
            throw new Error("KeyBind: character (first char) must be a single character. You gave ["+v+"]");
        }

        if(_code) _key = "keycode:"+_key;
        if(shift) _key+="+shift";
        if(ctrl) _key+="+ctrl";
        if(alt) _key+="+alt";
        if(onUp) _key+="+up";

    }

    public var useKeyCode(get, never):Bool;
    public function get_useKeyCode():Bool
    {
        return _code;
    }

    public var key(get, never):String;
    public function get_key():String
    {
        return _key;
    }
}