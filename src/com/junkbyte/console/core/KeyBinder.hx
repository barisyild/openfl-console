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

import openfl.text.TextFieldType;
import openfl.errors.Error;
import openfl.utils.Function;
import openfl.text.TextFieldType;
import openfl.text.TextField;
import com.junkbyte.console.Console;
import com.junkbyte.console.KeyBind;
import openfl.events.KeyboardEvent;

/**
	 * @private
	 * 
	 * Suppse this could be 'view' ?
	 */
class KeyBinder extends ConsoleCore {

    private var _passInd:Int;
    private var _binds:Map<String, Array<Dynamic>>;
    private var _warns:UInt;

    public function new(console:Console) {
        super(console);

        console.cl.addCLCmd("keybinds", printBinds, "List all keybinds used");
        _binds = new Map();
    }

    public function bindKey(key:KeyBind, fun:Function ,args:Array<Dynamic> = null):Void {
        if(config.keystrokePassword != null && (!key.useKeyCode && key.key.charAt(0) == config.keystrokePassword.charAt(0))){
            report("Error: KeyBind ["+key.key+"] is conflicting with Console password.",9);
            return;
        }
        if(fun == null){
            _binds.remove(key.key);
            //if(!config.quiet) report("Unbined key "+key.key+".", -1);
        }else{
            var arr:Array<Dynamic> = [fun, args];
            _binds[key.key] = arr;
            //if(!config.quiet) report("Bined key "+key.key+" to a function."+(config.keyBindsEnabled?"":" (will not trigger while key binding is disabled in config)"), -1);
        }
    }

    public function keyDownHandler(e:KeyboardEvent):Void {
        handleKeyEvent(e, false);
    }

    public function keyUpHandler(e:KeyboardEvent):Void {
        handleKeyEvent(e, true);
    }

    private function handleKeyEvent(e:KeyboardEvent, isKeyUp:Bool):Void
    {
        var char:String = String.fromCharCode(e.charCode);
        if(isKeyUp && config.keystrokePassword != null && char != null && char == config.keystrokePassword.substring(_passInd,_passInd+1)){
            _passInd++;
            if(_passInd >= config.keystrokePassword.length){
                _passInd = 0;
                if(canTrigger()){
                    if(console.visible && !console.panels.mainPanel.visible){
                        console.panels.mainPanel.visible = true;
                    }else {
                        console.visible = !console.visible;
                    }
                    if(console.visible && console.panels.mainPanel.visible){
                        console.panels.mainPanel.visible = true;
                        console.panels.mainPanel.moveBackSafePosition();
                    }
                }else if(_warns < 3){
                    _warns++;
                    report("Password did not trigger because you have focus on an input TextField.", 8);
                }
            }
        }
        else
        {
            if(isKeyUp) _passInd = 0;
            var bind:KeyBind = new KeyBind(e.keyCode, e.shiftKey, e.ctrlKey, e.altKey, isKeyUp);
            tryRunKey(bind.key);
            if(char != null){
                bind = new KeyBind(char, e.shiftKey, e.ctrlKey, e.altKey, isKeyUp);
                tryRunKey(bind.key);
            }
        }
    }

    private function printBinds(#if (haxe_ver >= "4.2.0") ...args:Dynamic #else args:Array<Dynamic> #end):Void {
        report("Key binds:", -2);
        var i:UInt = 0;
        for (X in _binds){
            i++;
            report(X, -2);
        }
        report("--- Found "+i, -2);
    }

    private function tryRunKey(key:String):Void
    {
        var a:Array<Dynamic> = _binds[key];
        if(config.keyBindsEnabled && a != null){
            if(canTrigger()){
                Reflect.callMethod(null, a[0], a[1]);
            }else if(_warns < 3){
                _warns++;
                report("Key bind [" + key + "] did not trigger because you have focus on an input TextField.", 8);
            }
        }
    }

    private function canTrigger():Bool {
        // in try catch block incase the textfield is in another domain and we wont be able to access the type... (i think)
        try {
            if(console.stage != null && Std.is(console.stage.focus, TextField)) {
                var txt:TextField = cast(console.stage.focus, TextField);
                if(txt.type == TextFieldType.INPUT) {
                    return false;
                }
            }
        }catch(err:Error) {

        }
        return true;
    }
}