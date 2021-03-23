package com.junkbyte.console.addons.autoFocus;

import com.junkbyte.console.Cc;
import com.junkbyte.console.Console;
import com.junkbyte.console.view.ConsolePanel;
import com.junkbyte.console.view.MainPanel;
import openfl.events.Event;
import openfl.text.TextField;

/**
	 * This addon sets focus to commandLine input field whenever Console becomes visible, e.g after entering password key.
	 */
class CommandLineAutoFocusAddon
{
    public static function registerToConsole(console:Console = null):Void
    {
        if (console == null)
        {
            console = Cc.instance;
        }
        if (console == null)
        {
            return;
        }

        console.panels.mainPanel.addEventListener(ConsolePanel.VISIBLITY_CHANGED, onPanelVisibilityChanged);
    }

    private static function onPanelVisibilityChanged(event:Event):Void
    {
        var mainPanel:MainPanel = cast(event.currentTarget, MainPanel);

        if (mainPanel.visible == false)
        {
            return;
        }

        var commandField:TextField = cast(mainPanel.getChildByName("commandField"), TextField);

        if (commandField != null && commandField.stage != null)
        {
            commandField.stage.focus = commandField;
            var textLen:UInt = commandField.text.length;
            commandField.setSelection(textLen, textLen);
        }
    }
}