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

import haxe.io.Bytes;
import Type.ValueType;
import openfl.errors.Error;
import com.junkbyte.console.Console;
import com.junkbyte.console.vos.WeakObject;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import openfl.utils.Dictionary;

/**
 * @private
 */
class LogReferences extends ConsoleCore
{

    public static inline var INSPECTING_CHANNEL:String = "⌂";

    private var _refMap:WeakObject = new WeakObject();
    private var _refRev:Dynamic = {};
    private var _refIndex:UInt = 1;

    private var _dofull:Bool;
    private var _current:Dynamic;// current will be kept as hard reference so that it stays...

    private var _history:Array<Dynamic>;
    private var _hisIndex:Int;

    private var _prevBank:Array<Dynamic> = new Array();
    private var _currentBank:Array<Dynamic> = new Array();
    private var _lastWithdraw:UInt;

    public function new(console:Console) {
        super(console);

        remoter.registerCallback("ref", function(bytes:ByteArray):Void {
            handleString(bytes.readUTF());
        });
        remoter.registerCallback("focus", handleFocused);
    }
    public function update(time:UInt):Void{
        if(_currentBank.length != 0 || _prevBank.length != 0){
            if( time > _lastWithdraw+config.objectHardReferenceTimer*1000){
                _prevBank = _currentBank;
                _currentBank = new Array();
                _lastWithdraw = time;
            }
        }
    }
    public function setLogRef(o:Dynamic):UInt{
        if(!config.useObjectLinking) return 0;
        var ind:UInt = Reflect.field(_refRev, o);
        if(ind == 0){
            ind = _refIndex;
            //_refMap[ind] = o;
            //TODO: implement required
            _refRev[o] = ind;
            if(config.objectHardReferenceTimer != 0)
            {
                _currentBank.push(o);
            }
            _refIndex++;
            // Look through every 50th older _refMap ids and delete empty ones
            // 50s rather than all to be faster.
            var i:Int = ind-50;
            while(i>=0){
                /*if(_refMap[i] == null)
                {
                    delete _refMap[i];
                }*/
                //TODO: implement required
                i-=50;
            }
        }
        return ind;
    }
    public function getRefId(o:Dynamic):UInt
    {
        return _refRev[o];
    }
    public function getRefById(ind:UInt):Dynamic
    {
        //return _refMap[ind];
        //TODO: implement required
        return null;
    }

    public function makeString(o:Dynamic, prop:Dynamic = null, html:Bool = false, maxlen:Int = -1):String {
        var txt:String = null;
        var v:Dynamic;
        try{
            v = prop != null ? Reflect.field(o, prop) : o;
        }catch(err:Error){
            //return "<p0><i>"+err.toString()+"</i></p0>";
            //TODO: implement required
            return "makeString: implement required.";
        }
        if(Std.is(v, Error)) {
            var err:Error = cast(v, Error);
            // err.getStackTrace() is not supported in non-debugger players...
            /*var stackstr:String = err.hasOwnProperty("getStackTrace")?err.getStackTrace():err.toString();
            if(stackstr != null){
                return stackstr;
            }
            return err.toString();
        }else if(Std.is(v, XML) || Std.is(v, XMLList)){
            return shortenString(EscHTML(cast(v, XML).toXMLString()), maxlen, o, prop);
        }else if(Std.is(v, QName)){
            return cast(v, String);*/
            //TODO: implement required
        }else if(Std.is(v, Array) || openfl.Lib.getQualifiedClassName(v).indexOf("__AS3__.vec::Vector.") == 0){
            // note: using openfl.Lib.getQualifiedClassName for vector for backward compatibility
            // Need to specifically cast to string in array to produce correct results
            // e.g: new Array("str",null,undefined,0).toString() // traces to: str,,,0, SHOULD BE: str,null,undefined,0
            var str:String = "[";
            var len:Int = cast(v, Array<Dynamic>).length;
            var hasmaxlen:Bool = maxlen>=0;
            for(i in 0...len){
                var strpart:String = makeString(v[i], null, false, maxlen);
                str += (i != 0 ? ", " : "") + strpart;
                maxlen -= strpart.length;
                if(hasmaxlen && maxlen<=0 && i<len-1){
                    str += ", "+genLinkString(o, prop, "...");
                    break;
                }
            }
            return str+"]";
        }else if(config.useObjectLinking && v != null && Type.typeof(v) == ValueType.TObject) {
            var add:String = "";
            if(Std.is(v, Bytes)) add = " position:"+cast(v, ByteArray).position+" length:"+cast(v, ByteArray).length;
            else if(Std.is(v, Date) || Std.is(v, Rectangle) || Std.is(v, Point) || Std.is(v, Matrix) || Std.is(v, Event)) add = " "+ cast(v, String);
            else if(Std.is(v, DisplayObject) && cast(v, DisplayObject).name != null) add = " "+cast(v, DisplayObject).name;
            txt = "{"+genLinkString(o, prop, ShortClassName(v))+EscHTML(add)+"}";
        }else{
            if(Std.is(v, Bytes)) txt = "[ByteArray position:"+cast(v, ByteArray).position+" length:"+cast(v, ByteArray).length+"]";
            else txt = cast(v, String);
            if(!html){
                return shortenString(EscHTML(txt), maxlen, o, prop);
            }
        }
        return txt;
    }

    public function makeRefTyped(v:Dynamic):String{
        //if(v != null && Type.typeof(v) == ValueType.TObject && !Std.is(v, QName)){
        //TODO: implement required
        if(v != null && Type.typeof(v) == ValueType.TObject){
            return "{"+genLinkString(v, null, ShortClassName(v))+"}";
        }
        return ShortClassName(v);
    }

