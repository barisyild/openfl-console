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
package com.junkbyte.console.addons.memorytracker;
import openfl.utils.Function;
import com.junkbyte.console.Console;
import com.junkbyte.console.KeyBind;

class MemoryTrackerAddon
{
    public static var sort:String->String->Int = function(a:String, b:String):Int {
        a = a.toUpperCase();
        b = b.toUpperCase();

        if (a < b) {
            return -1;
        }
        else if (a > b) {
            return 1;
        } else {
            return 0;
        }
    };

    public static function start(console:Console = null):MemoryTrackerPanel
    {
        if (console == null)
        {
            console = Cc.instance;
        }
        if (console == null)
        {
            return null;
        }
        var memoryTrackerPanel:MemoryTrackerPanel = new MemoryTrackerPanel(console);
        console.panels.addPanel(memoryTrackerPanel);
        return memoryTrackerPanel;
    }

    public static function registerCommand(commandName:String = "memorytracker", console:Console = null):Void
    {
        if (console == null)
        {
            console = Cc.instance;
        }
        if (console == null || commandName == null)
        {
            return;
        }

        var callbackFunction:Function = function(...arguments:Dynamic):Void
        {
            start(console);
        }
        console.addSlashCommand(commandName, callbackFunction);
    }

    public static function addToMenu(menuName:String = "Memory Tracker", console:Console = null):Void
    {
        if (console == null)
        {
            console = Cc.instance;
        }
        if (console == null || menuName == null)
        {
            return;
        }

        var callbackFunction:Function = function():Void
        {
            var panel:MemoryTrackerPanel = cast(console.panels.getPanel(MemoryTrackerPanel.NAME), MemoryTrackerPanel);
            if(panel != null)
            {
                panel.close();
            }
            else
            {
                panel = start();
                panel.x = console.mouseX - panel.width * 0.5;
                panel.y = console.mouseY + 10;
            }
        }
        console.addMenu(menuName, callbackFunction);
    }
}