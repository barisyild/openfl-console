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

import openfl.display.Stage;
import openfl.display.Tile;
import com.junkbyte.console.utils.FlashRegex;
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
        var ind:UInt = 0;
        if(Reflect.hasField(_refRev, o))
        {
            ind = Reflect.field(_refRev, o);
        }
        if(ind == 0){
            ind = _refIndex;
            _refMap.set(Std.string(ind), o);
            var test = _refMap.get(Std.string(ind));
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
                if(_refMap.exists(Std.string(i)))
                {
                    _refMap.remove(Std.string(i));
                }
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
        return _refMap.get(Std.string(ind));
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
            var stackstr:String = Reflect.hasField(err, "getStackTrace")?err.getStackTrace():Std.string(err);
            if(stackstr != null){
                return stackstr;
            }
            return Std.string(err);
        /*}else if(Std.is(v, XML) || Std.is(v, XMLList)){
            return shortenString(EscHTML(cast(v, XML).toXMLString()), maxlen, o, prop);
        }else if(Std.is(v, QName)){
            return cast(v, String);*/
            //TODO: implement required
        //}else if(Std.is(v, Array) || openfl.Lib.getQualifiedClassName(v).indexOf("__AS3__.vec::Vector.") == 0){
            //TODO: implement required
        }else if(Std.is(v, Array)){
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
        //}else if(config.useObjectLinking && v && typeof v == "object") {
        //TODO: implement required
        }else if(config.useObjectLinking && v != null && (Std.is(v, DisplayObject) || Std.is(v, Class))) {
            var add:String = "";
            if(Std.is(v, Bytes)) add = " position:"+cast(v, ByteArray).position+" length:"+cast(v, ByteArray).length;
            else if(Std.is(v, Date) || Std.is(v, Rectangle) || Std.is(v, Point) || Std.is(v, Matrix) || Std.is(v, Event)) add = " "+ cast(v, String);
            else if(Std.is(v, DisplayObject) && cast(v, DisplayObject).name != null) add = " "+cast(v, DisplayObject).name;
            txt = "{"+genLinkString(o, prop, ShortClassName(v))+EscHTML(add)+"}";
        }else{
            if(Std.is(v, Bytes)) txt = "[ByteArray position:"+cast(v, ByteArray).position+" length:"+cast(v, ByteArray).length+"]";
            else txt = Std.string(v);
            if(!html){
                return shortenString(EscHTML(txt), maxlen, o, prop);
            }
        }
        return txt;
    }

    public function makeRefTyped(v:Dynamic):String{
        //if(v != null && Type.typeof(v) == ValueType.TObject && !Std.is(v, QName))
        //TODO: implement required
        if(v != null && (Type.typeof(v) == ValueType.TObject || Std.is(v, DisplayObject) || Std.is(v, Tile)))
        {
            return "{" + genLinkString(v, null, ShortClassName(v)) + "}";
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
                    id = Std.parseInt(str.substring(ind1, ind2));
                    prop = str.substring(ind2+1);
                }else{
                    id = Std.parseInt(str.substring(ind1));
                }
                var o:Dynamic = getRefById(id);
                //if(prop != null)
                    //o = Reflect.field(o, prop);
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
            _current = o;
            if(_history.length <= _hisIndex)
                _history.push(o);
            else
                _history[_hisIndex] = o;
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

        if(!obj){
            report(obj, -2, true, ch);
            return;
        }
        var refIndex:UInt = setLogRef(obj);
        var showInherit:String = "";
        if(!viewAll)
            showInherit = " [<a href='event:refi'>show inherited</a>]";
        var menuStr:String = null;
        if(_history != null){
            menuStr = "<b>[<a href='event:refexit'>exit</a>]";
            if(_hisIndex>1){
                menuStr += " [<a href='event:refprev'>previous</a>]";
            }
            if(_history != null && _hisIndex < _history.length){
                menuStr += " [<a href='event:reffwd'>forward</a>]";
            }
            menuStr += "</b> || [<a href='event:ref_"+refIndex+"'>refresh</a>]";
            menuStr += "</b> [<a href='event:refe_"+refIndex+"'>explode</a>]";
            if(config.commandLineAllowed){
                menuStr += " [<a href='event:cl_"+refIndex+"'>scope</a>]";
            }

            if(viewAll)
                menuStr += " [<a href='event:refi'>hide inherited</a>]";
            else
                menuStr += showInherit;
            report(menuStr, -1, true, ch);
            report("", 1, true, ch);
        }
        //
        // Class extends... extendsClass
        // Class implements... implementsInterface
        // constant // statics
        // methods
        // accessors
        // varaibles
        // values
        // EVENTS .. metadata name="Event"
        //;
        var objClass:Class<Dynamic> = Type.getClass(obj);
        var self:String = Type.getClassName(objClass);
        var isClass:Bool = Std.is(obj, Class);
        var st:String = isClass?"*":"";
        var str:String = "<b>{"+st+genLinkString(obj, null, EscHTML(self))+st+"}</b>";
        var props:Array<String> = [];

        /*if(V.isStatic=="true"){
            props.push("<b>static</b>");
        }

        if(V.isDynamic=="true"){
            props.push("dynamic");
        }

        if(V.isFinal=="true"){
            props.push("final");
        }

        if(props.length > 0){
            str += " <p-1>"+props.join(" | ")+"</p-1>";
        }*/
        //TODO: implement required
        report(str, -2, true, ch);

        //
        // extends...
        //

        var fields = Executer.resolveAllFields(objClass);

        if(fields == null)
        {
            trace("fields null!");
            //describeType can be used for flash?
            return;
        }

        /*
        fields.staticFunctions;
        fields.variables;
        fields.functions;*/

        var staticVariables:Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            isStatic: Bool
        }> = fields.staticVariables;

        var staticFunctions: Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            variables: Map<String, {
                type:String,
                optional:Bool,
                value:Dynamic
            }>,
            isStatic: Bool
        }> = fields.staticFunctions;

        var variables: Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            isStatic: Bool
        }> = fields.variables;

        var functions: Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            variables: Map<String, {
                type:String,
                optional:Bool,
                value:Dynamic
            }>,
            isStatic: Bool
        }> = fields.functions;

        var superClasses:Array<String> = fields.superClasses;

        if(superClasses.length != 0)
        {
            props = [];
            for(superClass in superClasses) {
                props.push(st.indexOf("*") < 0 ? makeValue(Type.resolveClass(superClass)) : EscHTML(superClass));
                if(!viewAll)
                    break;
            }
            report("<p10>Extends:</p10> "+props.join(" &gt; "), 1, true, ch);
        }
        //
        // implements...
        //
        /*nodes = V.implementsInterface;
        if(nodes.length() != 0){
            props = [];
            for(implementX in nodes) {
                props.push(makeValue(getDefinitionByName(implementX.type.toString())));
            }
            report("<p10>Implements:</p10> "+props.join(", "), 1, true, ch);
        }
        report("", 1, true, ch);*/
        //TODO: implement required

        //
        // events
        // metadata name="Event"
        /*props = [];
        nodes = V.metadata.name == "Event";
        if(nodes.length() != 0){
            for(metadataX in nodes) {
                var mn:XMLList = metadataX.arg;
                var en:String = (mn.key=="name").value;
                var et:String = (mn.key=="type").value;
                if(refIndex != 0)
                    props.push("<a href='event:cl_"+refIndex+"_dispatchEvent(new "+et+"(\""+en+"\"))'>"+en+"</a><p0>("+et+")</p0>");
                else props.push(en+"<p0>("+et+")</p0>");
            }
            report("<p10>Events:</p10> "+props.join("<p-1>; </p-1>"), 1, true, ch);
            report("", 1, true, ch);
        }*/
        //TODO: implement required

        //
        // display's parents and direct children
        //
        if (Std.is(obj, DisplayObject)) {
            var disp:DisplayObject = cast(obj, DisplayObject);
            var theParent:DisplayObjectContainer = cast disp.parent;
            if (theParent != null) {
                props = [""+theParent.getChildIndex(disp)];
                while (theParent != null) {
                    var pr:DisplayObjectContainer = cast theParent;
                    theParent = theParent.parent;
                    var indstr:String = theParent != null ? "" + theParent.getChildIndex(pr) : "";
                    props.push("<b>"+pr.name+"</b>"+indstr+makeValue(pr));
                }
                report("<p10>Parents:</p10> "+props.join("<p-1> -> </p-1>")+"<br/>", 1, true, ch);
            }
        }

        if (Std.is(obj, DisplayObjectContainer)) {
            props = [];
            var cont:DisplayObjectContainer = cast(obj, DisplayObjectContainer);
            var clen:Int = cont.numChildren;
            for (ci in 0...clen) {
                var child:DisplayObject = cont.getChildAt(ci);
                props.push("<b>"+child.name+"</b>"+ci+makeValue(child));
            }
            if(clen != 0){
                report("<p10>Children:</p10> "+props.join("<p-1>; </p-1>")+"<br/>", 1, true, ch);
            }
        }


        if(Std.is(obj, Stage))
        {
            if(Std.is(obj, String)){
                report("", 1, true, ch);
                report("String", 10, true, ch);
                report(EscHTML(obj), 1, true, ch);
            }/*else if(obj is XML || obj is XMLList){
                report("", 1, true, ch);
                report("XMLString", 10, true, ch);
                report(EscHTML(obj.toXMLString()), 1, true, ch);
            }*/
            //TODO: implement required
            if(menuStr != null){
                report("", 1, true, ch);
                report(menuStr, -1, true, ch);
            }
            return;
        }
        //
        // constants...
        //

        /*props = [];
        nodes = clsV.constant;
        for (constantX in nodes) {
            report(" const <p3>"+constantX.name+"</p3>:"+constantX.type+" = "+makeValue(cls, constantX.name.toString())+"</p0>", 1, true, ch);
        }
        if(nodes.length() != 0){
            report("", 1, true, ch);
        }
        var inherit:UInt = 0;
        var hasstuff:Bool;
        var isstatic:Bool;*/
        //TODO: implement required

        //
        // methods
        //

        var inherit:UInt = 0;
        var hasstuff:Bool = false;
        var allFunctions = staticFunctions.concat(functions);
        for(allFunction in allFunctions)
        {
            //if(viewAll || self==methodX.declaredBy){
            //TODO: implement required
            if(viewAll)
            {
                hasstuff = true;
                str = " "+(allFunction.isStatic?"static ":"")+"function ";

                var params:Array<String> = [];
                for(variable in allFunction.variables){
                    params.push(variable.optional?("<i>"+variable.type + " = " + variable.value + "</i>"):variable.type);
                }
                //if(refIndex != 0 && (allFunction.isStatic || !isClass))
                //TODO: implement required

                if(refIndex != 0 && (allFunction.isStatic))
                {
                    str += "<a href='event:cl_"+refIndex+"_"+allFunction.name+"()'><p3>"+allFunction.name+"</p3></a>";
                }else{
                    str += "<p3>"+allFunction.name+"</p3>";
                }
                str += "("+params.join(", ")+"):"+allFunction.type;
                report(str, 1, true, ch);
            }else{
                inherit++;
            }
        }
        if(inherit != 0)
        {
            report("   \t + "+inherit+" inherited methods."+showInherit, 1, true, ch);
        }else if(hasstuff){
            report("", 1, true, ch);
        }
        //
        // accessors
        //
        /*hasstuff = false;
        inherit = 0;
        props = [];
        nodes = clsV.accessor; // '..' to include from <factory>
        for (accessorX in nodes) {
            if(viewAll || self==accessorX.declaredBy){
                hasstuff = true;
                isstatic = accessorX.parent().name()!="factory";
                str = " ";
                if(isstatic)
                    str += "static ";
                var access:String = accessorX.access;
                if(access == "readonly") str+= "get";
                else if(access == "writeonly") str+= "set";
                else str += "assign";

                if(refIndex && (isstatic || !isClass)){
                    str += " <a href='event:cl_"+refIndex+"_"+accessorX.name+"'><p3>"+accessorX.name+"</p3></a>:"+accessorX.type;
                }else{
                    str += " <p3>"+accessorX.name+"</p3>:"+accessorX.type;
                }
                if(access != "writeonly" && (isstatic || !isClass))
                {
                    str += " = "+makeValue(isstatic?cls:obj, accessorX.name.toString());
                }
                report(str, 1, true, ch);
            }else{
                inherit++;
            }
        }
        if(inherit){
            report("   \t + "+inherit+" inherited accessors."+showInherit, 1, true, ch);
        }else if(hasstuff){
            report("", 1, true, ch);
        }*/
        //TODO: implement required

        //
        // variables
        //
        var allVariables = staticVariables.concat(variables);
        for (allVariable in allVariables) {
            str = allVariable.isStatic?" static":"";
            if(refIndex != 0)
                str += " var <p3><a href='event:cl_"+refIndex+"_"+allVariable.name+" = '>"+allVariable.name+"</a>";
            else str += " var <p3>"+allVariable.name;
            str += "</p3>:"+allVariable.type+" = "+makeValue(allVariable.isStatic ? Type.getClass(obj) : obj, allVariable.name);
            report(str, 1, true, ch);
        }
        //
        // dynamic values
        // - It can sometimes fail if we are looking at proxy object which havnt extended nextNameIndex, nextName, etc.
        /*try{
            props = [];
            for (X in obj) {
                if(Std.is(X, String)){
                    if(refIndex != 0)
                        str = "<a href='event:cl_"+refIndex+"_"+X+" = '>"+X+"</a>";
                    else str = X;
                    report(" dynamic var <p3>"+str+"</p3> = "+makeValue(obj, X), 1, true, ch);
                }else{
                    report(" dictionary <p3>"+makeValue(X)+"</p3> = "+makeValue(obj, X), 1, true, ch);
                }
            }
        } catch(e : Error) {
            report("Could not get dynamic values. " + e.message, 9, false, ch);
        }*/
        //TODO: implement required

        if(Std.is(obj, String)){
            report("", 1, true, ch);
            report("String", 10, true, ch);
            report(EscHTML(obj), 1, true, ch);
        }/*else if(obj is XML || obj is XMLList){
        report("", 1, true, ch);
        report("XMLString", 10, true, ch);
        report(EscHTML(obj.toXMLString()), 1, true, ch);
        }*/
        //TODO: implement required
        if(menuStr != null){
            report("", 1, true, ch);
            report(menuStr, -1, true, ch);
        }
    }

    public function getPossibleCalls(obj:Dynamic):Array<Array<String>> {
        var list:Array<Array<String>> = new Array();

        var fields = Executer.resolveAllFields(Type.getClass(obj));

        if(fields == null)
        {
            //describeType can be used for flash?
            return list;
        }

        /*
        fields.staticFunctions;
        fields.variables;
        fields.functions;*/

        var staticVariables:Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            isStatic: Bool
        }> = fields.staticVariables;

        var staticFunctions: Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            variables: Map<String, {
                type:String,
                optional:Bool,
                value:Dynamic
            }>,
            isStatic: Bool
        }> = fields.staticFunctions;

        var variables: Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            isStatic: Bool
        }> = fields.variables;

        var functions: Array<{
            name: String,
            type: String,
            isFunction: Bool,
            isPublic: Bool,
            isFinal: Bool,
            isOverride: Bool,
            variables: Map<String, {
                type:String,
                optional:Bool,
                value:Dynamic
            }>,
            isStatic: Bool
        }> = fields.functions;

        for(field in functions)
        {
            var params:Array<String> = [];

            if(field.isPublic && !field.isOverride)
            {
                var params:Array<String> = [];
                for(variable in field.variables){
                    params.push(variable.optional?("<i>"+variable.type + " = " + variable.value + "</i>"):variable.type);
                }
                list.push([field.name+"(", params.join(", ")+" ):"+field.type]);
            }
        }


        for(field in variables)
        {
            if(field.isPublic)
            {
                list.push([field.name, field.type]);
            }
        }


        /*
        var list:Array = new Array();
			var V:XML = describeType(obj);
			var nodes:XMLList = V.method;
			for each (var methodX:XML in nodes) {
				var params:Array = [];
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
			}
			return list;
         */
        //TODO: implement required
        return list;
    }
    private function makeValue(obj:Dynamic, prop:Dynamic = null):String{
        return makeString(obj, prop, false, config.useObjectLinking?100:-1);
    }


    public static function EscHTML(str:String):String{
        str = FlashRegex.replace(str, ~/</g, "&lt;");
        str = FlashRegex.replace(str, ~/\\>/g, "&gt;");
        //TODO: Check if Regex is working.
        str = FlashRegex.replace(str, ~/\x00/g, "");
        return str;
    }
    /** 
     * Produces class name without package path
     * e.g: openfl.display.Sprite => Sprite
     */
    public static function ShortClassName(obj:Dynamic, eschtml:Bool = true):String{
        var str:String;
        if(Reflect.isFunction(obj))
        {
            str = "builtin.as$0::MethodClosure";
        }else{
            //getQualifiedClassName working little bit different in openfl.
            //getQualifiedClassName does not return results to functions.
            str = openfl.Lib.getQualifiedClassName(obj);
        }

        var ind:Int = str.indexOf("::");
        var st:String = Std.is(obj, Class)?"*":"";
        str = st+str.substring(ind>=0?(ind+2):0)+st;
        if(eschtml)
            return EscHTML(str);
        return str;
    }
}