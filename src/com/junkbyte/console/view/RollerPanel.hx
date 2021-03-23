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
package com.junkbyte.console.view;

import openfl.text.TextFieldAutoSize;
import com.junkbyte.console.Console;
import com.junkbyte.console.KeyBind;
import com.junkbyte.console.core.LogReferences;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.TextEvent;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.utils.Dictionary;

/**
	 * @private
	 */
class RollerPanel extends ConsolePanel{

    public static inline var NAME:String = "rollerPanel";

    private var _settingKey:Bool;

    public function new(m:Console) {
        super(m);
        name = NAME;
        init(60,100,false);
        txtField = makeTF("rollerPrints");
        txtField.multiline = true;
        txtField.autoSize = TextFieldAutoSize.LEFT;
        registerTFRoller(txtField, onMenuRollOver, linkHandler);
        registerDragger(txtField);
        addChild(txtField);
        addEventListener(Event.ENTER_FRAME, _onFrame);
        addEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
    }

    private function removeListeners(e:Event=null):Void {
        removeEventListener(Event.ENTER_FRAME, _onFrame);
        removeEventListener(Event.REMOVED_FROM_STAGE, removeListeners);
        if(stage != null) stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
    }

    private function _onFrame(e:Event):Void {
        if(console.stage == null){
            close();
            return;
        }
        if(_settingKey){
            txtField.htmlText = "<high><menu>Press a key to set [ <a href=\"event:cancel\"><b>cancel</b></a> ]</menu></high>";
        }else{
            txtField.htmlText = "<low>"+getMapString(false)+"</low>";
            txtField.autoSize = TextFieldAutoSize.LEFT;
            txtField.setSelection(0, 0);
        }
        width = txtField.width+4;
        height = txtField.height;
    }

    public function getMapString(dolink:Bool):String{
        var stg:Stage = console.stage;
        var str:String = "";
        if(!dolink){
            var key:String = console.rollerCaptureKey != null? console.rollerCaptureKey.key : "unassigned";
            str = "<menu> <a href=\"event:close\"><b>X</b></a></menu> Capture key: <menu><a href=\"event:capture\">"+key+"</a></menu><br/>";
        }
        var p:Point = new Point(stg.mouseX, stg.mouseY);
        if(stg.areInaccessibleObjectsUnderPoint(p)){
            str += "<p9>Inaccessible objects detected</p9><br/>";
        }
        var objs:Array<DisplayObject> = stg.getObjectsUnderPoint(p);

        var stepMap:Map<DisplayObject, Int> = new Map<DisplayObject, Int>();
        if(objs.length == 0){
            objs.push(stg);// if nothing at least have stage.
        }
        for(child in objs){
            var chain:Array<DisplayObject> = [child];
            var par:DisplayObjectContainer = child.parent;
            while(par != null){
                chain.unshift(par);
                par = par.parent;
            }
            var len:Int = chain.length;
            for (i in 0...len){
                var obj:DisplayObject = chain[i];
                //if(stepMap[obj] == undefined){
                if(stepMap[obj] == null){
                    stepMap[obj] = i;

                    var j = i;
                    while(j>0)
                    {
                        str += j==1?" ∟":" -";
                        j--;
                    }

                    var n:String = obj.name;
                    var ind:UInt;
                    if(dolink && console.config.useObjectLinking) {
                        ind = console.refs.setLogRef(obj);
                        n = "<a href='event:cl_"+ind+"'>"+n+"</a> "+console.refs.makeRefTyped(obj);
                    }
                    else n = n+" ("+LogReferences.ShortClassName(obj)+")";

                    if(obj == stg){
                        ind = console.refs.setLogRef(stg);
                        if(ind != 0) str +=  "<p3><a href='event:cl_"+ind+"'><i>Stage</i></a> ";
                        else str += "<p3><i>Stage</i> ";
                        str +=  "["+stg.mouseX+","+stg.mouseY+"]</p3><br/>";
                    }else if(i == len-1){
                        str +=  "<p5>"+n+"</p5><br/>";
                    }else {
                        str +=  "<p2><i>"+n+"</i></p2><br/>";
                    }
                }
            }
        }
        return str;
    }

    public override function close():Void {
        cancelCaptureKeySet();
        removeListeners();
        super.close();
        console.panels.updateMenu(); // should be black boxed :/
    }

    private function onMenuRollOver(e:TextEvent):Void {
        var txt:String = e.text != null ? StringTools.replace(e.text, "event:", "") : "";
        trace(txt);
        if(txt == "close"){
            txt = "Close";
        }else if(txt == "capture"){
            var key:KeyBind = console.rollerCaptureKey;
            if(key != null){
                txt = "Unassign key ::" + key.key;
            }else{
                txt = "Assign key";
            }
        }else if(txt == "cancel"){
            txt = "Cancel assign key";
        }else{
            txt = null;
        }
        console.panels.tooltip(txt, this);
    }

    private function linkHandler(e:TextEvent):Void {
        cast(e.currentTarget, TextField).setSelection(0, 0);
        trace(e.text);
        if(e.text == "close"){
            close();
        }else if(e.text == "capture"){
            if(console.rollerCaptureKey != null){
                console.setRollerCaptureKey(null);
            }else{
                _settingKey = true;
                stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler, false, 0, true);
            }
            console.panels.tooltip(null);
        }else if(e.text == "cancel"){
            cancelCaptureKeySet();
            console.panels.tooltip(null);
        }
        e.stopPropagation();
    }

    private function cancelCaptureKeySet():Void {
        _settingKey = false;
        if(stage != null)
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
        }
    }

    private function keyDownHandler(e:KeyboardEvent):Void {
        if(e.charCode == 0) return;
        var char:String = String.fromCharCode(e.charCode);
        cancelCaptureKeySet();
        console.setRollerCaptureKey(char, e.shiftKey, e.ctrlKey, e.altKey);
        console.panels.tooltip(null);
    }
}