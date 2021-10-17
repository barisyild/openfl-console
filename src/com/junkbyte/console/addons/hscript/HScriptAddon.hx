package com.junkbyte.console.addons.hscript;

import openfl.utils.Function;
import com.junkbyte.console.Cc;
import com.junkbyte.console.Console;
import com.junkbyte.console.view.ConsolePanel;
import openfl.display.DisplayObject;

class HScriptAddon
{
    public static function start(console:Console = null):HScriptPanel
    {
        if (console == null)
        {
            console = Cc.instance;
        }
        if (console == null)
        {
            return null;
        }
        var hscriptPanel:HScriptPanel = new HScriptPanel(console);
        console.panels.addPanel(hscriptPanel);
        return hscriptPanel;
    }

    public static function registerCommand(commandName:String = "hscript", console:Console = null):Void
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

    public static function addToMenu(menuName:String = "HScript", console:Console = null):Void
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
            var panel:HScriptPanel = cast(console.panels.getPanel(HScriptPanel.NAME), HScriptPanel);
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