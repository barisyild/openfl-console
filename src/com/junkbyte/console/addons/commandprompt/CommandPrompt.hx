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
import com.junkbyte.console.Cc;
import com.junkbyte.console.Console;

/**
	 * Command prompt addon.
	 * <ul>
	 * <li>Simulates 'command prompt' style user input.</li>
	 * <li>Ask to choose from a selection of input, user enter into command line to choose a selection.</li>
	 * <li>Could be useful for 'utility' sort of app where there is no GUI to represent user options.</li>
	 * </ul>
	 */
class CommandPrompt {

    public var ch : String = Console.CONSOLE_CHANNEL;
    public var headerQuestion:String;
    public var footerText:String;
    public var defaultCallback:Function;

    private var _console:Console;
    private var _choices:Array<CommandChoice> = new Array();

    private var _wasAutoCompleteEnabled:Bool;
    private var _wasScopeShown:Bool;

    public function new(headerQuestion:String = null, defaultCB:Function = null, choices:Array = null){

        this.headerQuestion = headerQuestion;
        defaultCallback = defaultCB;
        if(choices){
            _choices = choices;
        }
    }

    public function addCmdChoice(cmdChoice:CommandChoice):Void {
        _choices.push(cmdChoice);
    }

    public function start():Void {
        if (console != null) {
            console.config.commandLineInputPassThrough = cast commandLinePassThrough;
            _wasAutoCompleteEnabled = console.config.commandLineAutoCompleteEnabled;
            _wasScopeShown = console.config.style.showCommandLineScope;
            console.config.commandLineAutoCompleteEnabled = false;
            console.config.style.showCommandLineScope = false;
            ask();
        }
    }

    private function ask():Void {
        if(headerQuestion != null){
            console.addHTMLch(ch, -2, "<b>" + headerQuestion + "</b>");
        }
        printChoices();
        if(footerText != null){
            console.addHTMLch(ch, -2, footerText);
        }
    }

    private function printChoices():Void {
        for (choice in _choices) {
            console.addHTMLch(ch, 4,  choice.toHTMLString());
        }
    }

    private function commandLinePassThrough(command:String):Void {
        for (choice in _choices) {
            if (choice.key.toLowerCase() == command.toLowerCase()) {
                end();
                choice.callback(choice.key);
                return;
            }
        }
        if(defaultCallback != null){
            end();
            defaultCallback(command);
        }
    }

    private function end():Void {
        console.config.commandLineInputPassThrough = null;
        console.config.commandLineAutoCompleteEnabled = _wasAutoCompleteEnabled;
        console.config.style.showCommandLineScope = _wasScopeShown;
    }

    public function setConsole(targetC:Console):Void {
        if(targetC) _console = targetC;
    }

    public var console(get, never):Console;
    private function get_console():Console{
        if(_console) return _console;
        return Cc.instance;
    }
}