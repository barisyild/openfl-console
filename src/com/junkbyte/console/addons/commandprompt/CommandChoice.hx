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
package com.junkbyte.console.addons.commandprompt;

import openfl.utils.Function;

class CommandChoice {

    public var key:String;
    public var callback:Function;
    public var text:String;

    public function new(choiceKey : String, selectionCallback:Function, txt : String = "") {
        key = choiceKey;
        callback = selectionCallback;
        text = txt;
    }

    public function toHTMLString():String{
        var txt:String = (text ? text : "" );
        if(key) return "&gt; <b>"+key+"</b>: " + txt;
        return txt ? txt : "[CommandChoice empty]";
    }
}