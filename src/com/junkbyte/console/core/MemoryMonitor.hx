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

import openfl.errors.Error;
import com.junkbyte.console.Console;
import openfl.system.System;
import openfl.utils.Dictionary;

/**
 * @private
 */
class MemoryMonitor extends ConsoleCore {

    private var _namesList:Map<String, Bool>;
    private var _objectsList:Dynamic;
    private var _count:UInt;
    //
    //
    public function new(m:Console) {
        super(m);
        _namesList = new Map<String, Bool>();
        _objectsList = {};

        console.remoter.registerCallback("gc", gc);
    }

    public function watch(obj:Dynamic, n:String):String {
        var className:String = openfl.Lib.getQualifiedClassName(obj);
        if(n == null) n = className+"@"+openfl.Lib.getTimer();

        if(Reflect.hasField(_objectsList, obj)){
            if(_namesList[Reflect.field(_objectsList, obj)]){
                unwatch(Reflect.field(_objectsList, obj));
            }
        }
        if(_namesList[n]){
            if(_objectsList[obj] == n){
                _count--;
            }else{
                n = n+"@"+openfl.Lib.getTimer()+"_"+Math.floor(Math.random()*100);
            }
        }
        _namesList[n] = true;
        _count++;
        _objectsList[obj] = n;
        //if(!config.quiet) report("Watching <b>"+className+"</b> as <p5>"+ n +"</p5>.",-1);
        return n;
    }

    public function unwatch(n:String):Void {
        for (X in Reflect.fields(_objectsList)) {
            if(Reflect.field(_objectsList, X) == n){
                Reflect.deleteField(_objectsList, X);
            }
        }
        if(_namesList[n])
        {
            _namesList.remove(n);
            _count--;
        }
    }
    //
    //
    //
    public function update():Void {
        if(_count == 0) return;
        var arr:Array<String> = new Array();
        var o:Dynamic = {};
        for (X in Reflect.fields(_objectsList)) {
            Reflect.setField(o, Reflect.field(_objectsList, X), true);
        }

        for(Y in _namesList.keys()){
            if(Reflect.field(o, Y) == null){
                arr.push(Y);
                _namesList.remove(Y);
                _count--;
            }
        }

        if(arr.length != 0) report("<b>GARBAGE COLLECTED "+arr.length+" item(s): </b>"+arr.join(", "),-2);
    }

    public var count(get, never):UInt;
    public function get_count():UInt {
        return _count;
    }

    public function gc():Void {
        if(remoter.remoting == Remoting.RECIEVER){
            try{
                //report("Sending garbage collection request to client",-1);
                remoter.send("gc");
            }catch(e:Error){
                report(e,10);
            }
        }else{
            var ok:Bool = false;
            try{
                // have to put in brackes cause some compilers will complain.
                if(Reflect.hasField(System, "gc")) {
                    System.gc();
                    ok = true;
                }
            }catch(e:Error){

            }

            var str:String = "Manual garbage collection "+(ok?"successful.":"FAILED. You need debugger version of flash player.");
            report(str,(ok?-1:10));
        }
    }
}