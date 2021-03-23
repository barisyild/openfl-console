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

import Type.ValueType;
import openfl.errors.Error;
import openfl.utils.ByteArray;
import com.junkbyte.console.Cc;
import com.junkbyte.console.Console;

import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;

/**
	 * @private
	 */
class ConsoleTools extends ConsoleCore{

    public function new(console:Console) {
        super(console);
    }

    public function map(base:DisplayObjectContainer, maxstep:Int = 0, ch:String = null):Void {
        if(base == null){
            report("Not a DisplayObjectContainer.", 10, true, ch);
            return;
        }

        var steps:Int = 0;
        var wasHiding:Bool = false;
        var index:Int = 0;
        var lastmcDO:DisplayObject = null;
        var list:Array<DisplayObject> = new Array();
        list.push(base);
        while(index<list.length){
            var mcDO:DisplayObject = list[index];
            index++;
            // add children to list
            if(Std.isOfType(mcDO, DisplayObjectContainer)){
                var mc:DisplayObjectContainer = cast(mcDO, DisplayObjectContainer);
                var numC:Int = mc.numChildren;
                for(i in 0...numC){
                    var child:DisplayObject = mc.getChildAt(i);
                    //list.splice(index+i,0,child);
                    //TODO: implement required
                }
            }
            // figure out the depth and print it out.
            if(lastmcDO != null){
                if(Std.is(lastmcDO, DisplayObjectContainer) && cast(lastmcDO, DisplayObjectContainer).contains(mcDO)){
                    steps++;
                }else{
                    while(lastmcDO != null){
                        lastmcDO = lastmcDO.parent;
                        if(Std.is(lastmcDO, DisplayObjectContainer)){
                            if(steps>0){
                                steps--;
                            }
                            if(cast(lastmcDO, DisplayObjectContainer).contains(mcDO)){
                                steps++;
                                break;
                            }
                        }
                    }
                }
            }
            var str:String = "";
            for(i in 0...steps){
                str += (i==steps-1)?" ∟ ":" - ";
            }
            if(maxstep<=0 || steps<=maxstep){
                wasHiding = false;
                var ind:UInt = console.refs.setLogRef(mcDO);
                var n:String = mcDO.name;
                if(ind != 0) n = "<a href='event:cl_"+ind+"'>"+n+"</a>";
                if(Std.is(mcDO, DisplayObjectContainer)){
                    n = "<b>"+n+"</b>";
                }else{
                    n = "<i>"+n+"</i>";
                }
                str += n+" "+console.refs.makeRefTyped(mcDO);
                report(str,Std.is(mcDO, DisplayObjectContainer)?5:2, true, ch);
            }else if(!wasHiding){
                wasHiding = true;
                report(str+"...",5, true, ch);
            }
            lastmcDO = mcDO;
        }
        report(base.name + ":" + console.refs.makeRefTyped(base) + " has " + (list.length - 1) + " children/sub-children.", 9, true, ch);
        if (config.commandLineAllowed) report("Click on the child display's name to set scope.", -2, true, ch);
    }


    public function explode(obj:Dynamic, depth:Int = 3, p:Int = 9):String {
        //TODO: source code is completely incompatible.
        //TODO: Fix this issue!
        return "implement required";
    }

    private function stepExp(o:Dynamic, n:String, d:Int, p:Int):String {
        return n + ":" + explode(Reflect.field(o, n), d-1, p-1);
    }

    public function getStack(depth:Int, priority:Int):String {
        var e:Error = new Error();
        //var str:String = e.hasOwnProperty("getStackTrace")?e.getStackTrace():null;
        //TODO: implement required
        var str:String = null;
        if(str == null) return "";
        var txt:String = "";
        //var lines:Array<String> = str.split(/\n\sat\s/);
        //TODO: implement required

        var lines:Array<String> = [];
        var len:Int = lines.length;
        //var reg:RegExp = new RegExp("Function|" + openfl.Lib.getQualifiedClassName(Console) + "|" + openfl.Lib.getQualifiedClassName(Cc));
        //TODO: implement required
        var found:Bool = false;
        for (i in 2...len){
            //if(!found && (lines[i].search(reg) != 0))
            //TODO: implement required
            if(false)
            {
                found = true;
            }
            if(found){
                txt += "\n<p"+priority+"> @ "+lines[i]+"</p"+priority+">";
                if(priority>0) priority--;
                depth--;
                if(depth<=0){
                    break;
                }
            }
        }
        return txt;
    }
}