    private function genLinkString(o:Dynamic, prop:Dynamic, str:String):String{
        if(prop != null && !Std.is(prop, String)) {
            o = o[prop];
            prop = null;
        }
        var ind:UInt = setLogRef(o);
        if(ind != 0){
            return "<menu><a href='event:ref_"+ind+(prop?("_"+prop):"")+"'>"+str+"</a></menu>";
        }else{
            return str;
        }
    }
    private function shortenString(str:String, maxlen:Int, o:Dynamic, prop:Dynamic = null):String{
        if(maxlen>=0 && str.length > maxlen) {
            str = str.substring(0, maxlen);
            return str+genLinkString(o, prop, " ...");
        }
        return str;
    }
    private function historyInc(i:Int):Void {
        _hisIndex+=i;
        var v:Dynamic = _history[_hisIndex];
        if(v){
            focus(v, _dofull);
        }
    }

    public function handleRefEvent(str:String):Void {
        if(remoter.remoting == Remoting.RECIEVER){
            var bytes:ByteArray = new ByteArray();
            bytes.writeUTF(str);
            remoter.send("ref", bytes);
        }else{
            handleString(str);
        }
    }

    private function handleString(str:String):Void {
        if(str == "refexit"){
            exitFocus();
            console.setViewingChannels([]);
        }else if(str == "refprev"){
            historyInc(-2);
        }else if(str == "reffwd"){
            historyInc(0);
        }else if(str == "refi"){
            focus(_current, !_dofull);
        }else{
            var ind1:Int = str.indexOf("_")+1;
            if(ind1>0){
                var id:UInt;
                var prop:String = "";
                var ind2:Int = str.indexOf("_", ind1);
                if(ind2>0){
                    id = cast(str.substring(ind1, ind2), UInt);
                    prop = str.substring(ind2+1);
                }else{
                    id = cast(str.substring(ind1), UInt);
                }
                var o:Dynamic = getRefById(id);
                if(prop != null) o = Reflect.field(o, prop);
                if(o != null){
                    if(str.indexOf("refe_")==0){
                        console.explodech(console.panels.mainPanel.reportChannel, o);
                    }else{
                        focus(o, _dofull);
                    }
                    return;
                }
            }
            report("Reference no longer exist (garbage collected).", -2);
        }
    }

    public function focus(o:Dynamic, full:Bool = false):Void{
        remoter.send("focus");
        console.clear(LogReferences.INSPECTING_CHANNEL);
        console.setViewingChannels([LogReferences.INSPECTING_CHANNEL]);

        if(_history == null) _history = new Array();

        if(_current != o){
            _current = o; // current is kept as hard reference so that it stays...
            if(_history.length <= _hisIndex) _history.push(o);
            else _history[_hisIndex] = o;
            _hisIndex++;
        }
        _dofull = full;
        inspect(o, _dofull);
    }

    private function handleFocused():Void{
        console.clear(LogReferences.INSPECTING_CHANNEL);
        console.setViewingChannels([LogReferences.INSPECTING_CHANNEL]);
    }

    public function exitFocus():Void{
        _current = null;
        _dofull = false;
        _history = null;
        _hisIndex = 0;
        if(remoter.remoting == Remoting.SENDER){
            var bytes:ByteArray = new ByteArray();
            bytes.writeUTF("refexit");
            remoter.send("ref", bytes);
        }
        console.clear(LogReferences.INSPECTING_CHANNEL);
    }


    public function inspect(obj:Dynamic, viewAll:Bool= true, ch:String = null):Void {
        //TODO: source code is completely incompatible.
        //TODO: Fix this issue!
    }

    public function getPossibleCalls(obj:Dynamic):Array<String> {
        var list:Array<String> = new Array();
        /*var V:XML = describeType(obj);
        var nodes:XMLList = V.method;
        for (methodX in nodes) {
            var params:Array<String> = [];
            var mparamsList:XMLList = methodX.parameter;
            for each(var paraX:XML in mparamsList){
                params.push(paraX.@optional=="true"?("<i>"+paraX.@type+"</i>"):paraX.@type);
            }
            list.push([methodX.@name+"(", params.join(", ")+" ):"+methodX.@returnType]);
        }
        nodes = V.accessor;
        for each (var accessorX:XML in nodes) {
            list.push([String(accessorX.@name), String(accessorX.@type)]);
        }
        nodes = V.variable;
        for each (var variableX:XML in nodes) {
            list.push([String(variableX.@name), String(variableX.@type)]);
        }*/
        //TODO: implement required
        return list;
    }
    private function makeValue(obj:Dynamic, prop:Dynamic = null):String{
        return makeString(obj, prop, false, config.useObjectLinking?100:-1);
    }


    public static function EscHTML(str:String):String{
        //return str.replace(/</g, "&lt;").replace(/\>/g, "&gt;").replace(/\x00/g, "");
        //TODO: implement required
        return str;
    }
    /*public static function UnEscHTML(str:String):String{
	 		return str.replace(/&lt;/g, "<").replace(/&gt;/g, ">");
		}*/
    /** 
		 * Produces class name without package path
		 * e.g: openfl.display.Sprite => Sprite
		 */
    public static function ShortClassName(obj:Dynamic, eschtml:Bool = true):String{
        var str:String = openfl.Lib.getQualifiedClassName(obj);
        var ind:Int = str.indexOf("::");
        var st:String = Std.is(obj, Class)?"*":"";
        str = st+str.substring(ind>=0?(ind+2):0)+st;
        if(eschtml) return EscHTML(str);
        return str;
    }
}