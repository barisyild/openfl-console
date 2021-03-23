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
package com.junkbyte.console.core;

import com.junkbyte.console.Console;
import com.junkbyte.console.ConsoleConfig;
import openfl.events.EventDispatcher;

/**
	 * @private
	 */
class ConsoleCore extends EventDispatcher
{
    private var console:Console;
    private var config:ConsoleConfig;

    public function new(c:Console)
    {
        super();
        console = c;
        config = console.config;
    }

    public var remoter(get, never):Remoting;

    private function get_remoter():Remoting
    {
        return console.remoter;
    }

    private function report(obj:Dynamic = "", priority:Int = 0, skipSafe:Bool = true, ch:String = null):Void
    {
        console.report(obj, priority, skipSafe, ch);
    }
}