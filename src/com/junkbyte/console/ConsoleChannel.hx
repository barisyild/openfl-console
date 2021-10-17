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

import openfl.utils.Function;
import openfl.display.DisplayObjectContainer;

class ConsoleChannel {

    private var _c:Dynamic; // because it could be Console or Cc. This is the cheapest way I think...
    private var _name:String;

    public var enabled:Bool = true;

    /**
		 * Construct channel instance
		 *
		 * @param String Name of channel
		 * @param String (optional) instance of Console, leave blank to use C.
		 */
    public function new(n:Dynamic, c:Console = null){
        _name = Console.MakeChannelName(n);
        if (_name == Console.GLOBAL_CHANNEL) _name = Console.DEFAULT_CHANNEL;
        // allowed to pass in Console here incase you want to use a different console instance from whats used in Cc
        _c = c?c:Cc;
    }

    //TODO: Warning Modified arguement, priority:Number => priority:Float
    public function add(str:Dynamic, priority:Float = 2, isRepeating:Bool = false):Void {
        if(enabled) _c.ch(_name, str, priority, isRepeating);
    }
    /**
		 * Add log line with priority 1 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */

    public function log(#if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void {
        multiadd(_c.logch, #if (haxe_ver >= "4.2.0") ...args #else args #end);
    }
    /**
		 * Add log line with priority 3 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */

    public function info(#if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void {
        multiadd(_c.infoch, #if (haxe_ver >= "4.2.0") ...args #else args #end);
    }
    /**
		 * Add log line with priority 5 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */

    public function debug(#if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void {
        multiadd(_c.debugch, #if (haxe_ver >= "4.2.0") ...args #else args #end);
    }
    /**
		 * Add log line with priority 7 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param String to be logged, any type can be passed and will be converted to string
		 */

    public function warn(#if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void {
        multiadd(_c.warnch, #if (haxe_ver >= "4.2.0") ...args #else args #end);
    }
    /**
		 * Add log line with priority 9 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */

    public function error(#if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void {
        multiadd(_c.errorch, #if (haxe_ver >= "4.2.0") ...args #else args #end);
    }
    /**
		 * Add log line with priority 10 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */
    public function fatal(#if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void
    {
        multiadd(_c.fatalch, #if (haxe_ver >= "4.2.0") ...args #else args #end);
    }

    private function multiadd(f:Function, #if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void
    {
        if(enabled) f(null, new Array(_name).concat(args));
    }
    /**
		 * Add log line with priority 10 to channel
		 * Allows multiple arguments for convenience use.
		 *
		 * @param  Name of channel, if a non-string param is passed, it will use the object's class name as channel name.
		 * @param String to be logged, any type can be passed and will be converted to string
		 */

    //TODO: Warning Modified arguement, priority:Number => priority:Float
    public function stack(str:Dynamic, depth:Int = -1, priority:Float = 5):Void {
        if(enabled) _c.stackch(name, str, depth, priority);
    }

    /**
		 * Expand object values and print in channel - similar to JSON encode
		 *
		 * @param obj	Object to explode
		 * @param depth	Depth of explosion, -1 = unlimited
		 */
    public function explode(obj:Dynamic, depth:Int = 3):Void {
        _c.explodech(name, obj, depth);
    }
    /**
		 * Print the display list map to channel
		 *
		 * @param base	Display object to start mapping from
		 * @param maxstep	Maximum child depth. 0 = unlimited
		 */
    public function map(base:DisplayObjectContainer, maxstep:UInt = 0):Void {
        _c.mapch(name, base, maxstep);
    }

    /**
		 * Output an object's info such as it's variables, methods (if any), properties,
		 * superclass, children displays (if Display), parent displays (if Display), etc - to channel.
		 * Similar to clicking on an object link or in commandLine: /inspect  OR  /inspectfull.
		 * However this method does not go to 'inspection' channel but prints on the Console channel.
		 *
		 * @param obj		Object to inspect
		 * @param detail	Set to true to show inherited values.
		 *
		 */
    public function inspect(obj:Dynamic, detail:Bool = true):Void {
        _c.inspectch(name, obj, detail);
    }

    /**
		 * Get channel name
		 * Read only
		 */

    public var name(get, never):String;
    public function get_name():String {
        return _name;
    }
    /**
		 * Clear channel
		 */
    public function clear():Void {
        _c.clear(_name);
    }

    public function toString():String {
        return "[ConsoleChannel "+name+"]";
    }
}
